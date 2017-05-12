use strict;
use warnings;
use Test::More;
use Test::Requires (
    'Capture::Tiny'
);
use Cwd qw/getcwd/;
use File::Path qw/mkpath/;
use File::Temp qw/tempdir/;
use File::Basename;

my $cwd    = getcwd;
my $tmpdir = tempdir CLEANUP => 1;
chdir($tmpdir);
unpack_tree(*DATA);
run_cmd(qq{$^X Makefile.PL});
open( my $fh, "Makefile") or die $!;
my $makefile = do {
    local $/;
    <$fh>;
};
chdir $cwd;

my $S = ($^O eq 'MSWin32') ? "\x5c" : "\x2F";
my $foo_dr = quotemeta("${S}dist${S}\$(DISTNAME)${S}foo");
my $foo_r = quotemeta("${S}dist${S}\$(DISTNAME)${S}foo${S}foo.txt");
my $bar_dr = quotemeta("${S}dist${S}\$(DISTNAME)${S}bar");
my $bar_r = quotemeta("${S}dist${S}\$(DISTNAME)${S}bar${S}bar.txt");
my $baz_r = quotemeta("${S}module${S}Dummy-Web${S}baz.txt");


like $makefile, qr!\(MKPATH\).+$foo_dr"!;
like $makefile, qr!\(CHMOD\).+$foo_dr"!;
like $makefile, qr!\(CP\).+$foo_r"!;
like $makefile, qr!\(MKPATH\).+$bar_dr"!;
like $makefile, qr!\(CHMOD\).+$bar_dr"!;
like $makefile, qr!\(CP\).+$bar_r"!;
like $makefile, qr!\(CP\).+$baz_r"!;

ok(1);

done_testing();

sub run_cmd {
    my ($cmd) = @_;
    my $result = Capture::Tiny::capture_merged {
        system $cmd;
    };
    die "`$cmd` failed ($result)" if $?;
    return $result;
}

sub _parse_data {
    my $fh = shift;
    my $path;
    my $data;
    while (<$fh>) {
        if (/^\@\@/) {
            ($path) = $_ =~ /^\@\@ (.*)/;
            $data->{$path} = '';
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

__DATA__
@@ Makefile.PL
use inc::Module::Install;

name 'Dummy';
all_from 'lib/Dummy.pm';
install_sharefile 'foo.txt', dist => 'foo/foo.txt';
install_sharefile 'bar/bar.txt';
install_sharefile 'baz.txt', type => 'module', module => 'Dummy::Web';
tests 't/*.t';
WriteAll;

@@ foo.txt
foo

@@ bar/bar.txt
bar

@@ baz.txt
foo

@@ lib/Dummy.pm
package Dummy;
use 5.006;
our $VERSION = '0.1';
1;

__END__
=pod

=head1 AUTHOR

Masahiro Nagano E<lt>kazeburo@gmail.comE<gt>

=head1 COPYRIGHT

Copyright 2012- Masahiro Nagano

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

