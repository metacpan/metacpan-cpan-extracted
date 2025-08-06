package Params::Get;

use strict;
use warnings;

use Carp;
use Devel::Confess;
use Scalar::Util;

our @ISA = qw(Exporter);
our @EXPORT_OK = qw(get_params);

=head1 NAME

Params::Get - Get the parameters to a subroutine in any way you want

=head1 VERSION

Version 0.13

=cut

our $VERSION = '0.13';

=head1 DESCRIPTION

Exports a single function, C<get_params>, which returns a given value.
If a validation schema is provided, the value is validated using
L<Params::Validate::Strict>.
If validation fails, it croaks.

When used hand-in-hand with L<Return::Set> you should be able to formally specify the input and output sets for a method.

=head1 SYNOPSIS

    use Params::Get;
    use Params::Validate::Strict;

    sub where_am_i
    {
        my $params = Params::Validate::Strict::validate_strict({
            args => Params::Get::get_params(undef, \@_),
            schema => {
                'latitude' => {
                    type => 'number',
                    min => -180,
                    max => 180
                }, 'longitude' => {
                    type => 'number',
                    min => -180,
                    max => 180
                }
            }
        });

        print 'You are at ', $params->{'latitude'}, ', ', $params->{'longitude'}, "\n";
    }

    where_am_i(latitude => 0.3, longitude => 124);
    where_am_i({ latitude => 3.14, longitude => -155 });

=head1	METHODS

=head2 get_params

Parse the arguments given to a function.
Processes arguments passed to methods and ensures they are in a usable format,
allowing the caller to call the function in any way that they want
e.g. `foo('bar')`, `foo(arg => 'bar')`, `foo({ arg => 'bar' })` all mean the same
when called with

    get_params('arg', @_);

or

    get_params('arg', \@_);

Some people like this sort of model, which is also supported.

    use MyClass;

    my $str = 'hello world';
    my $obj = MyClass->new($str, { type => 'string' });

    package MyClass;

    use Params::Get;

    sub new {
        my $class = shift;
        my $rc = Params::Get::get_params('value', \@_);

        return bless $rc, $class;
    }

=cut

sub get_params
{
	# Directly return hash reference if the only parameter is a hash reference
	return $_[0] if((scalar(@_) == 1) && (ref($_[0]) eq 'HASH'));	# Note - doesn't check if "default" was given

	my $default = shift;

	my $args;
	my $array_ref;
	if((scalar(@_) == 1) && (ref($_[0]) eq 'ARRAY')) {
		if($default && (scalar(@{$_[0]}) == 2) && (@{$_[0]}[0] eq $default) && (!ref(@{$_[0]}[1]))) {
			# in main:
			#	routine('country' => 'US');
			# in routine():
			#	$params = Params::Get::get_params('country', \@);
			return { $default => @{$_[0]}[1] };
		}
		$args = $_[0];
		$array_ref = 1;
	} else {
		$args = \@_;
	}

	my $num_args = scalar(@{$args});

	# Populate %rc based on the number and type of arguments
	if($num_args == 1) {
		if(defined($default)) {
			if(!ref($args->[0])) {
				# %rc = ($default => shift);
				return { $default => $args->[0] };
			}
			if(ref($args->[0]) eq 'ARRAY') {
				return { $default => $args->[0] };
			}
			if(ref($args->[0]) eq 'SCALAR') {
				return { $default => ${$args->[0]} };
			}
			if(ref($args->[0]) eq 'CODE') {
				return { $default => $args->[0] };
			}
			if(Scalar::Util::blessed($args->[0])) {
				return { $default => $args->[0] };
			}
		}
		if(!defined($args->[0])) {
			return;
		}
		if(ref($args->[0]) eq 'REF') {
			$args->[0] = ${$args->[0]};
		}
		if(ref($args->[0]) eq 'HASH') {
			return $args->[0];
		}
		if((ref($args->[0]) eq 'ARRAY') && (scalar(@{$args->[0]}) == 0)) {
			# in main:
			#	routine('countries' => []);
			# in routine():
			#	$params = Params::Get::get_params('countries', \@);
			if(defined($default)) {
				return { $default => [] }
			}
			return $args->[0];
		}
		Carp::croak('Usage: ', __PACKAGE__, '->', (caller(1))[3], '()');
	}
	if($num_args == 0) {
		if(defined($default)) {
			# if(defined($_[0]) && (ref($_[0]) eq 'ARRAY')) {
				# FIXME
				# return { $default => [] };
			# }
			# FIXME: No means to say that the default is optional
			# Carp::croak('Usage: ', __PACKAGE__, '->', (caller(1))[3], "($default => \$val)");
			Carp::croak(Devel::Confess::longmess('Usage: ', __PACKAGE__, '->', (caller(1))[3], "($default => \$val)"));
		}
		return;
	}
	if(($num_args == 2) && (ref($args->[1]) eq 'HASH')) {
		if(defined($default)) {
			if(scalar keys %{$args->[1]}) {
				# Obj->new('foo', { 'key1' => 'val1' } - set foo to the mandatory first argument, and the rest are options
				return {
					$default => $args->[0],
					%{$args->[1]}
				};
			}
			# Obj->new(foo => {}) - set foo to be an empty hash
			return { $default => $args->[1] }
		}
	}

	if($array_ref && defined($default)) {
		return { $default => $args };
	}
	if(($num_args % 2) == 0) {
		my %rc = @{$args};
		return \%rc;
	}

	Carp::croak('Usage: ', __PACKAGE__, '->', (caller(1))[3], '()');
}

=head1 AUTHOR

Nigel Horne, C<< <njh at nigelhorne.com> >>

=head1 BUGS

Sometimes giving an array ref rather than array fails.

=head1 SEE ALSO

=over 4

=item * L<Params::Validate::Strict>

=item * L<Return::Set>

=back

=head1 SUPPORT

This module is provided as-is without any warranty.

Please report any bugs or feature requests to C<bug-params-get at rt.cpan.org>,
or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Params-Get>.
I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

You can find documentation for this module with the perldoc command.

    perldoc Params::Get

You can also look for information at:

=over 4

=item * MetaCPAN

L<https://metacpan.org/dist/Params-Get>

=item * RT: CPAN's request tracker

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Params-Get>

=item * CPAN Testers' Matrix

L<http://matrix.cpantesters.org/?dist=Params-Get>

=item * CPAN Testers Dependencies

L<http://deps.cpantesters.org/?module=Params::Get>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2025 Nigel Horne.

This program is released under the following licence: GPL2

=cut

1;

__END__
