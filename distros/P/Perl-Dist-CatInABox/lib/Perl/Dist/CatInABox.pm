package Perl::Dist::CatInABox;

=pod

=head1 NAME

Perl::Dist::CatInABox - Catalyst (and supporting modules) on top of
Strawberry perl for win32.

=head1 DESCRIPTION

See L<Perl::Dist::Strawberry> for details.  This distribution installs
the following modules (and their dependencies) to cover common modules
used in Catalyst applications.  To that end this distribution includes
(on top of the reqular Strawberry perl modules):

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
use warnings;
use Perl::Dist::Strawberry 1.07 ();

use vars qw{$VERSION @ISA};
BEGIN {
	$VERSION = '0.02';
	@ISA     = 'Perl::Dist::Strawberry';
}

sub new {
	shift->SUPER::new(
		app_id               => 'catinabox',
		app_name             => 'Catalyst In A Box Beta 1',
		app_publisher        => 'Kieren Diment',
		app_publisher_url    => 'http://www.catalystframework.org/',
		image_dir            => 'C:\\catinabox',
		output_base_filename => 'catinabox-5.10.0-beta-1',
		exe                  => 1,
		zip                  => 1,
		@_,
	);
}

sub install_perl_modules {
	my $self = shift;
	$self->SUPER::install_perl_modules(@_);
	$self->install_module( name => 'Task::CatInABox' );
	return 1;
}

1;

=pod

=head1 AUTHOR

Kieren Diment E<lt>zarquon@cpan.orgE<gt>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-perl-dist-catinabox at rt.cpan.org>, or through
the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Perl-Dist-CatInABox>.
I will be notified, and then you'll automatically be notified of progress
on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Perl::Dist::CatInABox

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Perl-Dist-CatInABox>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Perl-Dist-CatInABox>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Perl-Dist-CatInABox>

=item * Search CPAN

L<http://search.cpan.org/dist/Perl-Dist-CatInABox>

=back

=head1 ACKNOWLEDGEMENTS

Adam Kennedy for his Strawberry Perl project. All the Catalyst
contributors (L<http://catalystframework.org>).

=head1 COPYRIGHT & LICENSE

Copyright 2008 Kieren Diment.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
