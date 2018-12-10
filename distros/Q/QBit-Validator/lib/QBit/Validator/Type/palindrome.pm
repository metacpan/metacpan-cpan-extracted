package QBit::Validator::Type::palindrome;
$QBit::Validator::Type::palindrome::VERSION = '0.012';
use qbit;

use base qw(QBit::Validator::Type);

use Exception::Validator::FailedField;

sub get_template {
    return {
        type    => 'scalar',
        len_min => 1,
        check   => sub {
            throw FF gettext('String is not a palindrome') unless $_[1] eq reverse($_[1]);
        },
    };
}

TRUE;
