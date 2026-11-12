use strict;
use warnings;
use Test::More;
use Symbol qw(gensym);
use IO::Handle;
use Object::Proto;

# GlobRef: a reference to a glob, blessed or not.

Object::Proto::define('TGlobRef', 'v:GlobRef');
my $o = TGlobRef->new;

sub accepts { my ($v, $what) = @_; ok(eval { $o->v($v); 1 }, "GlobRef accepts $what") or diag($@) }
sub rejects { my ($v, $what) = @_; eval { $o->v($v) }; like($@, qr/Type constraint failed for 'v': expected GlobRef\b/, "GlobRef rejects $what") }

no warnings 'once';
my $glob_copy = *STDOUT;
open my $fh, '<', \(my $buf = "data\n") or die $!;

accepts(\*STDOUT,          'a ref to a named glob');
accepts(\*TGlobRef::NONE,  'a ref to a glob with no handle');
accepts($fh,               'a lexical filehandle');
accepts(\$glob_copy,       'a ref to a scalar holding a glob');
accepts(gensym(),          'a gensym');
accepts(IO::Handle->new,   'a blessed glob ref');

rejects(*STDOUT,           'a bare glob');
rejects(*STDOUT{IO},       'an IO ref');
rejects('STDOUT',          'a handle name');
rejects(\1,                'a scalar ref');
rejects([],                'an array ref');
rejects(qr/x/,             'a regexp');
rejects(undef,             'undef');

ok(TGlobRef->new(v => \*STDERR), 'new() accepts a GlobRef');
eval { TGlobRef->new(v => 'STDERR') };
like($@, qr/Type constraint failed for 'v' in new\(\): expected GlobRef\b/, 'new() rejects a handle name');

ok(Object::Proto::has_type('GlobRef'), 'has_type knows GlobRef');
is(Object::Proto::slot_info('TGlobRef', 'v')->{type}, 'GlobRef', 'slot_info reports GlobRef');

done_testing;
