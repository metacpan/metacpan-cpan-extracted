# Tests: func
#
# see: more func tests in decode.t

use strict;
use warnings;

use FindBin ();
use lib "$FindBin::Bin/../lib";

use Test::More;
use PHP::Decode::Transformer;
use PHP::Decode::Func;

plan tests => 3;

sub warn_cb {
	my ($ctx, $action, $stmt, $fmt) = (shift, shift, shift, shift);

	my $msg = sprintf $fmt, @_;
	print "WARN: [$ctx->{infunction}] $action $stmt", $msg, "\n";
}
my %strmap;
my $parser = PHP::Decode::Parser->new(strmap => \%strmap);
my $ctx = PHP::Decode::Transformer->new(parser => $parser, warn => \&warn_cb);
isnt($ctx, undef, 'func init');

my $str = $parser->setstr('test');
my $res = PHP::Decode::Func::exec_cmd($ctx, 'strlen', [$str]);
isnt($res, undef, 'func exec');

my $code = $parser->format_stmt($res, {avoid_semicolon => 1});
is($code, '4', 'func result');

