package Plasp::Exception::Redirect;

use Moo;

with 'Plasp::Exception';

=head1 NAME

Plasp::Exception::Redirect - Exception to end ASP processing due to redirect

=head1 DESCRIPTION

This is the class for the Exception which is thrown then you call
C<< $Response->Redirect() >>.

This class is not intended to be used directly by users.

=cut

has '+message' => (
    default => "redirect\n",
);

1;

__END__

=head1 SEE ALSO

=over

=item * L<Plasp::Exception>

=back
