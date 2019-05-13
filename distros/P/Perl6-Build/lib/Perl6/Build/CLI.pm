package Perl6::Build::CLI;
use strict;
use warnings;

use 5.10.1; # rakudo's Configure.pl requires 5.10.1. We follow that.
use Cwd ();
use File::Path ();
use File::Spec;
use File::Temp ();
use Getopt::Long ();
use Perl6::Build::Builder::RakudoStar;
use Perl6::Build::Builder::Source;
use Perl6::Build::Builder;
use Perl6::Build::Helper;
use Perl6::Build;
use Pod::Usage ();

sub new {
    my ($class, %args) = @_;
    my $workdir = $args{workdir} || File::Spec->catdir($ENV{HOME}, ".perl6-build");
    my $id = time . ".$$";
    bless { workdir => $workdir, id => $id }, $class;
}

sub cache_dir {
    my $self = shift;
    File::Spec->catdir($self->{workdir}, "cache");
}

sub git_reference_dir {
    my $self = shift;
    File::Spec->catdir($self->{workdir}, "git_reference");
}

sub build_base_dir {
    my $self = shift;
    File::Spec->catdir($self->{workdir}, "build");
}

sub build_dir {
    my $self = shift;
    File::Spec->catdir($self->build_base_dir, $self->{id});
}

sub log_file {
    my $self = shift;
    File::Spec->catfile($self->build_dir, "build.log");
}

sub run {
    my ($self, @argv) = @_;

    my @configure_option;
    my ($index) = grep { $argv[$_] eq '--' } 0..$#argv;
    if (defined $index) {
        (undef, @configure_option) = splice @argv, $index, @argv - $index;
    }

    local @ARGV = @argv;
    Getopt::Long::Configure(qw(default no_auto_abbrev no_ignore_case));
    Getopt::Long::GetOptions
        "l|list"      => \my $list,
        "L|list-all"  => \my $list_all,
        "h|help"      => \my $show_help,
        "version"     => \my $show_version,
        "jvm"         => \my $jvm,
        "w|workdir=s" => \$self->{workdir},
        'ensure-latest-version=s' => \my $ensure_latest_version,
    or exit 1;

    if (@configure_option and $jvm) {
        die "--jvm option may conflict with configure options after --; "
          . "please specify either.\n";
    }

    if ($show_help) {
        $self->show_help;
        return 1;
    }
    if ($show_version) {
        say Perl6::Build->VERSION;
        return 0;
    }
    if (my $base_dir = $ensure_latest_version) {
        my $ok = $self->ensure_latest_version($base_dir);
        return $ok ? 0 : 1;
    }

    if ($list || $list_all) {
        my $msg = $list_all ? "" : " (latest 20 versions)";
        print "Available versions$msg:\n";
        my @star = Perl6::Build::Builder::RakudoStar->available;
        my @source = Perl6::Build::Builder::Source->available;
        if ($list_all) {
            print " $_\n" for @star, @source;
        } else {
            print " $_\n" for @star[0..9], @source[0..9];
        }
        return 0;
    }

    my ($version, $prefix) = @ARGV;
    die "Invalid arguments; try `perl6-build --help` for help.\n" if !$prefix;
    if (!File::Spec->file_name_is_absolute($prefix)) {
        $prefix = File::Spec->canonpath(File::Spec->catdir(Cwd::cwd(), $prefix));
    }

    File::Path::mkpath($_) for grep !-d, $self->cache_dir, $self->build_dir, $self->git_reference_dir;

    if ($version =~ /^rakudo-star-/) {
        my $star = Perl6::Build::Builder::RakudoStar->new(
            backend => $jvm ? 'jvm' : 'moar',
            version => $version,
            cache_dir => $self->cache_dir,
            build_dir => $self->build_dir,
            log_file  => $self->log_file,
        );
        $star->fetch;
        $star->build($prefix, @configure_option);
    } else {
        my $source = Perl6::Build::Builder::Source->new(
            backend => $jvm ? 'jvm' : 'moar',
            commitish => $version,
            build_dir => $self->build_dir,
            git_reference_dir => $self->git_reference_dir,
            log_file  => $self->log_file,
        );
        $source->fetch;
        my $describe = $source->describe;
        $prefix =~ s/\{describe\}/$describe/g;
        $source->build($prefix, @configure_option);
    }
    $self->cleanup_build_base_dir;
    return 0;
}

sub show_help {
    my $self = shift;
    open my $fh, '>', \my $out;
    Pod::Usage::pod2usage
        exitval => 'noexit',
        input => $0,
        output => $fh,
        sections => 'SYNOPSIS|OPTIONS|EXAMPLES',
        verbose => 99,
    ;
    $out =~ s/^[ ]{4,6}/  /mg;
    $out =~ s/\n$//;
    print $out;
}

sub cleanup_build_base_dir {
    my $self = shift;
    my $base = $self->build_base_dir;
    opendir my ($dh), $base or die "$base: $!";
    my @dir =
        reverse
        sort
        grep { -d }
        map { File::Spec->catdir($base, $_) }
        grep { !/^\.{1,2}$/ }
        readdir $dh;
    return if @dir <= 10;
    warn "Expiring @{[ @dir - 10 ]} build directories\n";
    File::Path::rmtree($_) for @dir[10..$#dir];
}

sub ensure_latest_version {
    my ($self, $base_dir) = @_;

    my $current = Perl6::Build->VERSION;
    my $latest = eval { Perl6::Build::Helper->LATEST_VERSION };
    return if $@;
    return 1 if $current >= $latest;

    warn <<"___";

You are currently using perl6-build version $current.
The new version $latest is available; you might want to update it:

  \$ cd $base_dir
  \$ git pull origin master

___
    return;
}

1;
