use v5.20;

use Test::More;

use Object::Exercise;

my @testz =
(
    [
        [ qw( doit 1 ) ],
        undef,
        'Should fail, compare to undef'
    ],
    [
        [ qw( doit 1 ) ],
        '',
        'Should fail, compare to empty string'
    ],
);

$exercise->( WillFail->new, @testz );

package WillFail;

sub new     { bless \( my $a = '' ), __PACKAGE__    }
sub doit    { die "You asked for it...\n"           }

0

__END__
