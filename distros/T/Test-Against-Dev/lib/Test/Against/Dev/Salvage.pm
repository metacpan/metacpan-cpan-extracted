package Test::Against::Dev::Salvage;
use strict;
use 5.14.0;
our $VERSION = '0.13';
our @ISA = ('Test::Against::Dev');
use Carp;
use Cwd;
use File::Basename ( qw| dirname | );
use File::Path ( qw| make_path | );
use File::Spec;
use File::Temp ( qw| tempdir tempfile | );
use Data::Dump ( qw| dd pp | );
use Test::Against::Dev;

=head1 NAME

Test::Against::Dev::Salvage - Parse a F<cpanm> F<build.log> when C<run_cpanm()> existed prematurely.

=cut

our $PERL_VERSION_PATTERN = $Test::Against::Dev::PERL_VERSION_PATTERN;

sub new {
    my ($class, $args) = @_;
    croak "Must supply hash ref as argument"
        unless ( ( defined $args ) and ( ref($args) eq 'HASH' ) );
    my $verbose = delete $args->{verbose} || '';
    my $data = { perl_version_pattern => $PERL_VERSION_PATTERN };
    for my $el ( qw|
        path_to_cpanm_build_log
        perl_version
        title
        results_dir
    | ) {
        croak "Need '$el' element in arguments hash ref"
            unless exists $args->{$el};
    }
    my $blp = $args->{path_to_cpanm_build_log};
    croak "Could not locate cpanm build.log at '$blp'" unless (-l $blp or -f $blp);
        # Check for validity of this value down below
        #$data->{path_to_cpanm_build_log} = $blp;

    unless (defined $args->{title} and length $args->{title}) {
        croak "Must supply value for 'title' element";
    }
    $data->{title} = $args->{title};

    croak "'$args->{perl_version}' does not conform to pattern"
        unless $args->{perl_version} =~ m/$data->{perl_version_pattern}/;
    $data->{perl_version} = $args->{perl_version};

    # If $blp is a symlink, then we need to be able to -f its target.
    # Once we've found its target, or if it's not a symlink, we need to parse
    # its path in order to establish cpanm_dir:
    #     .../.cpanm/work/1234567890.12345/build.log
    # If we can't do any of this, we croak.

    my ($cpanm_dir);
    if (! -l $blp) {
        # If we've supplied the full path to the build.log file itself
        say "Value for 'path_to_cpanm_build_log' is not a symlink" if $verbose;
        my ($volume,$directories,$file) = File::Spec->splitpath($blp);
        my @directories = File::Spec->splitdir($directories);
        pop @directories if $directories[-1] eq '';
        my $partial = join('/' => @directories[-3 .. -1]);
        unless(
            ($directories[-1] =~ m/^\d+\.\d+$/) and
            ($directories[-2] eq 'work') and
            ($directories[-3] eq '.cpanm')
        ) {
            my $msg = "build.log file not found in directories ending $partial";
            croak $msg;
        }
        else {
            say "Found directories ending $partial" if $verbose;
            $cpanm_dir = File::Spec->catdir(@directories[0 .. ($#directories - 2)]);
            say "cpanm_dir: $cpanm_dir" if $verbose;
            my $possible_symlink = File::Spec->catfile($cpanm_dir, 'build.log');
            say "possible_symlink: $possible_symlink" if $verbose;
            if (-l $possible_symlink) {
                unlink $possible_symlink or croak "Unable to remove symlink $possible_symlink";
            }
            # Keep TAD::gzip_cpanm_build_log() happy
            symlink($blp, $possible_symlink) or croak "Unable to create symlink $possible_symlink";
        }
    }
    else {
        # If we've only supplied the full path to the symlink to the build.log
        say "Value for 'path_to_cpanm_build_log' is a symlink" if $verbose;
        my $real_log = readlink($blp);
        croak "Could not locate target of build.log symlink" unless (-f $real_log);
        $cpanm_dir = dirname($blp);
        say "cpanm_dir: $cpanm_dir" if $verbose;
    }

    my $vresults_dir = File::Spec->catdir($args->{results_dir}, $data->{perl_version});
    my $buildlogs_dir = File::Spec->catdir($vresults_dir, 'buildlogs');
    my $analysis_dir = File::Spec->catdir($vresults_dir, 'analysis');
    my $storage_dir = File::Spec->catdir($vresults_dir, 'storage');
    for my $dir ( $vresults_dir, $buildlogs_dir, $analysis_dir, $storage_dir ) {
        croak "Could not locate $dir" unless -d $dir;
    }

    my %load = (
        cpanm_dir           => $cpanm_dir,
        vresults_dir        => $vresults_dir,
        buildlogs_dir       => $buildlogs_dir,
        analysis_dir        => $analysis_dir,
        storage_dir         => $storage_dir,
    );
    $data->{$_} = $load{$_} for keys %load;

    return bless $data, $class;
}

1;
