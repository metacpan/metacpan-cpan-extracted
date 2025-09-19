package Test::Against::Commit;
use strict;
use 5.14.0;
our $VERSION = '0.15';
# core modules
use Archive::Tar;
use Carp;
use Cwd;
use File::Fetch;
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

Test::Against::Commit - Test CPAN modules against Perl dev releases

=head1 SYNOPSIS

    my $self = Test::Against::Commit->new( {
        application_dir => '/path/to/application',
        commit          => <commit_ID_tag_or_branch>,
    } );

    my $this_cpanm = $self->fetch_cpanm( { verbose => 1 } );

    my $gzipped_build_log = $self->run_cpanm( {
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

In the development of Perl as a language we face a problem typically referred to as B<Blead Breaks CPAN> (or B<BBC> for
short).  Perl 5 undergoes an annual development cycle characterized by:

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
on important provide a monthly snapshot of the impact of core development on
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

=head2 What Is the Result Produced by This Library?

We will use the term I<run> to describe an instance of (i) testing one or more
CPAN libraries against a given installed F<perl> and (ii) the recording of
data from that instance of testing.  Our objective is to be able to compare
the results of different runs against different F<perl> executables.

For example, suppose a person working on the Perl core distribution wants to
assess the impact of certain changes being proposed in a pull request on set
of fifty specific CPAN libraries.  The user will first create a benchmark
F<perl> probably built from a monthly development release, the GH tag
associated with that release, or the GH commit from which the pull request was
generated.  She will use this library to conduct a run against that
executable.  In the run, each CPAN library will be graded C<PASS>, C<FAIL> (or
C<NA> for "not applicable").

At a certain point in the course of the pull request's development, the user
will build a new F<perl> executable and conduct a run against that F<perl>.
If a particular CPAN library receives a grade of C<PASS> during the first run
and a grade of C<FAIL> during the next, the Perl 5 Porters will be asked to
determine the cause of that breakage.

=over 4

=item *

Sometimes the change in Perl 5 is wrong and needs to be reverted.

=item *

Sometimes the change in Perl 5 is correct (or, at least, plausible) but
exposes sub-optimal code in the CPAN module.

=item *

Sometimes the failure is due to external conditions, such as a change in a C
library on the testing platform.

=back

There's no way to write code to figure out which situation -- or mix of
situations -- we are in.  The human user must intervene at this point.

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

The user must decide on a Perl 5 configuration before using
F<Test-Against-Commit> on a regular basis and then must refrain from changing
that configuration over the course of the testing period.  Otherwise, the
results may reflect changes in that configuration rather than changes in Perl
5 core distribution code or changes in the targeted CPAN libraries.

By "Perl 5 configuration" we mean the way one calls F<Configure> when building
Perl 5 from source, <e.g.>:

    sh ./Configure -des -Dusedevel

or:

    sh ./Configure -des -Dusedevel \
        -Duseithreads \
        -Doptimize="-O2 -pipe -fstack-protector -fno-strict-aliasing"

For instance, you should not configure without threads in one run but with threads
in the next.  Nor should you switch from regular to debugging builds between threads.

=item * F<perl> Executable Installation Location

As noted above, this library leaves to the user the choice of a I<way to get
the Perl source code> and the decision of I<how to configure> an individual
F<perl> executable.  It also leaves to the user, with one caveat, the decision
of I<where> to install that executable on disk.  That caveat is that the
F<perl> installation should reside in a directory named F<testing> which in
turn sits underneath a directory which we'll refer to as the I<application
directory>.  The user will have to manually create the I<application
directory> as well as the F<testing> directory underneath.

Example:  Suppose you want all your Test-Against-Commit data to sit in the directory tree F</path/to/application>:

    /path/to/application

You will need a subdirectory called F<testing> underneath that:

    /path/to/application
    /path/to/application/testing

You can create these directories with this command:

    $ mkdir -p /path/to/application/testing

Now suppose that for one project you want to use as your baseline a F<perl>
built from a F<git> checkout at commit C<03f24b8a08>, and for a I<different>
project you want to use as your baseline a F<perl> built from a maintenance
release tarball of C<perl-5.40.2>.  That means you will I<ultimately> want a
directory structure like this:

    /path/to/application/
    /path/to/application/testing/
    /path/to/application/testing/03f24b8a08/
    /path/to/application/testing/perl-5.40.2/

Using the second of the C<Configure> examples above, for the first project you would configure with:

    $ sh ./Configure -des -Dusedevel \
        -Duseithreads \
        -Doptimize="-O2 -pipe -fstack-protector -fno-strict-aliasing"
        -Dprefix=/path/to/application/testing/03f24b8a08

For the second project you would configure with:

    $ sh ./Configure -des -Dusedevel \
        -Duseithreads \
        -Doptimize="-O2 -pipe -fstack-protector -fno-strict-aliasing"
        -Dprefix=/path/to/application/testing/perl-5.40.2

After running C<sh ./Configure>, you would then call in each project:

    $ make install

You would end up with a directory structure the top of which would look like this:

    /path/to/application/
    /path/to/application/testing/
    /path/to/application/testing/03f24b8a08/
    /path/to/application/testing/03f24b8a08/bin
    /path/to/application/testing/03f24b8a08/lib
    /path/to/application/testing/perl-5.40.2/
    /path/to/application/testing/perl-5.40.2/bin
    /path/to/application/testing/perl-5.40.2/lib

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
        commit => 'blead',
    } );

Takes a hash reference with the following elements:

=over 4

=item * C<application_dir>

String holding path to the directory which will serve as the top level for your application.

=item * C<commit>

String holding a name for the specific F<perl> executable against which you
will be attempting to install CPAN modules.  If you are building F<perl> from
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
    croak "Hash ref must contain 'commit' element"
        unless $args->{commit};
    croak "Could not locate application directory $args->{application_dir}"
        unless (-d $args->{application_dir});

    my %verified = ();
    for my $dir (qw| testing results |) {
        my $fdir = File::Spec->catdir($args->{application_dir}, $dir);
        croak "Could not locate $dir directory $fdir" unless (-d $fdir);
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

=head2 C<get_application_dir() get_testing_dir() get_results_dir()>

=over 4

=item * Purpose

Three methods which simply return the path to relevant directories (along with
I<short-hand versions> of their name):

=over 4

=item * application directory (I<application_dir>)

The top-level directory for all code and data implemented by
Test-Against-Commit.  It will typically hold 2 subdirectories: C<testing> and
C<results>, described below.

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

sub get_testing_dir {
    my $self = shift;
    return $self->{testing_dir};
}

sub get_results_dir {
    my $self = shift;
    return $self->{results_dir};
}

=head2 C<get_commit()>

=over 4

=item * Purpose

Each F<perl> installed underneath C<testing_dir> needs a unique name.  If we
build this F<perl> from a F<git> checkout, this should be one of the commit ID
(SHA), tag or branch name of the checkout.

=item * Arguments

    my $commit = $self->get_commit();

=item * Return Value

String holding a F<git> commit ID, tag or branch name.

=item * Comment

Since C<commit> is one of the key-value pairs we are handing to C<new()>, this
method essentially just gives us back what we already told it.  However, we
will use it internally later to derive the path to the installed F<perl>
against which we are trying to install modules.

TK:  What about when we're building from a tarball?

=back

=cut

sub get_commit {
    my $self = shift;
    return $self->{commit};
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

    my $commit_dir = File::Spec->catdir($self->{testing_dir}, $self->{commit});
    if (-d $commit_dir) {
        $self->{commit_dir} = $commit_dir;
    }
    else {
        croak "Could not locate $commit_dir; have you built and installed a perl executable?";
    }
    for my $dir (qw| bin lib|) {
        my $subdir = File::Spec->catdir($self->{commit_dir}, $dir);
        if (-d $subdir) {
            my $this = $dir . '_dir';
            $self->{$this} = $subdir;
        }
        else {
            croak "Could not locate $subdir; have you built and installed a perl executable?";
        }
    }
    my $thisperl = File::Spec->catfile($self->get_bin_dir, 'perl');
    my $libdir = $self->get_lib_dir();
    my $invoke = "$thisperl -I$libdir";
    my $rv = system(qq{$invoke -v | head -n 2 | tail -n 1})
        and croak "Could not run perl executable at $thisperl";

    return $self;
}

=head2 C<get_commit_dir() <get_bin_dir() get_lib_dir()>

=over 4

=item * Purpose

Once C<prepare_testing_directory()> has been run, three additional methods
become available to help the code determine where it is.

=over 4

=item * commit directory (I<commit_dir>)

A directory underneath C<testing_dir> holding F<perl> installation.  This
directory will start off life with two subdirectories, C<bin> and C<lib>.

=item * bin directory (I<bin_dir>)

The directory underneath an individual C<commit_dir> directory holding installed
executables such as F<perl>, F<cpan> and F<cpanm>.

=item * lib directory (I<lib_dir>)

The directory underneath an individual C<commit_dir> directory holding the
libraries supporting the installed executables found in the C<bin_dir>.

=back

=item * Arguments

    $commit_dir = $self->get_commit_dir();

    $bin_dir = $self->get_bin_dir();

    $lib_dir = $self->get_lib_dir();

=item * Return Value

String holding a path to the named directory.

=item * Comment

If the F<perl> executable has not yet been installed, these methods will
throw exceptions.

=back

=cut

sub get_commit_dir {
    my $self = shift;
    if (! defined $self->{commit_dir}) {
        croak "commit directory has not yet been defined; have you installed perl?";
    }
    else {
        return $self->{commit_dir};
    }
}

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

=head2 C<fetch_cpanm() get_this_cpanm() get_cpanm_dir()>

=over 4

=item * Purpose

Determine whether F<cpanm> has been installed.  If it has not, fetch the
fatpacked F<cpanm> executable and install it against the newly installed
F<perl>.

=item * Arguments

    my $rv = $self->fetch_cpanm( { verbose => 1 } );

Hash reference with these elements:

=over 4

=item * C<uri>

String holding URI from which F<cpanm> will be downloaded.  Optional; defaults
to L<https://fastapi.metacpan.org/source/MIYAGAWA/App-cpanminus-1.7048/bin/cpanm>.

=item * C<verbose>

Extra information provided on STDOUT.  Optional; defaults to being off;
provide a Perl-true value to turn it on.  Scope is limited to this method.

=back

=item * Return Value

Returns the Test::Against::Commit object, which now holds additional data.

=item * Comment

The F<cpanm> executable's location can subsequently be accessed by calling
C<$self->get_this_cpanm()>.  The method also guarantees the existence of a
F<.cpanm> directory underneath the commit directory, I<i.e.,> side-by-side
with C<bin> and C<lib>.  This directory can subsequently be accessed by
calling C<$self->get_cpanm_dir()>.

=back

=cut

sub fetch_cpanm {
    my ($self, $args) = @_;
    croak "fetch_cpanm: Must supply hash ref as argument"
        unless ( ( defined $args ) and ( ref($args) eq 'HASH' ) );
    my $verbose = delete $args->{verbose} || '';
    my $uri = (exists $args->{uri} and length $args->{uri})
        ? $args->{uri}
        : 'https://fastapi.metacpan.org/source/MIYAGAWA/App-cpanminus-1.7048/bin/cpanm';

    my $cpanm_dir = File::Spec->catdir($self->get_commit_dir(), '.cpanm');
    unless (-d $cpanm_dir) { make_path($cpanm_dir, { mode => 0755 }); }
    croak "Could not locate $cpanm_dir" unless (-d $cpanm_dir);
    $self->{cpanm_dir} = $cpanm_dir;

    my $bin_dir = $self->get_bin_dir();
    my $this_cpanm = File::Spec->catfile($bin_dir, 'cpanm');
    # If cpanm is already installed in bin_dir, we don't need to try to
    # reinstall it.
    if (-f $this_cpanm) {
        say "'$this_cpanm' already installed" if $verbose;
    }
    else {
       say "Fetching 'cpanm' from $uri" if $verbose;
       my $ff = File::Fetch->new(uri => $uri)->fetch(to => $bin_dir)
           or croak "Unable to fetch 'cpanm' from $uri";
    }
    my $cnt = chmod 0755, $this_cpanm;
    croak "Unable to make '$this_cpanm' executable" unless $cnt;
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

=head2 C<run_cpanm()>

=over 4

=item * Purpose

Use F<cpanm> to install selected Perl modules against the F<perl> built for
testing purposes.

=item * Arguments

Two mutually exclusive interfaces:

=over 4

=item * Modules provided in a list

    $gzipped_build_log = $self->run_cpanm( {
        module_list => [ 'DateTime', 'AnyEvent' ],
        title       => 'two-important-libraries',
        verbose     => 1,
    } );

=item * Modules listed in a file

    $gzipped_build_log = $self->run_cpanm( {
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
distribution.  In either case the module names are spelled in
C<Some::Module> format -- I<i.e.>, double-colons -- rather than in
C<Some-Distribution> format (hyphens).

=item * C<title>

String which will be used to compose the name of project-specific output
files.  Required.

=item * C<verbose>

Extra information provided on STDOUT.  Optional; defaults to being off;
provide a Perl-true value to turn it on.  Scope is limited to this method.

=back

=item * Return Value

String holding the absolute path of a gzipped copy of the F<build.log>
generated by the F<cpanm> run which this method conducts.  The basename
of this file, using the arguments supplied, would be:

   cpan-river-1000.perl-5.43.6.01.build.log.gz

=item * Comment

The method confirms the existence of several directories underneath the
I<results_dir> directory discussed above.  These are illustrated as follows:

    /path/to/application/results/
                        /results/perl-5.43.6/
                        /results/perl-5.43.6/analysis/
                        /results/perl-5.43.6/buildlogs/
                        /results/perl-5.43.6/storage/

=back

=cut

sub run_cpanm {
    my ($self, $args) = @_;
    croak "run_cpanm: Must supply hash ref as argument"
        unless ( ( defined $args ) and ( ref($args) eq 'HASH' ) );
    my $verbose = delete $args->{verbose} || '';
    my %eligible_args = map { $_ => 1 } ( qw|
        module_file module_list title
    | );
    for my $k (keys %$args) {
        croak "run_cpanm: '$k' is not a valid element"
            unless $eligible_args{$k};
    }
    if (exists $args->{module_file} and exists $args->{module_list}) {
        croak "run_cpanm: Supply either a file for 'module_file' or an array ref for 'module_list' but not both";
    }
    if ($args->{module_file}) {
        croak "run_cpanm: Could not locate '$args->{module_file}'"
            unless (-f $args->{module_file});
    }
    if ($args->{module_list}) {
        croak "run_cpanm: Must supply array ref for 'module_list'"
            unless ref($args->{module_list}) eq 'ARRAY';
    }

    unless (defined $args->{title} and length $args->{title}) {
        croak "Must supply value for 'title' element";
    }
    $self->{title} = $args->{title};

    # Need to rethink results directory setup, because we are now no longer
    # limited to testing perl releases (which have unambiguous perl_versions
    # associated with them).
    unless (-d $self->{vresults_dir}) {
        $self->setup_results_directories();
    }

    my $cpanreporter_dir = File::Spec->catdir($self->get_commit_dir(), '.cpanreporter');
    unless (-d $cpanreporter_dir) { make_path($cpanreporter_dir, { mode => 0755 }); }
    croak "Could not locate $cpanreporter_dir" unless (-d $cpanreporter_dir);
    $self->{cpanreporter_dir} = $cpanreporter_dir;

    unless ($self->{cpanm_dir}) {
        say "Defining previously undefined cpanm_dir" if $verbose;
        my $cpanm_dir = File::Spec->catdir($self->get_commit_dir(), '.cpanm');
        unless (-d $cpanm_dir) { make_path($cpanm_dir, { mode => 0755 }); }
        croak "Could not locate $cpanm_dir" unless (-d $cpanm_dir);
        $self->{cpanm_dir} = $cpanm_dir;
    }

    say "cpanm_dir: ", $self->get_cpanm_dir() if $verbose;
    local $ENV{PERL_CPANM_HOME} = $self->get_cpanm_dir();

    my @modules = ();
    if ($args->{module_list}) {
        @modules = @{$args->{module_list}};
    }
    elsif ($args->{module_file}) {
        open my $IN, '<', $args->{module_file}
            or croak "Could not open $args->{module_file} for reading";
        while (my $m = <$IN>) {
            chomp $m;
            push @modules, $m;
        }
        close $IN or croak "Could not close $args->{module_file} after reading";
    }
    my $libdir = $self->get_lib_dir();
    my @cmd = (
        $self->get_this_perl,
        "-I$libdir",
        $self->get_this_cpanm,
        @modules,
    );
    {
        local $@;
        my $rv;
        eval { $rv = system(@cmd); };
        say "<$@>" if $@;
        if ($verbose) {
            say $self->get_this_cpanm(), " exited with ", $rv >> 8;
        }
    }
    my $gzipped_build_log = $self->gzip_cpanm_build_log();
    say "See gzipped build.log in $gzipped_build_log" if $verbose;

    return $gzipped_build_log;
}

sub setup_results_directories {
    my $self = shift;
    my $vresults_dir = File::Spec->catdir($self->get_results_dir, $self->get_commit());
    my $buildlogs_dir = File::Spec->catdir($vresults_dir, 'buildlogs');
    my $analysis_dir = File::Spec->catdir($vresults_dir, 'analysis');
    my $storage_dir = File::Spec->catdir($vresults_dir, 'storage');
    my @created = make_path( $vresults_dir, $buildlogs_dir, $analysis_dir, $storage_dir,
        { mode => 0755 });
    for my $dir (@created) { croak "$dir not found" unless -d $dir; }
    $self->{vresults_dir} = $vresults_dir;
    $self->{buildlogs_dir} = $buildlogs_dir;
    $self->{analysis_dir} = $analysis_dir;
    $self->{storage_dir} = $storage_dir;
    return scalar(@created);
}

sub gzip_cpanm_build_log {
    my ($self) = @_;
    my $build_log_link = File::Spec->catfile($self->get_cpanm_dir, 'build.log');
    croak "Did not find symlink for build.log at $build_log_link"
        unless (-l $build_log_link);
    my $real_log = readlink($build_log_link);

    my $pattern = qr/^$self->{title}\.$self->{commit}\.build\.log\.gz$/;
    $self->{gzlog_pattern} = $pattern;
    opendir my $DIRH, $self->{buildlogs_dir} or croak "Unable to open buildlogs_dir for reading";
    my @files_found = grep { -f $_ and $_ =~ m/$pattern/ } readdir $DIRH;
    closedir $DIRH or croak "Unable to close buildlogs_dir after reading";

    # In this new approach, we'll assume that we never do anything except
    # exactly 1 run per monthly release.  Hence, there shouldn't be any files
    # in this directory whatsoever.  We'll croak if there are such file.
    # TODO: Now that we're in Test-Against-Commit, is that assumption still
    # valid?
    croak "There are already log files in '$self->{buildlogs_dir}'"if scalar(@files_found);

    my $gzipped_build_log = join('.' => (
        $self->{title},
        $self->{commit},
        'build',
        'log',
        'gz'
    ) );
    my $gzlog = File::Spec->catfile($self->{buildlogs_dir}, $gzipped_build_log);
    system(qq| gzip -c $real_log > $gzlog |)
        and croak "Unable to gzip $real_log to $gzlog";
    $self->{gzlog} = $gzlog;
}

=head2 C<analyze_cpanm_build_logs()>

=over 4

=item * Purpose

Parse the F<build.log> created by running C<run_cpanm()>, creating JSON files
which log the results of attempting to install each module in the list or
file.

=item * Arguments

    $ranalysis_dir = $self->analyze_cpanm_build_logs( { verbose => 1 } );

Hash reference which, at the present time, can only take one element:
C<verbose>.  Optional.

=item * Return Value

String holding absolute path to the directory holding F<.log.json> files for a
particular run of C<run_cpanm()>.

=item * Comment

=back

=cut

sub analyze_cpanm_build_logs {
    my ($self, $args) = @_;
    croak "analyze_cpanm_build_logs: Must supply hash ref as argument"
        unless ( ( defined $args ) and ( ref($args) eq 'HASH' ) );
    my $verbose = delete $args->{verbose} || '';

    my $gzlog = $self->{gzlog};
    unless (-d $self->{analysis_dir}) { make_path($self->{analysis_dir}, { mode => 0755 }); }
    croak "Could not locate $self->{analysis_dir}" unless (-d $self->{analysis_dir});

    my ($fh, $working_log) = tempfile();
    system(qq|gunzip -c $gzlog > $working_log|)
        and croak "Unable to gunzip $gzlog to $working_log";

    my $reporter = CPAN::cpanminus::reporter::RetainReports->new(
      force => 1, # ignore mtime check on build.log
      build_logfile => $working_log,
      build_dir => $self->get_cpanm_dir,
      'ignore-versions' => 1,
    );
    croak "Unable to create new reporter for $working_log"
        unless defined $reporter;
    no warnings 'redefine';
    local *CPAN::cpanminus::reporter::RetainReports::_check_cpantesters_config_data = sub { 1 };
    $reporter->set_report_dir($self->{analysis_dir});
    $reporter->run;
    say "See results in $self->{analysis_dir}" if $verbose;

    return $self->{analysis_dir};
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
    croak "analyze_json_logs: Must supply hash ref as argument"
        unless ( ( defined $args ) and ( ref($args) eq 'HASH' ) );
    my $verbose     = delete $args->{verbose}   || '';
    my $sep_char    = delete $args->{sep_char}  || '|';
    croak "analyze_json_logs: Currently only pipe ('|') and comma (',') are supported as delimiter characters"
        unless ($sep_char eq '|' or $sep_char eq ',');

    # Locate our log.json files
    my $json_log_files = $self->_list_log_files();
    dd($json_log_files) if $verbose;

    # As a precaution, we archive those log.json files.
    $self->_archive_log_files( {
        json_log_files  => $json_log_files,
        verbose         => $verbose,
    } );

    # Having archived our log.json files, we now proceed to read them and to
    # write a pipe- (or comma-) separated-values file summarizing the run.
    my %data = ();
    for my $log (@{$json_log_files}) {
        my $flog = File::Spec->catfile($self->{vresults_dir}, $log);
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
        sep_char        => $sep_char,
        data            => \%data,
        verbose         => $verbose,
    } );

    return $fcdvfile;
}

sub _list_log_files {
    my $self = shift;
    my $vranalysis_dir = $self->{analysis_dir};
    opendir my $DIRH, $vranalysis_dir or croak "Unable to open $vranalysis_dir for reading";
    my @json_log_files = sort map { File::Spec->catfile('analysis', $_) }
        grep { m/\.log\.json$/ } readdir $DIRH;
    closedir $DIRH or croak "Unable to close $vranalysis_dir after reading";
    return \@json_log_files;
}

sub _archive_log_files {
    my ($self, $args) = @_;
    # TODO: Is this file name self-documenting enough?  Need datestamp?
    my $output = join('.' => (
        $self->{title},
        $self->{commit},
        'log',
        'json',
        'tar',
        'gz'
    ) );
    my $foutput = File::Spec->catfile($self->{storage_dir}, $output);
    say "Output will be: $foutput" if $args->{verbose};
    my $versioned_results_dir = $self->{vresults_dir};
    my $previous_cwd = cwd();
    chdir $self->{vresults_dir} or croak "Unable to chdir to $self->{vresults_dir}";
    say "Now in $self->{vresults_dir}" if $args->{verbose};
    my $tar = Archive::Tar->new;
    $tar->add_files(@{$args->{json_log_files}});
    $tar->write($foutput, COMPRESS_GZIP);
    croak "$foutput not created" unless (-f $foutput);
    say "Created archive $foutput" if $args->{verbose};
    chdir $previous_cwd or croak "Unable to change back to $previous_cwd";
    return 1;
}

sub _create_csv_file {
    my ($self, $args) = @_;

    my $cdvfile = join('.' => (
        $self->{title},
        $self->{commit},
        (($args->{sep_char} eq ',') ? 'csv' : 'psv'),
    ) );
    my $fcdvfile = File::Spec->catfile($self->{storage_dir}, $cdvfile);
    say "Output will be: $fcdvfile" if $args->{verbose};

    my @fields = ( qw| author distname grade | );
    my $commit = $self->{commit};
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

