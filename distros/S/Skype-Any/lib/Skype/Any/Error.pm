package Skype::Any::Error;
use strict;
use warnings;
use overload '0+' => \&as_numeric, q{""} => \&as_string, fallback => 1;

sub new {
    my ($class, $code, $description) = @_;
    return bless {
        code        => $code,
        description => $description,
    }, $class;
}

sub as_numeric { $_[0]->{code} }
sub as_string  { $_[0]->{description} }

1;
__END__

=head1 NAME

Skype::Any::Error - Error interface for Skype::Any

=head1 METHODS

=head2 C<< $error->as_numeric() >>

Return error code.

=head2 C<< $error->as_string() >>

Return error description.

=head1 SEE ALSO

L<Public API Reference|https://developer.skype.com/public-api-reference#ERRORS>

=cut
