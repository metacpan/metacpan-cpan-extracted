package Plasp::Exception::Code;

use Moo;

with 'Plasp::Exception';

=head1 NAME

Plasp::Exception::Code - Exception to end ASP processing due to code error

=head1 DESCRIPTION

This is the class for the Exception which is thrown when an error is found in
the application code while parsing, compiling, or executing. This is incorrect
usage of ASP.

This class is not intended to be used directly by users.

=cut

has '+message' => (
    default => "code_error\n",
);

1;

__END__

=head1 SEE ALSO

=over

=item * L<Plasp::Exception>

=back
