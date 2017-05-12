=head1 NAME

Template::TAL::Provider - Base class for TAL template providers

=head1 SYNOPSIS

  my $provider = $provider_class->new;
  my $ttt = $provider_class->get_template("foo");

=head1 DESCRIPTION

TAL Templates come from Providers. You ask an instance of a provider for a
template with a specific name, and it should return a
L<Template::TAL::Template> object to you for that template.

This module is the base class of all providers - it should be subclassed by
developers who wish to write their own provider - for instance, to serve
templates from a database.

=head1 SUBCLASSING

The only method you need to implement is C<get_template>, which must
return either a Template::TAL::Template object, or undef. If you want to
do any module initialisation, override C<new()>. See
L<Template::TAL::Provider::Disk> for the simple provider that ships with
Template::TAL.

=cut

package Template::TAL::Provider;
use warnings;
use strict;
use Carp qw( croak );

=head1 METHODS

=over

=item new()

creates a new provider

=cut

sub new {
  return bless {}, shift;
}

=item get_template( template name )

Should return a Template::TAL::Template object with the given name, or die
if there is no such template.

=cut

sub get_template {
  croak('Template::TAL::Provider is abstract - use a subclass');
}

=back

=head1 COPYRIGHT

Written by Tom Insam, Copyright 2005 Fotango Ltd. All Rights Reserved.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

=head1 BUGS

None known.  Please see L<Template::TAL> for details of how to report bugs.

=head1 SEE ALSO

L<Template::TAL>, L<Template::TAL::Provider::Disk>

=cut

1;
