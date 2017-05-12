package Role::HasPayload;
{
  $Role::HasPayload::VERSION = '0.006';
}
use Moose::Role;
# ABSTRACT: something that carries a payload


requires 'payload';

no Moose::Role;
1;

__END__

=pod

=head1 NAME

Role::HasPayload - something that carries a payload

=head1 VERSION

version 0.006

=head1 OVERVIEW

Including Role::HasPayload in your class is a promise to provide a C<payload>
method that returns a hashref of data to be used for some purpose.  Some
implementations of pre-built payload behavior are bundled with Role-HasPayload:

=over 4

=item *

L<Role::HasPayload::Auto> - automatically compute a payload from attribtues

=item *

L<Role::HasPayload::Merged> - merge auto-payload with data from constructor

=back

=head1 AUTHOR

Ricardo Signes <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Ricardo Signes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
