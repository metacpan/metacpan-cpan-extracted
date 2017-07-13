# NOTE: do not use Renard::Incunabula::Common::Setup here due to Glib / Moo subclass conflict
use strict;
use warnings;
package Renard::Curie::Model::View;
# ABSTRACT: A base class for a view
$Renard::Curie::Model::View::VERSION = '0.003';
use Moo;

use Glib::Object::Subclass
	'Glib::Object',
	signals => { 'view-changed' => {} },
	;


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Renard::Curie::Model::View - A base class for a view

=head1 VERSION

version 0.003

=head1 EXTENDS

=over 4

=item * L<Glib::Object::Subclass>

=item * L<Moo::Object>

=item * L<Glib::Object>

=back

=head1 SIGNALS

=over 4

=item *

C<view-changed>: called when a view property is changed.

=back

=head1 AUTHOR

Project Renard

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Project Renard.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
