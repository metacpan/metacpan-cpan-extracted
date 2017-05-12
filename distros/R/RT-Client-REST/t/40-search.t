use strict;
use warnings;

package Mock;
use base 'RT::Client::REST::Object';

sub new {
    my $class = shift;
    bless {@_}, ref($class) || $class;
}

sub retrieve { shift }

sub id { shift->{id} }

package main;

use Test::More tests => 20;
use Test::Exception;

use constant METHODS => (
    'new', 'count', 'get_iterator',
);

BEGIN {
    use_ok('RT::Client::REST::SearchResult');
}

for my $method (METHODS) {
    can_ok('RT::Client::REST::SearchResult', $method);
}

my $search;
my @ids = (1 .. 9);
lives_ok {
    $search = RT::Client::REST::SearchResult->new(
        ids => \@ids,
        object => sub { Mock->new(id => shift) },
    );
};

ok($search->count == 9);

my $iter;
lives_ok {
    $iter = $search->get_iterator;
} "'get_iterator' call OK";

ok('CODE' eq ref($iter), "'get_iterator' returns a coderef");

my @results = &$iter;
ok(9 == @results, "Got 9 results in list context");
@results = &$iter;
ok(0 == @results, "Got 0 results in list context second time around");

$iter = $search->get_iterator;
my $i = 0;
while (my $obj = &$iter) {
    ++$i;
    ok($i == $obj->id, "id as expected");
}

ok(9 == $i, "Iterated 9 times (as expected)");

# vim:ft=perl:
