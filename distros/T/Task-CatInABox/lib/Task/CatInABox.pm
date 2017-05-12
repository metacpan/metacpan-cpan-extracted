package Task::CatInABox;

=pod

=head1 NAME

Task::CatInABox - Catalyst and related modules for exploring Catalyst

=head1 DESCRIPTION

This distribution defined a set of modules to cover common modules used
in Catalyst applications.

This package is used by L<Perl::Dist::CatInABox> to produce a standalone
Catalyst installer for Win32, but is made available seperately so that
others can update their installations to match the same module set.

The "Catalyst in a Box" module collection is curated by Kieren Diment
E<lt>zarquon@cpan.orgE<gt>, please contact him regarding the list of
modules and to request additions.

=head1 MODULES

=over

=item *

L<Catalyst::Devel>

=item *

L<Template|Template Toolkit>

=item *

L<DBIx::Class>

=item *

L<DBIx::Class::EncodedColumn>

=item *

L<DBIx::Class::Timestamp>

=item *

L<DBIx::Class::InflateColumn::DateTime>

=item *

L<DBIx::Class::Schema::Loader>

=item *

L<Catalyst::View::TT>

=item *

L<Catalyst::View::JSON>

=item *

L<Catalyst::Model::DBIC::Schema>

=item *

L<Catalyst::Model::DBIC::File>

=item *

L<Catalyst::Plugin::Authentication>

=item *

L<Catalyst::Authentication::Store::DBIx::Class>

=item *

L<Catalyst::Authentication::Store::Htpasswd>

=item *

L<Catalyst::Authentication::Credential::Password>

=item *

L<Catalyst::Authentication::Credential::HTTP>

=back

=cut

use 5.008;
use strict;

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.03';
}

1;

=pod

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 SUPPORT

Please contact the curator with bugs or questions regarding the module list
and contact the author with bugs or questions regarding the L<Task> package.

You can find documentation for this module with the perldoc command.

=head1 COPYRIGHT

Copyright 2008 - 2009 Adam Kennedy.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
