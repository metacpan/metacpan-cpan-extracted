package RDF::Closure::Engine;

use 5.008;
use strict;
use utf8;

use Module::Pluggable
	except      => qw[RDF::Closure::Engine::Core],
	require     => 1,
	search_path => qw[RDF::Closure::Engine],
	sub_name    => 'engines',	
	;

our $VERSION = '0.001';

sub new
{
	my ($class, $engine, @args) = @_;
	$engine = 'RDFS' unless defined $engine;

	my ($match) = grep { /^${class}::${engine}$/i } $class->engines;
	
	die sprintf("Package %s::%s not found.\n", $class, $engine)
		unless $match;
	
	return $match->new(@args);
}

sub entailment_regime
{
	return undef;
}

# Child classes MUST implement the following methods
sub graph   { die "Not implemented.\n"; }
sub closure { die "Not implemented.\n"; }
sub reset   { die "Not implemented.\n"; }
sub errors  { die "Not implemented.\n"; }
	
1;

=head1 NAME

RDF::Closure::Engine - an engine for inferring triples

=head1 DESCRIPTION

=head2 Constructor

=over

=item * C<< new($regime, $model, @arguments) >>

Instantiates an inference engine. This:

  RDF::Closure::Engine->new('RDFS', $model, @args);

is just a shortcut for:

  RDF::Closure::Engine::RDFS->new($model, @args);

Though in the former, 'RDFS' is treated case-insensitively.

C<< $model >> must be an L<RDF::Trine::Model> which the engine
will read its input from and write its output to.

=back

=head2 Methods

=over

=item * C<< entailment_regime >>

Returns a URI string identifying the type of inference implemented by the engine,
or undef.

=item * C<< graph >>

Returns the L<RDF::Trine::Model> the engine is operating on.

=item * C<< closure( [ $is_subsequent ] ) >>

Adds any new triples to the graph that can be inferred.

If C<< $is_subsequent >> is true, then skips axioms.

=item * C<< errors >>

Returns a list of consistency violations found so far.

=item * C<< reset >>

Removes all inferred triples from the graph.

=back

=head2 Class Method

=over

=item * C<< engines >>

Return a list of engines installed, e.g. 'RDF::Closure::Engine::RDFS'.

=back

=head1 SEE ALSO

L<RDF::Closure>,
L<RDF::Closure::Engine::RDFS>,
L<RDF::Closure::Engine::OWL2RL>,
L<RDF::Closure::Engine::OWL2Plus>.

L<http://www.perlrdf.org/>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT

Copyright 2011-2012 Toby Inkster

This library is free software; you can redistribute it and/or modify it
under any of the following licences:

=over

=item * The Artistic License 1.0 L<http://www.perlfoundation.org/artistic_license_1_0>.

=item * The GNU General Public License Version 1 L<http://www.gnu.org/licenses/old-licenses/gpl-1.0.txt>,
or (at your option) any later version.

=item * The W3C Software Notice and License L<http://www.w3.org/Consortium/Legal/2002/copyright-software-20021231>.

=item * The Clarified Artistic License L<http://www.ncftp.com/ncftp/doc/LICENSE.txt>.

=back


=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.


=cut

