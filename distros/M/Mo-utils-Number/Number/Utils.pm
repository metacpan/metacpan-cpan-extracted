package Mo::utils::Number::Utils;

use base qw(Exporter);
use strict;
use warnings;

use Error::Pure qw(err);
use Readonly;

Readonly::Array our @EXPORT_OK => qw(sub_check_percent);

our $VERSION = 0.04;

sub sub_check_percent {
	my ($value, $key, $func, $error_value) = @_;

	if (! defined $error_value) {
		$error_value = $value;
	}

	if (! defined $func) {
		$func = 'percent value';
	}

	# Check percent sign.
	if ($value =~ m/^(\d+(?:\.\d+)?)(\%)?$/ms) {
		$value = $1;
		my $p = $2;
		if (! $p) {
			err "Parameter '$key' has bad $func (missing %).",
				'Value', $error_value,
			;
		}
	# Check percent number.
	} else {
		err "Parameter '$key' has bad $func.",
			'Value', $error_value,
		;
	}

	# Check percent value.
	if ($value > 100) {
		err "Parameter '$key' has bad $func.",
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

Mo::utils::Number::Utils - Utilities for Mo::utils::Number.

=head1 SYNOPSIS

 use Mo::utils::Number::Utils qw(sub_check_percent);

 sub_check_percent($value, $key, $func, $error_value);

=head1 SUBROUTINES

=head2 C<sub_check_percent>

 sub_check_percent($value, $key, $func, $error_value);

Common subroutine for check percents.
It is exportable.

Returns undef.

=head1 ERRORS

 sub_check_percent():

=head1 EXAMPLE

=for comment filename=sub_check_percent.pl

 use strict;
 use warnings;

 use Mo::utils::Number::Utils qw(sub_check_percent);

 my $ret = sub_check_percent('20%', 'key', 'percent value', 'user value');
 if (! defined $ret) {
         print "Returns undef.\n";
 }

 # Output:
 # Returns undef.

=head1 DEPENDENCIES

L<Error::Pure>,
L<Exporter>,
L<Readonly>.

=head1 SEE ALSO

=over

=item L<Mo::utils::Number>

Mo number utilities.

=back

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/Mo-utils-Number>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2024-2025 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.04

=cut
