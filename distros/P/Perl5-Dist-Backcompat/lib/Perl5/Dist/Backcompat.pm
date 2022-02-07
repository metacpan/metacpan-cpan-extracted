package Perl5::Dist::Backcompat;
use 5.14.0;
use warnings;
our $VERSION = '0.10';
use Archive::Tar;
use Carp qw( carp croak );
use Cwd qw( cwd );
use File::Copy qw( copy move );
use File::Find qw( find );
use File::Spec;
use File::Temp qw( tempdir );
# From CPAN
use CPAN::DistnameInfo;
use Data::Dump qw( dd pp );
use File::Copy::Recursive::Reduced qw( dircopy );

=head1 NAME

Perl5::Dist::Backcompat - Analyze F<dist/> distributions for CPAN release viability

=head1 SYNOPSIS

    my $params = {
        perl_workdir => '/path/to/git/checkout/of/perl',
        verbose => 1,
    };
    my $self = Perl5::Dist::Backcompat->new( $params );

=head1 DESCRIPTION

This module serves as the backend for the program F<p5-dist-backcompat> which
is also part of the F<Perl5-Dist-Backcompat> distribution.  This document's
focus is on documenting the methods used publicly in that program as well as
internal methods and subroutines called by those public methods.  For
discussion on the problem which this distribution tries to solve, and how well
it currently does that or not, please (i) read the plain-text F<README> in the
CPAN distribution or the F<README.md> in the L<GitHub
repository|https://github.com/jkeenan/p5-dist-backcompat>; and (ii) read the
front-end program's documentation via F<perldoc p5-dist-backcompat>.

=head1 PREREQUISITES

F<perl> 5.14.0 or newer, with the following modules installed from CPAN:

=over 4

=item * F<CPAN::DistnameInfo>

=item * F<Data::Dump>

=item * F<File::Copy::Recursive::Reduced>

=back

=head1 PUBLIC METHODS

=head2 C<new()>

=over 4

=item * Purpose

Perl5::Dist::Backcompat constructor.

=item * Arguments

    my $self = Perl5::Dist::Backcompat->new( $params );

Single hash reference.  Currently valid keys for this hashref are:

=over 4

=item * C<path_to_perls>

String holding absolute path to directory on disk where older F<perl>
executables are stored.  Defaults to C</media/Tux/perls-t/bin>.

=item * C<perl_workdir>

String holding absolute path to directory holding a F<git> checkout of Perl 5
core distribution and which has been built up through F<make>.

=item * C<tarball_dir>

String holding absolute path to directory holding tarballs of the most recent
CPAN releases of F<dist/> distros.

=item * C<older_perls_file>

String holding path to file whose records list the versions of F<perl> against
which we intend to test the tarballs of F<dist/> distros found in
C<tarball_dir>.  In that file, these versions match this pattern:
C<^perl5\.\d{1,2}\.\d1,2}$>, I<e.g.,> C<perl5.14.4>.  (There is a default
value which is only meaningful if you're starting in a F<git> checkout of this
F<Perl5-Dist-Backcompat> library.)

=item * C<distro_metadata_file>

String holding path to file whose records are pipe-delimited fields holding
metadata about particular F<dist/> distributions.

    # name|minimum_perl_version|needs_threaded_perl|needs_ppport_h|needs_threads_h|needs_shared_h
    threads|5.014000|1|1|1|0

(There is a default value which is only meaningful if you're starting in a
F<git> checkout of this F<Perl5-Dist-Backcompat> library.)

=item * C<host>

String holding system's F<hostname>.  Defaults to C<dromedary.p5h.org>.

=item * C<verbose>

Boolean.  Extra output during operation.  Defaults to off (C<0>), but
recommended (C<1>).

=back

=item * Return Value

Perl5::Dist::Backcompat object.

=back

=cut

sub new {
    my ($class, $params) = @_;
    if (defined $params and ref($params) ne 'HASH') {
        croak "Argument supplied to constructor must be hashref";
    }
    my %valid_params = map {$_ => 1} qw(
        verbose
        host
        path_to_perls
        perl_workdir
        tarball_dir
        older_perls_file
        distro_metadata_file
    );
    my @invalid_params = ();
    for my $p (keys %$params) {
        push @invalid_params, $p unless $valid_params{$p};
    }
    if (@invalid_params) {
        my $msg = "Constructor parameter(s) @invalid_params not valid";
        croak $msg;
    }
    croak "Must supply value for 'perl_workdir'"
        unless $params->{perl_workdir};

    my $data = {};
    for my $p (keys %valid_params) {
        $data->{$p} = (defined $params->{$p}) ? $params->{$p} : '';
    }
    $data->{host} ||= 'dromedary.p5h.org';
    $data->{path_to_perls} ||= '/media/Tux/perls-t/bin';
    $data->{tarball_dir} ||= "$ENV{P5P_DIR}/dist-backcompat/tarballs";
    $data->{older_perls_file} ||=  File::Spec->catfile(
        '.', 'etc', 'dist-backcompat-older-perls.txt');
    $data->{distro_metadata_file} ||= File::Spec->catfile(
        '.', 'etc', 'dist-backcompat-distro-metadata.txt');

    croak "Could not locate directory $data->{path_to_perls} for perl executables"
        unless -d $data->{path_to_perls};
    croak "Could not locate directory $data->{tarball_dir} for downloaded tarballs"
        unless -d $data->{tarball_dir};

    return bless $data, $class;
}

=head2 C<init()>

=over 4

=item * Purpose

Guarantee that we can find the F<perl> executables we'll be using; the F<git>
checkout of the core distribution; metadata files and loading of data
therefrom.

=item * Arguments

    $self->init();

None; all data needed is found within the object.

=item * Return Value

Returns the object itself.

=back

=cut

sub init {
    # From here on, we assume we're starting from the home directory of
    # someone with an account on Dromedary.

    my $self = shift;

    my $currdir = cwd();
    chdir $self->{perl_workdir}
        or croak "Unable to change to $self->{perl_workdir}";

    my $describe = `git describe`;
    chomp($describe);
    croak "Unable to get value for 'git describe'"
        unless $describe;
    $self->{describe} = $describe;
    chdir $currdir or croak "Unable to change back to starting directory";

    my $manifest = File::Spec->catfile($self->{perl_workdir}, 'MANIFEST');
    croak "Could not locate $manifest" unless -f $manifest;
    $self->{manifest} = $manifest;

    my $maint_file = File::Spec->catfile($self->{perl_workdir}, 'Porting', 'Maintainers.pl');
    require $maint_file;   # to get %Modules in package Maintainers
    $self->{maint_file} = $maint_file;

    my $manilib_file = File::Spec->catfile($self->{perl_workdir}, 'Porting', 'manifest_lib.pl');
    require $manilib_file; # to get function sort_manifest()
    $self->{manilib_file} = $manilib_file;

    my %distmodules = ();
    for my $m (keys %Maintainers::Modules) {
        if ($Maintainers::Modules{$m}{FILES} =~ m{dist/}) {
            $distmodules{$m} = $Maintainers::Modules{$m};
        }
    }

    # Sanity checks; all modules under dist/ should be blead-upstream and have P5P
    # as maintainer.
    _sanity_check(\%distmodules, $self->{describe}, $self->{verbose});
    $self->{distmodules} = \%distmodules;

    croak "Could not locate $self->{distro_metadata_file}" unless -f $self->{distro_metadata_file};

    my %distro_metadata = ();

    open my $IN, '<', $self->{distro_metadata_file}
        or croak "Unable to open $self->{distro_metadata_file} for reading";
    while (my $l = <$IN>) {
        chomp $l;
        next if $l =~ m{^(\#|\s*$)};
        my @rowdata = split /\|/, $l;
        # Refine this later
        $distro_metadata{$rowdata[0]} = {
            minimum_perl_version => $rowdata[1] // '',
            needs_threaded_perl  => $rowdata[2] // '',
            needs_ppport_h       => $rowdata[3] // '',
            needs_threads_h      => $rowdata[4] // '',
            needs_shared_h       => $rowdata[5] // '',

        };
    }
    close $IN or die "Unable to close $self->{distro_metadata_file} after reading: $!";

    my $this = $self->identify_cpan_tarballs_with_makefile_pl();
    for my $d (keys %{$this}) {
        $distro_metadata{$d}{tarball}   = $this->{$d}->{tarball};
        $distro_metadata{$d}{distvname} = $this->{$d}->{distvname};
    }

    $self->{distro_metadata} = \%distro_metadata;

    croak "Could not locate $self->{older_perls_file}"
        unless -f $self->{older_perls_file};

    return $self;
}

=head2 C<categorize_distros()>

=over 4

=item * Purpose

Categorize each F<dist/> distro in one of 4 categories based on the status and
appropriateness of its F<Makefile.PL> (if any).

=item * Arguments

    $self->categorize_distros();

None; all data needed is already within the object.

=item * Return Value

Returns the object.

=item * Comment

Since our objective is to determine the CPAN release viability of code found
within F<dist/> distros in core, we need various ways to categorize those
distros.  This method will make a categorization based on the status of the
distros's F<Makefile.PL>.  The categories will be mutually exclusive. By order
of processing the categories will be:

=item *

B<unreleased:> As based on an examination of C<%Maintainers::Modules> in
F<Porting/Maintainers.PL>, at least one distro has no current CPAN release.
Such modules will be categorized as C<unreleased>.

=item *

B<cpan:> Certain F<dist/> distros have a CPAN release which contains a F<Makefile.PL>.
Such distros I<may> also have a F<Makefile.PL> in core; that F<Makefile.PL>
may or may not be functionally identical to that on CPAN.  In either case, we
shall make an assumption that the F<Makefile.PL> found in the most recent CPAN
release is the version to be preferred for the purpose of this program.  Such
distros will be categorized as C<cpan>.

B<Note:> The following 3 categories should be considered I<dormant> because,
as the code in this methods is currently structured, all current F<dist/>
distros are categorized as either C<unreleased> or C<cpan>.  These categories
may be removed in a future release.

=over 4

=item *

B<core:> Certain F<dist/> distros have a F<Makefile.PL> in core.  Assuming that such a
distro has not already been categorized as C<cpan>, we will use that version
in this program.  Such distros will be categorized as C<core>.

=item *

B<generated:> If a F<dist/> distro has no F<Makefile.PL> either on CPAN or in core but, at
the end of F<make> in the Perl 5 build process does have a F<Makefile.PL>
generated by that process, we will categorize such a distro as C<generated>.

=item *

B<tbd:> The remaining F<dist/> distros have a F<Makefile.PL> neither on CPAN nor in
core.  For purpose of compilation in core they I<may> have a F<Makefile>
generated by core's F<make_ext.pl> process, but this file, if created, does
not appear to be retained on disk at the end of F<make>.  Such a distro might
lack a F<Makefile.PL> in its CPAN release because the CPAN releasor uses
technology such as F<Dist::Zilla> to produce such a release and such
technology does not require a F<Makefile.PL> to be included in the CPAN
tarball.  At the present time we will categorize such distros as C<tbd> and
these will be skipped by subsequent methods.

=back

=back

=cut

sub categorize_distros {
    my $self = shift;
    my %makefile_pl_status = ();

    # First, identify those dist/ distros which, on the basis of data in
    # Porting/Maintainers.PL, do not currently have CPAN releases.

    for my $m (keys %{$self->{distmodules}}) {
        if (! exists $self->{distmodules}->{$m}{DISTRIBUTION}) {
            my ($distname) = $self->{distmodules}->{$m}{FILES} =~ m{^dist/(.*)/?$};
            $makefile_pl_status{$distname} = 'unreleased';
        }
    }

    # Second, identify those dist/ distros which have their own hard-coded
    # Makefile.PLs in their CPAN releases.  We'll call these 'cpan'.  (We've
    # already done some of the work for this in
    # $self->identify_cpan_tarballs_with_makefile_pl() called from within
    # init().  The location of a distro's tarball is given by:
    # $self->{distro_metadata}->{$d}->{tarball}.)

    for my $d (keys %{$self->{distro_metadata}}) {
        if (! $makefile_pl_status{$d}) {
            my $tb = $self->{distro_metadata}->{$d}->{tarball};
            my ($tar, $hasmpl);
            $tar = Archive::Tar->new($tb);
            croak "Unable to create Archive::Tar object for $d" unless defined $tar;
            $self->{distro_metadata}->{$d}->{tar} = $tar;
            $hasmpl = $self->{distro_metadata}->{$d}->{tar}->contains_file(
                File::Spec->catfile($self->{distro_metadata}->{$d}->{distvname},'Makefile.PL')
            );
            if ($hasmpl) {
                $makefile_pl_status{$d} = 'cpan';
            }
            else {
                carp "$d Makefile.PL doubtful" unless $hasmpl;
            }
        }
    }

    # Third, identify those dist/ distros which have their own hard-coded
    # Makefile.PLs in the core distribution.  We'll call these 'native'.

    my @sorted = read_manifest($self->{manifest});

    for my $f (@sorted) {
        next unless $f =~ m{^dist/};
        my $path = (split /\t+/, $f)[0];
        if ($path =~ m{/(.*?)/Makefile\.PL$}) {
            my $distro = $1;
            $makefile_pl_status{$distro} = 'native'
                unless $makefile_pl_status{$distro};
        }
    }

    # Fourth, identify those dist/ distros whose Makefile.PL is generated during
    # Perl's own 'make' process.

    my $get_generated_makefiles = sub {
        my $pattern = qr{dist/(.*?)/Makefile\.PL$};
        if ( $File::Find::name =~ m{$pattern} ) {
            my $distro = $1;
            if (! $makefile_pl_status{$distro}) {
                $makefile_pl_status{$distro} = 'generated';
            }
        }
    };
    find(
        \&{$get_generated_makefiles},
        File::Spec->catdir($self->{perl_workdir}, 'dist' )
    );

    # Fifth, identify those dist/ distros whose Makefile.PLs are not yet
    # accounted for.

    for my $d (sort keys %{$self->{distmodules}}) {
        next unless exists $self->{distmodules}->{$d}{FILES};
        my ($distname) = $self->{distmodules}->{$d}{FILES} =~ m{^dist/([^/]+)/?$};
        if (! exists $makefile_pl_status{$distname}) {
            $makefile_pl_status{$distname} = 'tbd';
        }
    }

    $self->{makefile_pl_status} = \%makefile_pl_status;
    return $self;
}

=head2 C<show_makefile_pl_status>

=over 4

=item * Purpose

Display a chart listing F<dist/> distros in one column and the status of their
respective F<Makefile.PL>s in the second column.

=item * Arguments

    $self->show_makefile_pl_status();

None; this method simply displays data already present in the object.

=item * Return Value

Returns a true value when complete.

=item * Comment

Does nothing unless a true value for C<verbose> was passed to C<new()>.

=back

=cut

sub show_makefile_pl_status {
    my $self = shift;
    my %counts;
    for my $module (sort keys %{$self->{makefile_pl_status}}) {
        $counts{$self->{makefile_pl_status}->{$module}}++;
    }
    if ($self->{verbose}) {
        for my $k (sort keys %counts) {
            printf "  %-18s%4s\n" => ($k, $counts{$k});
        }
        say '';
        printf "%-24s%-12s\n" => ('Distribution', 'Status');
        printf "%-24s%-12s\n" => ('------------', '------');
        for my $module (sort keys %{$self->{makefile_pl_status}}) {
            printf "%-24s%-12s\n" => ($module, $self->{makefile_pl_status}->{$module});
        }
    }
    return 1;
}

=head2 C<get_distros_for_testing()>

=over 4

=item * Purpose

Assemble the list of F<dist/> distros which the program will actually test
against older F<perl>s.

=item * Arguments

    my @distros_for_testing = $self->get_distros_for_testing( [ @distros_requested ] );

Single arrayref, optional (though recommended).  If no arrayref is provided,
then the program will test I<all> F<dist/> distros I<except> those whose
"Makefile.PL status" is C<unreleased>.

=item * Return Value

List holding distros to be tested.  (This is provided for readability of the
code, but the list will be stored within the object and subsequently
referenced therefrom.

=item * Comment

In a production program, the list of distros selected for testing may be
provided on the command-line and processed by C<Getopt::Long::GetOptions()>
within that program.  But it's only at this point that we need to add such a
list to the object.

=back

=cut

sub get_distros_for_testing {
    my ($self, $distros) = @_;
    if (defined $distros) {
        croak "Argument passed to get_distros_for_testing() must be arrayref"
            unless ref($distros) eq 'ARRAY';
    }
    else {
        $distros = [];
    }
    my @distros_for_testing = (scalar @{$distros})
        ? @{$distros}
        : sort grep { $self->{makefile_pl_status}->{$_} ne 'unreleased' }
            keys %{$self->{makefile_pl_status}};
    if ($self->{verbose}) {
        say "\nWill test ", scalar @distros_for_testing,
            " distros which have been presumably released to CPAN:";
        say "  $_" for @distros_for_testing;
    }
    $self->{distros_for_testing} = [ @distros_for_testing ];
    return @distros_for_testing;
}

=head2 C<validate_older_perls()>

=over 4

=item * Purpose

Validate the paths and executability of the older perl versions against which
we're going to test F<dist/> distros.

=item * Arguments

    my @perls = $self->validate_older_perls();

None; all necessary information is found within the object.

=item * Return Value

List holding older F<perl> executables against which distros will be tested.
(This is provided for readability of the code, but the list will be stored
within the object and subsequently referenced therefrom.

=back

=cut

sub validate_older_perls {
    my $self = shift;
    my @perllist = ();
    open my $IN1, '<', $self->{older_perls_file}
        or croak "Unable to open $self->{older_perls_file} for reading";
    while (my $l = <$IN1>) {
        chomp $l;
        next if $l =~ m{^(\#|\s*$)};
        push @perllist, $l;
    }
    close $IN1
        or croak "Unable to close $self->{older_perls_file} after reading";

    my @perls = ();

    for my $p (@perllist) {
        say "Locating $p executable ..." if $self->{verbose};
        my $rv;
        my $path_to_perl = File::Spec->catfile($self->{path_to_perls}, $p);
        warn "Could not locate $path_to_perl" unless -e $path_to_perl;
        $rv = system(qq| $path_to_perl -v 1>/dev/null 2>&1 |);
        warn "Could not execute perl -v with $path_to_perl" if $rv;

        my ($major, $minor, $patch) = $p =~ m{^perl(5)\.(\d+)\.(\d+)$};
        my $canon = sprintf "%s.%03d%03d" => ($major, $minor, $patch);

        push @perls, {
            version => $p,
            path => $path_to_perl,
            canon => $canon,
        };
    }
    $self->{perls} = [ @perls ];
    return @perls;
}

=head2 C<test_distros_against_older_perls()>

=over 4

=item * Purpose

Test a given F<dist/> distro against each of the older F<perl>s against which
it is eligible to be tested.

=item * Arguments

    $self->test_distros_against_older_perls('/path/to/debugging/directory');

String holding absolute path to an already created directory to which files
can be written for later study and debugging.  That directory I<may> be
created by C<File::Temp:::tempdir()>, but it should I<not> be created with C<(
CLEANUP => 1)>; the user should manually remove this directory after analysis
is complete.

=item * Return Value

Returns the object itself.

=item * Comment

The method will loop over the selected distros, calling
C<test_one_distro_against_older_perls()> against each.

=back

=cut

sub test_distros_against_older_perls {
    my ($self, $results_dir) = @_;
    # $results_dir will be explicitly user-created to hold the results of
    # testing.

    # A program using Perl5::Dist::Backcompat won't need it until now. So even
    # if we feed that directory to the program via GetOptions, it doesn't need
    # to go into the constructor.  It may be a tempdir but should almost
    # certainly NOT be set to get automatically cleaned up at program
    # conclusion (otherwise, where would you look for the results?).

    croak "Unable to locate $results_dir" unless -d $results_dir;
    $self->{results_dir} = $results_dir;

    # Calculations WILL, however, be done in a true tempdir.  We'll create
    # subdirs and files underneath that tempdir.  We'll cd to that tempdir but
    # come back to where we started before this method exits.
    # $self->{temp_top_dir} will be the conceptual equivalent of the top-level
    # directory in the Perl 5 distribution.  Hence, underneath it we'll create
    # the equivalents of the F<dist/Distro-A>, F<dist/Distro-B>, etc., and
    # F<t/> directories.
    $self->{currdir} = cwd();
    $self->{temp_top_dir} = tempdir( CLEANUP => 1 );
    my %results = ();

    chdir $self->{temp_top_dir} or croak "Unable to change to tempdir $self->{temp_top_dir}";

    # Create a 't/' directory underneath the temp_top_dir
    my $temp_t_dir = File::Spec->catdir($self->{temp_top_dir}, 't');
    mkdir $temp_t_dir or croak "Unable to mkdir $temp_t_dir";
    $self->{temp_t_dir} = $temp_t_dir;

    # Several of the F<dist/> distros need F<t/test.pl> for their tests; copy
    # it into position once only.
    my $testpl = File::Spec->catfile($self->{perl_workdir}, 't', 'test.pl');
    croak "Could not locate $testpl" unless -f $testpl;
    copy $testpl => $self->{temp_t_dir} or croak "Unable to copy $testpl";

    # Create a 'dist/' directory underneath the temp_top_dir
    my $temp_dist_dir = File::Spec->catdir($self->{temp_top_dir}, 'dist');
    mkdir $temp_dist_dir or croak "Unable to mkdir $temp_dist_dir";
    $self->{temp_dist_dir} = $temp_dist_dir;

    for my $d (@{$self->{distros_for_testing}}) {
        my $this_result = $self->test_one_distro_against_older_perls($d);
        $results{$d} = $this_result;
    }

    chdir $self->{currdir}
        or croak "Unable to change back to starting directory $self->{currdir}";

    $self->{results} = { %results };
    return $self;

    # temp_top_dir should go out of scope here (though its path and those of
    # temp_t_dir and temp_dist_dir will still be in the object)
}

=head2 C<print_distro_summaries()>

=over 4

=item * Purpose

Print on F<STDOUT>:

=over 4

=item 1

A list of the F<results_dir/Some-Distro.summary.txt> files created for each
tested distro (each file containing a summary of the results for that distro
against each designated F<perl> executable. Example:

    Summaries
    ---------
    Attribute-Handlers      /tmp/29LsgNfjVb/Attribute-Handlers.summary.txt
    Carp                    /tmp/29LsgNfjVb/Carp.summary.txt
    Data-Dumper             /tmp/29LsgNfjVb/Data-Dumper.summary.txt
    ...
    threads                 /tmp/29LsgNfjVb/threads.summary.txt
    threads-shared          /tmp/29LsgNfjVb/threads-shared.summary.txt

=item 2

A concatenation of all those files.

=back

=item * Arguments

To simply list the summary files:

    $self->print_distro_summaries();

To list the summary files and concatenate their content:

    $self->print_distro_summaries( {cat_summaries => 1} );

=item * Return Value

Returns true value upon success.

=item * Comment

You'll probably want to redirect or F<tee> F<STDOUT> to a file for further
study.

=back

=cut

sub print_distro_summaries {
    my ($self, $args) = @_;
    if (! defined $args) { $args = {}; }
    else {
        croak "Argument to print_distro_summaries must be hashref"
            unless ref($args) eq 'HASH';
    }

    say "\nSummaries";
    say '-' x 9;
    for my $d (sort keys %{$self->{results}}) {
        $self->print_distro_summary($d);
    }

    if ($args->{cat_summaries}) {
        say "\nOverall (at $self->{describe}):";
        for my $d (sort keys %{$self->{results}}) {
            say "\n$d";
            dd $self->{results}->{$d};
        }
    }
    return 1;
}

=head2 C<tally_results()>

=over 4

=item * Purpose

Provide an overall summary of PASSes and FAILs in the distro/perl-version matrix.

=item * Arguments

None, all data needed is stored within object.

=item * Return Value

Array ref with 4 elements: overall attempts, overall passes, overall failures,
overall skipped.

=item * Comment

An entry in the distro/perl-version matrix is skipped if there is a failure
running F<Makefile.PL>, which causes the C<configure>, C<make> and C<test>
values to be all undefined.

=back

=cut

sub tally_results {
    my $self = shift;
    my $overall_attempts = 0;
    my $overall_successes = 0;
    my $overall_skipped = 0;
    for my $d (keys %{$self->{results}}) {
        for my $p (keys %{$self->{results}->{$d}}) {
            $overall_attempts++;
            my %thisrun = %{$self->{results}->{$d}->{$p}};
            if (
                ! defined $thisrun{configure} and
                ! defined $thisrun{make} and
                ! defined $thisrun{test}
            ) {
                $overall_skipped++;
            }
            elsif (
                $thisrun{configure} and
                $thisrun{make} and
                $thisrun{test}
            ) {
                $overall_successes++;
            }
        }
    }
    my $overall_failures = $overall_attempts - ($overall_successes + $overall_skipped);
    return [$overall_attempts, $overall_successes, $overall_failures, $overall_skipped];
}

=head1 INTERNAL METHODS

The following methods use the Perl5::Dist::Backcompat object but are called
from within the public methods.  Other than this library's author, you
shouldn't need to explicitly call these methods (or the internal subroutines
documented below) in a production program.  The documentation here is mainly
for people working on this distribution itself.

=cut

=head2 C<test_one_distro_against_older_perls()>

=over 4

=item * Purpose

Test one selected F<dist/> distribution against the list of older F<perl>s.

=item * Arguments

Single string holding the name of the distro in C<Some-Distro> format.

=item * Return Value

Hash reference with one element for each F<perl> executable selected:

    {
    "5.006002" => { a => "perl5.6.2",  configure => 1, make => 0, test => undef },
    "5.008009" => { a => "perl5.8.9",  configure => 1, make => 0, test => undef },
    "5.010001" => { a => "perl5.10.1", configure => 1, make => 0, test => undef },
    ...
    "5.034000" => { a => "perl5.34.0", configure => 1, make => 1, test => 1 },
    }

The value of each element is a hashref with elements keyed as follows:

=over 4

=item * C<a>

Perl version in the spelling used in the default value for C<path_to_perls>.

=item * C<configure>

The result of calling F<perl Makefile.PL>: C<1> for success; C<0> for failure;
C<undef> for not attempted.

=item * C<make>

The result of calling F<make>: same meaning as above.

=item * C<make test>

The result of calling F<make test>: same meaning as above.

=back

=back

=cut

sub test_one_distro_against_older_perls {
    my ($self, $d) = @_;
    say "Testing $d ..." if $self->{verbose};
    my $this_result = {};

    my $source_dir = File::Spec->catdir($self->{perl_workdir}, 'dist', $d);
    my $this_tempdir  = File::Spec->catdir($self->{temp_dist_dir}, $d);
    mkdir $this_tempdir or croak "Unable to mkdir $this_tempdir";
    dircopy($source_dir, $this_tempdir)
        or croak "Unable to copy $source_dir to $this_tempdir";

    chdir $this_tempdir or croak "Unable to chdir to tempdir for dist/$d";
    say "  Now in $this_tempdir ..." if $self->{verbose};

    THIS_PERL: for my $p (@{$self->{perls}}) {
        $this_result->{$p->{canon}}{a} = $p->{version};
        # Skip this perl version if (a) distro has a specified
        # 'minimum_perl_version' and (b) that minimum version is greater than
        # the current perl we're running.
        if (
            (
                $self->{distro_metadata}->{$d}{minimum_perl_version}
                    and
                $self->{distro_metadata}->{$d}{minimum_perl_version} >= $p->{canon}
            )
#                Since we're currently using threaded perls for this
#                process, the following condition is not pertinent.  But we'll
#                retain it here commented out for possible future use.
#
#                or
#            (
#                $self->{distro_metadata}->{$d}{needs_threaded_perl}
#            )
        ) {
            $this_result->{$p->{canon}}{configure} = undef;
            $this_result->{$p->{canon}}{make} = undef;
            $this_result->{$p->{canon}}{test} = undef;
            next THIS_PERL;
        }
        my $f = join '.' => ($d, $p->{version}, 'txt');
        my $debugfile = File::Spec->catfile($self->{results_dir}, $f);
        if ($self->{verbose}) {
            say "Testing $d with $p->{canon} ($p->{version}); see $debugfile";
        }

        # Here, assuming the distro ($d) is classified as 'cpan', we should
        # extract the Makefile.PL from the tar and swap that into the
        # following 'perl Makefile.PL' command.

        my ($rv, $cmd);
        my $this_makefile_pl = 'Makefile.PL';
        if ($self->{makefile_pl_status}->{$d} eq 'cpan') {
            # We currently expect this branch to prevail 40 times
            if (-f $this_makefile_pl) {
                move $this_makefile_pl => "$this_makefile_pl.noncpan";
            }
            my $source = File::Spec->catfile($self->{distro_metadata}->{$d}->{distvname},'Makefile.PL');
            my $destination = File::Spec->catfile('.', $this_makefile_pl);
            my $extract = $self->{distro_metadata}->{$d}->{tar}->extract_file(
                $source,
                $destination,
            );
            croak "Unable to extract Makefile.PL from tarball" unless $extract;
            croak "Unable to locate extracted Makefile.PL" unless -f $destination;
        }
        croak "Could not locate $this_makefile_pl for configuring" unless -f $this_makefile_pl;

        if ($self->{distro_metadata}->{$d}->{needs_ppport_h}) {
            my $source = File::Spec->catfile($self->{distro_metadata}->{$d}->{distvname},'ppport.h');
            my $destination = File::Spec->catfile('.', 'ppport.h');
            my $extract = $self->{distro_metadata}->{$d}->{tar}->extract_file(
                $source,
                $destination,
            );
            croak "Unable to extract ppport.h from tarball" unless $extract;
            croak "Unable to locate extracted ppport.h" unless -f $destination;
        }

        if ($self->{distro_metadata}->{$d}->{needs_threads_h}) {
            my $source = File::Spec->catfile($self->{distro_metadata}->{$d}->{distvname},'threads.h');
            my $destination = File::Spec->catfile('.', 'threads.h');
            my $extract = $self->{distro_metadata}->{$d}->{tar}->extract_file(
                $source,
                $destination,
            );
            croak "Unable to extract threads.h from tarball" unless $extract;
            croak "Unable to locate extracted threads.h" unless -f $destination;
        }

        if ($self->{distro_metadata}->{$d}->{needs_shared_h}) {
            my $source = File::Spec->catfile($self->{distro_metadata}->{$d}->{distvname},'shared.h');
            my $destination = File::Spec->catfile('.', 'shared.h');
            my $extract = $self->{distro_metadata}->{$d}->{tar}->extract_file(
                $source,
                $destination,
            );
            croak "Unable to extract shared.h from tarball" unless $extract;
            croak "Unable to locate extracted shared.h" unless -f $destination;
        }

        $cmd = qq| $p->{path} $this_makefile_pl > $debugfile 2>&1 |;
        $rv = system($cmd) and say STDERR "  FAIL: $d: $p->{canon}: Makefile.PL";
        $this_result->{$p->{canon}}{configure} = $rv ? 0 : 1; undef $rv;
        unless ($this_result->{$p->{canon}}{configure}) {
            undef $this_result->{$p->{canon}}{make};
            undef $this_result->{$p->{canon}}{test};
            next THIS_PERL;
        }

        $rv = system(qq| make >> $debugfile 2>&1 |)
            and say STDERR "  FAIL: $d: $p->{canon}: make";
        $this_result->{$p->{canon}}{make} = $rv ? 0 : 1; undef $rv;
        unless ($this_result->{$p->{canon}}{make}) {
            undef $this_result->{$p->{canon}}{test};
            next THIS_PERL;
        }

        $rv = system(qq| make test >> $debugfile 2>&1 |)
            and say STDERR "  FAIL: $d: $p->{canon}: make test";
        $this_result->{$p->{canon}}{test} = $rv ? 0 : 1; undef $rv;

        system(qq| make clean 2>&1 1>/dev/null |)
            and carp "Unable to 'make clean' for $d";
    }
    chdir $self->{temp_top_dir}
        or croak "Unable to change to tempdir $self->{temp_top_dir}";
    return $this_result;
}

=head2 C<print_distro_summary()>

=over 4

=item * Purpose

Create a file holding a summary of the results for running one distro against
each of the selected F<perl>s.

=item * Arguments

        $self->print_distro_summary('Some-Distro');

String holding name of distro.

=item * Return Value

Returns true value on success.

=item * Comment

File created will be named like F</path/to/results_dir/Some-Distro.summary.txt>.

File's content will look like this:

    Attribute-Handlers                                   v5.35.7-48-g34e3587
    {
      "5.006002" => { a => "perl5.6.2",  configure => 1, make => 0, test => undef },
      "5.008009" => { a => "perl5.8.9",  configure => 1, make => 0, test => undef },
      "5.010001" => { a => "perl5.10.1", configure => 1, make => 0, test => undef },
      ...
      "5.034000" => { a => "perl5.34.0", configure => 1, make => 1, test => 1 },
    }

=back

=cut

sub print_distro_summary {
    my ($self, $d) = @_;
    my $output = File::Spec->catfile($self->{results_dir}, "$d.summary.txt");
    open my $OUT, '>', $output or die "Unable to open $output for writing: $!";
    say $OUT sprintf "%-52s%20s" => ($d, $self->{describe});
    my $oldfh = select($OUT);
    dd $self->{results}->{$d};
    close $OUT or die "Unable to close $output after writing: $!";
    select $oldfh;
    say sprintf "%-24s%-48s" => ($d, $output)
        if $self->{verbose};
}

    # Check tarballs we have on disk to see whether they contain a
    # Makefile.PL.
    # $ pwd
    # /home/jkeenan/learn/perl/p5p/dist-backcompat/tarballs/authors/id
    # $ ls . | head -n 5
    # Attribute-Handlers-0.99.tar.gz
    # autouse-1.11.tar.gz
    # base-2.23.tar.gz
    # Carp-1.50.tar.gz
    # constant-1.33.tar.gz

sub identify_cpan_tarballs_with_makefile_pl {
    my $self = shift;
    my $id_dir = File::Spec->catdir($self->{tarball_dir}, 'authors', 'id');
    opendir my $DIR, $id_dir
        or croak "Unable to open directory $id_dir for reading";
    my @available = map { File::Spec->catfile('authors', 'id', $_) }
        grep { m/\.tar\.gz$/ } readdir $DIR;
    closedir $DIR or croak "Unable to close directory $id_dir after reading";
    my %this = ();
    for my $tb (@available) {
        my $d = CPAN::DistnameInfo->new($tb);
        my $dist = $d->dist;
        my $distvname = $d->distvname;
        $this{$dist}{tarball} = File::Spec->catfile($self->{tarball_dir}, $tb);
        $this{$dist}{distvname} = $distvname;
    }
    return \%this;
}

=head1 INTERNAL SUBROUTINES

=head2 C<sanity_check()>

=over 4

=item * Purpose

Assure us that our environment is adequate to the task.

=item * Arguments

    sanity_check(\%distmodules, $verbose);

List of two scalars: (i) reference to the hash which is storing list of
F<dist/> distros; (ii) verbosity selection.

=item * Return Value

Implicitly returns true on success, but does not otherwise return any
meaningful value.

=item * Comment

If verbosity is selected, displays the current git commit and other useful
information on F<STDOUT>.

=back

=cut

sub _sanity_check {
    my ($distmodules, $describe, $verbose) = @_;
    for my $m (keys %{$distmodules}) {
        if ($distmodules->{$m}{UPSTREAM} ne 'blead') {
            warn "Distro $m has UPSTREAM other than 'blead'";
        }
        if ($distmodules->{$m}{MAINTAINER} ne 'P5P') {
            warn "Distro $m has MAINTAINER other than 'P5P'";
        }
    }

    if ($verbose) {
        say "p5-dist-backcompat";
        my $ldescribe = length $describe;
        my $message = q|Found | .
            (scalar keys %{$distmodules}) .
            q| 'dist/' entries in %Maintainers::Modules|;
        my $lmessage = length $message;
        my $ldiff = $lmessage - $ldescribe;
        say sprintf "%-${ldiff}s%s" => ('Results at commit:', $describe);
        say "\n$message";
    }
    return 1;
}

=head2 C<read_manifest()>

=over 4

=item * Purpose

Get a sorted list of all files in F<MANIFEST> (without their descriptions).

=item * Arguments

    read_manifest('/path/to/MANIFEST');

One scalar: the path to F<MANIFEST> in a git checkout of the Perl 5 core distribution.

=item * Return Value

List (sorted) of all files in F<MANIFEST>.

=item * Comment

Depends on C<sort_manifest()> from F<Porting/manifest_lib.pl>.

(This is so elementary and useful that it should probably be in F<Porting/manifest_lib.pl>!)

=back

=cut

sub read_manifest {
    my $manifest = shift;
    open(my $IN, '<', $manifest) or die("Can't read '$manifest': $!");
    my @manifest = <$IN>;
    close($IN) or die($!);
    chomp(@manifest);

    my %seen= ( '' => 1 ); # filter out blank lines
    return grep { !$seen{$_}++ } sort_manifest(@manifest);
}

1;

