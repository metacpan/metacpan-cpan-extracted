use strict;
use warnings;

use Test;
use Term::ANSIColorx::ColorNicknames;
use Term::ANSIColorx::AutoFilterFH qw(filtered_handle);

plan tests => 2;

open my $fh, '>', \my $str or die $!;
my $colored = filtered_handle($fh => (qr(test1) => 'sky'), ("test2" => "blood") );
print $colored "this is a test: test1, test2\n";
close $fh;

ok( $str, qr/\e\[1;34mtest1\e\[0?m/ );
ok( $str, qr/\e\[31mtest2\e\[0?m/ );
