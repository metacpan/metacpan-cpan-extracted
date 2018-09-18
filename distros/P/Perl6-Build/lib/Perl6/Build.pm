package Perl6::Build;
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
use Pod::Simple::SimpleTree;

our $VERSION = '0.002';

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
        "h|help"      => \my $help,
        "jvm"         => \my $jvm,
        "w|workdir=s" => \$self->{workdir},
    or exit 1;

    if (@configure_option and $jvm) {
        die "--jvm option may conflict with configure options after --; "
          . "please specify either.\n";
    }

    if ($help) {
        $self->show_help;
        return 1;
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
    my $root = Pod::Simple::SimpleTree->new->parse_file($0)->root;
    my ($name, $attr, @node) = @$root;
    my $synopsis;
    while (my $node = shift @node) {
        my ($name, $attr, $value) = @$node;
        if ($value eq 'SYNOPSIS') {
            my $next = shift @node;
            $synopsis = $next->[2];
            last;
        }
    }
    print "\n", $synopsis, "\n\n";
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

1;

__END__

=encoding utf-8

=head1 NAME

Perl6::Build - build rakudo Perl6

=head1 SYNOPSIS

  Usage:
   $ perl6-build [options] VERSION   PREFIX [-- [configure options]]
   $ perl6-build [options] COMMITISH PREFIX [-- [configure options]]

  Options:
   -h, --help      show this help
   -l, --list      list available versions (latest 20 versions)
   -L, --list-all  list all available versions
   -w, --workdir   set working directory, default: ~/.perl6-build
       --jvm       build perl6 with jvm backend

  Example:
   # List available versions
   $ perl6-build -l

   # Build and install rakudo-star-2018.04 to ~/perl6
   $ perl6-build rakudo-star-2018.04 ~/perl6

   # Build and install rakudo from git repository (2018.06 tag) to ~/perl6
   $ perl6-build 2018.06 ~/perl6

   # Build and install rakudo from git repository (HEAD) to ~/perl6-{describe}
   # where {describe} will be replaced by `git describe` such as `2018.06-259-g72c8cf68c`
   $ perl6-build HEAD ~/perl6-'{describe}'

   # Build and install rakudo from git repository (HEAD) with jvm backend
   $ perl6-build --jvm 2018.06 ~/2018.06-jvm

   # Build and install rakudo from git repository (2018.06 tag) with custom configure options
   $ perl6-build 2018.06 ~/2018.06-custom -- --backends moar --with-nqp /path/to/bin/nqp

=head1 INSTALLATION

There are 3 ways:

=over 4

=item CPAN

  $ cpm install -g Perl6::Build

=item Self-contained version

  $ wget https://raw.githubusercontent.com/skaji/perl6-build/master/bin/perl6-build
  $ chmod +x perl6-build
  $ ./perl6-build --help

=item As a p6env plugin

  $ git clone https://github.com/skaji/perl6-build ~/.p6env/plugins/perl6-build
  $ p6env install -l

See L<https://github.com/skaji/p6env>.

=back

=head1 DESCRIPTION

Perl6::Build builds rakudo Perl6.

=head1 AUTHOR

Shoichi Kaji <skaji@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright 2018 Shoichi Kaji <skaji@cpan.org>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
