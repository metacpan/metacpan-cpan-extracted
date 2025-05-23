package Perl::APIReference::V5_028_002;
use strict;
use warnings;
use parent 'Perl::APIReference::V5_028_001';

sub new {
  my $class = shift;
  my $obj = $class->SUPER::new(@_);

  $obj->{perl_version} = '5.028002';
  bless $obj => $class;

  # Override the few changes since 5.28.1
  $obj->{'index'}{'AvFILL'} = {'text' => q{Same as C<av_top_index()> or C<av_tindex()>.

	int	AvFILL(AV* av)','name' => 'AvFILL}};

  $obj->{'index'}{'grok_infnan'} = {'text' => q{Helper for C<grok_number()>, accepts various ways of spelling "infinity"
or "not a number", and returns one of the following flag combinations:

  IS_NUMBER_INFINITY
  IS_NUMBER_NAN
  IS_NUMBER_INFINITY | IS_NUMBER_NEG
  IS_NUMBER_NAN | IS_NUMBER_NEG
  0

possibly |-ed with C<IS_NUMBER_TRAILING>.

If an infinity or a not-a-number is recognized, C<*sp> will point to
one byte past the end of the recognized string.  If the recognition fails,
zero is returned, and C<*sp> will not move.

	int	grok_infnan(const char** sp, const char *send)},'name' => 'grok_infnan'};

  $obj->{'index'}{'sv_catpvf'} = {'text' => q{Processes its arguments like C<sprintf>, and appends the formatted
output to an SV.  As with C<sv_vcatpvfn> called with a non-null C-style
variable argument list, argument reordering is not supported.
If the appended data contains "wide" characters
(including, but not limited to, SVs with a UTF-8 PV formatted with C<%s>,
and characters >255 formatted with C<%c>), the original SV might get
upgraded to UTF-8.  Handles 'get' magic, but not 'set' magic.  See
C<L</sv_catpvf_mg>>.  If the original SV was UTF-8, the pattern should be
valid UTF-8; if the original SV was bytes, the pattern should be too.

	void	sv_catpvf(SV *const sv, const char *const pat,
		          ...)},'name' => 'sv_catpvf'};

  $obj->{'index'}{'sv_vcatpvf'} = {'text' => q{Processes its arguments like C<sv_vcatpvfn> called with a non-null C-style
variable argument list, and appends the formatted output
to an SV.  Does not handle 'set' magic.  See C<L</sv_vcatpvf_mg>>.

Usually used via its frontend C<sv_catpvf>.

	void	sv_vcatpvf(SV *const sv, const char *const pat,
		           va_list *const args)},'name' => 'sv_vcatpvf'};

  return $obj;
}

1;
