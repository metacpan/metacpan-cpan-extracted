#!/usr/bin/perl
use warnings;
use strict;
use lib ('lib');
use Test::More 'no_plan';
use Petal;

my $template_file = 'canonical_error.html';
$Petal::DISK_CACHE = 0;
$Petal::MEMORY_CACHE = 0;
$Petal::TAINT = 1;
$Petal::BASE_DIR = 't/data';
my $template = new Petal ($template_file);

my $hash = {
	error_message => "Kilroy was Here",
	first_name => "William",
	last_name => "McKee",
	email => 'william@knowmad.com',
	students => [
	    {
		student_id => '1',
		first_name => 'William',
		last_name => 'McKee',
		email => 'william@knowmad.com',
	    },
	    {
		student_id => '2',
		first_name => 'Elizabeth',
		last_name => 'McKee',
		email => 'elizabeth@knowmad.com',
	    },
	   ],
    };

eval { $template->process($hash) };
ok (!$@);

$Petal::OUTPUT = "HTML";
ok (!$@);
