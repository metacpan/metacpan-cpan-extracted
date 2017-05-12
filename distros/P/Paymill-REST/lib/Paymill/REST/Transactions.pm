package Paymill::REST::Transactions;

use Moose;
with 'Paymill::REST::Base';

has '+type' => (default => 'transaction');

__PACKAGE__->meta->make_immutable;
1;
__END__

=encoding utf-8

=head1 NAME

Paymill::REST::Transactions - Item factory for transactions

=head1 AVAILABLE OPERATIONS

=over 4

=item create

L<Paymill::REST::Operations::Create>

=item find

L<Paymill::REST::Operations::Find>

=item list

L<Paymill::REST::Operations::List>

=back

=head1 SEE ALSO

L<Paymill::REST> for more documentation.

=head1 AUTHOR

Matthias Dietrich E<lt>perl@rainboxx.deE<gt>

=head1 COPYRIGHT

Copyright 2013 - Matthias Dietrich

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.