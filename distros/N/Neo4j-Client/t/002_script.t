use Test::More;
use Test::Exception;
use File::Spec;
use IPC::Run qw/run/;


my $d = (-d 't' ? '.' : '..');

my $script = File::Spec->catfile($d,'bin','neoclient.pl');
my ($in,$out,$err);
  
lives_ok { run [ $^X, '-Mblib', $script, '-?' ],\$in,\$out,\$err };

like $out, qr/Usage/, 'usage note';

ok(run([ $^X, '-Mblib', $script, '--lib' ],\$in,\$out,\$err),"--lib");
like $out, qr{-L/}, "got some libs";
ok(run([ $^X, '-Mblib', $script, '--cc' ],\$in,\$out,\$err),"--cc");
like $out, qr{-I/},"got some ccflags";
ok(run([ $^X, '-Mblib', $script, '--cc', '--dev' ],\$in,\$out,\$err),"--cc --dev");
like $out, qr{-I/},"got some ccflags";
like $out, qr{Client/include}, "got dev ccflags";
done_testing;
