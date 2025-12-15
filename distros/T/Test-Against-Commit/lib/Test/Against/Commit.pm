package Test::Against::Commit;
use strict;
use 5.14.0;
our $VERSION = '0.17';
# core modules
use Archive::Tar;
use Carp;
use Cwd;
use File::Path ( qw| make_path | );
use File::Spec;
use File::Temp ( qw| tempfile | );
# non-core modules
use CPAN::cpanminus::reporter::RetainReports;
use Data::Dump ( qw| dd pp | );
use JSON;
use Path::Tiny;
use Text::CSV_XS;

=head1 NAME

Test::Against::Commit - Test CPAN modules against Perl dev releases, branches or individual commits

=head1 SYNOPSIS

    my $self = Test::Against::Commit->new( {
        application_dir => '/path/to/application',
        project         => 'business_project',
        install          => <commit_ID_tag_or_branch>,
    } );

    $self->prepare_testing_directories();

    my $this_cpanm = $self->fetch_cpanm( { verbose => 1 } );

    my $modules_ref = $self->process_modules( {
        module_file => '/path/to/cpan-river-file.txt',
        title       => 'cpan-river-1000',
        verbose     => 1,
    } );

=head1 DESCRIPTION

=head2 Who Should Use This Library?

This library should be used by anyone who wishes to assess the impact of
day-to-day changes in the Perl 5 core distribution on the installability of
libraries found on the Comprehensive Perl Archive Network (CPAN).  This
library supersedes the existing CPAN library
L<Test-Against-Dev|https://metacpan.org/dist/Test-Against-Dev>.

=head2 The Problem Addressed by This Library

In the development of Perl as a language we face a problem typically referred
to as B<Blead Breaks CPAN> (or B<BBC> for short).  Perl 5 undergoes an annual
development cycle characterized by:

=over 4

=item *

Commits on a near daily basis to a L<GitHub (GH)
repository|https://github.com/Perl/perl5>.

=item *

Monthly development releases (tarballs) whose version numbers follow the
convention of C<5.43.0>, C<5.43.1>, etc., where the middle digits are always
odd numbers.

=item *

Annual production releases and subsequent maintenance releases whose version
numbers have even-numbered middle digits, I<e.g.>, C<5.44.0>, C<5.44.1>, etc.

=back

A monthly development release is essentially a roll-up of a month's worth of
commits to the master repository branch known as B<blead> (pronounced
I<"bleed">).  Changes in the Perl 5 code base have the potential to adversely
impact the installability of existing CPAN libraries.  Hence, various
individuals have, over the years, developed ways of testing those libraries
against blead and reporting problems to those people actively involved in the
ongoing development of the Perl 5 core distribution.  The latter are typically
referred to as "core developers" or as the "Perl 5 Porters."

This library is intended as a contribution to those efforts by enabling the
Perl 5 Porters to assess the impact of changes in the Perl 5 core distribution
CPAN libraries well in advance of production and maintenance releases.

=head2 The Approach Test-Against-Commit Takes

Unlike other efforts, F<Test-Against-Commit> does I<not> depend on test reports
sent to L<CPANtesters.org|http://www.cpantesters.org/>.  Hence, it should be
unaffected by any technical problems which that site may face.  As a
consequence, however, a user of this library must be willing to maintain more
of her own local infrastructure than a typical CPANtester would maintain.

While this library could, in principle, be used to test the entirety of CPAN,
it is probably better suited for testing selected subsets of CPAN libraries
which the user deems important to her individual or organizational needs.

Unlike its ancestor F<Test-Against-Dev>, this library is designed to test CPAN
libraries against either Perl 5 monthly development releases or against
individual commits to any branch of any GH repository holding the Perl 5 core
distribution.  I<This library presumes that the user knows how to configure and
build a F<perl> executable and how to run the core distribution's test suite.
This library leaves the configuration, build and installation of a F<perl>
executable to the user.>  The scope of this library's activity begins at the
point that a F<perl> has been installed on disk, continues through
installation of libraries needed for testing CPAN libraries against that
executable to analysis of the results of that testing and presentation of
those results in a usable form.

While this library is currently focused on Perl 5 libraries publicly available
on CPAN, it could in principle be extended to test an organization's private
libraries as well.  This functionality, however, has not yet been implemented
or tested.

=head2 Terminology

Here are some terms which we use in a specific way in this library:

=over 4

=item * B<application directory>

A directory to which the user has write-privileges and which holds the input
and output for one or more I<projects>.  I<Example:> C</path-to-application>.

=item * B<project>

A short-hand description of the focus of a particular investigation using
Test-Against-Commit.  I<Example:> C<goto-fatal> could describe an investigation of
the impact of fatalization of certain uses of the Perl C<goto> function on
CPAN libraries.

=item * B<project directory>

A subdirectory of the I<application directory> which holds the input and
output data for one I<project>.  I<Example:> C</path-to-application/goto-fatal>.

=item * B<installation>

An installation of one F<perl> executable, the libraries that get installed
with the core distribution, CPAN libraries whose installability we tested
against that F<perl> and data gathered to analyze that installability and
answer questions for the business purpose of the I<project>.

An installation will be built either from a particular checkout, tag or branch
from a F<git> repository of the Perl 5 source code (C<23ae7f95ea>, C<v5.43.3>,
C<blead>) or from a Perl 5 development, production or maintenance release in
tarball form (C<perl-5.44.0>).

A I<project> will consist of at least one installation but will probably hold
two or three installations: the first will be used to determine a baseline
state, the second will be used to assess the impact of a proposed change in
the Perl 5 core distribution on installability of CPAN libraries.

=item * B<installation directory>

A subdirectory of the I<project directory> holding one installation.  I<Example:>

    /path-to-application/                         # <-- application directory
    /path-to-application/goto-fatal/              # <-- project directory
    /path-to-application/goto-fatal/23ae7f95ea/   # <-- installation directory
    /path-to-application/goto-fatal/v5.43.3/      # <-- another installation directory

Each installation directory will have exactly two subdirectories: C<testing>
and C<results>. (See next two items.)

=item * B<testing directory>

A subdirectory of an I<installation directory> which in turn initially holds
two subdirectories, C<bin/> and C<lib/>.

The C<bin/> directory holds the F<perl>, F<perldoc>, F<cpan> and other
executable when a particular F<perl> is built for the project.  The C<lib/>
directory holds all modules installed either initially with the executable or
subsequently, including those whose functionality we are assessing as part of
the project's business purpose.  Test-Against-Commit methods will create other
subdirectories next to C<bin/> and C<lib/>, some of which are hidden, as part
of the testing progress.

    /path-to-application/goto-fatal/23ae7f95ea/               # <-- installation directory
    /path-to-application/goto-fatal/23ae7f95ea/testing/       # <-- testing directory
    /path-to-application/goto-fatal/23ae7f95ea/testing/bin/   # <-- bin directory
    /path-to-application/goto-fatal/23ae7f95ea/testing/lib/   # <-- lib directory

The data in the I<testing directory> can be thought of as the project's
I<input> data.

=item * B<results directory>

A subdirectory of an I<installation directory> which holds the data created by
running a program using Test::Against::Commit methods.  This directory will in turn
hold two subdirectories: C<analysis/> and C<storage/>.

    /path-to-application/goto-fatal/23ae7f95ea/           # <-- installation directory
    /path-to-application/goto-fatal/23ae7f95ea/testing/   # <-- testing directory
    ...
    /path-to-application/goto-fatal/23ae7f95ea/results/   # <-- results directory
    /path-to-application/goto-fatal/23ae7f95ea/results/analysis/
    /path-to-application/goto-fatal/23ae7f95ea/results/storage/

The data in the I<results directory> can be thought of as the project's
I<output> data.

=item * B<run>

A I<run> is an instance of (i) testing a set of one or more CPAN libraries
against a given I<installation> and (ii) the recording of data from that
instance of testing.

=item * B<Perl 5 configuration>

The way one calls F<Configure> when building Perl 5 from source, <e.g.>:

    sh ./Configure -des -Dusedevel

or:

    sh ./Configure -des -Dusedevel \
        -Duseithreads \
        -Doptimize="-O2 -pipe -fstack-protector -fno-strict-aliasing"

Once you begin to use Test-Against-Commit for a particular I<project>, you
should use the same configuration for each I<installation> over the life of
that project.  For instance, you should not configure without threads in one
run but with threads in the next.  Nor should you switch from regular to
debugging builds between I<runs>.  Otherwise, the results may reflect changes
in that configuration rather than changes in Perl 5 core distribution code or
changes in the targeted CPAN libraries.

=back

=head2 What Is the Result Produced by This Library?

Our objective is to be able to compare output data recorded in one I<run> for
a given I<project> with data recorded in a different I<run> for a different
(presumably subsequent) installation within the same I<project>.  To return to
the example of the I<goto-fatal> project, let's assume we have two different
installations, the first of which sets our baseline (which CPAN libraries
currently C<PASS> and which currently C<FAIL>) and a second which determines
the impact of applying a pull request.

    /path-to-application/goto-fatal/              # <-- project directory
    /path-to-application/goto-fatal/23ae7f95ea/   # <-- first installation directory
    /path-to-application/goto-fatal/v5.43.3/      # <-- second installation directory

We will end up comparing data stored in these installations' respective
C<results/analysis/> subdirectories.

    /path-to-application/goto-fatal/23ae7f95ea/results/analysis/
    /path-to-application/goto-fatal/v5.43.3/results/analysis/

=head2 What Preparations Are Needed to Use This Library?

=over 4

=item * Platform

The user should select a machine/platform which is likely to be reasonably
stable over one Perl 5 annual development cycle.  We presume that the
platform's system administrator will be updating system libraries for security
and other reasons over time.  But it would be a hassle to run this software on
a machine scheduled for a complete major version update of its operating
system.

=item * Perl 5 Configuration

The user must decide on a Perl 5 configuration for a given I<project> and then
must refrain from changing configurations over the course of the project's
existence.  See item under L<Terminology> above.

=item * F<perl> Executable Installation Location

As noted above, this library leaves to the user the choice of a I<way to get
the Perl source code> and the decision of I<how to configure> an individual
F<perl> executable.  It also leaves to the user, with one caveat, the decision
of I<where> to install that executable on disk.  That caveat is that the
I<installation> should reside in a directory named F<testing> which in turn
sits underneath a directory which we'll refer to as the I<application
directory>.  The user will have to manually create the I<application
directory>, the I<project directory>, the I<installation directory> and the
I<testing directory> and then use the I<testing directory> as the value for
the I<-Dprefix> option in the invocation of F<Configure>.

In terms of the directory structure discussed above, that the user would
create a directory structure something like this:

    $ cd ~/tmp
    $ export TESTINGDIR=`pwd`/all-tad-projects/goto-fatal/23ae7f95ea/testing
    $ echo $TESTINGDIR
    .../tmp/all-tad-projects/goto-fatal/23ae7f95ea/testing
    $ mkdir -p $TESTINGDIR
    $ ls -l $TESTINGDIR
    total 0

    $ cd <git checkout of perl branch or decompressed release tarball>

The user would then invoke F<Configure> in a way something like this:

    $ sh ./Configure -des -Dusedevel -Dprefix=$TESTINGDIR \
        -Uversiononly -Dman1dir=none -Dman3dir=none
    $ make install

The user could then confirm installation with this:

    $ $TESTINGDIR/bin/perl -v | head -2 | tail -1
    This is perl 5, version 43, subversion 3 (v5.43.3 (v5.43.2-343-g5fdb3e501b)) built for x86_64-linux

Note that at this point we have not yet created the I<results directory> ...

    $ cd ~/tmp
    $ ls -l ./all-tad-projects/goto-fatal/23ae7f95ea/results
    ... No such file or directory

... but no worries; Test-Against-Commit methods will handle that.

=item * Selection of CPAN Libraries for Testing

B<This is the most important step in preparation to use this library.>

When you use this library, you are in effect saying:  I<Here is a list of CPAN
modules important enough to me that I don't want to see them begin to break in
the course of Perl's annual development cycle.  (If they do break, then the
Perl 5 Porters and the modules' authors/maintainers must address how to handle
the breakage.)  To keep track of the problem, I'm going to build F<perl> from
a starting point where those modules are working proprerly and assess their
installability at later points.>

Hence, once you decide to track a certain CPAN library, you should continue to
include it in your list of modules to be tracked for the balance of that year's
development cycle.  You can, it is true, B<add> additional modules to your
list part way through the development cycle.  You simply won't have the same
baseline data that you have for the modules you selected at the very
beginning.

Here are some approaches that come to mind:

=over 4

=item * CPAN river

The CPAN river is a concept developed by Neil Bowers and other participants in
the Perl Toolchain Gang and Perl QA Hackathons and Summits.  The concept
starts from the premise that CPAN libraries upon which many other CPAN
libraries depend are more important than those upon which few other libraries
depend.  That's a useful definition of importance even if it is far from strictly
true.  Modules "way upstream" feed modules and real-world code "farther
downstream."  Hence, if Perl 5's development branch changes in a way such that
"upstream" modules start to fail to configure, build, test and install
correctly, then we have a potentially serious problem.

=item * Organizational dependencies

Many organizations use technologies such as F<Carton> and F<cpanfile> to keep
track of their dependencies on CPAN libraries.  The lists compiled by such
applications could very easily be translated into a list of modules tested
once a month against a Perl development release.

=item * What repeatedly breaks

Certain CPAN libraries get broken relatively frequently.  While this can
happen because of sub-standard coding practices in those libraries, it more
often happens because these libraries, in order to do what they want to do,
reach down deep into the Perl 5 guts and use features of the Perl-to-C API.

=back

=back

=head1 METHODS

=head2 C<new()>

=over 4

=item * Purpose

Test::Against::Commit constructor.  Guarantees that the top-level directory for
the application (C<application_dir>) already exists, then creates two
directories thereunder:  F<testing/> and F<results/>.

=item * Arguments

    my $self = Test::Against::Commit->new( {
        application_dir => '/path/to/application',
        project => 'goto-fatal'
        install => '23ae7f95ea',
    } );

Takes a hash reference with the following elements:

=over 4

=item * C<application_dir>

String holding path to the directory which will serve as the top level for all
projects using Test-Against-Commit technology.

=item * C<project>

String holding a short name for your current business project.

=item * C<install>

String holding a name for the specific I<installation> of F<perl> against which you
will be attempting to install CPAN modules.  If you have built F<perl> from
a F<git> checkout, this should be the F<git> commit ID (SHA), F<git> tag or
F<git> branch name from which you are starting.  If you are building F<perl>
from a release tarball, consider using a string such as C<perl-5.42.0> from
the tarball's basename.

=back

=item * Return Value

Test::Against::Commit object.

=item * Comment

The constructor merely verifies the existence of certain directories on your
machine.  It does not install a F<perl> executable.  That is the user's
responsibility.  The user will subsequently have to call the
C<prepare_testing_directory()> and perhaps C<fetch_cpanm()> to be fully ready
to test.

=back

=cut

sub new {
    my ($class, $args) = @_;

    croak "Argument to constructor must be hashref"
        unless ref($args) eq 'HASH';
    croak "Hash ref must contain 'application_dir' element"
        unless $args->{application_dir};
    croak "Hash ref must contain 'install' element"
        unless $args->{install};
    croak "Could not locate application directory $args->{application_dir}"
        unless (-d $args->{application_dir});
    croak "Must supply name for project"
        unless length($args->{project});

    my %verified = ();
    my $project_dir = File::Spec->catdir($args->{application_dir}, $args->{project});
    unless (-d $project_dir) { make_path($project_dir, { mode => 0755 }); }
    $verified{project_dir} = $project_dir;
    my $install_dir = File::Spec->catdir($project_dir, $args->{install});
    unless (-d $install_dir) { make_path($install_dir, { mode => 0755 }); }
    $verified{install_dir} = $install_dir;

    for my $dir (qw| testing results |) {
        my $fdir = File::Spec->catdir($install_dir, $dir);
        unless (-d $fdir) { make_path($fdir, { mode => 0755 }); }
        my $k = $dir . '_dir';
        $verified{$k} = $fdir;
    }

    my $data;
    for my $k (keys %{$args}) {
        $data->{$k} = $args->{$k};
    }
    for my $k (keys %verified) {
        $data->{$k} = $verified{$k};
    }

    return bless $data, $class;
}

=head2 C<get_application_dir() get_project_dir() get_install_dir() get_testing_dir() get_results_dir()>

=over 4

=item * Purpose

Methods which simply return the path to relevant directories (along with
I<short-hand versions> of their name):

=over 4

=item * application directory (I<application_dir>)

The top-level directory for all code and data implemented by
Test-Against-Commit.  It will typically hold 1 subdirectory for each business
project using Test-Against-Commit technology.

=item * project directory (I<project_dir>)

TK

=item * install directory (I<install_dir>)

TK

=item * testing directory (I<testing_dir>)

A directory which holds one or more subdirectories, each of which contains an
installation of a perl executable.  That installation will start off with
C<bin/> and C<lib/> subdirectories and C<./bin/perl -Ilib -v> will be called
to demonstrate the presence of a viable F<perl>.

=item * results directory (I<results_dir>)

The directory under which all data created by runs of programs using
Test::Against::Commit will be placed.  This will include data in JSON and
pipe-separated-value (PSV) formats.

=back

=item * Arguments

    $application_dir = $self->get_application_dir();

    $project_dir = $self->get_project_dir();

    $install_dir = $self->get_install_dir();

    $testing_dir = $self->get_testing_dir();

    $results_dir = $self->get_results_dir();

=item * Return Value

String holding a path to the named directory.

=item * Comment

These methods become available once a F<perl> executable has been installed
and C<new()> has been run.

=back

=cut

sub get_application_dir {
    my $self = shift;
    return $self->{application_dir};
}

sub get_project_dir {
    my $self = shift;
    return $self->{project_dir};
}

sub get_install_dir {
    my $self = shift;
    return $self->{install_dir};
}

sub get_testing_dir {
    my $self = shift;
    return $self->{testing_dir};
}

sub get_results_dir {
    my $self = shift;
    return $self->{results_dir};
}

=head2 C<get_install()>

=over 4

=item * Purpose

Each F<perl> installed underneath C<testing_dir> needs a unique name.  If we
build this F<perl> from a F<git> checkout, this should be one of the commit ID
(SHA), tag or branch name of the checkout.

=item * Arguments

    my $install = $self->get_install();

=item * Return Value

String holding a F<git> commit ID, tag or branch name.

=item * Comment

Since C<install> is one of the key-value pairs we are handing to C<new()>, this
method essentially just gives us back what we already told it.  However, we
will use it internally later to derive the path to the installed F<perl>
against which we are trying to install modules.

TK:  What about when we're building from a tarball?

=back

=cut

sub get_install {
    my $self = shift;
    return $self->{install};
}

=head2 C<prepare_testing_directory>

=over 4

=item * Purpose

Determines whether the F<perl> executable has been installed -- I<if not, it's
the user's responsibility to install it> -- and whether this application has
the correct directory structure.

=item * Arguments

    $self->prepare_testing_directory()

=item * Return Value

Returns the Test::Against::Commit object, which now holds additional data.

=item * Comment

TK

=back

=cut

sub prepare_testing_directory {
    my $self = shift;

    for my $dir (qw| bin lib|) {
        my $subdir = File::Spec->catdir($self->{testing_dir}, $dir);
        if (-d $subdir) {
            my $this = $dir . '_dir';
            $self->{$this} = $subdir;
        }
        else {
            croak "Could not locate $subdir; have you built and installed a perl executable?";
        }
    }
    my $lib_dir = $self->get_lib_dir();
    my $this_perl = File::Spec->catfile($self->get_bin_dir, 'perl');
    my $invoke = "$this_perl -I$lib_dir";
    my $rv = system(qq{$invoke -v | head -n 2 | tail -n 1})
        and croak "Could not run perl executable at $this_perl";
    $self->{this_perl} = $this_perl;

    my $this_cpan = File::Spec->catfile($self->get_bin_dir, 'cpan');
    $invoke = "$this_cpan -v";
    $rv = system(qq{$invoke})
        and croak "Could not run cpan executable at $this_cpan";
    $self->{this_cpan} = $this_cpan;

    return $self;
}

=head2 C<get_bin_dir() get_lib_dir()>

=over 4

=item * Purpose

Once C<prepare_testing_directory()> has been run, two additional methods
become available to help the code determine where it is.

=over 4

=item * bin directory (I<bin_dir>)

The directory underneath an individual C<install_dir> directory holding installed
executables such as F<perl>, F<cpan> and F<cpanm>.

=item * lib directory (I<lib_dir>)

The directory underneath an individual C<install_dir> directory holding the
libraries supporting the installed executables found in the C<bin_dir>.

=back

=item * Arguments

    $bin_dir = $self->get_bin_dir();

    $lib_dir = $self->get_lib_dir();

=item * Return Value

String holding a path to the named directory.

=item * Comment

If the F<perl> executable has not yet been installed, these methods will
throw exceptions.

=back

=cut

sub get_bin_dir {
    my $self = shift;
    if (! defined $self->{bin_dir}) {
        croak "bin directory has not yet been defined; have you installed perl?";
    }
    else {
        return $self->{bin_dir};
    }
}

sub get_lib_dir {
    my $self = shift;
    if (! defined $self->{lib_dir}) {
        croak "lib directory has not yet been defined; have you installed perl?";
    }
    else {
        return $self->{lib_dir};
    }
}

=head2 C<get_this_perl()>

=over 4

=item * Purpose

Identify the location of the F<perl> executable file being tested.

=item * Arguments

    $this_perl = $self->get_this_perl()

=item * Return Value

String holding the path to the F<perl> executable being tested.

=item * Comment

Will throw an exception if such a F<perl> executable has not yet been installed.

=back

=cut

sub get_this_perl {
    my $self = shift;
    if ($self->{this_perl}) {
        return $self->{this_perl};
    }
    else {
        local $@;
        my $this_perl;
        eval {
            $this_perl = File::Spec->catfile($self->get_bin_dir, 'perl');
        };
        if ($@) {
            croak $@;
        }
        elsif (-e $this_perl) {
            $self->{this_perl} = $this_perl;
            return $self->{this_perl};
        }
        else {
            croak "No executable perl found at: $this_perl";
        }
    }
}

=head2 C<get_this_cpan()>

=over 4

=item * Purpose

Identify the location of the F<cpan> executable file.

=item * Arguments

    $this_cpan = $self->get_this_cpan()

=item * Return Value

String holding the path to the F<cpan> executable being tested.

=item * Comment

Will throw an exception if such a F<cpan> executable has not yet been installed.  We will use F<cpan> to subsequently install F<App::cpanminus>.

=back

=cut

sub get_this_cpan {
    my $self = shift;
    if ($self->{this_cpan}) {
        return $self->{this_cpan};
    }
    else {
        local $@;
        my $this_cpan;
        eval {
            $this_cpan = File::Spec->catfile($self->get_bin_dir, 'cpan');
        };
        if ($@) {
            croak $@;
        }
        elsif (-e $this_cpan) {
            $self->{this_cpan} = $this_cpan;
            return $self->{this_cpan};
        }
        else {
            croak "No executable cpan found at: $this_cpan";
        }
    }
}

=head2 C<fetch_cpanm() get_this_cpanm() get_cpanm_dir()>

=over 4

=item * Purpose

Determine whether F<cpanm> has been installed.  If it has not, install
F<App::cpanminus> and the F<cpanm> executable against the installed F<perl>.

=item * Arguments

    my $rv = $self->fetch_cpanm();

None.  All information is already inside the object.  No C<verbose> output.

=item * Return Value

Returns the Test::Against::Commit object, which now holds additional data.

=item * Comment

The F<cpanm> executable's location can subsequently be accessed by calling
C<$self->get_this_cpanm()>.  The method also guarantees the existence of a
F<.cpanm> directory underneath the install directory, I<i.e.,> side-by-side
with C<bin> and C<lib>.  This directory can subsequently be accessed by
calling C<$self->get_cpanm_dir()>.

=back

=cut

sub fetch_cpanm {
    my $self = shift;

    my $cpanm_dir = File::Spec->catdir($self->get_testing_dir(), '.cpanm');
    unless (-d $cpanm_dir) { make_path($cpanm_dir, { mode => 0755 }); }
    croak "Could not locate $cpanm_dir" unless (-d $cpanm_dir);
    $self->{cpanm_dir} = $cpanm_dir;

    my $bin_dir = $self->get_bin_dir();
    my $this_cpan = File::Spec->catfile($bin_dir, 'cpan');
    $self->{this_cpan} = $this_cpan;
    system(qq| $this_cpan -v 1>/dev/null |) and croak "Unable to call 'cpan -v'";
    system(qq| $this_cpan App::cpanminus 1>/dev/null |)
        and croak "Unable to use cpan to install App::cpanminus";
    my $this_cpanm = File::Spec->catfile($bin_dir, 'cpanm');
    system(qq| $this_cpanm -V 1>/dev/null |) and croak "Unable to call 'cpanm -V'";
    $self->{this_cpanm} = $this_cpanm;

    return $self;
}

sub get_this_cpanm {
    my $self = shift;
    if (! defined $self->{this_cpanm}) {
        croak "location of cpanm has not yet been defined; run fetch_cpanm()";
    }
    else {
        return $self->{this_cpanm};
    }
}

sub get_cpanm_dir {
    my $self = shift;
    if (! defined $self->{cpanm_dir}) {
        croak "cpanm directory has not yet been defined; run fetch_cpanm()";
    }
    else {
        return $self->{cpanm_dir};
    }
}

=head2 C<process_modules()>

=over 4

=item * Purpose

Use F<cpanm> to install selected Perl modules against the F<perl> built for
testing purposes.

=item * Arguments

Two mutually exclusive interfaces:

=over 4

=item * Modules provided in a list

    my $modules_ref = $self->process_modules( {
        module_list => [ 'DateTime', 'AnyEvent' ],
        title       => 'two-important-libraries',
        verbose     => 1,
    } );

=item * Modules listed in a file

    my $modules_ref = $self->process_modules( {
        module_file => '/path/to/cpan-river-file.txt',
        title       => 'cpan-river-1000',
        verbose     => 1,
    } );

=back

Each interface takes a hash reference with the following elements:

=over 4

=item * C<module_list> B<OR> C<module_file>

Mutually exclusive; you may use one or the other but not both.

The value of C<module_list> must be an array reference holding a list of
modules for which you wish to assess the impact of changes in the Perl 5 core
distribution.

The value of C<module_file> must be an absolute path to a file which holds a
list of modules, one module per line.  Lines in such a file that start with a
'C<#>' (hash-mark or sharp) be treated as a comment and no module listed on
that line will be processed.

In either case the module names are spelled in C<Some::Module> format --
I<i.e.>, double-colons -- rather than in C<Some-Distribution> format
(hyphens).

=item * C<title>

String which will be used to compose the name of project-specific output
files.  Required.

=item * C<verbose>

Extra information provided on STDOUT.  Optional; defaults to being off;
provide a Perl-true value to turn it on.  Scope is limited to this method.

=item * C<dryrun>

Optional; defaults to being off.  Program runs only as far as determining
modules which the user will attempt to load, prints number of modules being
attempted, then C<process_modules()> returns an undefined value (which would
prevent subsequent methods from running correctly).

=back

=item * Return Value

Default: Single array reference holding a list of all modules that
C<process_modules()> at least attempted to process.

With true-value for C<dryrun>: Undefined value.

=item * Comment

The method creates or confirms the existence of several directories underneath the
I<results_dir> directory discussed above.  These are illustrated as follows:

    /path-to-application/                                 # <-- application directory
    /path-to-application/goto-fatal/                      # <-- project directory
    /path-to-application/goto-fatal/23ae7f95ea/           # <-- installation directory
    /path-to-application/goto-fatal/23ae7f95ea/testing/   # <-- testing directory
    /path-to-application/goto-fatal/23ae7f95ea/results/   # <-- results directory
    /path-to-application/goto-fatal/23ae7f95ea/results/analysis/   # <-- analysis directory
    /path-to-application/goto-fatal/23ae7f95ea/results/storage/   # <-- storage directory

=back

=cut

sub process_modules {
    my ($self, $args) = @_;
    croak "process_modules: Must supply hash ref as argument"
        unless ( ( defined $args ) and ( ref($args) eq 'HASH' ) );

    my $verbose = delete $args->{verbose} || '';
    my $dryrun = delete $args->{dryrun} || '';
    my %eligible_args = map { $_ => 1 } ( qw|
        module_file module_list title
    | );
    for my $k (keys %$args) {
        croak "process_modules: '$k' is not a valid element"
            unless $eligible_args{$k};
    }

    unless (defined $args->{title} and length $args->{title}) {
        croak "Must supply value for 'title' element";
    }
    $self->{title} = $args->{title};

    if (exists $args->{module_file} and exists $args->{module_list}) {
        croak "process_modules: Supply either a file for 'module_file' or an array ref for 'module_list' but not both";
    }
    if (! (exists $args->{module_file} or exists $args->{module_list}) ) {
        croak "process_modules: Must supply one of 'module_file' or 'module_list'";
    }
    if ($args->{module_file}) {
        croak "process_modules: Could not locate '$args->{module_file}'"
            unless (-f $args->{module_file});
    }
    if ($args->{module_list}) {
        croak "process_modules: Must supply array ref for 'module_list'"
            unless ref($args->{module_list}) eq 'ARRAY';
    }

    $self->setup_results_directories();

    say "cpanm_dir: ", $self->get_cpanm_dir() if $verbose;
    local $ENV{PERL_CPANM_HOME} = $self->get_cpanm_dir();

    my @modules = ();
    if ($args->{module_list}) {
        @modules = @{$args->{module_list}};
    }
    else {
        open my $IN, '<', $args->{module_file}
            or croak "Could not open $args->{module_file} for reading";
        while (my $m = <$IN>) {
            chomp $m;
            next if $m =~ m/^#/; # Skip lines that are commented out
            push @modules, $m;
        }
        close $IN or croak "Could not close $args->{module_file} after reading";
    }
    if ($dryrun) {
        say "Planning to process ", scalar(@modules), " modules";
        if ($verbose) {
            dd(\@modules);
        }
        return;
    }

    my $libdir = $self->get_lib_dir();

    for my $m (@modules) {

        # Formulate the system call
        my @cmd = (
            $self->get_this_perl(),
            "-I$libdir",
            $self->get_this_cpanm(),
            $m,
        );
        # Execute the system call
        {
            local $@;
            my $rv;
            eval { $rv = system(@cmd); };
            say "<$@>" if $@;
            say $self->get_this_cpanm(), " exited with ", $rv >> 8
                if ($verbose);
        }
        my $this_buildlog_link =
            File::Spec->catfile($self->get_cpanm_dir(), 'build.log');
        croak "$this_buildlog_link is not a symlink" unless (-l $this_buildlog_link);
        my $this_buildlog = readlink($this_buildlog_link);
        croak "$this_buildlog not found" unless (-f $this_buildlog);

        $self->process_one_report($this_buildlog);
    }

    # End of loop.
    # This should lead to 100s of .json files in the analysis_dir.

    return [ @modules ];
}

sub setup_results_directories {
    my $self = shift;
    my $results_dir = $self->get_results_dir();
    my $analysis_dir = File::Spec->catdir($results_dir, 'analysis');
    my $storage_dir = File::Spec->catdir($results_dir, 'storage');
    my @created = make_path( $analysis_dir, $storage_dir,
        { mode => 0755 });
    for my $dir (@created) { croak "$dir not found" unless -d $dir; }
    $self->{analysis_dir} = $analysis_dir;
    $self->{storage_dir} = $storage_dir;
    return scalar(@created);
}

sub process_one_report {
    my ($self, $this_buildlog) = @_;
    my $reporter = CPAN::cpanminus::reporter::RetainReports->new(
      force => 1, # ignore mtime check on build.log
      build_logfile => $this_buildlog,
      build_dir => $self->get_cpanm_dir(),
      'ignore-versions' => 1,
    );
    croak "Unable to create new reporter for $this_buildlog"
        unless defined $reporter;
    no warnings 'redefine';
    local *CPAN::cpanminus::reporter::RetainReports::_check_cpantesters_config_data = sub { 1 };
    $reporter->set_report_dir($self->get_analysis_dir());
    $reporter->run;
    return 1;
}

=head2 C<get_analysis_dir() get_storage_dir()>

=over 4

=item * Purpose

Once C<process_modules()> has been run, two additional methods become available to
help code determine where output data are located.

=over 4

=item * analysis directory (I<analysis_dir>)

The directory underneath the I<results directory> holding files representing
the parsed content of the build log of the most recent run.  These files are
in C<.json> format.

=item * storage directory (I<storage_dir>)

The directory underneath the I<results directory> holding final output results.

=back

=item * Arguments

    $storage_dir = $self->get_storage_dir();

=item * Return Value

String holding a path to the named directory.

=item * Comment

These directories are only confirmed to exist once internal method
C<setup_results_directories()> has been executed.  (That method is called
within C<process_modules()>.) Otherwise, these methods will throw exceptions.

=back

=cut

sub get_analysis_dir {
    my $self = shift;
    if (! defined $self->{analysis_dir}) {
        croak "analysis directory has not yet been defined";
    }
    else {
        return $self->{analysis_dir};
    }
}

sub get_storage_dir {
    my $self = shift;
    if (! defined $self->{storage_dir}) {
        croak "storage directory has not yet been defined";
    }
    else {
        return $self->{storage_dir};
    }
}

=head2 C<analyze_json_logs()>

=over 4

=item * Purpose

Create a character-delimited-values file summarizing the results of a given
run.  The delimiter defaults to a pipe (C<|>), thereby creating a
pipe-separated values file (C<.psv>), but you may select a comma (C<,>),
generating a comma-separated-values file (C<.csv>) as well.

=item * Arguments

    my $fcdvfile = $self->analyze_json_logs( { verbose => 1, sep_char => '|' } );

Hash reference with these elements:

=over 4

=item * C<verbose>

Extra information provided on STDOUT.  Optional; defaults to being off;
provide a Perl-true value to turn it on.  Scope is limited to this method.

=item * C<sep_char>

Delimiter character.  Optional; defaults to pipe (C<|>), but comma (C<,>) may
also be chosen.

=back

=item * Return Value

String holding absolute path to the C<.psv> or C<.csv> file created.

=item * Comment

As a precaution, the function creates a tarball to archive the F<.log.json>
files for a given run.

=back

=cut

sub analyze_json_logs {
    my ($self, $args) = @_;
    # TODO: If we don't have an $args supplied at all, that's okay provided we
    # can ensure that we will have a default sep_char set
    # Test this method with hash ref but lacking 'verbose'
    # Test this method with hash ref but lacking 'sep_char'
    # Test this method with hash ref but both KVPs
    # Test this method with no arg
    croak "analyze_json_logs: Must supply hash ref as argument"
        unless ( ( defined $args ) and ( ref($args) eq 'HASH' ) );
    my $verbose     = delete $args->{verbose}   || '';
    my $sep_char    = delete $args->{sep_char}  || '|';
    croak "analyze_json_logs: Currently only pipe ('|') and comma (',') are supported as delimiter characters"
        unless ($sep_char eq '|' or $sep_char eq ',');

    # Locate our log.json files
    my $json_log_files = $self->_list_log_files();
    # Test without verbose
    dd($json_log_files) if $verbose;

    # As a precaution, we archive those log.json files.
    $self->_archive_log_files( {
        json_log_files  => $json_log_files,
        # $verbose: ensure that it is initialized, if only to ''
        verbose         => $verbose,
    } );

    # Having archived our log.json files, we now proceed to read them and to
    # write a pipe- (or comma-) separated-values file summarizing the run.
    my %data = ();
    for my $log (@{$json_log_files}) {
        my $flog = File::Spec->catfile($self->{results_dir}, $log);
        my %this = ();
        my $f = Path::Tiny::path($flog);
        my $decoded;
        {
            local $@;
            eval { $decoded = decode_json($f->slurp_utf8); };
            if ($@) {
                warn "JSON decoding problem in $flog: <$@>";
                eval { $decoded = JSON->new->decode($f->slurp_utf8); };
            }
        }
        map { $this{$_} = $decoded->{$_} } ( qw| author distname grade | );
        $data{$decoded->{dist}} = \%this;
    }

    # Now we create a CSV file (really ... a PSV)
    my $fcdvfile = $self->_create_csv_file( {
        # $verbose: ensure that it is initialized, if only to ''
        sep_char        => $sep_char,
        data            => \%data,
        # $verbose: ensure that it is initialized, if only to ''
        verbose         => $verbose,
    } );

    return $fcdvfile;
}

sub _list_log_files {
    my $self = shift;
    my $analysis_dir = $self->{analysis_dir};
    opendir my $DIRH, $analysis_dir or croak "Unable to open $analysis_dir for reading";
    my @json_log_files = sort map { File::Spec->catfile('analysis', $_) }
        grep { m/\.log\.json$/ } readdir $DIRH;
    closedir $DIRH or croak "Unable to close $analysis_dir after reading";
    return \@json_log_files;
}

sub _archive_log_files {
    my ($self, $args) = @_;
    # TODO: Is this file name self-documenting enough?  Need datestamp?
    my $output = join('.' => (
        $self->{title},
        $self->{install},
        'log',
        'json',
        'tar',
        'gz'
    ) );
    my $foutput = File::Spec->catfile($self->{storage_dir}, $output);
    # Test this without $args->{verbose}
    say "Output will be: $foutput" if $args->{verbose};
    my $versioned_results_dir = $self->{results_dir};
    my $previous_cwd = cwd();
    chdir $self->{results_dir} or croak "Unable to chdir to $self->{results_dir}";
    # Test this without $args->{verbose}
    say "Now in $self->{results_dir}" if $args->{verbose};
    my $tar = Archive::Tar->new;
    $tar->add_files(@{$args->{json_log_files}});
    $tar->write($foutput, COMPRESS_GZIP);
    croak "$foutput not created" unless (-f $foutput);
    # Test this without $args->{verbose}
    say "Created archive $foutput" if $args->{verbose};
    chdir $previous_cwd or croak "Unable to change back to $previous_cwd";
    return 1;
}

sub _create_csv_file {
    my ($self, $args) = @_;

    my $cdvfile = join('.' => (
        $self->{title},
        $self->{install},
        (($args->{sep_char} eq ',') ? 'csv' : 'psv'),
    ) );
    my $fcdvfile = File::Spec->catfile($self->{storage_dir}, $cdvfile);
    # Test this without $args->{verbose}
    say "Output will be: $fcdvfile" if $args->{verbose};

    my @fields = ( qw| author distname grade | );
    my $install = $self->{install};
    my $columns = [
        'dist',
        @fields,
    ];
    my $psv = Text::CSV_XS->new({
        binary => 1,
        auto_diag => 1,
        sep_char => $args->{sep_char},
        eol => $/,
    });
    open my $OUT, ">:encoding(utf8)", $fcdvfile
        or croak "Unable to open $fcdvfile for writing";
    $psv->print($OUT, $columns), "\n" or $psv->error_diag;
    for my $dist (sort keys %{$args->{data}}) {
        $psv->print($OUT, [
           $dist,
           @{$args->{data}->{$dist}}{@fields},
        ]) or $psv->error_diag;
    }
    close $OUT or croak "Unable to close $fcdvfile after writing";
    croak "$fcdvfile not created" unless (-f $fcdvfile);
    # Test this without $args->{verbose}
    say "Examine ",
        (($args->{sep_char} eq ',') ? 'comma' : 'pipe'),
        "-separated values in $fcdvfile"
            if $args->{verbose};
    return $fcdvfile;
}

1;

=head1 LIMITATIONS

This library has a fair number of direct and indirect dependencies on other
CPAN libraries.  Consequently, the library may experience problems if there
are major changes in those libraries.  In particular, the code is indirectly
dependent upon F<App::cpanminus::reporter>, which in turn is dependent upon
F<cpanm>.  (Nonetheless, this software could never have been written without
those two libraries by Breno G. de Oliveira and Tatsuhiko Miyagawa,
respectively.)

This library has been developed in a Unix programming environment and is
unlikely to work in its current form on Windows, Cygwin or VMS.

=head1 AUTHOR

    James E Keenan
    CPAN ID: JKEENAN
    jkeenan@cpan.org
    http://thenceforward.net/perl

=head1 SUPPORT

Please report any bugs in our GitHub Issues queue at
L<https://github.com/jkeenan/perl5-test-cpan-against-commit/issues>.

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

Copyright James E Keenan 2017-2025.  All rights reserved.

=head1 ACKNOWLEDGEMENTS

This library's ancestor, Test-Against-Dev, emerged in the wake of the author's
participation in the Perl 5 Core Hackathon held in Amsterdam, Netherlands, in
October 2017.  The author thanks the lead organizers of that event, Sawyer X
and Todd Rinaldo, for the invitation to the hackathon.  The event could not
have happened without the generous contributions from the following companies:

=over 4

=item * L<Booking.com|https://www.booking.com>

=item * L<cPanel|https://cpanel.com>

=item * L<Craigslist|https://www.craigslist.org/about/craigslist_is_hiring>

=item * L<Bluehost|https://www.bluehost.com/>

=item * L<Assurant|https://www.assurantmortgagesolutions.com/>

=item * L<Grant Street Group|https://grantstreet.com/>

=back

=head2 Additional Contributors

=over 4

=item * Mohammad S Anwar

=back

=head1 SEE ALSO

perl(1). CPAN::cpanminus::reporter::RetainReports(3).
App::cpanminus::reporter(3).  cpanm(3).

L<2017 Perl 5 Core Hackathon Discussion on Testing|https://github.com/p5h/2017/wiki/What-Do-We-Want-and-Need-from-Smoke-Testing%3F>.

L<perl.cpan.testers.discuss Thread on Testing|https://www.nntp.perl.org/group/perl.cpan.testers.discuss/2017/10/msg4172.html>.

=cut

