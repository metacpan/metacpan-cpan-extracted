#!perl -w

use strict;
use Test::More skip_all => 'no longer maintained';

use FindBin qw($Bin);
use File::Spec;
use Config;
use File::Find;
use File::Copy qw(copy);

my $dist_dir = File::Spec->join($Bin, '..', 'example');
chdir $dist_dir or die "Cannot chdir to $dist_dir: $!";

# workaround subdir auto-building :(
copy "MyMakefile.PL" => "Makefile.PL";
END {
    unlink 'Makefile.PL';
}

my $make = $Config{make};

my $out;

note "$^X Makefile.PL";
ok($out = `$^X Makefile.PL`, "$^X Makefile.PL");
is $?, 0, '... success' or diag $out;

ok($out = `$make`, $make);
is $?, 0, '... success' or diag $out;

ok($out = `$make test`, "$make test");
is $?, 0, '... success' or diag $out;

ok -e 'ppport.h', 'ppport.h exists';

my %h_files;

find sub{
	$h_files{$_} = File::Spec->canonpath($File::Find::name) if / \.h \z/xms;
}, qw(blib);

is scalar(keys %h_files), 3, 'two head files are installed';
ok exists $h_files{'foo.h'}, 'foo.h exists';
ok exists $h_files{'bar.h'}, 'bar.h exists';
ok exists $h_files{'baz.h'}, 'baz.h exists';

sub f2rx{
	my $f = quotemeta( File::Spec->join(@_) );
	return qr/$f/xmsi;
}

like $h_files{'foo.h'}, f2rx(qw(Foo foo.h));
like $h_files{'bar.h'}, f2rx(qw(Foo bar.h));
like $h_files{'baz.h'}, f2rx(qw(Foo foo baz.h));

my $Makefile = do{
    local *MF;
    open MF, 'Makefile' or die $!;
    local $/;
    <MF>;
};

like $Makefile, qr/\b foo_is_ok \b/xms, 'Makefile includes foo_is_ok()';
like $Makefile, qr/\b bar_is_ok \b/xms, 'Makefile includes bar_is_ok()';

ok scalar `$make realclean`, "$make realclean";
is $?, 0, '... success';

done_testing;
