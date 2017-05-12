## ----------------------------------------------------------------------------
#  String::Gsub::Functions
# -----------------------------------------------------------------------------
# Mastering programmed by YAMASHINA Hio
#
# Copyright 2006 YAMASHINA Hio
# -----------------------------------------------------------------------------
# $Id$
# -----------------------------------------------------------------------------
package String::Gsub::Functions;
use warnings;
use strict;
use String::Gsub::Matcher;

use base qw(Exporter);
our @EXPORT_OK = qw(gsub gsubx subs subsx);

1;

# -----------------------------------------------------------------------------
# gsub($str, $regex, $replacement);
#   $regex is qr// or "string".
#   $replacement is sub{} or "string".
#   returns new value.
#
sub gsub($$$)
{
	splice(@_, 0, 1, $_[0]); # copy.
	&gsubx;
}

# -----------------------------------------------------------------------------
# gsubx($str, $regex, $replacement);
#   $regex is qr// or "string".
#   $replacement is sub{} or "string".
#   returns new value and $str is replaced with result too.
sub gsubx($$$)
{
	#my $str = $_[0];
	my $re  = $_[1];
	my $sub = $_[2];
	
	ref($re)  or $re  = qr/\Q$re\E/;
	ref($sub) or $sub = do{ my$tmpl=$sub; sub{ shift->expand($tmpl); }; };
	$_[0] =~ s{$re}
	{
		my $match = String::Gsub::Matcher->new($_[0]);
		$sub->($match);
	}ge;
	$_[0];
}

# -----------------------------------------------------------------------------
# subs($str, $regex, $replacement);
#   $regex is qr// or "string".
#   $replacement is sub{} or "string".
#   returns new value.
#
sub subs($$$)
{
	splice(@_, 0, 1, $_[0]); # copy.
	&subsx;
}

# -----------------------------------------------------------------------------
# subsx($str, $regex, $replacement);
#   $regex is qr// or "string".
#   $replacement is sub{} or "string".
#   returns new value and $str is replaced with result too.
sub subsx($$$)
{
	#my $str = $_[0];
	my $re  = $_[1];
	my $sub = $_[2];
	
	ref($re)  or $re  = qr/\Q$re\E/;
	ref($sub) or $sub = do{ my$tmpl=$sub; sub{ shift->expand($tmpl); }; };
	$_[0] =~ s{$re}
	{
		my $match = String::Gsub::Matcher->new($_[0]);
		$sub->($match);
	}e;
	$_[0];
}

__END__

=head1 NAME

String::Gsub::Functions - core functions of String::Gsub

=head1 SYNOPSIS

 use String::Gsub::Functions qw(gsub);
 
 print gsub("abcabc", qr/(b)/,sub{uc$1}); # ==> "aBcaBc"
 
 gsubx(my $str = "abcabc", qr/(b)/, sub{uc $1});
 print $str; # ==> "aBcaBc";

=head1 DESCRIPTION

This module has folloing functions:

 gsub ($str, $regexp, $replacement)
 gsubx($str, $regexp, $replacement)
 subs ($str, $regexp, $replacement)
 subsx($str, $regexp, $replacement)

C<$regexp> is regular expression (C<qr//>). 
And C<$replacement> is code reference, which is invoked at replacement.
In C<$replacement> subroutine, match variables (C<$1>, C<$2>, ...)
are avaiable like replacement part of C<s/PATTERN/REPLACEMENT/>.

Both C<$regexp> and C<$replacement> can be string, 
but there are difference from usual part.

String passed on C<$regexp> is not treated as regular expression
, just string. special chars will be escaped.

String passwd on C<$replacement> will be replaced some substrings
with match strings and used as replacement string.
C<\&>, C<\`> and C<\'> are also did.

=head1 EXPORT

This module can export C<gsub>, C<gsubx>, C<subs>, C<subsx>.

=head1 FUNCTIONS

=head2 gsub($str, $regexp, $replacement)

process global substitute, and return new string.

=head2 gsubx($str, $regexp, $replacement)

like gsub, but replace self string and return itself.

=head2 subs($str, $regexp, $replacement)

process one substitute, and return new string.

=head2 subsx($str, $regexp, $replacement)

like subs, but replace self string and return itself.

=head1 SEE ALSO

L<String::Gsub>

=cut

# -----------------------------------------------------------------------------
# End of File.
# -----------------------------------------------------------------------------
