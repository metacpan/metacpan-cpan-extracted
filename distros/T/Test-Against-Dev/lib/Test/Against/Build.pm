package Test::Against::Build;
use strict;
use 5.14.0;
our $VERSION = '0.13';
use Carp;
use Cwd;
use File::Basename;
use File::Path ( qw| make_path | );
use File::Spec;
use File::Temp ( qw| tempdir tempfile | );
use Archive::Tar;
use CPAN::cpanminus::reporter::RetainReports;
use Data::Dump ( qw| dd pp | );
use JSON;
use Path::Tiny;
use Text::CSV_XS;

=head1 NAME

Test::Against::Build - Test CPAN modules against specific Perl build

=head1 SYNOPSIS

    my $self = Test::Against::Build->new( {
        build_tree      => '/path/to/top/of/build_tree',
        results_tree    => '/path/to/top/of/results_tree',
        verbose => 1,
    } );

    my $gzipped_build_log = $self->run_cpanm( {
        module_file => '/path/to/cpan-river-file.txt',
        title       => 'cpan-river-1000',
        verbose     => 1,
    } );

    $ranalysis_dir = $self->analyze_cpanm_build_logs( { verbose => 1 } );

    $fcdvfile = $self->analyze_json_logs( { verbose => 1, sep_char => '|' } );

=head1 DESCRIPTION

=head2 Who Should Use This Library?

This library should be used by anyone who wishes to assess the impact of a
given build of the Perl 5 core distribution on the installability of libraries
found on the Comprehensive Perl Archive Network (CPAN).

=head2 The Problem to Be Addressed

=head3 The Perl Annual Development Cycle

Perl 5 undergoes an annual development cycle whose components typically include:

=over 4

=item * Individual commits to the Perl 5 F<git> repository

These commits may be identified by commit IDs (SHAs), branches or tags.

=item * Release tarballs

=over 4

=item * Monthly development release tarballs

Whose version numbers follow the convention of C<5.27.0>, C<5.27.1>,
etc., where the middle digits are always odd numbers.

=item * Release Candidate (RC) tarballs

Whose version numbers follow the convention of C<5.28.0-RC1>, C<5.28.0-RC2>,
C<5.28.1-RC1>.

=item * Production release tarballs

Whose version numbers follow the convention of C<5.28.0> (new release);
C<5.28.1>, C<5.28.2>, etc. (maintenance releases).

=back

=back

=head3 Measuring the Impact of Changes in Core on CPAN Modules

You can configure, build and install a F<perl> executable starting from any of
the above components and you can install CPAN modules against any such F<perl>
executable.  Given a list of specific CPAN modules, you may want to be able to
compare the results you get from trying to install that list against different
F<perl> executables built from different commits or releases at various points
in the development cycle.  To make such comparisons, you will need to have
data generated and recorded in a consistent format.  This library provides
methods for that data generation and recording.

=head2 High-Level View of What the Module Does

=head3 Tree Structure

For any particular attempt to build a F<perl> executable from any of the
starting points described above, F<Test::Against::Build> guarantees that there
exists on disk B<two> directory trees:

=over 4

=item 1 The build tree

The build tree is a directory beneath which F<perl>, other executables and
libraries will be installed (or already are installed).  As such, the
structure of this tree will look like this:

    top_of_build_tree/bin/
                      bin/perl
                      bin/perldoc
                      bin/cpan
                      bin/cpanm
    ...
    top_of_build_tree/lib/
                      lib/perl5/
                      lib/perl5/5.29.0/
                      lib/perl5/site_perl/
    ...
    top_of_build_tree/.cpanm/
    top_of_build_tree/.cpanreporter/

F<Test::Against::Build> presumes that you will be using Miyagawa's F<cpanm>
utility to install modules from CPAN.  The F<.cpanm> and F<.cpanreporter>
directories will be the locations where data concerning attempts to install CPAN
modules are recorded.

=item 2 The results tree

The results tree is a directory beneath which data parsed from the F<.cpanm>
directory is formatted and stored.  Its format looks like this:

    top_of_results_tree/analysis/
                        buildlogs/
                        storage/

=back

The names of the top-level directories are arbitrary; the names of their
subdirectories are not.  The top-level directories may be located anywhere
writable on disk and need not share a common parent directory.  It is the
F<Test::Against::Build> object which will establish a relationship between the
two trees.

=head3 Installation of F<perl> and F<cpanm>

F<Test::Against::Build> does B<not> provide you with methods to build or
install these executables.  It presumes that you know how to build F<perl>
from source, whether that be from a specific F<git> checkout or from a release
tarball.  It further presumes that you know how to install F<cpanm> against
that F<perl>.  It does provide a method to identify the directory you should
use as the value of the C<-Dprefix=> option to F<Configure>.  It also provides
methods to determine that you have installed F<perl> and F<cpanm> in the
expected locations.  Once that determination has been made, it provides you
with methods to run F<cpanm> against a specific list of modules, parse the
results into files in JSON format and then summarize those results in a
delimiter-separated-values file (such as a pipe-separated-values (C<.psv>)
file).

Why, you may ask, does F<Test::Against::Build> B<not> provide methods to
install these executables?  There are a number of reasons why not.

=over 4

=item * F<perl> and F<cpanm> already installed

You may already have on disk one or more F<perl>s built from specific commits
or release tarballs and have no need to re-install them.

=item * Starting from F<git> commit versus starting from a tarball

You can build F<perl> either way, but there's no need to have code in this
package to express both ways.

=item * Many ways to configure F<perl>

F<perl> configuration is a matter of taste.  The only thing which this package
needs to provide you is a value for the C<-Dprefix=> option.  It should go
without saying that if want to measure the impact on CPAN modules of two
different builds of F<perl>, you should call F<Configure> with exactly the
same set of options for each.

=back

The examples below will provide guidance.

=head1 METHODS

=head2 C<new()>

=over 4

=item * Purpose

Test::Against::Build constructor.  Guarantees that the build tree and results
tree have the expected directory structure.  Determines whether F<perl> and
F<cpanm> have already been installed or not.

=item * Arguments

    my $self = Test::Against::Build->new( {
        build_tree      => '/path/to/top/of/build_tree',
        results_tree    => '/path/to/top/of/results_tree',
        verbose => 1,
    } );

=item * Return Value

Test::Against::Build object.

=item * Comment

=back

=cut

sub new {
    my ($class, $args) = @_;

    croak "Argument to constructor must be hashref"
        unless ref($args) eq 'HASH';
    my $verbose = delete $args->{verbose} || '';
    for my $d (qw| build_tree results_tree |) {
        croak "Hash ref must contain '$d' element"
            unless $args->{$d};
        unless (-d $args->{$d}) {
            croak "Could not locate directory '$args->{$d}' for '$d'";
        }
        else {
            say "Located directory '$args->{$d}' for '$d'" if $verbose;
        }
    }
    # Crude test of difference of directories;
    # need to take into account, e.g., symlinks, relative paths
    croak "Arguments for 'build_tree' and 'results_tree' must be different directories"
        unless $args->{build_tree} ne $args->{results_tree};

    my $data;
    for my $k (keys %{$args}) {
        $data->{$k} = $args->{$k};
    }

    for my $subdir ( 'bin', 'lib' ) {
        my $dir = File::Spec->catdir($data->{build_tree}, $subdir);
        my $key = "${subdir}_dir";
        $data->{$key} = (-d $dir) ? $dir : undef;
    }
    for my $subdir ( '.cpanm', '.cpanreporter' ) {
        my $dir = File::Spec->catdir($data->{build_tree}, $subdir);
        my $key = "${subdir}_dir";
        $key =~ s{^\.(.*)}{$1};
        $data->{$key} = (-d $dir) ? $dir : undef;
    }
	$data->{PERL_CPANM_HOME} = $data->{cpanm_dir};
	$data->{PERL_CPAN_REPORTER_DIR} = $data->{cpanreporter_dir};

    for my $subdir ( qw| analysis buildlogs storage | ) {
        my $dir = File::Spec->catdir($data->{results_tree}, $subdir);
        unless (-d $dir) {
            my @created = make_path($dir, { mode => 0711 })
                or croak "Unable to make_path '$dir'";
        }
        my $key = "${subdir}_dir";
        $data->{$key} = $dir;
    }

    my $expected_perl = File::Spec->catfile($data->{bin_dir}, 'perl');
    $data->{this_perl} = (-e $expected_perl) ? $expected_perl : '';

    my $expected_cpanm = File::Spec->catfile($data->{bin_dir}, 'cpanm');
    $data->{this_cpanm} = (-e $expected_cpanm) ? $expected_cpanm : '';

    return bless $data, $class;
}

=head2 Accessors

The following accessors return the absolute path to the directories in their names:

=over 4

=item * C<get_build_tree()>

=item * C<get_bin_dir()>

=item * C<get_lib_dir()>

=item * C<get_cpanm_dir()>

=item * C<get_cpanreporter_dir()>

=item * C<get_results_tree()>

=item * C<get_analysis_dir()>

=item * C<get_buildlogs_dir()>

=item * C<get_storage_dir()>

=back

=cut

sub get_build_tree { my $self = shift; return $self->{build_tree}; }
sub get_bin_dir { my $self = shift; return $self->{bin_dir}; }
sub get_lib_dir { my $self = shift; return $self->{lib_dir}; }
sub get_cpanm_dir { my $self = shift; return $self->{cpanm_dir}; }
sub get_cpanreporter_dir { my $self = shift; return $self->{cpanreporter_dir}; }
sub get_results_tree { my $self = shift; return $self->{results_tree}; }
sub get_analysis_dir { my $self = shift; return $self->{analysis_dir}; }
sub get_buildlogs_dir { my $self = shift; return $self->{buildlogs_dir}; }
sub get_storage_dir { my $self = shift; return $self->{storage_dir}; }

sub get_this_perl {
    my $self = shift;
    if (! $self->{this_perl}) {
        croak "perl has not yet been installed; configure, build and install it";
    }
    else {
        return $self->{this_perl};
    }
}

=head2 C<is_perl_built()>

=over 4

=item * Purpose

Determines whether a F<perl> executable has actually been installed in the
directory returned by C<get_bin_dir()>.

=item * Arguments

None.

=item * Return Value

C<1> for yes; C<0> for no.

=back

=cut

sub is_perl_built {
    my $self = shift;
    if (! $self->{this_perl}) {
        my $expected_perl = File::Spec->catfile($self->get_bin_dir, 'perl');
        $self->{this_perl} = (-e $expected_perl) ? $expected_perl : '';
    }
    return ($self->{this_perl}) ? 1 : 0;
}

sub get_this_cpanm {
    my $self = shift;
    if (! $self->{this_cpanm}) {
        croak "cpanm has not yet been installed; configure, build and install it";
    }
    else {
        return $self->{this_cpanm};
    }
}


=head2 C<is_cpanm_built()>

=over 4

=item * Purpose

Determines whether a F<cpanm> executable has actually been installed in the
directory returned by C<get_bin_dir()>.

=item * Arguments

=item * Return Value

C<1> for yes; C<0> for no.

=back

=cut

sub is_cpanm_built {
    my $self = shift;
    if (! $self->{this_cpanm}) {
        my $expected_cpanm = File::Spec->catfile($self->get_bin_dir, 'cpanm');
        $self->{this_cpanm} = (-e $expected_cpanm) ? $expected_cpanm : '';
    }
    return ($self->{this_cpanm}) ? 1 : 0;
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

    # At this point, we must have real .cpanm and .cpanreporter directories

    for my $subdir ( '.cpanm', '.cpanreporter' ) {
        my $dir = File::Spec->catdir($self->get_build_tree(), $subdir);
        unless (-d $dir) {
            make_path($dir, { mode => 0711 })
                or croak "Unable to make_path $dir";
        }
        my $key = "${subdir}_dir";
        $key =~ s{^\.(.*)}{$1};
        $self->{$key} = $dir;
    }
	$self->{PERL_CPANM_HOME} = $self->{cpanm_dir};
	$self->{PERL_CPAN_REPORTER_DIR} = $self->{cpanreporter_dir};

    say "cpanm_dir: ", $self->get_cpanm_dir() if $verbose;
    local $ENV{PERL_CPANM_HOME} = $self->{PERL_CPANM_HOME};
    local $ENV{PERL_CPAN_REPORTER_DIR} = $self->{PERL_CPAN_REPORTER_DIR};

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
    eval {
        local $@;
        my $rv = system(@cmd);
        say "<$@>" if $@;
        if ($verbose) {
            say $self->get_this_cpanm(), " exited with ", $rv >> 8;
        }
    };
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
    $self->{timestamp} = (File::Spec->splitdir(dirname($real_log)))[-1] || '';

    my $gzipped_build_log_filename = join('.' => (
        $self->{title},
        #(File::Spec->splitdir(dirname($real_log)))[-1],
        $self->{timestamp},
        'build',
        'log',
        'gz'
    ) );
    my $gzlog = File::Spec->catfile(
        $self->get_buildlogs_dir,
        $gzipped_build_log_filename,
    );
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
    my ($fh, $working_log) = tempfile('acbl_XXXXX', UNLINK => 1);
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
    #$reporter->set_report_dir($ranalysis_dir);
    my $ranalysis_dir = $self->get_analysis_dir;
    $reporter->set_report_dir($ranalysis_dir);
    $reporter->run;
    say "See results in $ranalysis_dir" if $verbose;

    return $ranalysis_dir;
}


=head2 C<analyze_json_logs()>

=over 4

=item * Purpose

Tabulate the grades (C<PASS>, C<FAIL>, etc.) assigned to each CPAN
distribution analyzed in C<analyze_cpanm_build_logs()> and write to a
separator-delimited file.

=item * Arguments

    $fcdvfile = $self->analyze_json_logs( { verbose => 1, sep_char => '|' } );

Hash reference which, at the present time, can only take only two elements:

=over 4

=item * C<verbose>

Extra information provided on STDOUT.  Optional; defaults to being off;
provide a Perl-true value to turn it on.  Scope is limited to this method.

=item * C<sep_char>

The separator character used to delimit columns in the output file.  Optional;
two possibilities:

=over 4

=item * C<|>

Pipe -- in which case the file extension will be C<.psv> (default).

=item * C<,>

Comma -- in which case the file extension will be C<.csv>.

=back

=back

=item * Return Value

String holding absolute path to the separator-delimited file created by this
method.  This file will be placed in the F<storage/> directory in the results
tree as described above.

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
        $self->{timestamp},
        'log',
        'json',
        'tar',
        'gz'
    ) );
    my $foutput = File::Spec->catfile($self->get_storage_dir(), $output);
    say "Output will be: $foutput" if $verbose;

    my $vranalysis_dir = $self->get_analysis_dir;
    opendir my $DIRH, $vranalysis_dir or croak "Unable to open $vranalysis_dir for reading";
    my @json_log_files = sort map { File::Spec->catfile('analysis', $_) }
        grep { m/\.log\.json$/ } readdir $DIRH;
    closedir $DIRH or croak "Unable to close $vranalysis_dir after reading";
    dd(\@json_log_files) if $verbose;

    my $versioned_results_dir = $self->get_results_tree;
    chdir $versioned_results_dir or croak "Unable to chdir to $versioned_results_dir";
    my $cwd = cwd();
    say "Now in $cwd" if $verbose;

    my $tar = Archive::Tar->new;
    $tar->add_files(@json_log_files);
    no strict 'subs';
    $tar->write($foutput, COMPRESS_GZIP);
    use strict;
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
        $self->{timestamp},
        (($sep_char eq ',') ? 'csv' : 'psv'),
    ) );

    my $fcdvfile = File::Spec->catfile($self->get_storage_dir(), $cdvfile);
    say "Output will be: $fcdvfile" if $verbose;

    my @fields = ( qw| author distname distversion grade | );
    my $columns = [
        'dist',
        map { "$self->{title}.$_" } @fields,
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

1;

__END__


