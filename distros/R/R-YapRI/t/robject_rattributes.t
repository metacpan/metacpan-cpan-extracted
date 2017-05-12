#!/usr/bin/perl

=head1 NAME

  robject_rattributes.t
  A piece of code to test the R::YapRI::Robject::Rattributes object

=cut

=head1 SYNOPSIS

 perl robject_rattributes.t
 prove robject_rattributes.t

=head1 DESCRIPTION

 Test R::YapRI::Robject::Rattributes module

=cut

=head1 AUTHORS

 Aureliano Bombarely
 (aurebg@vt.edu)

=cut

use strict;
use warnings;
use autodie;

use Data::Dumper;
use Test::More tests => 22;
use Test::Exception;

use FindBin;
use lib "$FindBin::Bin/../lib";


## TEST 1

BEGIN {
    use_ok('R::YapRI::Robject::Rattributes');
}

## TEST 2 to 4
## Create a new object

my $rattr = R::YapRI::Robject::Rattributes->new();

is(ref($rattr), 'R::YapRI::Robject::Rattributes', 
   "testing new(), checking object identity")
    or diag("Looks like this has failed");

throws_ok  { R::YapRI::Robject::Rattributes->new('fake') } qr/ARG. ERROR: fak/, 
    'TESTING DIE ERROR when arg. supplied to new is not an hashref.';

throws_ok  { R::YapRI::Robject::Rattributes->new({fake => 1}) } qr/ERROR: acc/, 
    'TESTING DIE ERROR when accessor name used as arg. for new isnt permitted';


## TEST 5 to 22 
## Test accessors

my %accs = (
    names    => ['a', 'b', 'c'],
    dim      => [3, 6],
    dimnames => [ [ 'A', 'B', 'C'], ['n1', 'n2', 'n3', 'n4', 'n5', 'n6'] ],
    class    => 'class.test',
    tsp      => ['start', 'end', 'frequency', 'test-go-away'],
    );


foreach my $acc_key (sort keys %accs) {

    my $set_func = 'set_' . $acc_key;
    my $get_func = 'get_' . $acc_key;
    
    $rattr->$set_func($accs{$acc_key});
    is($rattr->$get_func(), $accs{$acc_key},
	"testing $set_func/$get_func, checking accessor value")
	or diag("Looks like this has failed");

    throws_ok { $rattr->$set_func() } qr/ERROR: No argument was supplied/,
    'TESTING DIE ERROR when no argument was supplied to accessor ' . $acc_key;

    throws_ok { $rattr->$set_func({}) } qr/ERROR: HASH/,
    'TESTING DIE ERROR when arg. supplied to acc. '.$acc_key.' isnt right ref.';
}

## Additional accessor test

throws_ok { $rattr->set_dim(['fk']) } qr/ERROR: dim=fk/,
    'TESTING DIE ERROR when element supplied to accessor dim isnt an integer';

throws_ok { $rattr->set_dimnames(['fk']) } qr/ERROR: fk used/,
    'TESTING DIE ERROR when element supplied to accessor dimnames isnt an aref';

is(scalar(@{$rattr->get_tsp()}), 3, 
    "testing set_tsp, checking the number of elements in the array is 3")
    or diag("Looks like thus has failed");

  
####
1; #
####
