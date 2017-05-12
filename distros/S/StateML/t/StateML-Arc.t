use Test;
use StateML::Event;
use StateML::Arc;
use StateML::Machine;
use strict;

my $m;
my $a;

my @tests = (
sub {
    $m = StateML::Machine->new(   ID => "test machine" );
    $m->add( StateML::Event->new( ID => "test event"   ) );
    $m->add(
        $a = StateML::Arc->new(   ID => "test arc 1"   )
    );
    ok 1;
},

sub {
    ok $a->event_id, undef;
},
sub {
    ## See if the arc picks up the default event
    $m->add( StateML::Event->new( ID => "#DEFAULT"   ) );
    ok $a->event_id, "#DEFAULT";
},

);

plan tests => 0+@tests;

$_->() for @tests;
