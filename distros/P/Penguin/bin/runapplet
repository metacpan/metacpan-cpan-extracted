#!/usr/bin/perl 
use Penguin;
use Penguin::Rights;
use Penguin::Frame::Code;
use Penguin::Frame::Data;
use Penguin::Wrapper::PGP;
use Penguin::Wrapper::Transparent;
use Penguin::Compartment;

my $filename = shift;
my $password = shift; # bad idea, of course

open(PENGUINFILE, "<$filename");
{local $/ = undef; $penguinframe = <PENGUINFILE>}
close(PENGUINFILE);

print("penguinframe is $penguinframe\n");
$frame = new Penguin::Frame::Code Text => $penguinframe;

($title, $signer, $wrapmethod, $code) = $frame->disassemble(
                                             Password => $password);

$rightsdb = new Penguin::Rights;

get $rightsdb;

$userrights = getrights $rightsdb User => $signer;

print<<"ENDOFFORM";
Title: $title
Signer: $signer
Rights: $userrights
Wrap Method: $wrapmethod
Code
--------------
$code
--------------
ENDOFFORM

$compartment = new Penguin::Compartment;
$compartment->initialize( Operations => $userrights );

$result = $compartment->execute( Code => $code );

if ($@) { # illegal code tried to execute
    $result = $@;
}

print "-------result was--------\n$result\n";
