package Mo::utils::CSS;

use base qw(Exporter);
use strict;
use warnings;

use Error::Pure qw(err);
use Graphics::ColorNames::CSS;
use List::Util 1.33 qw(any none);
use Mo::utils 0.31 qw(check_array);
use Mo::utils::Number::Utils qw(sub_check_percent);
use Readonly;

Readonly::Array our @EXPORT_OK => qw(check_array_css_color check_css_border
	check_css_class check_css_color check_css_unit);
Readonly::Array our @ABSOLUTE_LENGTHS => qw(cm mm in px pt pc);
Readonly::Array our @BORDER_GLOBAL => qw(inherit initial revert revert-layer unset);
Readonly::Array our @BORDER_STYLES => qw(none hidden dotted dashed solid double groove ridge inset outset);
Readonly::Array our @BORDER_WIDTHS => qw(thin medium thick);
Readonly::Array our @RELATIVE_LENGTHS => qw(em ex ch rem vw vh vmin vmax %);
Readonly::Array our @COLOR_FUNC => qw(rgb rgba hsl hsla);

our $VERSION = 0.12;

sub check_array_css_color {
	my ($self, $key) = @_;

	if (! exists $self->{$key}) {
		return;
	}

	check_array($self, $key);

	foreach my $css_color (@{$self->{$key}}) {
		_check_color($css_color, $key);
	}

	return;
}

sub check_css_border {
	my ($self, $key) = @_;

	_check_key($self, $key) && return;

	# Global values.
	if (any { $self->{$key} eq $_ } @BORDER_GLOBAL) {
		return;
	}

	my @parts = split m/\s+/ms, $self->{$key}, 3;
	if (@parts == 1) {
		_check_border_style($self->{$key}, $key);
	} elsif (@parts == 2) {

		# Border style on first place.
		if (any { $parts[0] eq $_ } @BORDER_STYLES) {
			_check_color($parts[1], $key, $self->{$key});

		# Border style on second place.
		} elsif (any { $parts[1] eq $_ } @BORDER_STYLES) {
			if (none { $parts[0] eq $_ } @BORDER_WIDTHS) {
				_check_unit($parts[0], $key, $self->{$key});
			}

		} else {
			err "Parameter '$key' hasn't border style.",
				'Value', $self->{$key},
			;
		}
	} else {
		if (none { $parts[0] eq $_ } @BORDER_WIDTHS) {
			_check_unit($parts[0], $key, $self->{$key});
		}
		_check_border_style($parts[1], $key, $self->{$key});
		_check_color($parts[2], $key, $self->{$key});
	}

	return;
}

sub check_css_class {
	my ($self, $key) = @_;

	_check_key($self, $key) && return;

	if ($self->{$key} !~ m/^[a-zA-Z0-9\-_]+$/ms) {
		err "Parameter '$key' has bad CSS class name.",
			'Value', $self->{$key},
		;
	} elsif ($self->{$key} =~ m/^\d/ms) {
		err "Parameter '$key' has bad CSS class name (number on begin).",
			'Value', $self->{$key},
		;
	}

	return;
}

sub check_css_color {
	my ($self, $key) = @_;

	_check_key($self, $key) && return;

	_check_color($self->{$key}, $key);

	return;
}

sub check_css_unit {
	my ($self, $key) = @_;

	_check_key($self, $key) && return;

	_check_unit($self->{$key}, $key);

	return;
}

sub _check_alpha {
	my ($alpha, $key, $func, $error_value) = @_;

	if ($alpha !~ m/^[\d\.]+$/ms || $alpha > 1) {
		err "Parameter '$key' has bad $func alpha.",
			'Value', $error_value,
		;
	}

	return;
}

sub _check_border_style {
	my ($value, $key, $error_value) = @_;

	if (! defined $error_value) {
		$error_value = $value;
	}

	if (none { $value eq $_ } @BORDER_STYLES) {
		err "Parameter '$key' has bad border style.",
			'Value', $error_value,
		;
	}

	return;
}

sub _check_color {
	my ($value, $key, $error_value) = @_;

	if (! defined $error_value) {
		$error_value = $value;
	}

	my $funcs = join '|', @COLOR_FUNC;
	if ($value =~ m/^#(.*)$/ms) {
		my $rgb = $1;
		if (length $rgb == 3 || length $rgb == 6 || length $rgb == 8) {
			if ($rgb !~ m/^[0-9A-Fa-f]+$/ms) {
				err "Parameter '$key' has bad rgb color (bad hex number).",
					'Value', $error_value,
				;
			}
		} else {
			err "Parameter '$key' has bad rgb color (bad length).",
				'Value', $error_value,
			;
		}
	} elsif ($value =~ m/^($funcs)\((.*)\)$/ms) {
		my $func = $1;
		my $args_string = $2;
		my @args = split m/\s*,\s*/ms, $args_string;
		if ($func eq 'rgb') {
			if (@args != 3) {
				err "Parameter '$key' has bad rgb color (bad number of arguments).",
					'Value', $error_value,
				;
			}
			_check_colors([@args[0 .. 2]], $key, $func, $error_value);
		} elsif ($func eq 'rgba') {
			if (@args != 4) {
				err "Parameter '$key' has bad rgba color (bad number of arguments).",
					'Value', $error_value,
				;
			}
			_check_colors([@args[0 .. 2]], $key, $func, $error_value);
			_check_alpha($args[3], $key, $func, $error_value);
		} elsif ($func eq 'hsl') {
			if (@args != 3) {
				err "Parameter '$key' has bad hsl color (bad number of arguments).",
					'Value', $error_value,
				;
			}
			_check_degree($args[0], $key, $func, $error_value);
			_check_percent([@args[1 .. 2]], $key, $func.' percent', $error_value);
		# hsla
		} else {
			if (@args != 4) {
				err "Parameter '$key' has bad hsla color (bad number of arguments).",
					'Value', $error_value,
				;
			}
			_check_degree($args[0], $key, $func, $error_value);
			_check_percent([@args[1 .. 2]], $key, $func.' percent', $error_value);
			_check_alpha($args[3], $key, $func, $error_value);
		}
	} else {
		if (none { $value eq $_ } keys %{Graphics::ColorNames::CSS->NamesRgbTable}) {
			err "Parameter '$key' has bad color name.",
				'Value', $error_value,
			;
		}
	}

	return;
}

sub _check_colors {
	my ($value_ar, $key, $func, $error_value) = @_;

	foreach my $i (@{$value_ar}) {
		if ($i !~ m/^\d+$/ms || $i > 255) {
			err "Parameter '$key' has bad $func color (bad number).",
				'Value', $error_value,
			;
		}
	}

	return;
}

sub _check_degree {
	my ($angle, $key, $func, $error_value) = @_;

	if ($angle !~ m/^\d+$/ms || $angle > 360) {
		err "Parameter '$key' has bad $func degree.",
			'Value', $error_value,
		;
	}

	return;
}

sub _check_key {
	my ($self, $key) = @_;

	if (! exists $self->{$key} || ! defined $self->{$key}) {
		return 1;
	}

	return 0;
}

sub _check_percent {
	my ($value_ar, $key, $func, $error_value) = @_;

	foreach my $i (@{$value_ar}) {
		sub_check_percent($i, $key, $func, $error_value);
	}

	return;
}

sub _check_unit {
	my ($value, $key, $error_value) = @_;

	if (! defined $error_value) {
		$error_value = $value;
	}

	my ($num, $unit) = $value =~ m/^(\d*\.?\d+)([^\d]*)$/ms;
	if (! $num) {
		err "Parameter '$key' doesn't contain unit number.",
			'Value', $error_value,
		;
	}
	if (! $unit) {
		err "Parameter '$key' doesn't contain unit name.",
			'Value', $error_value,
		;
	}
	if (none { $_ eq $unit } (@ABSOLUTE_LENGTHS, @RELATIVE_LENGTHS)) {
		err "Parameter '$key' contain bad unit.",
			'Unit', $unit,
			'Value', $error_value,
		;
	}

	return;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Mo::utils::CSS - Mo CSS utilities.

=head1 SYNOPSIS

 use Mo::utils::CSS qw(check_array_css_color check_css_border check_css_class check_css_color check_css_unit);

 check_array_css_color($self, $key);
 check_css_border($self, $key);
 check_css_class($self, $key);
 check_css_color($self, $key);
 check_css_unit($self, $key);

=head1 DESCRIPTION

Mo utilities for checking of CSS style things.

=head1 SUBROUTINES

=head2 C<check_array_css_color>

 check_array_css_color($self, $key);

I<Since version 0.03.>

Check parameter defined by C<$key> which is reference to array.
Check if all values are CSS colors.

Put error if check isn't ok.

Returns undef.

=head2 C<check_css_border>

 check_css_border($self, $key);

I<Since version 0.07.>

Check parameter defined by C<$key> if it's CSS border.
Value could be undefined.

Put error if check isn't ok.

Returns undef.

=head2 C<check_css_class>

 check_css_class($self, $key);

I<Since version 0.02.>

Check parameter defined by C<$key> if it's CSS class name.
Value could be undefined.

Put error if check isn't ok.

Returns undef.

=head2 C<check_css_color>

 check_css_color($self, $key);

I<Since version 0.03.>

Check parameter defined by C<$key> if it's CSS color.
Value could be undefined.

Put error if check isn't ok.

Returns undef.

=head2 C<check_css_unit>

 check_css_unit($self, $key);

I<Since version 0.01. Described functionality since version 0.07.>

Check parameter defined by C<$key> if it's CSS unit.
Value could be undefined.

Put error if check isn't ok.

Returns undef.

=head1 ERRORS

 check_array_css_color():
         Parameter '%s' has bad color name.
                 Value: %s
         Parameter '%s' has bad hsl color (bad number of arguments).
                 Value: %s
         Parameter '%s' has bad hsl degree.
                 Value: %s
         Parameter '%s' has bad hsl percent (missing %).
                 Value: %s
         Parameter '%s' has bad hsl percent.
                 Value: %s
         Parameter '%s' has bad hsla alpha.
                 Value: %s
         Parameter '%s' has bad hsla color (bad number of arguments).
                 Value: %s
         Parameter '%s' has bad hsla degree.
                 Value: %s
         Parameter '%s' has bad hsla percent (missing %).
                 Value: %s
         Parameter '%s' has bad hsla percent.
                 Value: %s
         Parameter '%s' has bad rgb color (bad hex number).
                 Value: %s
         Parameter '%s' has bad rgb color (bad length).
                 Value: %s
         Parameter '%s' has bad rgb color (bad number).
                 Value: %s
         Parameter '%s' has bad rgb color (bad number of arguments).
                 Value: %s
         Parameter '%s' has bad rgba alpha.
                 Value: %s
         Parameter '%s' has bad rgba color (bad number).
                 Value: %s
         Parameter '%s' has bad rgba color (bad number of arguments).
                 Value: %s
         Parameter '%s' must be a array.
                 Value: %s
                 Reference: %s

 check_css_border()
         Parameter '%s' contain bad unit.
                 Unit: %s
                 Value: %s
         Parameter '%s' doesn't contain unit name.
                 Value: %s
         Parameter '%s' doesn't contain unit number.
                 Value: %s
         Parameter '%s' has bad color name.
                 Value: %s
         Parameter '%s' has bad hsl color (bad number of arguments).
                 Value: %s
         Parameter '%s' has bad hsl degree.
                 Value: %s
         Parameter '%s' has bad hsl percent (missing %).
                 Value: %s
         Parameter '%s' has bad hsl percent.
                 Value: %s
         Parameter '%s' has bad hsla alpha.
                 Value: %s
         Parameter '%s' has bad hsla color (bad number of arguments).
                 Value: %s
         Parameter '%s' has bad hsla degree.
                 Value: %s
         Parameter '%s' has bad hsla percent (missing %).
                 Value: %s
         Parameter '%s' has bad hsla percent.
                 Value: %s
         Parameter '%s' has bad rgb color (bad hex number).
                 Value: %s
         Parameter '%s' has bad rgb color (bad length).
                 Value: %s
         Parameter '%s' has bad rgb color (bad number).
                 Value: %s
         Parameter '%s' has bad rgb color (bad number of arguments).
                 Value: %s
         Parameter '%s' has bad rgba alpha.
                 Value: %s
         Parameter '%s' has bad rgba color (bad number).
                 Value: %s
         Parameter '%s' has bad rgba color (bad number of arguments).
                 Value: %s
         Parameter '%s' hasn't border style.
                 Value: %s
         Parameter '%s' must be a array.
                 Value: %s
                 Reference: %s

 check_css_class():
         Parameter '%s' has bad CSS class name.
                 Value: %s
         Parameter '%s' has bad CSS class name (number on begin).
                 Value: %s

 check_css_color():
         Parameter '%s' has bad color name.
                 Value: %s
         Parameter '%s' has bad hsl color (bad number of arguments).
                 Value: %s
         Parameter '%s' has bad hsl degree.
                 Value: %s
         Parameter '%s' has bad hsl percent (missing %).
                 Value: %s
         Parameter '%s' has bad hsl percent.
                 Value: %s
         Parameter '%s' has bad hsla alpha.
                 Value: %s
         Parameter '%s' has bad hsla color (bad number of arguments).
                 Value: %s
         Parameter '%s' has bad hsla degree.
                 Value: %s
         Parameter '%s' has bad hsla percent (missing %).
                 Value: %s
         Parameter '%s' has bad hsla percent.
                 Value: %s
         Parameter '%s' has bad rgb color (bad hex number).
                 Value: %s
         Parameter '%s' has bad rgb color (bad length).
                 Value: %s
         Parameter '%s' has bad rgb color (bad number).
                 Value: %s
         Parameter '%s' has bad rgb color (bad number of arguments).
                 Value: %s
         Parameter '%s' has bad rgba alpha.
                 Value: %s
         Parameter '%s' has bad rgba color (bad number).
                 Value: %s
         Parameter '%s' has bad rgba color (bad number of arguments).
                 Value: %s

 check_css_unit():
         Parameter '%s' contain bad unit.
                 Unit: %s
                 Value: %s
         Parameter '%s' doesn't contain unit name.
                 Value: %s
         Parameter '%s' doesn't contain unit number.
                 Value: %s

=head1 EXAMPLE1

=for comment filename=check_array_css_color_ok.pl

 use strict;
 use warnings;

 use Mo::utils::CSS qw(check_array_css_color);

 my $self = {
         'key' => [
                 'red',
                 '#F00', '#FF0000', '#FF000000',
                 'rgb(255,0,0)', 'rgba(255,0,0,0.3)',
                 'hsl(120, 100%, 50%)', 'hsla(120, 100%, 50%, 0.3)',
         ],
 };
 check_array_css_color($self, 'key');

 # Print out.
 print "ok\n";

 # Output:
 # ok

=head1 EXAMPLE2

=for comment filename=check_array_css_color_fail.pl

 use strict;
 use warnings;

 use Error::Pure;
 use Mo::utils::CSS qw(check_array_css_color);

 $Error::Pure::TYPE = 'Error';

 my $self = {
         'key' => ['xxx'],
 };
 check_array_css_color($self, 'key');

 # Print out.
 print "ok\n";

 # Output like:
 # #Error [...CSS.pm:?] Parameter 'key' has bad color name.

=head1 EXAMPLE3

=for comment filename=check_css_border_ok.pl

 use strict;
 use warnings;

 use Mo::utils::CSS qw(check_css_border);

 my $self = {
         'key' => '1px solid red',
 };
 check_css_border($self, 'key');

 # Print out.
 print "ok\n";

 # Output:
 # ok

=head1 EXAMPLE4

=for comment filename=check_css_border_fail.pl

 use strict;
 use warnings;

 use Error::Pure;
 use Mo::utils::CSS qw(check_css_border);

 $Error::Pure::TYPE = 'Error';

 my $self = {
         'key' => 'bad',
 };
 check_css_border($self, 'key');

 # Print out.
 print "ok\n";

 # Output like:
 # #Error [...CSS.pm:?] Parameter 'key' has bad border style.

=head1 EXAMPLE5

=for comment filename=check_css_class_ok.pl

 use strict;
 use warnings;

 use Mo::utils::CSS qw(check_css_class);

 my $self = {
         'key' => 'foo-bar',
 };
 check_css_class($self, 'key');

 # Print out.
 print "ok\n";

 # Output:
 # ok

=head1 EXAMPLE6

=for comment filename=check_css_class_fail.pl

 use strict;
 use warnings;

 use Error::Pure;
 use Mo::utils::CSS qw(check_css_class);

 $Error::Pure::TYPE = 'Error';

 my $self = {
         'key' => '1xxx',
 };
 check_css_class($self, 'key');

 # Print out.
 print "ok\n";

 # Output like:
 # #Error [...CSS.pm:?] Parameter 'key' has bad CSS class name (number of begin).

=head1 EXAMPLE7

=for comment filename=check_css_color_ok.pl

 use strict;
 use warnings;

 use Mo::utils::CSS qw(check_css_color);

 my $self = {
         'key' => '#F00',
 };
 check_css_color($self, 'key');

 # Print out.
 print "ok\n";

 # Output:
 # ok

=head1 EXAMPLE8

=for comment filename=check_css_color_fail.pl

 use strict;
 use warnings;

 use Error::Pure;
 use Mo::utils::CSS qw(check_css_color);

 $Error::Pure::TYPE = 'Error';

 my $self = {
         'key' => 'xxx',
 };
 check_css_color($self, 'key');

 # Print out.
 print "ok\n";

 # Output like:
 # #Error [...CSS.pm:?] Parameter 'key' has bad color name.

=head1 EXAMPLE9

=for comment filename=check_css_unit_ok.pl

 use strict;
 use warnings;

 use Mo::utils::CSS qw(check_css_unit);

 my $self = {
         'key' => '123px',
 };
 check_css_unit($self, 'key');

 # Print out.
 print "ok\n";

 # Output:
 # ok

=head1 EXAMPLE10

=for comment filename=check_css_unit_fail.pl

 use strict;
 use warnings;

 use Error::Pure;
 use Mo::utils::CSS qw(check_css_unit);

 $Error::Pure::TYPE = 'Error';

 my $self = {
         'key' => '12',
 };
 check_css_unit($self, 'key');

 # Print out.
 print "ok\n";

 # Output like:
 # #Error [...CSS.pm:?] Parameter 'key' doesn't contain unit name.

=head1 DEPENDENCIES

L<Error::Pure>,
L<Exporter>,
L<Graphics::ColorNames::CSS>,
L<List::Util>,
L<Mo::utils>,
L<Mo::utils::Number::Utils>,
L<Readonly>.

=head1 SEE ALSO

=over

=item L<Mo>

Micro Objects. Mo is less.

=item L<Mo::utils>

Mo utilities.

=item L<Mo::utils::Language>

Mo language utilities.

=item L<Wikibase::Datatype::Utils>

Wikibase datatype utilities.

=back

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/Mo-utils-CSS>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2023-2025 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.12

=cut
