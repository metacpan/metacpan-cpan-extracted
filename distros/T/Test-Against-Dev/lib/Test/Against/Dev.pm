package Test::Against::Dev;
use strict;
use 5.14.0;
our $VERSION = '0.12';
use Carp;
use Cwd;
use File::Basename;
use File::Fetch;
use File::Path ( qw| make_path | );
use File::Spec;
use File::Temp ( qw| tempdir tempfile | );
use Archive::Tar;
use CPAN::cpanminus::reporter::RetainReports;
use Data::Dump ( qw| dd pp | );
use JSON;
use Path::Tiny;
use Perl::Download::FTP;
use Text::CSV_XS;

=head1 NAME

Test::Against::Dev - Test CPAN modules against Perl dev releases

=head1 SYNOPSIS

    my $self = Test::Against::Dev->new( {
        application_dir => '/path/to/application',
    } );

    my ($tarball_path, $work_dir) = $self->perform_tarball_download( {
        host                => 'ftp.funet.fi',
        hostdir             => /pub/languages/perl/CPAN/src/5.0,
        perl_version        => 'perl-5.27.6',
        compression         => 'gz',
        work_dir            => "~/tmp/Downloads",
        verbose             => 1,
        mock                => 0,
    } );

    my $this_perl = $self->configure_build_install_perl({
        verbose => 1,
    });

    my $this_cpanm = $self->fetch_cpanm( { verbose => 1 } );

    my $gzipped_build_log = $self->run_cpanm( {
        module_file => '/path/to/cpan-river-file.txt',
        title       => 'cpan-river-1000',
        verbose     => 1,
    } );

=head1 DESCRIPTION

=head2 Who Should Use This Library?

This library should be used by anyone who wishes to assess the impact of
month-to-month changes in the Perl 5 core distribution on the installability of
libraries found on the Comprehensive Perl Archive Network (CPAN).

=head2 The Problem to Be Addressed

This problem is typically referred to as B<Blead Breaks CPAN> (or B<BBC> for
short).  Perl 5 undergoes an annual development cycle characterized by monthly
releases whose version numbers follow the convention of C<5.27.0>, C<5.27.1>,
etc., where the middle digits are always odd numbers.  (Annual production
releases and subsequent maintenance releases have even-numbered middle digits,
I<e.g.>, C<5.26.0>, C<5.26.1>, etc.)  A monthly development release is
essentially a roll-up of a month's worth of commits to the master branch known
as B<blead> (pronounced I<"bleed">).  Changes in the Perl 5 code base have the
potential to adversely impact the installability of existing CPAN libraries.
Hence, various individuals have, over the years, developed ways of testing
those libraries against blead and reporting problems to those people actively
involved in the ongoing development of the Perl 5 core distribution -- people
typically referred to as the Perl 5 Porters.

This library is intended as a contribution to those efforts.  It is intended
to provide a monthly snapshot of the impact of Perl 5 core development on
important CPAN libraries.

=head2 The Approach Test-Against-Dev Currently Takes and How It May Change in the Future

Unlike other efforts, F<Test-Against-Dev> does not depend on test reports
sent to L<CPANtesters.org|http://www.cpantesters.org/>.  Hence, it should be
unaffected by any technical problems which that site may face.  As a
consequence, however, a user of this library must be willing to maintain more
of her own local infrastructure than a typical CPANtester would maintain.

While this library could, in principle, be used to test the entirety of CPAN,
it is probably better suited for testing selected subsets of CPAN libraries
which the user deems important to her individual or organizational needs.

This library is currently focused on monthly development releases of Perl 5.
It does not directly provide a basis for identifying individual commits to
blead which adversely impacted particular CPAN libraries.  It "tests against
dev" more than it "tests against blead" -- hence, the name of the library.
However, once it has gotten some production experience, it may be extended to,
say, measure the effect of individual commits to blead on CPAN libraries using
the previous monthly development release as a baseline.

This library is currently focused on Perl 5 libraries publicly available on
CPAN.  In the future, it may be extended to be able to include an
organization's private libraries as well.

This library is currently focused on blead, the master branch of the Perl 5
core distribution.  However, it could, in principle, be extended to assess the
impact on CPAN libraries of code in non-blead ("smoke-me") branches as well.

=head2 What Is the Result Produced by This Library?

Currently, if you run code built with this library on a monthly basis, you
will produce an updated version of a pipe-separated-values (PSV) plain-text
file suitable for opening in a spreadsheet.  The columns in that PSV file will
be these:

    dist
    perl-5.27.0.author
    perl-5.27.0.distname
    perl-5.27.0.distversion
    perl-5.27.0.grade
    perl-5.27.1.author
    perl-5.27.1.distname
    perl-5.27.1.distversion
    perl-5.27.1.grade
    ...

So the output for particular CPAN libraries will look like this:

    dist|perl-5.27.0.author|perl-5.27.0.distname|perl-5.27.0.distversion|perl-5.27.0.grade|perl-5.27.1.author|perl-5.27.1.distname|perl-5.27.1.distversion|perl-5.27.1.grade|...
    Acme-CPANAuthors|ISHIGAKI|Acme-CPANAuthors-0.26|0.26|PASS|ISHIGAKI|Acme-CPANAuthors-0.26|0.26|PASS|...
    Algorithm-C3|HAARG|Algorithm-C3-0.11|0.11|PASS|HAARG|Algorithm-C3-0.11|0.11|PASS|...

If a particular CPAN library receives a grade of C<PASS> one month and a grade
of C<FAIL> month, it ought to be inspected for the cause of that breakage.
Sometimes the change in Perl 5 is wrong and needs to be reverted.  Sometimes
the change in Perl 5 is correct (or, at least, plausible) but exposes
sub-optimal code in the CPAN module.  Sometimes the failure is due to external
conditions, such as a change in a C library on the testing platform.  There's
no way to write code to figure out which situation -- or mix of situations --
we are in.  The human user must intervene at this point.

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
F<Test-Against-Dev> on a regular basis and then must refrain from changing
that configuration over the course of the testing period.  Otherwise, the
results may reflect changes in that configuration rather than changes in Perl
5 core distribution code or changes in the targeted CPAN libraries.

By "Perl 5 configuration" we mean the way one calls F<Configure> when building
Perl 5 from source, <e.g.>:

    sh ./Configure -des -Dusedevel \
        -Duseithreads \
        -Doptimize="-O2 -pipe -fstack-protector -fno-strict-aliasing"

So, you should not configure without threads one month but with threads
another month.  You should not switch to debugging builds half-way through the
testing period.

=item * Selection of CPAN Libraries for Testing

B<This is the most important step in preparation to use this library.>

When you use this library, you are in effect saying:  I<Here is a list of CPAN
modules important enough to me that I don't want to see them start breaking in
the course of Perl's annual development cycle.  (If they do break, then the
Perl 5 Porters and the modules' authors/maintainers must address how to handle
the breakage.)  To keep track of the problem, I'm going to build F<perl> from
each monthly release and attempt to install this entire list against that
F<perl>.>

Hence, once you decide to track a certain CPAN library, you should continue to
include it in your list of modules to be tracked for the balance of the
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
depend.  That's a useful definition of importance even if it is not strictly
true.  Modules "way upstream" feed modules and real-world code "farther
downstream".  Hence, if Perl 5's development branch changes in a way such that
"upstream" modules start to fail to configure, build, test and install
correctly, then we have a potentially serious problem.  The author of this
library has primarily developed it with the idea that it would be run monthly
to see what happens with the 1000 "farthest upstream" modules -- the so-called
"CPAN River Top 1000".

=item * Organizational dependencies

Many organizations use technologies such as F<Carton> and F<cpanfile> to keep
track of their dependencies on CPAN libraries.  The lists compiled by such
applications could very easily be translated into a list of modules tested
once a month against a Perl development release.

=item * What repeatedly breaks

Certain CPAN libraries get broken relatively frequently.  While this can
happen because of sub-standard coding practices in those libraries, it more
often happens because these libraries, in order to do what they want to do,
reach down deep into the Perl 5 guts and use undocumented or not publicly
supported features of Perl.

=back

=back

=head2 Notice of Breaking Change in Version 0.06 (March 20 2018)

If you are first using F<Test-Against-Dev> in version 0.06 released on the
date above, you may skip this section.

If you used F<Test-Against-Dev> in an ongoing way prior to that version,
please be advised that the library now creates a slightly different directory
structure beneath the directory specified by the value of F<application_dir>
passed to the constructor.  Up through version 0.05, that structure looked
like this:

    $> find . -maxdepth 4 -type d
    ./results
    ./results/perl-5.27.6
    ./results/perl-5.27.6/storage
    ./results/perl-5.27.6/analysis
    ./results/perl-5.27.6/analysis/01
    ./results/perl-5.27.6/buildlogs
    ./testing
    ./testing/perl-5.27.6
    ./testing/perl-5.27.6/.cpanreporter
    ./testing/perl-5.27.6/.cpanm
    ./testing/perl-5.27.6/.cpanm/work
    ./testing/perl-5.27.6/lib
    ./testing/perl-5.27.6/lib/site_perl
    ./testing/perl-5.27.6/lib/5.27.6
    ./testing/perl-5.27.6/bin

The F<results/E<lt>perl-versionE<gt>/analysis/01> directory would hold F<.log.json>
files like these:

    $> ls -l ./results/perl-5.27.6/analysis/01 | head -5
    total 5824
    -rw-r--r-- 1 jkeenan jkeenan    757 Dec 16 13:58 ABH.Mozilla-CA-20160104.log.json
    -rw-r--r-- 1 jkeenan jkeenan   6504 Dec 16 13:58 ABIGAIL.Regexp-Common-2017060201.log.json
    -rw-r--r-- 1 jkeenan jkeenan  11639 Dec 16 13:58 ABW.Template-Toolkit-2.27.log.json
    -rw-r--r-- 1 jkeenan jkeenan    645 Dec 16 13:58 ABW.XML-Namespace-0.02.log.json

In versions 0.06 and later, the F<.log.json> files are placed one directory
higher, I<i.e.,> in F<results/E<lt>perl-versionE<gt>/analysis>.  An F<analysis/01>
directory is no longer created, as it was deemed unnecessary.  Please upgrade
to a newer version at the completion of your tracking of the Perl 5.27
development cycle, I<i.e.,> once Perl 5.28.0 has been released.

As a consequence of this change, the C<analyze_json_logs()> method no longer
needs a key-value pair like C<run =E<gt> 1> in the hash reference passed to the
method as argument.

=head1 METHODS

=head2 C<new()>

=over 4

=item * Purpose

Test::Against::Dev constructor.  Guarantees that the top-level directory for
the application (C<application_dir>) already exists, then creates two
directories thereunder:  F<testing/> and F<results/>.

=item * Arguments

    my $self = Test::Against::Dev->new( {
        application_dir => '/path/to/application',
    } );

Takes a hash reference with the following elements:

=over 4

=item * C<application_dir>

String holding path to the directory which will serve as the top level for your application.

=back

=item * Return Value

Test::Against::Dev object.

=item * Comment

This class has two possible constructors:  this method and
C<new_from_existing_perl_cpanm()> (see below).  Use C<new()> when you need to
do a fresh install of a F<perl> by compiling it from a downloaded tarball.
Use C<new_from_existing_perl_cpanm()> when you have already installed such a
F<perl> on disk and have installed a F<cpanm> against that F<perl>.

The method will guarantee that underneath the application directory there are
two directories:  F<testing> and F<results>.

=back

=cut

our $PERL_VERSION_PATTERN = qr/^perl-5\.\d+\.\d{1,2}(?:-RC\d{1,2})?$/;

sub new {
    my ($class, $args) = @_;

    croak "Argument to constructor must be hashref"
        unless ref($args) eq 'HASH';
    croak "Hash ref must contain 'application_dir' element"
        unless $args->{application_dir};
    croak "Could not locate $args->{application_dir}"
        unless (-d $args->{application_dir});

    my $data;
    for my $k (keys %{$args}) {
        $data->{$k} = $args->{$k};
    }

    for my $dir (qw| testing results |) {
        my $fdir = File::Spec->catdir($data->{application_dir}, $dir);
        unless (-d $fdir) { make_path($fdir, { mode => 0755 }); }
        croak "Could not locate $fdir" unless (-d $fdir);
        $data->{"${dir}_dir"} = $fdir;
    }

    $data->{perl_version_pattern} = $PERL_VERSION_PATTERN;

    return bless $data, $class;
}

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

=head2 C<perform_tarball_download()>

=over 4

=item * Purpose

=item * Arguments

    ($tarball_path, $work_dir) = $self->perform_tarball_download( {
        host                => 'ftp.funet.fi',
        hostdir             => /pub/languages/perl/CPAN/src/5.0,
        perl_version        => 'perl-5.27.6',
        compression         => 'gz',
        work_dir            => "~/tmp/Downloads",
        verbose             => 1,
        mock                => 0,
    } );

Hash reference with the following elements:

=over 4

=item * C<host>

String.  The FTP mirror from which you wish to download a tarball of a Perl
release.  Required.

=item * C<hostdir>

String.  The directory on the FTP mirror specified by C<host> in which the
tarball is located.  Required.

=item * C<perl_version>

String denoting a Perl release.  The string must start with C<perl->, followed
by the major version, minor version and patch version delimited by periods.
The major version is always C<5>.  Required.

=item * C<compression>

String denoting the compression format of the tarball you wish to download.
Eligible compression formats are C<gz>, C<bz2> and C<bz2>.  Required.

Note that not all compression formats are available for all tarballs on our
FTP mirrors and that the compression formats offered may change over time.

Note further that C<gz> is currently the recommended format, as the other
methods have not been thorougly tested.

=item * C<work_dir>

String holding absolute path to the directory in which the work of configuring
and building the new F<perl> will be performed.  Optional; if not provided a
temporary directory created via C<File::Temp::tempdir()> will be used.

=item * C<verbose>

Extra information provided on STDOUT.  Optional; defaults to being off;
provide a Perl-true value to turn it on.  Scope is limited to this method.

=item * C<mock>

Display the expected results of the download on STDOUT, but don't actually do
it.  Optional; defaults to being off; provide a Perl-true value to turn it on.
Any program using this option will terminate with a non-zero status once the
results have been displayed.

=back

=item * Return Value

Returns a list of two elements:

=over 4

=item * Tarball path

String holding absolute path to the tarball once downloaded.

=item * Work directory

String holding path of directory in which work of configuring and building
F<perl> will be performed.  (This is probably only useful if you want to see
the path to the temporary directory.  It will be uninitialized if C<mock> is
turned on.)

=back

=item * Comment

The method guarantees the existence of a directory whose name will be the
value of the C<perl_version> argument and which will be found underneath the
F<testing> directory (discussed in C<new()> above).  This "release directory"
-- accessible by calling C<$self->get_release_dir()> -- will be the directory
below which a new F<perl> will be installed.

=back

=cut

sub perform_tarball_download {
    my ($self, $args) = @_;
    croak "perform_tarball_download: Must supply hash ref as argument"
        unless ref($args) eq 'HASH';
    my $verbose = delete $args->{verbose} || '';
    my $mock = delete $args->{mock} || '';
    my %eligible_args = map { $_ => 1 } ( qw|
        host hostdir perl_version compression work_dir
    | );
    for my $k (keys %$args) {
        croak "perform_tarball_download: '$k' is not a valid element"
            unless $eligible_args{$k};
    }
    croak "perform_tarball_download: '$args->{perl_version}' does not conform to pattern"
        unless $args->{perl_version} =~ m/$self->{perl_version_pattern}/;

    my %eligible_compressions = map { $_ => 1 } ( qw| gz bz2 xz | );
    croak "perform_tarball_download: '$args->{compression}' is not a valid compression format"
        unless $eligible_compressions{$args->{compression}};

    croak "Could not locate '$args->{work_dir}' for purpose of downloading tarball and building perl"
        if (exists $args->{work_dir} and (! -d $args->{work_dir}));

    # host, hostdir, compression are only used within the scope of this
    # method.  Hence, they don't need to be inserted into the object.

    for my $k ( qw| perl_version work_dir | ) {
        $self->{$k} = $args->{$k};
    }

    my $this_tarball = "$self->{perl_version}.tar.$args->{compression}";

    my $this_release_dir = File::Spec->catdir($self->get_testing_dir(), $self->{perl_version});
    unless (-d $this_release_dir) { make_path($this_release_dir, { mode => 0755 }); }
    croak "Could not locate $this_release_dir" unless (-d $this_release_dir);
    $self->{release_dir} = $this_release_dir;

    my $ftpobj = Perl::Download::FTP->new( {
        host        => $args->{host},
        dir         => $args->{hostdir},
        Passive     => 1,
        verbose     => $verbose,
    } );

    unless ($mock) {
        if (! $self->{work_dir}) {
            $self->{restore_to_dir} = cwd();
            $self->{work_dir} = tempdir(CLEANUP => 1);
        }
        if ($verbose) {
            say "Beginning FTP download (this will take a few minutes)";
            say "Perl configure-build-install cycle will be performed in $self->{work_dir}";
        }
        my $tarball_path = $ftpobj->get_specific_release( {
            release         => $this_tarball,
            path            => $self->{work_dir},
        } );
        unless (-f $tarball_path) {
            croak "Tarball $tarball_path not found: $!";
        }
        else {
            say "Path to tarball is $tarball_path" if $verbose;
            $self->{tarball_path} = $tarball_path;
            return ($tarball_path, $self->{work_dir});
        }
    }
    else {
        say "Mocking; not really attempting FTP download" if $verbose;
        return 1;
    }
}

sub get_release_dir {
    my $self = shift;
    if (! defined $self->{release_dir}) {
        croak "release directory has not yet been defined; run perform_tarball_download()";
    }
    else {
        return $self->{release_dir};
    }
}

sub access_configure_command {
    my ($self, $arg) = @_;
    my $cmd;
    if (length $arg) {
        $cmd = $arg;
    }
    else {
        $cmd = "sh ./Configure -des -Dusedevel -Uversiononly -Dprefix=";
        $cmd .= $self->get_release_dir;
        $cmd .= " -Dman1dir=none -Dman3dir=none";
    }
    $self->{configure_command} = $cmd;
}

sub access_make_install_command {
    my ($self, $arg) = @_;
    my $cmd;
    if (length $arg) {
        $cmd = $arg;
    }
    else {
        $cmd = "make install"
    }
    $self->{make_install_command} = $cmd;
}

=head2 C<configure_build_install_perl()>

=over 4

=item * Purpose

Configures, builds and installs F<perl> from the downloaded tarball.

=item * Arguments

    my $this_perl = $self->configure_build_install_perl({
        verbose => 1,
    });

Hash reference with the following elements:

=over 4

=item * C<configure_command>

String holding a shell command to call Perl's F<Configure> program with
command-line options.  Optional; will default to:

    my $release_dir = $self->get_release_dir();

    sh ./Configure -des -Dusedevel -Uversiononly -Dprefix=$release_dir \
        -Dman1dir=none -Dman3dir=none

The spelling of the command is subsequently accessible by calling
C<$self->access_configure_command()>.

=item * C<make_install_command>

String holding a shell command to build and install F<perl> underneath the
release directory.  Optional; will default to:

    make install

The spelling of the command is subsequently accessible by calling
C<$self->access_make_install_command()>.

=item * C<verbose>

Extra information provided on STDOUT.  Optional; defaults to being off.  Set
to C<1> (recommended) for moderate verbosity.  Set to C<2> for extra verbosity
(full output of decompression commands, F<Configure> and F<make>).  Scope is
limited to this method.

=back

=item * Return Value

String holding absolute path to the new F<perl> executable.  This location can
subsequently be accessed by calling C<$self->get_this_perl()>.

=item * Comment

The new F<perl> executable will sit two levels underneath the release
directory in a directory named F<bin/>.  That directory will sit next to a
directory named F<lib/> under which libraries will be installed.  Those
locations can subsequently be accessed by calling C<$self->get_bin_dir()> and
C<$self->get_lib_dir()>, respectively.

=back

=cut

sub configure_build_install_perl {
    my ($self, $args) = @_;
    my $cwd = cwd();
    croak "configure_build_install_perl: Must supply hash ref as argument"
        unless ( ( defined $args ) and ( ref($args) eq 'HASH' ) );
    my $verbose = delete $args->{verbose} || '';

    # What I want in terms of verbose output:
    # 0: No verbose output from Test::Against::Dev
    #    Minimal output from tar, Configure, make
    #    (tar xzf; Configure, make 1>/dev/null
    # 1: Verbose output from Test::Against::Dev
    #    Minimal output from tar, Configure, make
    #    (tar xzf; Configure, make 1>/dev/null
    # 2: Verbose output from Test::Against::Dev
    #    Verbose output from tar ('v')
    #    Regular output from Configure, make

    # Use default configure and make install commands unless an argument has
    # been passed.
    my $acc = $self->access_configure_command($args->{configure_command} || '');
    my $mic = $self->access_make_install_command($args->{make_install_command} || '');
    unless ($verbose > 1) {
        $self->access_configure_command($acc . " 1>/dev/null");
        $self->access_make_install_command($mic . " 1>/dev/null");
    }

    chdir $self->{work_dir} or croak "Unable to change to $self->{work_dir}";
    my $untar_command = ($verbose > 1) ? 'tar xzvf' : 'tar xzf';
    system(qq|$untar_command $self->{tarball_path}|)
        and croak "Unable to untar $self->{tarball_path}";
    say "Tarball has been untarred into ", File::Spec->catdir($self->{work_dir}, $self->{perl_version})
        if $verbose;
    my $build_dir = $self->{perl_version};
    chdir $build_dir or croak "Unable to change to $build_dir";
    say "Configuring perl with '$self->{configure_command}'" if $verbose;
    system(qq|$self->{configure_command}|)
        and croak "Unable to configure with '$self->{configure_command}'";
    say "Building and installing perl with '$self->{make_install_command}'" if $verbose;
    system(qq|$self->{make_install_command}|)
        and croak "Unable to build and install with '$self->{make_install_command}'";
    my $rdir = $self->get_release_dir();
    my $bin_dir = File::Spec->catdir($rdir, 'bin');
    my $lib_dir = File::Spec->catdir($rdir, 'lib');
    my $this_perl = File::Spec->catfile($bin_dir, 'perl');
    croak "Could not locate '$bin_dir'" unless (-d $bin_dir);
    croak "Could not locate '$lib_dir'" unless (-d $lib_dir);
    croak "Could not locate '$this_perl'" unless (-f $this_perl);
    $self->{bin_dir} = $bin_dir;
    $self->{lib_dir} = $lib_dir;
    $self->{this_perl} = $this_perl;
    chdir $cwd or croak "Unable to change back to $cwd";
    if ($self->{restore_to_dir}) {
        chdir $self->{restore_to_dir} or croak "Unable to change back to $self->{restore_to_dir}";
    }
    return $this_perl;
}

sub get_this_perl {
    my $self = shift;
    if (! defined $self->{this_perl}) {
        croak "perl has not yet been installed; run configure_build_install_perl";
    }
    else {
        return $self->{this_perl};
    }
}

sub get_bin_dir {
    my $self = shift;
    if (! defined $self->{bin_dir}) {
        croak "bin directory has not yet been defined; run configure_build_install_perl()";
    }
    else {
        return $self->{bin_dir};
    }
}

sub get_lib_dir {
    my $self = shift;
    if (! defined $self->{lib_dir}) {
        croak "lib directory has not yet been defined; run configure_build_install_perl()";
    }
    else {
        return $self->{lib_dir};
    }
}

=head2 C<fetch_cpanm()>

=over 4

=item * Purpose

Fetch the fatpacked F<cpanm> executable and install it against the newly
installed F<perl>.

=item * Arguments

    my $this_cpanm = $self->fetch_cpanm( { verbose => 1 } );

Hash reference with these elements:

=over 4

=item * C<uri>

String holding URI from which F<cpanm> will be downloaded.  Optional; defaults
to L<http://cpansearch.perl.org/src/MIYAGAWA/App-cpanminus-1.7043/bin/cpanm>.

=item * C<verbose>

Extra information provided on STDOUT.  Optional; defaults to being off;
provide a Perl-true value to turn it on.  Scope is limited to this method.

=back

=item * Return Value

String holding the absolute path to the newly installed F<cpanm> executable.

=item * Comment

The executable's location can subsequently be accessed by calling
C<$self->get_this_cpanm()>.  The method also guarantees the existence of a
F<.cpanm> directory underneath the release directory.  This directory can
subsequently be accessed by calling C<$self->get_cpanm_dir()>.

=back

=cut

sub fetch_cpanm {
    my ($self, $args) = @_;
    croak "fetch_cpanm: Must supply hash ref as argument"
        unless ( ( defined $args ) and ( ref($args) eq 'HASH' ) );
    my $verbose = delete $args->{verbose} || '';
    my $uri = (exists $args->{uri} and length $args->{uri})
        ? $args->{uri}
        : 'http://cpansearch.perl.org/src/MIYAGAWA/App-cpanminus-1.7043/bin/cpanm';

    my $cpanm_dir = File::Spec->catdir($self->get_release_dir(), '.cpanm');
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
}

sub get_this_cpanm {
    my $self = shift;
    if (! defined $self->{this_cpanm}) {
        croak "cpanm has not yet been installed against the 'perl' being tested; run fetch_cpanm()";
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

sub setup_results_directories {
    my $self = shift;
    croak "Perl release not yet defined" unless $self->{perl_version};
    my $vresults_dir = File::Spec->catdir($self->get_results_dir, $self->{perl_version});
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

Mutually exclusive; must use one or the other but not both.

The value of C<module_list> must be an array reference holding a list of
modules for which you wish to track the impact of changes in the Perl 5 core
distribution over time.  In either case the module names are spelled in
C<Some::Module> format -- I<i.e.>, double-colons -- rather than in
C<Some-Module> format (hyphens).

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

   cpan-river-1000.perl-5.27.6.01.build.log.gz

=item * Comment

The method guarantees the existence of several directories underneath the
"results" directory discussed above.  These are illustrated as follows:

    /path/to/application/results/
                        /results/perl-5.27.6/
                        /results/perl-5.27.6/analysis/
                        /results/perl-5.27.6/buildlogs/
                        /results/perl-5.27.6/storage/

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

    unless (-d $self->{vresults_dir}) {
        $self->setup_results_directories();
    }

    my $cpanreporter_dir = File::Spec->catdir($self->get_release_dir(), '.cpanreporter');
    unless (-d $cpanreporter_dir) { make_path($cpanreporter_dir, { mode => 0755 }); }
    croak "Could not locate $cpanreporter_dir" unless (-d $cpanreporter_dir);
    $self->{cpanreporter_dir} = $cpanreporter_dir;

    unless ($self->{cpanm_dir}) {
        say "Defining previously undefined cpanm_dir" if $verbose;
        my $cpanm_dir = File::Spec->catdir($self->get_release_dir(), '.cpanm');
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
        @modules = path($args->{module_file})->lines({ chomp => 1 });
    }
    my @cmd = (
        $self->get_this_perl,
        "-I$self->get_lib_dir",
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

sub gzip_cpanm_build_log {
    my ($self) = @_;
    my $build_log_link = File::Spec->catfile($self->get_cpanm_dir, 'build.log');
    croak "Did not find symlink for build.log at $build_log_link"
        unless (-l $build_log_link);
    my $real_log = readlink($build_log_link);

    my $pattern = qr/^$self->{title}\.$self->{perl_version}\.build\.log\.gz$/;
    $self->{gzlog_pattern} = $pattern;
    opendir my $DIRH, $self->{buildlogs_dir} or croak "Unable to open buildlogs_dir for reading";
    my @files_found = grep { -f $_ and $_ =~ m/$pattern/ } readdir $DIRH;
    closedir $DIRH or croak "Unable to close buildlogs_dir after reading";

    # In this new approach, we'll assume that we never do anything except
    # exactly 1 run per monthly release.  Hence, there shouldn't be any files
    # in this directory whatsoever.  We'll croak if there are such file.
    croak "There are already log files in '$self->{buildlogs_dir}'"if scalar(@files_found);

    my $gzipped_build_log = join('.' => (
        $self->{title},
        $self->{perl_version},
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
    my $ranalysis_dir = $self->{analysis_dir};
    unless (-d $ranalysis_dir) { make_path($ranalysis_dir, { mode => 0755 }); }
        croak "Could not locate $ranalysis_dir" unless (-d $ranalysis_dir);

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
    $reporter->set_report_dir($ranalysis_dir);
    $reporter->run;
    say "See results in $ranalysis_dir" if $verbose;

    return $ranalysis_dir;
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

    # As a precaution, we archive the log.json files.

    my $output = join('.' => (
        $self->{title},
        $self->{perl_version},
        'log',
        'json',
        'tar',
        'gz'
    ) );
    my $foutput = File::Spec->catfile($self->{storage_dir}, $output);
    say "Output will be: $foutput" if $verbose;

    my $vranalysis_dir = $self->{analysis_dir};
    opendir my $DIRH, $vranalysis_dir or croak "Unable to open $vranalysis_dir for reading";
    my @json_log_files = sort map { File::Spec->catfile('analysis', $_) }
        grep { m/\.log\.json$/ } readdir $DIRH;
    closedir $DIRH or croak "Unable to close $vranalysis_dir after reading";
    dd(\@json_log_files) if $verbose;

    my $versioned_results_dir = $self->{vresults_dir};
    chdir $versioned_results_dir or croak "Unable to chdir to $versioned_results_dir";
    my $cwd = cwd();
    say "Now in $cwd" if $verbose;

    my $tar = Archive::Tar->new;
    $tar->add_files(@json_log_files);
    $tar->write($foutput, COMPRESS_GZIP);
    croak "$foutput not created" unless (-f $foutput);
    say "Created $foutput" if $verbose;

    # Having archived our log.json files, we now proceed to read them and to
    # write a pipe- (or comma-) separated-values file summarizing the run.

    my %data = ();
    for my $log (@json_log_files) {
        my $flog = File::Spec->catfile($cwd, $log);
        my %this = ();
        my $f = Path::Tiny::path($flog);
        my $decoded;
        {
            local $@;
            eval { $decoded = decode_json($f->slurp_utf8); };
            if ($@) {
                say STDERR "JSON decoding problem in $flog: <$@>";
                eval { $decoded = JSON->new->decode($f->slurp_utf8); };
            }
        }
        map { $this{$_} = $decoded->{$_} } ( qw| author dist distname distversion grade | );
        $data{$decoded->{dist}} = \%this;
    }
    #pp(\%data);

    my $cdvfile = join('.' => (
        $self->{title},
        $self->{perl_version},
        (($sep_char eq ',') ? 'csv' : 'psv'),
    ) );

    my $fcdvfile = File::Spec->catfile($self->{storage_dir}, $cdvfile);
    say "Output will be: $fcdvfile" if $verbose;

    my @fields = ( qw| author distname distversion grade | );
    my $perl_version = $self->{perl_version};
    my $columns = [
        'dist',
        map { "$perl_version.$_" } @fields,
    ];
    my $psv = Text::CSV_XS->new({ binary => 1, auto_diag => 1, sep_char => $sep_char, eol => $/ });
    open my $OUT, ">:encoding(utf8)", $fcdvfile
        or croak "Unable to open $fcdvfile for writing";
    $psv->print($OUT, $columns), "\n" or $psv->error_diag;
    for my $dist (sort keys %data) {
        $psv->print($OUT, [
           $dist,
           @{$data{$dist}}{@fields},
        ]) or $psv->error_diag;
    }
    close $OUT or croak "Unable to close $fcdvfile after writing";
    croak "$fcdvfile not created" unless (-f $fcdvfile);
    say "Examine ", (($sep_char eq ',') ? 'comma' : 'pipe'), "-separated values in $fcdvfile" if $verbose;

    return $fcdvfile;
}

=head2 C<new_from_existing_perl_cpanm()>

=over 4

=item * Purpose

Alternate constructor to be used when you have already built a C<perl>
executable to be used in tracking Perl development and have installed a
C<cpanm> against that C<perl>.

=item * Arguments

    $self = Test::Against::Dev->new_from_existing_perl_cpanm( {
        path_to_perl    => '/path/to/perl-5.27.0/bin/perl',
        application_dir => '/path/to/application',
        perl_version    => 'perl-5.27.0',
    } );

Takes a hash reference with the following elements:

=over 4

=item * C<path_to_perl>

String holding path to an installed F<perl> executable.  Required.

=item * C<application_dir>

String holding path to the directory which will serve as the top level for
your application.  (Same meaning as in C<new()>.)  Required.

=item * C<perl_version>

String denoting a Perl release.  The string must start with C<perl->, followed
by the major version, minor version and patch version delimited by periods.
The major version is always C<5>.  (Same meaning as in
C<perform_tarball_download()>.)  Required.

=item * C<verbose>

Extra information provided on STDOUT.  Optional; defaults to being off;
provide a Perl-true value to turn it on.  Scope is limited to this method.

=back

=item * Return Value

Test::Against::Dev object.

=item * Comment

As was the case with C<new()>, this method guarantees the existence of the
application directory and the F<testing> and F<results> directories
thereunder.  It also performs sanity checks for the paths to installed F<perl>
and F<cpanm>.

If you already have a F<perl> installed which suffices for a monthly
development release, then you can start with this method, omit calls to
C<perform_tarball_download()>, C<configure_build_install_perl()> and
C<fetch_cpanm()> and go directly to C<run_cpanm()>.

=back

=cut

sub new_from_existing_perl_cpanm {
    my ($class, $args) = @_;
    croak "new_from_existing_perl_cpanm: Must supply hash ref as argument"
        unless ( ( defined $args ) and ( ref($args) eq 'HASH' ) );
    my $verbose = delete $args->{verbose} || '';
    for my $el ( qw| path_to_perl application_dir perl_version | ) {
        croak "Need '$el' element in arguments hash ref"
            unless exists $args->{$el};
    }
    croak "Could not locate perl executable at '$args->{path_to_perl}'"
        unless (-x $args->{path_to_perl} and basename($args->{path_to_perl}) =~ m/^perl/);

    my $data = { perl_version_pattern => $PERL_VERSION_PATTERN };

    croak "'$args->{perl_version}' does not conform to pattern"
        unless $args->{perl_version} =~ m/$data->{perl_version_pattern}/;
    $data->{perl_version} = $args->{perl_version};

    my $this_perl = $args->{path_to_perl};

    croak "Could not locate $args->{application_dir}"
        unless (-d $args->{application_dir});
    $data->{application_dir} = $args->{application_dir};

    for my $dir (qw| testing results |) {
        my $fdir = File::Spec->catdir($data->{application_dir}, $dir);
        unless (-d $fdir) { make_path($fdir, { mode => 0755 }); }
        croak "Could not locate $fdir" unless (-d $fdir);
        $data->{"${dir}_dir"} = $fdir;
    }

    # Is the perl's parent directory bin/?
    # Is there a lib/ directory next to parent bin/?
    # Can the user write to directory lib/?
    # What is the parent of bin/ and lib/?
    # Is that parent writable (as user will need to create .cpanm/ and
    # .cpanreporter/ there)?
    # Is there a 'cpanm' executable located in bin?

    my ($volume,$directories,$file) = File::Spec->splitpath($this_perl);
    my @directories = File::Spec->splitdir($directories);
    pop @directories if $directories[-1] eq '';
    croak "'$this_perl' not found in directory named 'bin/'"
        unless $directories[-1] eq 'bin';
    my $bin_dir = File::Spec->catdir(@directories);

    my $lib_dir = File::Spec->catdir(@directories[0 .. ($#directories - 1)], 'lib');
    croak "Could not locate '$lib_dir'" unless (-d $lib_dir);
    croak "'$lib_dir' not writable" unless (-w $lib_dir);

    my $release_dir  = File::Spec->catdir(@directories[0 .. ($#directories - 1)]);
    croak "'$release_dir' not writable" unless (-w $release_dir);

    my $this_cpanm = File::Spec->catfile($bin_dir, 'cpanm');
    croak "Could not locate cpanm executable at '$this_cpanm'"
        unless (-x $this_cpanm);

    my $cpanm_dir = File::Spec->catdir($release_dir, '.cpanm');
    croak "Could not locate $cpanm_dir" unless (-d $cpanm_dir);

    my %load = (
        release_dir     => $release_dir,
        bin_dir         => $bin_dir,
        lib_dir         => $lib_dir,
        this_perl       => $this_perl,
        this_cpanm      => $this_cpanm,
        cpanm_dir       => $cpanm_dir,
    );
    $data->{$_} = $load{$_} for keys %load;

    return bless $data, $class;
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

Please report any bugs by mail to C<bug-Test-Against-Dev@rt.cpan.org> or
through the web interface at L<http://rt.cpan.org>.

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

Copyright James E Keenan 2017-2018.  All rights reserved.

=head1 ACKNOWLEDGEMENTS

This library emerged in the wake of the author's participation in the Perl 5
Core Hackathon held in Amsterdam, Netherlands, in October 2017.  The author
thanks the lead organizers of that event, Sawyer X and Todd Rinaldo, for the
invitation to the hackathon.  The event could not have happened without the
generous contributions from the following companies:

=over 4

=item * L<Booking.com|https://www.booking.com>

=item * L<cPanel|https://cpanel.com>

=item * L<Craigslist|https://www.craigslist.org/about/craigslist_is_hiring>

=item * L<Bluehost|https://www.bluehost.com/>

=item * L<Assurant|https://www.assurantmortgagesolutions.com/>

=item * L<Grant Street Group|https://grantstreet.com/>

=back

=head1 SEE ALSO

perl(1). CPAN::cpanminus::reporter::RetainReports(3).  Perl::Download::FTP(3).
App::cpanminus::reporter(3).  cpanm(3).

L<2017 Perl 5 Core Hackathon Discussion on Testing|https://github.com/p5h/2017/wiki/What-Do-We-Want-and-Need-from-Smoke-Testing%3F>.

L<perl.cpan.testers.discuss Thread on Testing|https://www.nntp.perl.org/group/perl.cpan.testers.discuss/2017/10/msg4172.html>.

=cut

