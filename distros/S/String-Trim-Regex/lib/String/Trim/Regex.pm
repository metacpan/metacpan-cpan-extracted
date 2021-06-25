package String::Trim::Regex;
our $VERSION = 20210604;  

use warnings FATAL => qw(all);
use strict;
use Carp;

=pod

Trims the spaces off the leading / trailing string.
This is my first module. Be kind.

=cut

sub trim($)
{
	my $string = shift;
	
	unless (defined $string)
	{
			confess qq[String needs to be defined.\n];
	}	
	
	$string =~ s~^\s+|\s+$~~g;
	
	$string
}


use Exporter qw(import);
use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);

@ISA          = qw(Exporter);
@EXPORT       = qw();
@EXPORT_OK    = qw(trim);
			
%EXPORT_TAGS = (all=>[@EXPORT, @EXPORT_OK]);

1

__END__


