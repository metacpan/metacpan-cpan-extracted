#!/usr/bin/env perl

use v5.10;
use strict;
use warnings;

use File::Slurper 'read_lines';

use Regexp::Parsertron;

# ---------------------

my($input_file_name) = "./re_tests";

my(%marpa_failure);
my(%perl_failure);

my(@fields);
my(@re);
my(%seen);

for my $line (grep{! /#/ && ! /^\s*$/ && ! /^__END__/} read_lines($input_file_name) )
{
	@fields		= split(/\t/, $line);
	$fields[0]	=~ s/^\s+//;

	next if ($seen{$fields[0]});

	$seen{$fields[0]} = 1;

	push @re, $fields[0];
}

my($count)	= 0;
my($number)	= shift(@ARGV) || 0;
my($parser)	= Regexp::Parsertron -> new(verbose => 1);

my($error);
my($result);

for my $re (@re)
{
	$count++;

	# Use this trick to run the tests one-at-a-time. See scripts/test.sh.

	next if ( ($number > 0) && ($count != $number) );

	if ($perl_failure{$count})
	{
		print 'Perl error: ';
	}
	elsif ($marpa_failure{$count})
	{
		print 'Marpa error: ';
	}

	$result = $parser -> parse(re => $re);

	# Reset for next test.

	$parser -> reset;
}

say 'Perl error count:  ', $parser -> perl_error_count;
say 'Marpa error count: ', $parser -> marpa_error_count;

my($prefix) = 'perl-5.21.11';

open(my $fh, '>', "xt/author/$prefix.tests");
say $fh map{$_} sort keys %seen;
close $fh;
