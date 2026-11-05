package Praxo::Errors;

use strict;
use warnings;
use Exporter 'import';

our @EXPORT_OK = qw(praxo_error error_code);

sub praxo_error {
    my ($code, $message) = @_;
    die bless { code => $code, message => $message }, 'Praxo::Errors::Error';
}

sub error_code {
    my ($error) = @_;
    return ref($error) eq 'Praxo::Errors::Error' ? $error->{code} : '';
}

package Praxo::Errors::Error;

use overload '""' => sub { $_[0]->{message} }, fallback => 1;

1;
