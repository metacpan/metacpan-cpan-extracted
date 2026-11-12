use strict;
use warnings;
use Test::More;
use IO::Handle;
use IO::File;
use Object::Proto;

# FileHandle: an open handle - a glob (including one held in an lvalue), glob
# ref or IO ref whose IO is open or tied - or an object that isa IO::Handle.

Object::Proto::define('TFileHandle', 'v:FileHandle');
my $o = TFileHandle->new;

sub accepts { my ($v, $what) = @_; ok(eval { $o->v($v); 1 }, "FileHandle accepts $what") or diag($@) }
sub rejects { my ($v, $what) = @_; eval { $o->v($v) }; like($@, qr/Type constraint failed for 'v': expected FileHandle\b/, "FileHandle rejects $what") }

{
    package TFileHandle::Tied;
    sub TIEHANDLE { bless {}, shift }
}
{
    package TFileHandle::Subclass;
    our @ISA = ('IO::Handle');
}
tie *TIED, 'TFileHandle::Tied';

open my $open,   '<', \(my $b1 = "data\n") or die $!;
open my $closed, '<', \(my $b2 = "data\n") or die $!;
close $closed;

accepts(\*STDOUT,                               'a ref to STDOUT');
accepts(*STDOUT,                                'the bare glob STDOUT');
accepts(*STDOUT{IO},                            'the IO ref of STDOUT');
accepts($open,                                  'an open lexical handle');
accepts(IO::File->new(\(my $b3 = "x"), '<'),    'an open IO::File');
accepts(IO::Handle->new,                        'an unopened IO::Handle');
accepts(bless({}, 'TFileHandle::Subclass'),     'an object whose class isa IO::Handle');
accepts(\*TIED,                                 'a ref to a tied handle');
accepts(*TIED,                                  'a tied bare glob');

rejects($closed,                     'a closed lexical handle');
rejects(\*TFileHandle::NONE,         'a ref to a glob with no handle');
rejects(*TFileHandle::NONE,          'a bare glob with no handle');
rejects('STDOUT',                    'a handle name');
rejects(bless({}, 'TFileHandle::X'), 'an object that is not a handle');
rejects(\1,                          'a scalar ref');
rejects([],                          'an array ref');
rejects(sub { 1 },                   'a code ref');
rejects(undef,                       'undef');

# A glob assigned through an alias to a hash element that does not exist yet
# is held in an lvalue, not a real glob (see perl #77362). It is an open
# handle - fileno() works on it - so it is passed to the setter as it is:
# copying it into a lexical, or taking a ref to it, would make it a real glob.
{
    my %h;
    sub { for (shift) {
        $_ = *STDOUT;
        ok(eval { $o->v($_); 1 }, 'FileHandle accepts an open glob held in an lvalue') or diag($@);
    } }->($h{k});
}

ok(TFileHandle->new(v => \*STDERR), 'new() accepts a FileHandle');
eval { TFileHandle->new(v => $closed) };
like($@, qr/Type constraint failed for 'v' in new\(\): expected FileHandle\b/, 'new() rejects a closed handle');

ok(Object::Proto::has_type('FileHandle'), 'has_type knows FileHandle');
is(Object::Proto::slot_info('TFileHandle', 'v')->{type}, 'FileHandle', 'slot_info reports FileHandle');

done_testing;
