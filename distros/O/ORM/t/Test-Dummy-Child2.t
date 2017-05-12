#!/usr/bin/perl

use lib "t";
use Test::More tests => 2;

BEGIN { use_ok( 'Test::Dummy::Child2' ); }

my $e = ORM::Error->new;

#ORM::DbLog->write_to_stdout( 1 );
#$d = Test::Dummy::Child2->new( prop=>{ a=>'bad value' }, error=>$e );
#ORM::DbLog->write_to_stdout( 0 );
#print $e->text;
#exit;

$stat = Test::Dummy::Child2->stat
(
    data => 
    {
        self => Test::Dummy::Child2->M,
        ref  => Test::Dummy::Child2->M->ref,
    },
    preload => { ref=>1, self=>1 },
    order   => ORM::Order->new( ORM::Ident->new( 'ref' ) ),
    filter  => (Test::Dummy::Child2->M->id == 416),
);

ok
(
    !$e->fatal && $stat->[0]{ref} 
    && $stat->[0]{ref}->id == 415 
    && $stat->[0]{self}->a eq 'aa',
    'stat'
);

print $e->text;
