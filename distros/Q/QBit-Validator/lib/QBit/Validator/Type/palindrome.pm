package QBit::Validator::Type::palindrome;
$QBit::Validator::Type::palindrome::VERSION = '0.011';
use qbit;

use base qw(QBit::Validator::Type);

use Exception::Validator::FailedField;

sub _get_options {[]}

sub _get_options_name {qw()}

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
