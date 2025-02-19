package Terse::Model::Es;
use 5.006; use strict; use warnings;
our $VERSION = '0.03';
use base 'Terse::Model';

sub columns { }

sub attributes {
	$_[0]->{_attributes} ||= [
		qw/size page sorting group optional aggregation cols must_not fields/,
		keys %{ $_[0]->columns() }
	];
	return $_[0]->{_attributes};
}

sub index { }

sub has_column {
	my $columns = $_[0]->columns();
	return $columns->{$_[1]};
}

sub count {
	my ($self, $t) = @_;
	my $res = $t->plugin('es')->count($self->filter('count'));
	return $res->{count};
}

sub grouped {
	my ($self, $t, @g) = @_;
	$self->group = \@g;
	return $t->plugin('es')->search($self->filter('grouped'));
}

sub search {
	my ($self, $t, @g) = @_;
	return $t->plugin('es')->search($self->filter('search'));
}

sub filter {
	my ($self, $type) = @_;

	my $filter = {};
	my $optional = $self->optional;
	my @should = ();
	my %cols = %{ $self->columns() };
	if ($optional && scalar keys %{$optional}) {
		for my $o (sort keys %{$optional}) {
			if (ref $optional->{$o} && ref $optional->{$o} eq 'ARRAY') {
				# itterate the values
				for (@{$optional->{$o}}) {
					# and push into @should a phrase prefix query
					push @should, { prefix => { $o => $_ } };
				}
			} else {
				if ($cols{$o}->{alias}) {
					# if so push wth the correct aliased column
					push @should, {
						wildcard => {
							$cols{$o}->{alias} => '*' . quotemeta($optional->{$o}) . '*'
						}
					};
				} else {
				# else just push the wildcard query
					push @should, { wildcard => { $o => '*' . quotemeta($optional->{$o}) . '*' } };
				}
			}
		}
	}

	my (@must, @mustnot);
	for (keys %cols) {
		my $val = $self->can($_) && $self->$_;
		if (defined $val) {
			my %spec = (
				SCALAR => 'term',
				ARRAY => 'terms',
				%{ $cols{$_} }
			);
			my $ref = ref $val || 'SCALAR';
			my %must_not;
			%must_not = map { (ref $_ ? ( $_->[0] => $_->[1] ) : ($_ => 1)) } @{ $self->must_not }
				if $self->must_not;
			if ($must_not{$_}) {
				if (ref $must_not{$_}) {
					push @mustnot, $must_not{$_};
				} else {
					my $aa = $spec{alias} ? $spec{alias} : $_;
					push @mustnot, {
						($spec{$ref} ? ($spec{$ref} => {
							$aa => $val
						}) : ($aa => $val))
					};
				}
			} else {
				if (((ref $val) || "") eq 'HASH' && $val->{not_exists}) {
					push @must, {
						"bool" => {
							"should"=> [
								(($val->{val} && scalar @{$val->{val}}) ? (
								{
									"bool"=> {
										"must"=> [
											{
												"terms" => {
		                                                                                        $_ => $val->{val}
	                                                                                        }
	                                                                                }
	                                                                        ]
	                                                                }
	                                                        }) :()),
	                                                        {
	                                                                "bool"=> {
	                                                                        "must_not"=> [
	                                                                                {
	                                                                                        "exists"=> {
	                                                                                                "field"=> $_
	                                                                                        }
	                                                                                }
	                                                                        ]
	                                                                }
	                                                        }
	                   	                       ]
	                                        }
	                                };
	                        } else {
	                                my $aa = $spec{alias} ? $spec{alias} : $_;
	                                push @must, {
	                                        ($spec{$ref} ? ($spec{$ref} => {
	                                                $aa => $val
	                                        }) : ($aa => $val))
	                                };
	                        }
	                }
	        }
	}

	if (scalar @should) {
	        push @must, {bool => {should => \@should}};
	}

	if (scalar @must || scalar @mustnot) {
	        $filter->{query} = {
	                bool => {
	                        (scalar @must ? (must => \@must) : ()),
	                        (scalar @mustnot ? (must_not => \@mustnot) : ()),
	                }
	        };
	}

	my $aggs = $self->aggs;
	my $group = $filter;
	if ($type eq 'grouped') {
	        my ($groups) = $self->group;
	        if ($groups && scalar @{$groups}) {
	                for my $g (@{ $groups }) {
	                        $group = ($group->{aggs} ||= {});
	                        $group = ($group->{'group_by_' . $g} = {
	                                terms => { field => $g, size => 10000 },
	                                ($aggs && $aggs->{$g} ? ( aggs => $aggs->{$g} ) : ())
	                        });
	                }
	        }
	}}

	if ($type =~ m/search|grouped/) {
	        if (defined $self->size) {
	                $filter->{size} = $self->size;
	                $filter->{from} = (($self->page * $self->size) - $self->size) if defined $self->page;
	        }
	        $group->{aggs} = $aggs->{default} if (!$group->{aggs} && $aggs && $aggs->{default} && keys %{$aggs->{default}});

	        if (defined $self->fields) {
	                $filter->{script_fields} = $self->fields;
	                $filter->{_source} = \1;
	        }
	}

	if ($type eq 'search') {
	        my $sort = $self->sort;
	        if (scalar @{$sort}) {
	                $filter->{sort} = $self->sort;
	        }
	}

	return { index => $self->index, body => $filter };
}

sub clone {
	my ($self) = shift;
	my $clone = ref($self)->new(
		map +( $_ => $self->$_ ), @{ $self->attributes }
	);
	return $clone;
}

1;

__END__

=head1 NAME

Terse::Model::Es - Terse Elasticsearch Model

=head1 VERSION

Version 0.03

=cut

=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

	package MyApp::Model::Shiva;

	use base 'Terse::Model::Es';

	sub index { return 'shiva'; }

	sub columns { 
		$_[0]->{_columns} ||= {
			id => {
				display => 'ID',
				table => {
					response => 8,
					sort => 1
				}
			},
			name => {
				alias => 'name.keyword',
				display => 'Name',
				table => {
					response => 1,
					sort => 1,
				}
			},
			type => { ... },
			body => { ... }
		};
	}

	sub jokes {
		my ($self, $t) = ($_[0]->clone(), $_[1]);
		$self->size = 10;
		$self->type = 'joke';
		return $self->search($t);
	}

	1;

	__END__

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-terse-plugin-es at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Terse-Model-Es>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Terse::Model::Es


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Terse-Model-Es>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Terse-Model-Es>

=item * Search CPAN

L<https://metacpan.org/release/Terse-Model-Es>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2023 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

1; # End of Terse::Model::Es
