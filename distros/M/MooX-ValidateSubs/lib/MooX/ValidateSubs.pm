package MooX::ValidateSubs;

use strict;
use warnings;

use MooX::ReturnModifiers;

our $VERSION = '1.012000';

sub import {
	my $target	= caller;
	my %modifiers = return_modifiers($target);

	my $validate_subs = sub {
		my @attr = @_;
		while (@attr) {
			my @names = ref $attr[0] eq 'ARRAY' ? @{ shift @attr } : shift @attr;
			my $spec = shift @attr;
			for my $name (@names) {
				my $store_spec = sprintf '%s_spec', $name;
				$modifiers{has}->( $store_spec => ( is => 'ro', default => sub { $spec } ) );
				unless ( $name =~ m/^\+/ ) {
					$modifiers{around}->(
						$name,
						sub {
							my ( $orig, $self, @params ) = @_;
							my $current_spec = $self->$store_spec;

							if ( my $param_spec = $current_spec->{params} ) {
								@params = $self->_validate_sub(
									$name, 'params', $param_spec, @params
								);
							}

							@params = $self->$orig(@params);

							if ( my $param_spec = $current_spec->{returns} ) {
								@params = $self->_validate_sub(
									$name, 'returns', $param_spec, @params
								);
							}

							return wantarray ? @params : shift @params;
						}
					);
				}
			}
		}
	};

	$target->can('_validate_sub') or $modifiers{with}->('MooX::ValidateSubs::Role');

	{
		no strict 'refs';
		*{"${target}::validate_subs"} = $validate_subs;
	}

	return 1;
}

1;

__END__

=head1 NAME

MooX::ValidateSubs - Validating sub routines via Type::Tiny.

=head1 VERSION

Version 1.012000

=cut

=head1 SYNOPSIS

	package Welcome::To::A::World::Of::Types;

	use Moo;
	use MooX::ValidateSubs;
	use Types::Standard qw/Str ArrayRef HashRef/;

	validate_subs (
		hello_world => {
			params => {
				one   => [ Str, 1 ], # 1 means I'm optional
				two   => [ ArrayRef ],
				three => [ HashRef, 'before_add_me' ],
			},
			returns => {
				one   => [ Str, 1 ], # 1 means I'm optional
				two   => [ ArrayRef ],
				three => [ HashRef ],
				four  => [ Str, 'add_on' ],
			},
		},
		goodbye_world => { params => [ [Str], [ArrayRef], [HashRef] ] },
	);

	sub before_add_me {
		return {
			okay => 'fine',
		};
	}

	sub add_on {
		return 'sad face';
	}

	sub hello_world {
		my ($self, %args) = @_;

		# $args{one}	# optional string
		# $args{two}	# valid arrayref
		# $args{three}  # valid hashref

		if ( ... # some condition ... ) {
			$args{four} = 'may or may not get set here';
		}

		return %args;
	}

=head1 Exports

=head2 validate_subs

I'm a key/value list, my keys should reference a sub routine, My value must now be a hash reference that
can contain two *optional* keys (params and returns).

	validate_subs (
		hash_example => {
			params => { ... },
			returns => { ... },
		},
		array_example => {
			params => [ ... ],
			returns => [ ... ],
		}
	);

Both params and returns value can either be an array reference of array references, that indicates we are going
to be validating either an Array or an Array Reference,

	array_example => {
		params => [ [Str], [HashRef], [Str] ],
		returns => [ [Str], [HashRef] ],
	},

	...

	sub array_example {
		my ($self) = shift;
		return (shift, shift);
	}

Or a hash reference with array reference values, when validating either a Hash or Hash reference.

	hash_example => {
		params => {
			one => [ Str ],
			two => [ HashRef ],
		},
		returns => {
			one => [ Str ],
			two => [ HashRef ],
			three => [ Str ],
		},
	},

	...

	sub hash_example {
		my ($self, %hash) = @_;
		$hash{three} = 'add a key';
		return %hash;
	}

The array references must always have a first index that is a code reference, you can optionally pass a second index that can
either be 1, which indicates *optional*, a scalar that reference a subroutine/attribute available to *self* or a code reference
that gets used to fill a default value if one was not passed.

	params => {
		one => [ Str, sub { 'Hello World' } ],
		two => [ Str, 'basics' ],
	},
	returns => [ [Str], [Str], [Str, 'say_goodbye'],

	....

	has basics => (
		is => 'ro',
		default => sub { "How are you" },
	);

	sub say_goodbye {
		my ($self) = shift;
		return 'In a rush, goodbye.';
	}

	sub example {
		my ($self, %hash) = @_;
		return values %hash;
	}

...

=head1 Breaking things

I decided to make some breaking changes so 0.07++ syntax is not compatible with 0.06--. I also changed from
*before* to *around* as I want to modify $args. If you prefer the *before* approach it can currently be found here -
L<https://github.com/ThisUsedToBeAnEmail/MooX-TypeParams>.

=head1 AUTHOR

Robert Acock, C<< <thisusedtobeanemail at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-moox-validatesubs at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=MooX-ValidateSubs>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

	perldoc MooX::ValidateSubs

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=MooX-ValidateSubs>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/MooX-ValidateSubs>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/MooX-ValidateSubs>

=item * Search CPAN

L<http://search.cpan.org/dist/MooX-ValidateSubs/>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

Copyright 2017 Robert Acock.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut

1; # End of MooX::ValidateSubs
