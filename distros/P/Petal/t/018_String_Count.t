#!/usr/bin/perl
use warnings;
use strict;
use lib ('lib');
use Test::More 'no_plan';
use Petal;

my $template_file = 'string_count.html';
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
	students => [ { student_id => '1',
					first_name => 'William',
					last_name => 'McKee',
					email => 'william@knowmad.com',
					},
				  { student_id => '2',
					  first_name => 'Elizabeth',
					  last_name => 'McKee',
					  email => 'elizabeth@knowmad.com',
					},
				],
};

# warn $template->_code_with_line_numbers();
my $html = $template->process($hash);
like($html, '/1 - William/');
like($html, '/2 - Elizabeth/');
