package Rope;

use 5.006; use strict; use warnings;
our $VERSION = '0.05';

use Rope::Object;
my (%META, %PRO);
our @ISA;
BEGIN {
	%PRO = (
		keyword => sub {
			my ($caller, $method, $cb) = @_;
			no strict 'refs';
			*{"${caller}::${method}"} = $cb;
		},
		scope => sub {
			my ($self, %props) = @_;
			for (keys %{$props{properties}}) {
				$props{properties}->{$_} = {%{$props{properties}{$_}}};
				if ($props{properties}{$_}{value} && ref $props{properties}{$_}{value} eq 'CODE') {
					my $cb = $props{properties}{$_}{value};
					$props{properties}{$_}{value} = sub { $cb->($self, @_) };
				}
			}
			return \%props;
		},
		clone => sub {
			my $obj = shift;
			my $ref = ref $obj;
			return $obj if !$ref;
			return [ map { $PRO{clone}->($_) } @{$obj} ] if $ref eq 'ARRAY';
			return { map { $_ => $PRO{clone}->($obj->{$_}) } keys %{$obj} } if $ref eq 'HASH';
			return $obj;
		},
		set_prop => sub {
			my ($caller, $prop, %options) = @_;
			if ($META{$caller}{properties}{$prop}) {
				if ($META{$caller}{properties}{$prop}{writeable}) {
					$META{$caller}{properties}{$prop}{value} = $options{value};
					$META{$caller}{properties}{$prop}{class} = $caller;
				} elsif ($META{$caller}{properties}{$prop}{configurable}) {
					if ((ref($META{$caller}{properties}{$prop}{value}) || "") eq (ref($options{value}) || "")) {
						$META{$caller}{properties}{$prop}{value} = $options{value};
						$META{$caller}{properties}{$prop}{class} = $caller;
					} else {
						die "Cannot inherit $META{$caller}{properties}{$prop}{class} and change property $prop type";
					}
				} else {
					die "Cannot inherit $META{$caller}{properties}{$prop}{class} and change property $prop type";
				}
			} else {
				$META{$caller}{properties}{$prop} = {
					%options,
					class => $caller,
					index => ++$META{$caller}{keys}
				};
			}
		},
		requires => sub {
			my ($caller) = shift;
			return sub {
				my (@requires) = @_;
				$META{$caller}{requires}{$_}++ for (@requires);
			};
		},
		function => sub {
			my ($caller) = shift;
			return sub {
				my ($prop, @options) = @_;
				$prop = shift @options if ( @options > 1 );
				$PRO{set_prop}(
					$caller,
					$prop,
					value => $options[0],
					enumerable => 0,
					writeable => 0,
					configurable => 1
				);
			};
		},
		property => sub {
			my ($caller) = shift;
			return sub {
				my ($prop, @options) = @_;
				if (scalar @options % 2) {
					$prop = shift @options;
				}
				$PRO{set_prop}(
					$caller,
					$prop,
					@options
				);
			};
		},
		prototyped => sub {
			my ($caller) = shift;
			return sub {
				my (@proto) = @_;
				while (@proto) {
					my ($prop, $value) = (shift @proto, shift @proto);
					$PRO{set_prop}(
						$caller,
						$prop,
						enumerable => 1,
						writeable => 1,
						configurable => 1,
						value => $value
					);
				}
			}
		},
		with => sub {
			my ($caller) = shift;
			return sub {
				my (@withs) = @_;
				for my $with (@withs) {
					if (!$META{$with}) {
						(my $name = $with) =~ s!::!/!g;
						$name .= ".pm";
						CORE::require($name);
					}
					my $initial = $META{$caller};
					my $merge = $PRO{clone}($META{$with});
					$merge->{name} = $initial->{name};
					$merge->{locked} = $initial->{locked};
					for (keys %{$initial->{properties}}) {
						$initial->{properties}->{$_}->{index} = ++$merge->{keys};
						if ($merge->{properties}->{$_}) {
							if ($merge->{properties}->{writeable}) {
								$merge->{properties}->{$_} = $initial->{properties}->{$_};
							} elsif ($merge->{properties}->{configurable}) {
								if ((ref($merge->{properties}->{$_}->{value}) || "") eq (ref($initial->{properties}->{$_}->{value} || ""))) {
									$merge->{properties}->{$_} = $initial->{properties}->{$_};
								} else {
									die "Cannot include $with and change property $_ type";
								}
							} else {
								die "Cannot include $with and override property $_";
							}
						} else {
							$merge->{properties}->{$_} = $initial->{properties}->{$_};
						}
					}
					$merge->{requires} = {%{$merge->{requires}}, %{$initial->{requires}}};
					$META{$caller} = $merge;
				}
			}
		},
		extends => sub {
			my ($caller) = shift;
			return sub {
				my (@extends) = @_;
				for my $extend (@extends) {
					if (!$META{$extend}) {
						(my $name = $extend) =~ s!::!/!g;
						$name .= ".pm";
						CORE::require($name);
					}
					my $initial = $META{$caller};
					my $merge = $PRO{clone}($META{$extend});
					$merge->{name} = $initial->{name};
					$merge->{locked} = $initial->{locked};
					for (keys %{$initial->{properties}}) {
						$initial->{properties}->{$_}->{index} = ++$merge->{keys};
						if ($merge->{properties}->{$_}) {
							if ($merge->{properties}->{writeable}) {
								$merge->{properties}->{$_} = $initial->{properties}->{$_};
							} elsif ($merge->{properties}->{configurable}) {
								if ((ref($merge->{properties}->{$_}->{value}) || "") eq (ref($initial->{properties}->{$_}->{value} || ""))) {
									$merge->{properties}->{$_} = $initial->{properties}->{$_};
								} else {
									die "Cannot inherit $extend and change property $_ type";
								}
							} else {
								die "Cannot inherit $extend and override property $_";
							}
						} else {
							$merge->{properties}->{$_} = $initial->{properties}->{$_};
						}
					}
					$merge->{requires} = {%{$merge->{requires}}, %{$initial->{requires}}};
					my $isa = '@' . $caller . '::ISA';
					eval "push $isa, '$extend'";
					$META{$caller} = $merge;
				}
			}
		},
		new => sub {
			my ($caller) = shift;
			return sub {
				my ($class, %params) = @_;
				my $self = \{
					prototype => {},
				};
				$self = bless $self, $caller;
				tie %{${$self}->{prototype}}, 'Rope::Object', $PRO{scope}($self, %{$META{$caller}});
				for (keys %params) {
					$self->{$_} = $params{$_};
				}
				return $self;
			};
		}
	);
}

sub import {
	my ($pkg, $options, $caller) = (shift, {@_}, caller());
	return if $options->{no_import};
	$caller = $options->{caller} if $options->{caller};
	if (!$META{$caller}) {
		$META{$caller} = {
			name => $caller,
			locked => 0,
			properties => {},
			requires => {},
			keys => 0
		};
	}
	$PRO{keyword}($caller, '((', sub {});
	$PRO{keyword}($caller, '(%{}', sub {
		${$_[0]}->{prototype};
	});
	$PRO{keyword}($caller, $_, $PRO{$_}($caller))
		for $options->{import} 
			? @{$options->{import}} 
			: qw/function property prototyped extends with requires new/;
}

1;

__END__

=head1 NAME

Rope - Tied objects

=head1 VERSION

Version 0.05

=cut

=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.


	package Knot;

	use Rope;

	prototyped (
		loops => 1,
		hitches => 10,
		...

	);

	properties {
		bends => {
			type => sub { $_[0] =~ m/^\d+$/ ? $_[0] : die "$_[0] != integer" },
			value => 10,
			writeable => 0,
			configurable => 1,
			enumerable => 1,
		},
		...
	};

	function add_loops => sub {
		my ($self, $loop) = @_;
		$self->{loops} += $loop;
	};

	1;

...

	my $k = Knot->new();

	say $k->{loops}; # 1;
	
	$k->{add_loops}(5);

	say $k->{loops}; # 6;

	$k->{add_loops} = 5; # errors

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

1; # End of Rope
