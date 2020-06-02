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

done_testing;
