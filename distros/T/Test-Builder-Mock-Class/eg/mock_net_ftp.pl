#!/usr/bin/perl

use lib 'lib', '../lib';

use strict;
use warnings;

use Test::More 'no_plan';

use Test::Builder::Mock::Class ':all';
use Test::More;

# concrete mock class
mock_class 'Net::FTP' => 'Net::FTP::Mock';
my $mock_object1 = Net::FTP::Mock->new;
$mock_object1->mock_tally;

# anonymous mocked class
my $metamock2 = mock_anon_class 'Net::FTP';
my $mock_object2 = $metamock2->new_object;
$mock_object2->mock_tally;

# anonymous class with role applied
my $metamock3 = Test::Builder::Mock::Class->create_mock_anon_class(
    class => 'Net::FTP',
    roles => [ 'My::Handler::Role' ],
);
my $mock_object3 = $metamock3->new_object;
$mock_object3->mock_tally;


package My::Handler::Role;
use Moose::Role;
