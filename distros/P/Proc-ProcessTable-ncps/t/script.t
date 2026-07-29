#!perl
use 5.006;
use strict;
use warnings;
use Test::More;
use lib 'lib';
use Proc::ProcessTable::ncps;

my $script = 'src_bin/ncps';

if ( !-f $script ) {
	plan skip_all => 'src_bin/ncps not found, not running from the dist root';
}

plan tests => 5;

my $version_output = `$^X -Ilib $script -v`;
is( $? >> 8, 0, '-v exits zero' );
like( $version_output, qr/ncps v\. \Q$Proc::ProcessTable::ncps::VERSION\E/, '-v prints the module version' );

my $help_output = `$^X -Ilib $script -h`;
is( $? >> 8, 0, '-h exits zero' );
like( $help_output, qr/-c \<regex\>/, '-h prints the switch list' );

`$^X -Ilib $script --bogus 2> /dev/null`;
is( $? >> 8, 255, 'a unknown switch exits 255' );
