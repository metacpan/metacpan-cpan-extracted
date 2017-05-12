#!/usr/bin/perl
use Penguin;
use Penguin::Frame::Code;
use Penguin::Frame::Data;
use Penguin::Wrapper::PGP;
use Penguin::Wrapper::Transparent;

my $filename = shift;
open(CODEFILE, "<$filename");
{local $/ = undef; $codetosend = <CODEFILE>}
close(CODEFILE);

print("assembling...\n");
$frame = new Penguin::Frame::Code Wrapper => 'Penguin::Wrapper::Transparent';

assemble $frame Password => $password, 
                Text     => $codetosend,
                Title    => "untitled program",
                Name     => "mapthecat <map\@amicus.com>";

open(FRAMEFILE, ">$filename.pen");
print FRAMEFILE $frame->contents();
close FRAMEFILE;
print("...done\n");
