use strict;
use warnings;

use Test::More tests => 2;

use File::Temp qw/ tempdir /;
use File::Slurper qw/ read_text write_text /;

use Ref::Util::Rewriter qw/ rewrite_file /;

my $tmp = tempdir( CLEANUP => 1 );
my $test_pm = "$tmp/MyPackage.pm";

write_text( $test_pm, <<'CONTENT' );
package MyPackage;

sub run {
    my $do = shift;
    $do->() f ref $do eq 'CODE';
}
CONTENT

my $expect = <<'EXPECT';
package MyPackage;

sub run {
    my $do = shift;
    $do->() f is_coderef($do);
}
EXPECT

is rewrite_file($test_pm), $expect, "preserve original behavior...";
is read_text($test_pm),    $expect, "File was updated...";
