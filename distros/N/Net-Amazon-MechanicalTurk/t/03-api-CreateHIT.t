#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
BEGIN { push(@INC, "lib", "t"); }
use TestHelper;

my $mturk = TestHelper->new;

if (!$ENV{MTURK_TEST_WRITABLE}) {
    plan skip_all => "Set environment variable MTURK_TEST_WRITABLE=1 to enable tests which have side-effects.";
}
else {
    plan tests => 14; 
}

my $hit = $mturk->newHIT();

ok($hit, "CreateHIT");
$mturk->destroyHIT($hit);
ok(1, "Destroyed HIT");

$hit = $mturk->CreateHIT( Question=>$mturk->sampleQuestion(), HITTypeId=>$hit->getFirst("HITTypeId"));
ok($hit, "CreateHIT with HitTypeId");
$mturk->destroyHIT($hit);
ok(1, "Destroyed HIT (from template)");

$hit = $mturk->CreateHIT( {Question=>$mturk->sampleQuestion(), HITTypeId=>$hit->getFirst("HITTypeId")});
ok($hit, "CreateHIT with HitTypeId");
$mturk->destroyHIT($hit);
ok(1, "Destroyed HIT (from template)");

# test invalid parameters
my $error;
$error = $mturk->expectError( "AWS.ParameterOutOfRange", sub { $mturk->newHIT( MaxAssignments=>-1 ); } );
ok($error, "CreateHIT with negative MaxAssignments");

$error = $mturk->expectError( "AWS.MechanicalTurk.InvalidParameterValue", sub { $mturk->newHIT( MaxAssignments=>"green" ); } );
ok($error, "CreateHIT with invalid MaxAssignments");

# missing parameters
$error = $mturk->expectError( "AWS.MissingParameters", sub { $mturk->CreateHIT(); } );
ok($error, "CreateHIT with no parameters");

$error = $mturk->expectError( "AWS.MechanicalTurk.InvalidParameterValue", sub {$mturk->CreateHIT( Question=>$mturk->sampleQuestion(), HITTypeId=>"asfd"); } );
ok($error, "CreateHIT with invalid HITTypeId");
$error = $mturk->expectError( "AWS.MechanicalTurk.InvalidParameterValue", sub {$mturk->CreateHIT( HITTypeId=>$hit->getFirst("HITTypeId")); } );
ok($error, "CreateHIT with no Question");
$error = $mturk->expectError( "AWS.MechanicalTurk.XMLParseError", sub {$mturk->CreateHIT( Question=>"who what?", HITTypeId=>$hit->getFirst("HITTypeId")); } );
ok($error, "CreateHIT with invalid Question");

# Test with invalid SecretKey
my $broken_mturk = TestHelper->new( secretKey=>"bogus" );
$error = $broken_mturk->expectError( "AWS.NotAuthorized", sub { $broken_mturk->newHIT(); } );
ok($error, "CreateHIT with invalid SecretKey");

# Test with invalid endpoint
my $imaginary_mturk = TestHelper->new( serviceUrl => "http://localhost:1234" );
$error = $imaginary_mturk->expectError( "Client.TransportError", sub { $imaginary_mturk->newHIT(); } );
ok($error, "CreateHIT with invalid ServiceUrl");
