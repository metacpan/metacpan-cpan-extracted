package Role::HasPayload 0.007;
use Moose::Role;
# ABSTRACT: something that carries a payload

#pod =head1 OVERVIEW
#pod
#pod Including Role::HasPayload in your class is a promise to provide a C<payload>
#pod method that returns a hashref of data to be used for some purpose.  Some
#pod implementations of pre-built payload behavior are bundled with Role-HasPayload:
#pod
#pod =for :list
#pod * L<Role::HasPayload::Auto> - automatically compute a payload from attribtues
#pod * L<Role::HasPayload::Merged> - merge auto-payload with data from constructor
#pod
#pod =cut

requires 'payload';

no Moose::Role;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Role::HasPayload - something that carries a payload

=head1 VERSION

version 0.007

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

=head1 PERL VERSION

This library should run on perls released even a long time ago.  It should work
on any version of perl released in the last five years.

Although it may work on older versions of perl, no guarantee is made that the
minimum required version will not be increased.  The version may be increased
for any reason, and there is no promise that patches will be accepted to lower
the minimum required perl.

=head1 AUTHOR

Ricardo Signes <cpan@semiotic.systems>

=head1 CONTRIBUTOR

=for stopwords Ricardo Signes

Ricardo Signes <rjbs@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by Ricardo Signes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
