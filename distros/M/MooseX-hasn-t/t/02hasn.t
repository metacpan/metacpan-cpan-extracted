package Local::Test;

use Moose;

has attribute => (is => 'ro', predicate => 'has_attribute', required => 1);

sub method { 'method' };

package Local::Test::Awesome;

use Moose;
use MooseX::hasn't;
extends 'Local::Test';

hasn't 'attribute' => (default => sub{'A'});
hasn't [qw/method/];

package main;

use 5.010;
use Test::More tests => 6;
use Test::Exception;

my $inst1 = Local::Test->new(attribute => 'attribute');
is($inst1->attribute, 'attribute');
is($inst1->method, 'method');

my $inst2 = Local::Test::Awesome->new();
ok !$inst2->can('attribute');
ok !$inst2->can('method');

dies_ok { $inst2->attribute };
dies_ok { $inst2->method };
