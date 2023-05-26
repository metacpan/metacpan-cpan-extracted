# Tests: transformer
#
# see: more transformer tests in decode.t

use strict;
use warnings;

use FindBin ();
use lib "$FindBin::Bin/../lib";

use Test::More;
use PHP::Decode::Transformer;

plan tests => 4;

sub warn_cb {
	my ($ctx, $action, $stmt, $fmt) = (shift, shift, shift, shift);

	my $msg = sprintf $fmt, @_;
	print "WARN: [$ctx->{infunction}] $action $stmt", $msg, "\n";
}
my %strmap;
my $parser = PHP::Decode::Parser->new(strmap => \%strmap);
my $ctx = PHP::Decode::Transformer->new(parser => $parser, warn => \&warn_cb);
isnt($ctx, undef, 'transformer init');

my $str = $parser->setstr('<?php echo "test"; ?>');
my $blk = $ctx->parse_eval($str);
is($blk, '#stmt1', 'transformer parse');

my $stmt = $ctx->exec_eval($blk);
is($stmt, '#blk1', 'transformer exec');

my $code = $parser->format_stmt($stmt);
is($code, "echo 'test' ; \$STDOUT = 'test' ;", 'transformer format');

