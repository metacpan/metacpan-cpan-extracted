#!/usr/bin/perl

use strict;
use lib '../lib';
use lib 'lib';
use OS390::IEBUtils;
use Data::Dumper;
use Test::More 'no_plan';


open my $input, '<./t/testdata/JCLLIB' or die $!;
# local $/ = \65536;


# initialize new instance
my $obj = OS390::IEBUtils::IEBUPDTE->new($input);
$obj->{debug} = 0;
ok(defined($obj), 'object was defined');

# getNextMember
my ($name, $dataRef);

# get a member
($name, $dataRef) = $obj->getNextMember();
ok ($name eq 'EXTRACT', 'getNextMember 1');

($name, $dataRef) = $obj->getNextMember();
ok ($name eq 'FTP', 'getNextMember 2');

($name, $dataRef) = $obj->getNextMember();
ok ($name eq 'CATEX', 'getNextMember 3');

($name, $dataRef) = $obj->getNextMember();
ok ($name eq 'FTPGEN', 'getNextMember 4');

($name, $dataRef) = $obj->getNextMember();
is ($name, undef() , 'getNextMember 5');




# get member count
ok( scalar($obj->getMemberNames) == 4, 'count of member names with scalar()');
ok( $obj->getMemberNames == 4, 'count of member names w/o scalar()');


# get all member names
is_deeply($obj->getMemberNames(), [qw(EXTRACT FTP CATEX FTPGEN)], 'member name list');



# test for valid file
ok ($obj->isValidFile(), 'File is valid.');


# test for invalid file
open my $input, '<./t/testdata/bogus' or die $!;
$obj = OS390::IEBUtils::IEBUPDTE->new($input);
ok($obj->isValidFile() == 0 , 'File is invalid');







