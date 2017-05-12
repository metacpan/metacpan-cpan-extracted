use strict;
use warnings;

BEGIN { $ENV{PERL_RL} = 'Stub'; }
BEGIN { $^W = 0 } # common::sense does funny things, we don't need to hear about it.

package Term::ReadLine::Test;

use parent 'Term::ReadLine';
sub new
{
    my $class = shift;
    my $obj = $class->SUPER::new(@_);
    bless $obj, $class;
}

package main;

use Test::More;
BEGIN {
    plan skip_all => "AnyEvent is not installed" unless eval "use AnyEvent; 1";
}
plan tests => 1;

use Term::ReadLine 1.09;
use Term::ReadLine::Event;

my $term = Term::ReadLine::Test->new('foo');
$term = Term::ReadLine::Event->with_AnyEvent($term);
isa_ok($term->trl() => 'Term::ReadLine::Test');

