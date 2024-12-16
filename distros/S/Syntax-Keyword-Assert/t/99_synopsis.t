use Test2::V0;

use Syntax::Keyword::Assert;

my $name = 'Alice';
my $e = dies { assert( $name eq 'Bob' ) };
like $e, qr/Assertion failed \("Alice" eq "Bob"\)/;

done_testing;
