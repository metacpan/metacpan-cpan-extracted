package Rope::Variant;

use strict;
use warnings;
use Combine::Keys qw/combine_keys/;
use Rope::Pro;
my (%PRO);

BEGIN {
	%PRO = Rope::Pro->new(
		find_from_given => sub {
			my ( $self, $set, $given) = @_;
			my $ref_given = ref $given;
			if ( $ref_given eq 'Type::Tiny' ) {
				$set = $given->($set);
				return $given->display_name eq 'Object' ? ref $set : $set;
			}
			elsif ( $ref_given eq 'CODE' ) {
				return $given->( $self, $set );
			}
			return $set;
		},
		struct_the_same => sub {
			my ($stored, $passed) = @_;
			my $stored_ref = ref($stored) || 'STRING';
			my $passed_ref = ref($passed) || 'STRING';
			$stored_ref eq $passed_ref or return undef;
			if ($stored_ref eq 'STRING') {
				return ($stored =~ m/^$passed$/) ? 1 : undef;
			} elsif ($stored_ref eq 'SCALAR') {
				return ($$stored =~ m/^$$passed$/) ? 1 : undef;
			} elsif ($stored_ref eq 'HASH') {
				for (combine_keys($stored, $passed)) {
					$stored->{$_} and $passed->{$_} or return undef;
					$PRO{struct_the_same}($stored->{$_}, $passed->{$_}) or return undef;    
				}
				return 1;
			} elsif ($stored_ref eq 'ARRAY') {
				my @count = (scalar @{$stored}, scalar @{$passed});
				$count[0] == $count[1] or return undef;
				for ( 0 .. $count[1] - 1 ) {
					$PRO{struct_the_same}($stored->[$_], $passed->[$_]) or return undef;
				}
				return 1;
			}
			return 1;
		}
	);
}

sub import {
	my ($caller) = (scalar caller);
	$PRO{keyword}($caller, 'variant', sub {
		my ($name, %definition) = @_;

		my ($meta, $variant, $exists) = (Rope->get_meta($caller), [], 0);
		if ($meta->{properties}->{$name}) {
			if ($meta->{properties}->{$name}->{variant}) {
				push @{$meta->{properties}->{$name}->{variant}->{when}}, @{$definition{when}};
				Rope->set_property($caller, $name, $meta->{properties}->{$name});	
				$exists = 1;
			} else {
				die "Cannot convert an existing property into a variant property";
			}
		}

		$caller->property($name,
			initable => 1,
			writeable => 1,
			variant => \%definition,
			trigger => sub {
				my ($self, $set) = @_;
				my $meta = Rope->get_meta($caller)->{properties}->{$name};
				my $find = $PRO{find_from_given}(@_, $meta->{variant}->{given});
				my @when = @{$meta->{variant}->{when}};
				while (scalar @when >= 2) {
					my ($check, $found) = (
						shift @when,
						shift @when
					);
					if ( $PRO{struct_the_same}($check, $find) ) {
						if ($found->{alias}) {
							if (ref $set ne 'HASH') {
								for my $alias ( keys %{ $found->{alias} } ) {
									next if $set->can($alias);
									my $actual = $found->{alias}->{$alias};
									{
										no strict 'refs';
										*{"${find}::${alias}"} = sub { goto &{"${find}::${actual}"} };
									}
								}
								return $set;
							} else {
								return { 
									map { $set->{$_} = $set->{$found->{alias}->{$_}} } keys %{ $found->{alias} }
								}
							}
						}
						elsif ($found->{run}) {
							my $run = $found->{run};
							return ref $run
								? $run->($self, $set)
								: $self->$run($set);
						}
					}
				}
			}
		) if !$exists;
	});
}

1;

__END__

=head1 NAME

Rope::Variant - Rope variant properties

=head1 VERSION

Version 0.42

=cut

=head1 SYNOPSIS

	package Variant;

	use Rope;
	use Rope::Autoload;
	use Rope::Variant;
	use Types::Standard qw/Str Object/

	variant parser => (
		given => Object,
		when => [
			'Test::Parser::One' => {
				alias => {
					parse_string => 'parse',
					# parse_file exists
				},
			},
			'Random::Parser::Two' => {
				alias => {
					# parse_string exists
					parse_file   => 'parse_from_file',
				},
			},
			'Another::Parser::Three' => {
				alias => {
					parse_string => 'meth_one',
					parse_file   => 'meth_two',
				},
			},
		],
	);

	variant string => (
		given => Str,
		when => [
			'one' => {
			    run => sub { return "$_[1] - cold, cold, cold inside" },
			},
			'two' => {
			    run => sub { return "$_[1] - don't look at me that way"; },
			},
			'three' => {
			    run => sub { return "$_[1] - how hard will i fall if I live a double life"; },
			},
		],
	);

	variant string => (
		when => [
			four => {
				run => sub {
					return "$_[1] - we can extend";
				}
			}
		]
	);

	...

	1;

...

	my $k = Variant->new();

	my $obj = Variant->new(
		string => 'one',
		parser => Test::Parser::One->new
	);

	$obj->string; # one - cold, cold, cold inside
	$obj->parser->parse_string; # lalala land

	$obj->string = 'two';
	$obj->parser = Random::Parser::Two->new();

	$obj->string; # two - don't look at me that way
	$obj->parser->parse_string; # lalala land 2


=head1 Exports

=cut

=head2 variant

=cut

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-rope at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Rope>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Rope

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Rope>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Rope>

=item * Search CPAN

L<https://metacpan.org/release/Rope>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2023 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
