package SQL::Abstract::Plugin::TableAlias;
use strict; use warnings; our $VERSION = '0.05';
use Moo;

with 'SQL::Abstract::Role::Plugin';

sub register_extensions {
	my ($self, $sqla) = @_;
	$sqla->plugin('+ExtraClauses');
	$sqla->wrap_expander(select => sub {
		$self->cb('_alias_select', $_[0]);
	});
}

sub _alias_select {
	my ($self, $orig, $select, $args) = @_;
	$args = $self->_alias_from_array($args) if (ref $args eq 'HASH' && ref $args->{from} eq 'ARRAY');
	return $self->sqla->$orig($select, $args);
}

sub _alias_from_array {
	my ($self, $args) = @_;

	$args->{talias} ||= [];

	my ($i, @map, %columns) = 0;
	for my $from (@{ $args->{from} }) {
		my $ref = ref $from || "";
		if ( $ref eq 'HASH' ) {
			if ($from->{to}) {
				$from->{as} ||= scalar @{$args->{talias}} ? shift(@{$args->{talias}}) : ref $from->{to} ? $from->{to}->{-ident}->[0] : $from->{to};
				push @map, $from->{as};
				if ($from->{on}) {
					if ($from->{on}->{-op}) {
						if (scalar @{$from->{on}->{-op}->[1]->{-ident}} == 1) {
							unshift @{$from->{on}{-op}[1]{-ident}}, $map[-2];
						}
						if (scalar @{$from->{on}->{-op}->[2]->{-ident}} == 1) {
							unshift @{$from->{on}{-op}[2]{-ident}}, $map[-1];
						}
					} else {
						for my $on (keys %{$from->{on}}) {
							if (ref $from->{on}->{$on}) {
								for my $oo (keys %{$from->{on}->{$on}}) {
									$from->{on}->{$on}->{$oo} = sprintf("%s.%s", $map[-1], $from->{on}->{$on}->{$oo});
								}
							}
							$from->{on}->{sprintf("%s.%s", $map[-2], $on)} = delete $from->{on}->{$on};
						}
					}
				}
			} else {
				push @map, $from->{$_}->{-as} ||= shift(@{$args->{talias}}) || $_ 
					for ( sort keys %{ $from } );
			}
		} elsif ($ref eq 'ARRAY') {
			if ($from->[1] eq 'as') {
				push @map, $from->[2];
			} else {
				push @map, shift @{$args->{talias}} || $from->[0];
				splice @{$from}, 1, 0, 'as', $map[-1];
			}
			for my $key ( keys %{ $from->[-1] } ) {
				$from->[-1]->{_valid_column($key, $map[-2], {})} = _valid_column(delete $from->[-1]->{$key}, $map[-1], {});
			}
		} elsif (!$ref && $from !~ m/^-/) {
			push @map, shift @{$args->{talias}} || $from;
			splice @{$args->{from}}, $i, 1, { $from => { 'as' => $map[-1] } };
		}
		$i++;
	}

	($args, %columns) = $self->_alias_select_array($args, \@map)
		if ((ref($args->{select}) || "") eq 'ARRAY');
	
	my $where = ref $args->{where};
	$where eq 'HASH' 
		? $self->_alias_where_hash($args, $map[0], \%columns)
		: $where eq 'ARRAY' && $self->_alias_where_array($args, $map[0], \%columns);

	my $order_by = ref $args->{order_by};
	$order_by eq 'HASH' 
		? $self->_alias_order_by_hash($args, $map[0], \%columns)
		: $order_by eq 'ARRAY'
			? $self->_alias_order_by_array($args, $map[0], \%columns)
			: defined $args->{order_by} && ! ref $order_by && $self->_alias_order_by_string($args, $map[0], \%columns);

	my $group_by = ref $args->{group_by};
	$group_by eq 'ARRAY'
		? $self->_alias_group_by_array($args, $map[0], \%columns)
		: $group_by eq 'HASH' && $self->_alias_group_by_hash($args, $map[0], \%columns);

	return $args;
}

sub _alias_select_array {
	my ($self, $args, $map) = @_;
	my ($i, $last_array, @select, %columns) = -1;
	for my $sel ( @{ $args->{select} } ) {
		my $ref = ref $sel;
		if ( $ref eq 'ARRAY' ) {
			$i++; 
			for (my $l = 0; $l < scalar @{$sel}; $l++) {
				if (ref($sel->[$l]) || "" eq "HASH") {
					for my $key ( keys %{ $sel->[$l] } ) {
						$sel->[$l]{_valid_column($key, $map->[$i], {})} = delete $sel->[$l]{$key};
						$columns{$key} = $map->[$i];
					}
					push @select, $sel->[$l];
				} else {
					$columns{$sel->[$l]} = $map->[$i];
					push @select, sprintf("%s.%s", $map->[$i], $sel->[$l]);
				}
			}
			$last_array = 1;
		} elsif ( $ref eq 'HASH' ) {
			$i++ if $i < 0 || $last_array && do { $last_array = 0; 1; };
			for my $key ( keys %{ $sel } ) {
				$sel->{_valid_column($key, $map->[$i], {})} = delete $sel->{$key};
				$columns{$key} = $map->[$i];
			}
			push @select, $sel;
		} elsif (! $ref) {
			$i++ if $i < 0 || $last_array && do { $last_array = 0; 1; };
			$columns{$sel} = $map->[$i];
			push @select, sprintf("%s.%s", $map->[$i], $sel);
		}
	}
	$args->{select} = \@select;
	return ($args, %columns);
}

sub _alias_where_hash {
	my ($self, $args, $default, $columns) = @_;
	my %where;
	for my $w (keys %{ $args->{where} }) {
		if (ref $args->{$w} eq 'HASH' && $args->{$w}->{-alias}) {
			$where{sprintf("%s.%s", delete $args->{where}->{$w}->{-alias}, $w)} = $args->{where}->{$w};
		} else {
			$where{_valid_column($w, $default, $columns)} = $args->{where}->{$w};
		}
	}
	$args->{where} = \%where;
	return $args;
}

sub _alias_where_array {
	my ($self, $args, $default, $columns) = @_;
	my $list = grep { $_ % 2 > 0 && $args->{where}->[$_] =~ m/-(and|or)/ }  0 .. scalar @{ $args->{where} };
	return $self->_alias_where_list($args, $default, $columns) if $list;  
	for my $where (@{ $args->{where} }) {
		my $ref = ref $where || "";
		if ( $ref eq 'HASH' ) {
			my $update = $self->_alias_where_hash({ where => $where }, $default, $columns);	
			%{$where} = %{$update->{where}};
		}
	}
	return $args;
}

sub _alias_order_by_hash {
	my ($self, $args, $default, $columns) = @_;
	my %order_by;
	for my $w (keys %{ $args->{order_by} }) {
		my $ref = ref $args->{order_by}->{$w};
		if ($ref eq 'ARRAY') {
			my @order;
			for my $o ( @{ $args->{order_by}->{$w} } ) {
				push @order, _valid_column($o, $default, $columns);
			}
			$order_by{$w} = \@order;
		} elsif ( ! $ref ) {
			$order_by{$w} = _valid_column($args->{order_by}{$w}, $default, $columns);
		}
	}
	$args->{order_by} = \%order_by;
	return $args;
}

sub _alias_order_by_array {
	my ($self, $args, $default, $columns) = @_;
	my $i = 0;
	for my $w ( @{ $args->{order_by} }) {
		my $ref = ref $w || "";
		if ($ref eq 'HASH') { 
			my $new = $self->_alias_order_by_hash({ order_by => $w }, $default, $columns);
			%{$w} = %{$new->{order_by}};		
		} else {
			$args->{order_by}->[$i] = _valid_column($w, $default, $columns);	
		}
		$i++;
	}
	return $args;
}

sub _alias_order_by_string {
	my ($self, $args, $default, $columns) = @_;
	$args->{order_by} = _valid_column($args->{order_by}, $default, $columns);
}

sub _alias_group_by_array {
	my ($self, $args, $default, $columns) = @_;
	my @group_by;
	for my $group (@{ $args->{group_by} }) {
		push @group_by, _valid_column($group, $default, $columns);
	}
	$args->{group_by} = \@group_by;
	return $args;
}

sub _alias_group_by_hash {
	my ($self, $args, $default, $columns) = @_;
	my @group_by = shift @{ $args->{group_by}->{-op} };
	for my $group (@{ $args->{group_by}->{-op} }) {
		$group->{-ident} = ref $group->{-ident} ? [map {
			_valid_column($_, $default, $columns);
		} @{$group->{-ident}}] : _valid_column($group->{-ident}, $default, $columns);
		push @group_by, $group;
	}
	$args->{group_by}->{-op} = \@group_by;
	return $args;
}

sub _valid_column {
	my ($column, $default, $columns) = @_;
	return $column if ($column =~ m/[^.]+\W+/);
	return sprintf( "%s.%s", ($columns->{$column} || $default), $column);
}

1;

__END__

=head1 NAME

SQL::Abstract::Plugin::TableAlias - automagical table aliasing

=head1 VERSION

Version 0.05

=cut

=head1 SYNOPSIS

	use SQL::Abstract;

	my $sql = SQL::Abstract->new->plugin('+TableAlias');
		
	my ($stmt, @bind) = $sql->select({
		select => [ qw/one two three/, [qw/four five/], [qw/six seven eight/] ],
		from => [
			"already",
			-join => [
				aware => on => { one => "one" }
			],
			-join => {
				on => { two => { ">" => "other" } },
				to => "first",
				type => "left"
			}
		],
		where => {
			five => "A",
			six => "B",
			nine => "C"
		},
		order_by => [
			qw/one/,
			{ -asc => 'four' },
			{ -desc => [qw/three seven/] }
		],
	});

produces:

	SELECT 
		already.one,
		already.two,
		already.three,
		aware.four,
		aware.five,
		first.six,
		first.seven,
		first.eight 
	FROM already AS already 
		JOIN aware AS aware ON already.one = aware.one 
		LEFT JOIN first AS first ON aware.two > first.other 
	WHERE ( first.six = ? AND aware.five = ? AND already.nine = ? ) 
	ORDER BY already.one, aware.four ASC, already.three DESC, first.seven DESC

setting talias:

	my ($stmt, @bind) = $sql->select({
		talias => [qw/n i f/],
		select => [ qw/one two three/, [qw/four five/], [qw/six seven eight/] ],
		from => [
			"already",
			-join => [
				aware => on => { one => "one" }
			],
			-join => {
				on => { two => { ">" => "other" } },
				to => "first",
				type => "left"
			}
		],
		where => {
			five => "A",
			six => "B",
			nine => "C"
		},
		order_by => [
			qw/one/,
			{ -asc => 'four' },
			{ -desc => [qw/three seven/] }
		],
	});

produces:

	SELECT 
		n.one,
		n.two,
		n.three,
		i.four,
		i.five,
		f.six,
		f.seven,
		f.eight 
	FROM already AS n 
		JOIN aware AS i ON n.one = i.one 
		LEFT JOIN first AS f ON i.two > f.other 
	WHERE ( f.six = ? AND i.five = ? AND n.nine = ? ) 
	ORDER BY n.one, i.four ASC, n.three DESC, f.seven DESC

you know who you are.

=head1 DESCRIPTION

This module is an extension of the L<SQL::Abstract::Plugin::ExtraClauses> plugin, it's objective is to assist with the aliasing of tables.

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-sql-abstract-plugin-tablealias at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=SQL-Abstract-Plugin-TableAlias>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc SQL::Abstract::Plugin::TableAlias

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=SQL-Abstract-Plugin-TableAlias>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/SQL-Abstract-Plugin-TableAlias>

=item * Search CPAN

L<https://metacpan.org/release/SQL-Abstract-Plugin-TableAlias>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

I've not forgotten.

This software is Copyright (c) 2022 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

1; # End of SQL::Abstract::Plugin::TableAlias
