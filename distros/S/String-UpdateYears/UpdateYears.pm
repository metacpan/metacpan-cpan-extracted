package String::UpdateYears;

use base qw(Exporter);
use strict;
use warnings;

use Readonly;

our $VERSION = 0.01;

# Constants.
Readonly::Array our @EXPORT => qw(update_years);

sub update_years {
	my ($string, $opts_hr, $new_last_year) = @_;

	if (! defined $opts_hr) {
		$opts_hr = {};
	}
	if (! exists $opts_hr->{'prefix_glob'}) {
		$opts_hr->{'prefix_glob'} = '.*';
	}
	if (! exists $opts_hr->{'suffix_glob'}) {
		$opts_hr->{'suffix_glob'} = '.*';
	}

	my $pg = $opts_hr->{'prefix_glob'};
	my $sg = $opts_hr->{'suffix_glob'};
	if ($string =~ m/^($pg)(\d{4})-(\d{4})($sg)$/ms) {
		my $pre = $1;
		my $first_year = $2;
		my $last_year = $3;
		my $post = $4;
		if ($last_year != $new_last_year) {
			my $new_string = $pre.$first_year.'-'.$new_last_year.$post;
			return $new_string;
		}
	} elsif ($string =~ m/^($pg)(\d{4})($sg)$/ms) {
		my $pre = $1;
		my $first_year = $2;
		my $post = $3;
		if ($first_year != $new_last_year) {
			my $new_string = $pre.$first_year.'-'.$new_last_year.$post;
			return $new_string;
		}
	}

	return;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

String::UpdateYears - Look for year or years range in string and update years

=head1 SYNOPSIS

 use String::UpdateYears qw(update_years);

 my $updated_or_undef = update_years($string_with_year, $opts_hr, $new_last_year);

=head1 SUBROUTINES

=head2 C<update_years>

 my $updated_or_undef = update_years($string_with_year, $opts_hr, $new_last_year);

Look for year or years range in string and update them.

Parameters:

 C<$string_with_year> - Input string with year or range years.
 C<$opts_hr> - Reference to hash with options. Possible options:
   C<prefix_glob> - Prefix glob from begin of string to year(s) part (default '.*').
   C<postfix_glob> - Postfix glob from year(s) part to end of string (default '.*').
 C<$new_last_year> - New last year to update.

Returns undef if year or years range not found in string.
Returns updated string if year or years range found in string.

=head1 EXAMPLE1

=for comment filename=update_years.pl

 use strict;
 use warnings;

 use String::UpdateYears qw(update_years);

 my $input = '1900';
 my $output = update_years($input, {}, 2023);

 # Print input and output.
 print "Input: $input\n";
 print "Output: $output\n";

 # Output:
 # Input: 1900
 # Output: 1900-2023

=head1 EXAMPLE2

=for comment filename=update_years_copyright.pl

 use strict;
 use warnings;

 use String::UpdateYears qw(update_years);
 use Unicode::UTF8 qw(decode_utf8 encode_utf8);

 my $input = decode_utf8('© 1977-2022 Michal Josef Špaček');
 my $output = update_years($input, {}, 2023);

 # Print input and output.
 print 'Input: '.encode_utf8($input)."\n";
 print 'Output: '.encode_utf8($output)."\n";

 # Output:
 # Input: © 1987-2022 Michal Josef Špaček
 # Output: © 1987-2023 Michal Josef Špaček

=head1 SEE ALSO

=over

=item L<perl-module-copyright-years>

Tool for update copyright years in Perl distribution.

=item L<Pod::CopyrightYears>

Object for copyright years changing in POD.

=back

=head1 DEPENDENCIES

L<Exporter>,
L<Readonly>.

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/String-UpdateYears>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2023 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.01

=cut
