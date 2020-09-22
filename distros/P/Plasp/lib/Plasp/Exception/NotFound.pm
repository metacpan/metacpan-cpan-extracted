package Plasp::Exception::NotFound;

use Moo;

with 'Plasp::Exception';

=head1 NAME

Plasp::Exception::NotFound - Exception to end ASP processing due file not found

=head1 DESCRIPTION

This is the class for the Exception which is thrown when the file to be
compiled is not found. This should eventually end up being a 404 for the
end-user.

This class is not intended to be used directly by users.

=cut

has '+message' => (
    default => "not_found\n",
);

1;

__END__

=head1 SEE ALSO

=over

=item * L<Plasp::Exception>

=back
