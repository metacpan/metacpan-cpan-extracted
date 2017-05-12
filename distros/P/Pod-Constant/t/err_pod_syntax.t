use strict;
use warnings;

# Invalid import, should die.

=head1 DESCRIPTION

X<$a=>1 X<$b=>2 and X<$c=>3

Don't forget X<$d=>"Four!"

=cut

use Test::More tests => 1;
use Test::Exception;

throws_ok {
    require Pod::Constant;
    Pod::Constant->import('$e');
} qr/No such constant '\$e'/, 'missing constant';
