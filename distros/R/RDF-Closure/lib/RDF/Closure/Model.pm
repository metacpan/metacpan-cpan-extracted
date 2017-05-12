package RDF::Closure::Model;

use 5.008;
use strict;
use utf8;

use Carp qw[carp croak];
use RDF::Closure::Engine;
#use RDF::Trine;
use Scalar::Util qw[];

our @ISA = qw[RDF::Trine::Model];

our $VERSION = '0.001';

BEGIN
{
	no strict 'refs';
	my $pkg = __PACKAGE__;
	foreach my $delegated_method (qw[
		get_list size etag count_statements get_statements
		get_pattern get_contexts as_stream as_hashref
		as_graphviz subjects predicates objects as_string
		objects_for_predicate_list bounded_description
	])
	{
		*{$pkg.'::'.$delegated_method} = sub
		{
			my ($self, @args) = @_;
			return $self->_egraph->$delegated_method(@args);
		};
	}
}

sub new
{
	my ($class, $original_data, %args) = @_;
	
	$args{store}  ||= RDF::Trine::Store->temporary_store;
	$args{engine} ||= 'RDFS';
	
	my $model = RDF::Trine::Model->new($args{store});
	
	if (Scalar::Util::blessed($original_data))
	{
		# Coerce $original_data to be a stream.
		
		$original_data = RDF::Trine::Model->new($original_data)
			if $original_data->isa('RDF::Trine::Store');
		$original_data = $original_data->as_stream
			if $original_data->isa('RDF::Trine::Model');
		
		die("\$original_data cannot be a %s.\n", ref($original_data))
			unless $original_data->isa('RDF::Trine::Iterator::Graph');
		
		$original_data->each(sub { $model->add_statement($_[0]); });
	}
	
	my $engine = RDF::Closure::Engine->new($args{engine}, $model);
	$engine->closure;
	
	return bless {
		model    => $model, 
		engine   => $engine,
		bulkmode => 0,
		removals => 0,
		}, $class;
}

sub entailment_regime
{
	my ($self) = @_;
	return $self->_engine->entailment_regime;
}

sub recalculate
{
	my ($self) = @_;
	$self->{removals} = 0;
	$self->_engine->reset;
	$self->_engine->closure;
	return $self;
}

sub _engine
{
	return $_[0]->{engine};
}

sub _egraph
{
	return $_[0]->_engine->graph;
}

sub _reclose
{
	my ($self) = @_;
	
	if ($self->{removals})
	{
		$self->_engine->reset;
		$self->_engine->closure;
		$self->{removals} = 0;
	}
	else
	{
		$self->_engine->closure(1);
	}
}

sub temporary_model
{
	croak "temporary_model not implemented yet (RDF::Closure::Model)";
}

sub dataset_model
{
	croak "dataset_model not implemented yet (RDF::Closure::Model)";
}

sub begin_bulk_ops
{
	my ($self) = @_;
	$self->{bulkmode}++;
}

sub end_bulk_ops
{
	my ($self) = @_;
	if ($self->{bulkmode} > 0)
	{
		$self->{bulkmode}--;
		
		if ($self->{bulkmode} < 1)
		{
			$self->_reclose;
			$self->{bulkmode} = 0;
		}
	}
}

sub add_statement
{
	my ($self, @args) = @_;
	$self->_egraph->add_statement(@args);
	$self->_reclose
		unless $self->{bulkmode};
}

sub add_hashref
{
	my ($self, @args) = @_;
	$self->begin_bulk_ops;
	$self->_egraph->add_hashref(@args);
	$self->end_bulk_ops;
}

sub add_list
{
	my ($self, @args) = @_;
	$self->begin_bulk_ops;
	$self->_egraph->add_list(@args);
	$self->end_bulk_ops;
}

sub remove_statement
{
	my ($self, @args) = @_;
	$self->_egraph->remove_statement(@args);
	$self->{removals} = 1;
	$self->_reclose
		unless $self->{bulkmode};
}

sub remove_statements
{
	my ($self, @args) = @_;
	$self->_egraph->remove_statements(@args);
	$self->{removals} = 1;
	$self->_reclose
		unless $self->{bulkmode};
}

1;

=head1 NAME

RDF::Closure::Model - RDF::Trine::Model-compatible inferface

=head1 DESCRIPTION

This module provides a subclass of L<RDF::Trine::Model> allowing you to
dollop some reasoning into existing RDF::Trine code very easily. While
L<RDF::Closure::Engine> allows you to infer lots of new statements from an
existing model, this class also allows you to add and remove statements from
the reasoned model with new inferences calculated on-the-fly.

Removing a statement is much slower than adding one, though adding a
statement isn't what you'd call fast. Juditious use of C<begin_bulk_ops> and
C<end_bulk_ops> is recomnmended.

If a lot of statements have been added and removed from a model since it
was created, then it's theoretically possible for the inferred data to contain
statements which are no longer entailed by the explicit data, or for the
inferred data to be missing some inferences. A C<recalculate> method
is provided which allows you to re-run the inference from scratch.

=head2 Constructor

=over

=item * C<< new($input, [, engine => $engine ] [, store => $store ]) >>

Instantiates a module. $input may be undef, an existing L<RDF::Trine::Model>
or an L<RDF::Trine::Store>. The input will not be modified.

C<$engine> is the inference engine to use; a string suitable for passing to
C<< RDF::Closure::Engine->new >>; defaults to 'RDFS'.

C<$store> is an L<RDF::Trine::Store> to use to build the inferred model in;
defaults to a new, temporary store.

=back

=head2 Methods

This package inherits from L<RDF::Trine::Model> and provides all the
methods it does. It additionally provides:

=over

=item * C<< entailment_regime >>

Returns a URI string identifying the type of inference in use.

=item * C<< recalculate >>

Drops and re-infers all inferred data.

=back

=head1 SEE ALSO

L<RDF::Closure>,
L<RDF::Closure::Engine>,
L<RDF::Trine::Model>.

Take careful note of the C<begin_bulk_ops> and C<end_bulk_ops> methods
present in L<RDF::Trine::Model>. Judicious use of them can seriously speed up
this module.

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

