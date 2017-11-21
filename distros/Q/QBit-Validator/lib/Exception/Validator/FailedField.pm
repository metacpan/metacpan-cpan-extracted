package Exception::Validator::FailedField;
$Exception::Validator::FailedField::VERSION = '0.011';
use base qw(Exception::Validator);

sub import {
    FF->export_to_level(1);
}

package FF;
$FF::VERSION = '0.011';
use base qw(Exception::Validator::FailedField Exporter);

1;
