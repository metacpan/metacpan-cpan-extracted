package t::Util;

use strict;
use warnings;
use Test::Builder;
use File::Temp qw/tempdir/;
use File::Path qw/mkpath/;
use File::Basename qw/dirname/;
use File::Spec;
use Cwd;
use Config;
use base qw(Exporter);

use constant DMAKE => $^O eq 'MSWin32' && $Config{make} =~ /dmake(?:\.exe)?$/i;
use constant NMAKE => $^O eq 'MSWin32' && $Config{make} =~ /nmake(?:\.exe)?$/i;
use constant MAKE  => $Config{make} || 'make';

our @EXPORT = qw/find_make_test_command unpack_tree build run_make DMAKE NMAKE/;

sub find_make_test_command {
    my ($fh, @target) = @_;
    my $target = +{ map { $_ => 1 } @target, qw(test test_dynamic) };

    local $ENV{PERL5LIB} = join $Config{path_sep},
        map { File::Spec->rel2abs($_) } @INC;

    my $cwd = getcwd;
    my $tmpdir = tempdir CLEANUP => 1;

    chdir $tmpdir or die $!;

    unpack_tree($fh);

    my $make_test_commands = eval {
        build($cwd);

        my $commands = {};
        open my $fh, '<', 'Makefile' or die "Cannot open 'Makefile' for reading: $!";
        my $regex = _regex(keys %$target);
        while (<$fh>) {
            next unless /^ ($regex) \s+ :: \s+ (?:pure_all|$regex) /xms;
            $commands->{$1} = scalar <$fh>;
            delete $target->{$1};
            my @target = keys %$target;
            last unless @target;
            $regex = _regex(@target);
        }
        return $commands;
    };
    chdir $cwd or die $!;

    die $@ if $@;

    return $make_test_commands;
}

sub build {
    my $distdir = shift;
    die "Makefile.PL not found" unless -f 'Makefile.PL';
    my $tb = Test::Builder->new;
    $tb->note( run_cmd(qq{$^X Makefile.PL}) );
    run_make();
}

sub run_cmd {
    my ($cmd) = @_;
    my $result = `$cmd`;
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
