# Tests: parser
#
# see: more parser tests in decode.t

use strict;
use warnings;

use FindBin ();
use lib "$FindBin::Bin/../lib";

use Test::More;
use PHP::Decode::Parser;

plan tests => 5;

sub warn_msg {
	my ($action, $fmt) = (shift, shift);
	my $msg = sprintf $fmt, @_;
	print 'WARN: ', $action, ': ', $msg, "\n";
}

my %strmap;
my $parser = PHP::Decode::Parser->new(strmap => \%strmap, warn => \&warn_msg);
isnt($parser, undef, 'parser init');

my $line = '<?php echo "test"; ?>';
my $quote = $parser->tokenize_line($line);
is($quote, undef, 'parser quote');

my $tokens = $parser->tokens();
my $res = join(' ', @$tokens);
is($res, "echo #str1 ;", 'parser result');

my $stmt = $parser->read_code($tokens);
is($stmt, '#stmt1', 'parser stmt');

my $code = $parser->format_stmt($stmt, {format => 1});
is($code, "echo 'test' ;", 'parser format');

