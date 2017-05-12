package Number::WithError::LaTeX;

use 5.008;
use strict;
use warnings;

our $VERSION = '0.06';

use base 'Number::WithError';

use base 'Exporter';
our %EXPORT_TAGS = %Number::WithError::EXPORT_TAGS;
our @EXPORT_OK = @Number::WithError::EXPORT_OK;

use TeX::Encode;
use Encode ();
use Carp qw/croak/;

sub witherror {	Number::WithError::LaTeX->new(@_) }
sub witherror_big {	Number::WithError::LaTeX->new_big(@_) }

use Params::Util qw/_ARRAY0/;


=head1 NAME

Number::WithError::LaTeX - LaTeX output for Number::WithError

=head1 SYNOPSIS

  use Number::WithError::LaTeX;
  
  my $num = Number::WithError::LaTeX->new(5.647, 0.31);
  print $num . "\n";
  # prints '5.65e+00 +/- 3.1e-01'
  # (I.e. it automatically does scientific rounding)
  
  print $num->latex() . "\n";
  # prints '5.65 \cdot 10^{0} \pm 3.1 \cdot 10^{-1}'
  
  print $num->latex(radix => ',', enclose => '$') . "\n";
  # prints '$5,\!65 \cdot 10^{0} \pm 3,\!1 \cdot 10^{-1}$'
  
  print $num->encode("This will encode an e-acute (".chr(0xe9).") as \\'e") . "\n";
  # Delegated to TeX::Encode::encode().
  # prints 'This is a German umlaut: \"a'

=head1 DESCRIPTION

This class is a subclass of L<Number::WithError>. It provides the same
interface and the same exports.

It adds several methods to every object. The main functionality is provided by
C<latex()>, which dumps the object
as valid LaTeX code. Also, C<encode()> is a convenient way to encode
any UTF-8 string into TeX. It is just a convenience thing since it is delegated
to L<TeX::Encode>.

Unlike C<Number::WithError>, this module requires perl version 5.8 or later.
(That is the rationale for creating a separate distribution, too.)

=head1 EXPORT

This module exports the following subroutines on demand. It supports
the C<:all> Exporter tag to export all of them. The subroutines are
documented in L<Number::WithError>.

=head2 witherror

=head2 witherror_big

=cut

=head1 METHODS

This is a list of public methods.

=head2 latex

This method stringifies the object as valid LaTeX code. The returned
string is valid in a LaTeX math mode. That means, you will have to
enclose it in dollars or in an C<equation> environment by default.

The method takes named parameters. All parameters are optional.

The C<enclose> parameter can set a string to enclose the produced
latex code in. This can be either a simple string like C<$> or an
array reference containing two strings. Those two strings will be
used for the start and end respectively. (For environments.)

Example: (let C<$obj> be '5.6e-01 +/- 2.3e-02')

  $obj->latex(enclose => '$');
  # returns '$5.6 \cdot 10^{-1} \pm 2.3 \cdot 10^{-2}$'

The asymmetric environment-like C<enclose> can be used as follows:

  $obj->latex(enclose => ['\begin{equation}', '\end{equation}']);
  # returns'\begin{equation}5.6 \cdot 10^{-1} \pm 2.3 \cdot 10^{-2}\end{equation}'

There are two convenience methods C<latex_math> and C<latex_equation> which do
exactly what the above examples demonstrated.

The C<radix> parameter can set the radix (I<decimal point>) used. The default is
a dot (C<.>). If you use a comma, LaTeX will generally typeset it in a way that
results in a space after the comma. Since that is not desireable, using a C<,>
as the radix results in the radix being set as C<,\!>. An example can be found
in the synopsis.

=cut

our $CFloatCapture = qr/([+-]?)(?=\d|\.\d)(\d*(?:\.\d*)?)((?:[Ee][+-]?\d+)?)/;

sub latex {
	my $self = shift;
	croak("Uneven number of arguments to ".__PACKAGE__."->latex().") if @_ % 2;
	my %opt = @_;
	my $radix = $opt{radix};
	if (not defined $radix) {
		$radix = '.';
	}
	elsif ($radix eq '.') {
		#fine
	}
	else {
		$radix .= '\!';
	}

	my $enclose = $opt{enclose};
	$enclose = '' if not defined $enclose;
	$enclose = '' if _ARRAY0($enclose) and @$enclose != 2;
	
	my $str = "".$self->round();

	my $result;
	pos($str) = 0;
	my $p = -1;
	my $number = 1;
	while (defined pos($str) and pos($str) < length($str)) {
		die "Failed to advance string parser at position $p in '$str'." if pos($str) == $p;
		$p = pos($str);
		
		# number
		if ($number) {
			$str =~ /\G\s*$CFloatCapture\s*/cgo or die "Expected number starting at position $p in '$str'.";
			my $sgn = $1;
			my $num = $2;
			my $exp = $3;

			unless ($exp =~ s/^[eE]([+-]?)(\d+)$/" \\cdot 10^{".($1eq'-'?'-':'').(0+$2)."}"/e) {
				$exp = ' \cdot 10^{0}';
			}
			
			$num =~ s/\./$radix/;
			
			$result .= "$sgn$num$exp";
			$number = 0;
		}
		# +/-, +, -
		else {
			$str =~ /\G\s*(\+\/\-|\+|\-)\s*/cgo or die "Expected operator (+/-, +, -) starting at position $p in '$str'.";
			my $op = $1;
			if ($op eq '+/-') {
				$op = '\pm';
			}

			$result .= " $op ";
			$number = 1;
		}
		
	}
	
	if (_ARRAY0($enclose)) {
		return $enclose->[0].$result.$enclose->[1];
	}
	else {
		return $enclose.$result.$enclose;
	}
}

=head2 latex_math

Works exactly like C<latex()> except that the C<enclose> string defaults to C<$>.

=cut

sub latex_math {
	shift()->latex(enclose => '$', @_)
}

=head2 latex_equation

Works exactly like C<latex()> except that the C<enclose> string defaults to the
environment C<\begin{equation}\n> and C<\n\end{equation}>.

=cut

sub latex_equation {
	shift()->latex(enclose => ["\\begin{equation}\n", "\n\\end{equation}"], @_)
}

=head2 encode

This method encodes an arbitrary UTF-8 string as TeX. Syntax:

  my $encoded = $obj->encode($string);

For detailed documentation, please refer to L<TeX::Encode>.

=cut

sub encode {
	my $self = shift;
	return Encode::encode('latex', shift);
}


1;

__END__

=pod

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Number-WithError-LaTeX>

For other issues, contact the author.

=head1 SEE ALSO

It is important that you have a look at the L<TeX::Encode> module if you use
the C<encode()> method. The C<decode()> operation from that module, however,
is not supported by C<Number::WithError::LaTeX>.

You may use L<Math::BigFloat> with this module. Also, it should be possible to
use L<Math::Symbolic> to calculate larger formulas. Just assign a
C<Number::WithError::LaTeX> object to the C<Math::Symbolic> variables and it should
work.

You also possibly want to have a look at the L<prefork> pragma.

The test suite is implemented using the L<Test::LectroTest> module. In order to
keep the total test time in reasonable bounds, the default number of test attempts
to falsify the test properties is kept at a low number of 100. You can
enable more rigorous testing by setting the environment variable
C<PERL_TEST_ATTEMPTS> to a higher value. A value in the range of C<1500> to
C<3000> is probably a good idea, but takes a long time to test.

=head1 AUTHOR

Steffen Mueller E<lt>modules at steffen-mueller dot netE<gt>, L<http://steffen-mueller.net/>

=head1 COPYRIGHT

Copyright 2006 Steffen Mueller. All rights reserved.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

=cut
