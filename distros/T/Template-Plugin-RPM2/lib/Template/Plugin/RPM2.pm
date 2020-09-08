package Template::Plugin::RPM2;

use 5.006;
use warnings;
use strict;

use RPM2;
use Template::Plugin;

require Exporter;

our @ISA = qw(Exporter RPM2 Template::Plugin);

=head1 NAME

Template::Plugin::RPM2 - Template Toolkit plugin for RPM2

=head1 VERSION

Version 1.3.0

=cut

our $VERSION = '1.3.0';

=head1 SYNOPSIS

Access details of an RPM file from within a Template Toolkit template.

  [% USE pkg = RPM2(file) %]
  Name:     [% pkg.name %]
  Version:  [% pkg.version %]
  Release:  [% pkg.release %]
  Group:    [% pkg.group %]
  Packager: [% pkg.packager %]

=head1 METHODS

=head2 new

Creates a new Template::Plugin::RPM2 object. Usually called from a template.

=cut

sub new {
  my ($class, $context, $file) = @_;

  my $self = $class->SUPER::open_package($file);

  return $self;
}

=head1 SEE ALSO

=over 4

=item *

L<Template> (the Template Toolkit)

=item *

L<RPM2>

=back

=head1 AUTHOR

Dave Cross, C<< <dave@perlhacks.com> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-template-plugin-rpm2@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Template-Plugin-RPM2>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright (c) 2006-20 Magnum Solutions Ltd., all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Template::Plugin::RPM2
