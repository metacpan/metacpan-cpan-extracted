package Paymill::REST::Preauthorizations;

use Moose;
with 'Paymill::REST::Base';
with 'Paymill::REST::Operations::Delete';

has '+type' => (default => 'preauthorization');
has _type_create => (is => 'ro', isa => 'Str', default => 'transaction');

__PACKAGE__->meta->make_immutable;
1;

__END__

=encoding utf-8

=head1 NAME

Paymill::REST::Preauthorizations - Item factory for preauthorizations

=head1 AVAILABLE OPERATIONS

=over 4

=item create

L<Paymill::REST::Operations::Create>

B<IMPORTANT:> The C<create> operation returns an transaction item
instead of a preauthorization item.  This is due to PAYMILL's API
which also returns transaction objects via this endpoint.

=item delete

L<Paymill::REST::Operations::Delete>

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