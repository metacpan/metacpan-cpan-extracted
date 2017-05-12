use strict;
use warnings;

use Test;
use Term::ANSIColorx::AutoFilterFH qw(filtered_handle);

plan tests => 3;

open my $fh, '>', \my $str or die $!;
eval { my $colored = filtered_handle($fh => (qr(test1) => 'red'), ("test2" => "blood") ) };
ok( $@ =~ m/blood/ );

my $truncated = filtered_handle($fh => (qr(test1) => 'red'));
   $truncated->set_truncate(80);

my $string = "test1 " x 25;
print $truncated $string;

ok( $str =~ m/\e\[31mtest1\e\[0?m/ );
ok( length($str), 81 );
