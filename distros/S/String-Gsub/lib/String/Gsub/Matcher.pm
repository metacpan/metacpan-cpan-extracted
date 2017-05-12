## ----------------------------------------------------------------------------
#  String::Gsub::Matcher
# -----------------------------------------------------------------------------
# Mastering programmed by YAMASHINA Hio
#
# Copyright 2006 YAMASHINA Hio
# -----------------------------------------------------------------------------
# $Id$
# -----------------------------------------------------------------------------
package String::Gsub::Matcher;
use strict;
use warnings;
use overload q|""| => \&stringy;

1;

# -----------------------------------------------------------------------------
# $matcher = $pkg->new($str);
#
sub new
{
	my $pkg = shift;
	my $this = bless { origref=>\$_[0], }, $pkg;
	$this->{st} = [@-];
	$this->{ed} = [@+];
	$this;
}

# -----------------------------------------------------------------------------
# $str = $matcher->expand($tmpl);
#   evaluate string-template by match results.
#
sub expand
{
	my $this = shift;
	my $tmpl = shift;
	
	$tmpl =~ s{\\(\d+)|\\([&`'])}
	{
		if( defined($1) )
		{
			$1<=$#{$this->{st}} ? substr(${$this->{origref}}, $this->{st}[$1], $this->{ed}[$1] - $this->{st}[$1]) : '';
		}elsif( $2 eq '&' )
		{
			substr(${$this->{origref}}, $this->{st}[0], $this->{ed}[0] - $this->{st}[0]);
		}elsif( $2 eq '`' )
		{
			substr(${$this->{origref}}, 0, $this->{st}[0]);
		}elsif( $2 eq "\'" )
		{
			substr(${$this->{origref}}, $this->{ed}[0]);
		}else
		{ # never reach here.
			'';
		}
	}xmse;
	$tmpl;
}

# -----------------------------------------------------------------------------
# $str = $matcher->stringy();
#   overloading of  "".
#   returns whole of match ($&).
#
sub stringy
{
	my $this = shift;
	substr(${$this->{origref}},$this->{st}[0], $this->{ed}[0]-$this->{st}[0]);
}

__END__

=head1 NAME

String::Gsub::Matcher - match result object

=head1 SYNOPSIS

 use String::Gsub::Matcher;
 
 my $matcher = String::Gsub::Matcher($origstr);
 print $matcher; # ==> ($MATCH)
 print $matcher->expand($tmpl); # expand.

=head1 DESCRIPTION

used by L<String::Gsub::Functions> internally.

=head1 EXPORT

This module exports no functions.

=head1 METHODS

=head2 new

=head2 expand

=head2 stringy

=head1 SEE ALSO

L<String::Gsub>

=cut

# -----------------------------------------------------------------------------
# End of File.
# -----------------------------------------------------------------------------
