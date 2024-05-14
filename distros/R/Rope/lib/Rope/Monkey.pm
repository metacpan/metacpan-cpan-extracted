package Rope::Monkey;
use strict;
use warnings;
use Want;
my (%PRO);

BEGIN {
	%PRO = (
		keyword => sub {
			my ($caller, $method, $cb) = @_;
			no strict 'refs';
			*{"${caller}::${method}"} = $cb;
		},
		monkey_patch => sub {
			my ($caller, $meta, $build) = @_;
			for my $key (keys %{$meta}) {
				$caller->CORE::can($key) || $PRO{keyword}($caller, $key, $PRO{monkey_patch_sub}($key));
				if ($build) {
					for (qw/predicate clearer/) {
						if ($meta->{$key}->{$_}) {
							my $prep = $_ eq 'predicate' ? 'has_' : 'clear_';
							my $pred = $meta->{$key}->{$_};
							my $ref = ref($pred);
							$pred = !$ref && $pred !~ m/^\d+$/
								? $pred
								: $ref eq 'HASH' && $pred->{name}
									? $pred->{name}
									: "$prep$key";
							$caller->can($pred) || $PRO{keyword}($caller, $pred, $PRO{monkey_patch_sub}($pred));
						}
					}
					for my $handle (keys %{$meta->{$key}->{handles}}) {
						$PRO{keyword}($caller, $handle, sub { 
							my ($self) = shift;
							my $meth = $meta->{$key}->{handles}->{$handle};
							$self->{$key}->$meth(@_);
						});
					}
				}
			}
		},
		monkey_patch_sub => sub {
			my $key = shift;
			return sub :lvalue {
				my ($self) = shift;
				return $self->{$key}(@_) if !want(qw'LVALUE ASSIGN') && ref $self->{$key} eq 'CODE'; 
				$self->{$key} = $_[0] if defined $_[0];
				return $self->{$key};
			};
		}
	);
}

sub import {
	my $caller = scalar(caller);
	$PRO{keyword}($caller, 'monkey', sub {
		my $self = shift;
		if (ref $self) {
			while (@_) {
				my ($prop, $options) = (shift @_, shift @_);
				$self->{$prop} = $options;
				$PRO{monkey_patch}($caller, { $prop => 1 });
			}
		} else {
			my $meta = Rope->get_meta($caller);
			$PRO{monkey_patch}($caller, $meta->{properties}, 1);
		}
	});
}

1;

=head1 NAME

Rope::Monkey - Rope Monkey Patching

=head1 VERSION

Version 0.35

=cut

=head1 SYNOPSIS

	package Knot;

	use Rope;
	use Rope::Monkey;

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
		$self->loops += $loop;
	};

	monkey; # THIS IS IMPORTANT AND SHOULD COME AT THE END OF YOUR DEFINITION

	1;

...

	my $k = Knot->new();

	say $k->loops; # 1;

	$k->add_loops(5);

	say $k->loops; # 6;

	$k->hitches = 15;
	
	$k->add_loops = 5; # errors

	$k->monkey(extending => 'okay', another => { writeable => 1 });

=head1 Description

I once had a conversation with an individual about how Autoloading was evil so here is a monkey patch version, which I personally think is as evil. I believe me and that individual have been through more than anyone else can comprehend in the modern world that we live in. Although we had very different outcomes from the process, they should understand I think this way but perhaps I am wrong to. They should find my book on the biggest book store in the world, like the rest of you. I can only speak for my truth.

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

1; # End of Rope::Autoload
