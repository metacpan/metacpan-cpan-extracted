package xt::Util;

use strict;
use warnings;
use Test::Builder;
use File::Temp qw(tempdir);
use File::Path qw(mkpath);
use File::Basename qw(dirname);
use Cwd qw(getcwd);
use Config qw(%Config);
use YAML::Tiny;
use Capture::Tiny qw(capture_merged);
use base qw(Exporter);

use constant DMAKE => $^O eq 'MSWin32' && $Config{make} =~ /dmake(?:\.exe)?$/i;
use constant NMAKE => $^O eq 'MSWin32' && $Config{make} =~ /nmake(?:\.exe)?$/i;
use constant MAKE  => $Config{make} || 'make';

our @EXPORT = qw/make_meta_data unpack_tree build run_make DMAKE NMAKE/;

sub make_meta_data {
    my $fh = shift;

    local $ENV{PERL5LIB} = join $Config{path_sep},
        map { File::Spec->rel2abs($_) } @INC;

    my $cwd    = getcwd;
    my $tmpdir = tempdir CLEANUP => 1;
    chdir $tmpdir or die $!;

    unpack_tree($fh);

    my $yaml = eval {
        build($cwd);
        YAML::Tiny->read('META.yml');
    };
    chdir $cwd or die $!;

    die $@ if $@;

    return $yaml->[0];
}

sub build {
    my $distdir = shift;
    die "Makefile.PL not found" unless -f 'Makefile.PL';
    my $output = run_cmd(qq{$^X Makefile.PL});
    my $tb = Test::Builder->new;
    $tb->note($output);
    warn $output if $output =~ /warning/i;
    run_make();
}

sub run_cmd {
    my ($cmd) = @_;
    my $result = capture_merged {
        system $cmd;
    };
    die "`$cmd` failed ($result)" if $?;
    return $result;
}

sub run_make {
    run_cmd(join ' ', MAKE, @_);
}

sub _parse_data {
    my $fh = shift;
    my ($data, $path);
    while (<$fh>) {
        if (/^\@\@/) {
            ($path) = $_ =~ /^\@\@ (.*)/;
            next;
        }
        $data->{$path} .= $_;
    }
    close $fh;
    return $data;
}

sub unpack_tree {
    my $data = _parse_data(shift);

    for my $path (keys %$data) {
        my $dir = dirname($path);
        unless (-e $dir) {
            mkpath($dir) or die "Cannot mkpath '$dir': $!";
        }

        my $content = $data->{$path};
        open my $out, '>', $path or die "Cannot open '$path' for writing: $!";
        print $out $content;
        close $out;
    }
}

sub _regex {
    my @target = @_;
    my $regex = join '|', @target;
    return qr/$regex/;
}

1;
__END__
