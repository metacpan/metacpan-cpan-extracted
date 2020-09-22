package Plasp::Exception::End;

use Moo;

with 'Plasp::Exception';

=head1 NAME

Plasp::Exception::End - Exception to end ASP processing

=head1 DESCRIPTION

This is the class for the Exception which is thrown then you call
C<< $Response->End() >>.

This class is not intended to be used directly by users.

=cut

has '+message' => (
    default => "asp_end\n",
);

1;

__END__

=head1 SEE ALSO

=over

=item * L<Plasp::Exception>

=back
