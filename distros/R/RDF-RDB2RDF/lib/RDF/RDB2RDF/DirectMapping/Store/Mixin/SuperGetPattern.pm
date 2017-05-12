package RDF::RDB2RDF::DirectMapping::Store::Mixin::SuperGetPattern;

use 5.010;
use strict;
use utf8;

use Scalar::Util qw[blessed reftype];

use namespace::clean;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.008';

# This was removed from RDF::Trine::Store. :-(
sub _SUPER_get_pattern
{
	my $self    = shift;
	my $bgp     = shift;
	my $context = shift;
	my @args    = @_;
	my %args    = @args;
	
	if ($bgp->isa('RDF::Trine::Statement')) {
		$bgp	= RDF::Trine::Pattern->new($bgp);
	}
	
	my %iter_args;
	my @triples = $bgp->triples;
	
	my ($iter);
	if (1 == @triples)
	{
		my $t        = shift @triples;
		my @nodes    = $t->nodes;
		my $size     = scalar @nodes;
		my %vars;
		my @names    = qw(subject predicate object context);
		foreach my $n (0 .. $#nodes)
		{
			if ($nodes[$n]->isa('RDF::Trine::Node::Variable'))
			{
				$vars{ $names[ $n ] } = $nodes[$n]->name;
			}
		}
		
		my $_iter = $self->get_statements(@nodes);
		if ($_iter->finished)
		{
			return RDF::Trine::Iterator::Bindings->new( [], [] );
		}
		
		my @vars = values %vars;
		my $sub = sub
		{
			my $row  = $_iter->next or return undef;
			my %data = map { $vars{$_} => eval { $row->$_ } } keys %vars;
			return RDF::Trine::VariableBindings->new(\%data);
		};
		
		$iter = RDF::Trine::Iterator::Bindings->new($sub, \@vars);
	}
	else
	{
		my $t    = shift(@triples);
		my $rhs  = $self->get_pattern( RDF::Trine::Pattern->new($t), $context, @args );
		my $lhs  = $self->get_pattern( RDF::Trine::Pattern->new(@triples), $context, @args );
		my @inner;
		while (my $row = $rhs->next)
		{
			push @inner, $row;
		}
		my @results;
		while (my $row = $lhs->next) {
			RESULT: foreach my $irow (@inner) {
				my %keysa;
				my @keysa = keys %$irow;
				@keysa{ @keysa } = (1) x scalar(@keysa);
				my @shared = grep { exists $keysa{ $_ } } keys %$row;
				KEY: foreach my $key (@shared) {
					my $val_a = $irow->{ $key };
					my $val_b = $row->{ $key };
					defined $val_a && defined $val_b
						or next KEY;
					$val_a->equal($val_b)
						or next RESULT;
				}
				
				my $jrow = { (map { $_ => $irow->{$_} } grep { defined($irow->{$_}) } keys %$irow), (map { $_ => $row->{$_} } grep { defined($row->{$_}) } keys %$row) };
				push @results, RDF::Trine::VariableBindings->new($jrow);
			}
		}
		$iter = RDF::Trine::Iterator::Bindings->new(
			\@results,
			[ $bgp->referenced_variables ]
		);
	}
	
	my $o = $args{orderby} or return $iter;
	
	unless (reftype($o) eq 'ARRAY')
	{
		throw RDF::Trine::Error::MethodInvocationError
			-text => "The orderby argument to get_pattern must be an ARRAY reference";
	}
	
	my @order;
	my %order;
	my @o = @$o;
	my @sorted_by;
	my %vars = map { $_ => 1 } $bgp->referenced_variables;
	if (scalar(@o) % 2 != 0)
	{
		throw RDF::Trine::Error::MethodInvocationError
			-text => "The orderby argument ARRAY to get_pattern must contain an even number of elements";
	}
	while (@o)
	{
		my ($k,$dir)	= splice @o, 0, 2, qw();
		next unless ($vars{ $k });
		unless ($dir =~ m/^ASC|DESC$/i)
		{
			throw RDF::Trine::Error::MethodInvocationError
				-text => "The sort direction for key $k must be either 'ASC' or 'DESC' in get_pattern call";
		}
		my $asc = ($dir eq 'ASC') ? 1 : 0;
		push @order, $k;
		$order{ $k } = $asc;
		push @sorted_by, $k, $dir;
	}
	
	my @results = $iter->get_all;
	@results = _sort_bindings( \@results, \@order, \%order );
	$iter_args{ sorted_by } = \@sorted_by;
	return RDF::Trine::Iterator::Bindings->new(
		\@results,
		[ $bgp->referenced_variables ],
		%iter_args,
	);
}

sub _sort_bindings
{
	my $res    = shift;
	my $o      = shift;
	my $dir    = shift;
	my @sorted =
		map { $_->[0] }
		sort { _sort_mapped_data($a,$b,$o,$dir) }
		map { _map_sort_data( $_, $o ) }
		@$res;
	return @sorted;
}

sub _sort_mapped_data
{
	my $a   = shift;
	my $b   = shift;
	my $o   = shift;
	my $dir = shift;
	foreach my $i (1 .. $#{ $a }){
		my $av    = $a->[ $i ];
		my $bv    = $b->[ $i ];
		my $key   = $o->[ $i-1 ];
		next unless defined $av || defined $bv;
		my $cmp   = RDF::Trine::Node::compare($av, $bv);
		unless ($dir->{ $key })
		{
			$cmp *= -1;
		}
		return $cmp if ($cmp);
	}
	return 0;
}

sub _map_sort_data
{
	my $res     = shift;
	my $o       = shift;
	my @data    = ($res, map { $res->{ $_ } } @$o);
	return \@data;
}

1;

__END__

=encoding utf8

=head1 NAME

RDF::RDB2RDF::DirectMapping::Store::Mixin::SuperGetPattern - provides functionality that was removed from RDF::Trine::Store 0.140

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=RDF-RDB2RDF>.

=head1 SEE ALSO

L<RDF::RDB2RDF>.

L<http://www.perlrdf.org/>.

=head1 AUTHOR

Gregory Todd Williams E<lt>gwilliams@cpan.orgE<gt>.

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT

Copyright 2006-2012 Gregory Todd Williams.

Copyright 2012-2013 Toby Inkster.

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

