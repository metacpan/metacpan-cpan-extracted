
package PBS::Attributes ;

use 5.006 ;
use strict ;
use warnings ;
 
require Exporter ;
use AutoLoader qw(AUTOLOAD) ;

our @ISA = qw(Exporter) ;
our %EXPORT_TAGS = ('all' => [ qw() ]) ;
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } ) ;
use vars qw($VERSION @ISA @EXPORT) ;

require Exporter;

@ISA     = qw(Exporter AutoLoader) ;
#~ @EXPORT  = qw() ;

$VERSION = '0.01' ;

use Attribute::Handlers ;

sub ShellCommandGenerator : ATTR(CODE)
{
my ($package, $symbol, $referent, $attr, $data, $phase) = @_;

#~ print STDERR
	#~ ref($referent), " '",
	#~ *{$symbol}{NAME}, "' ",
	#~ "($referent) ", "was just declared ",
	#~ "and ascribed the ${attr} attribute ",
	#~ #"with data ($data)\n",
	#~ "in phase $phase\n";

bless $referent, $attr ;
}

sub Creator : ATTR(CODE)
{
my ($package, $symbol, $referent, $attr, $data, $phase) = @_;

#~ print STDERR
	#~ ref($referent), " '",
	#~ *{$symbol}{NAME}, "' ",
	#~ "($referent) ", "was just declared ",
	#~ "and ascribed the ${attr} attribute ",
	#~ #"with data ($data)\n",
	#~ "in phase $phase\n";

bless $referent, $attr ;
}


#-------------------------------------------------------------------------------
1 ;

__END__
=head1 NAME

PBS::Attributes - definition of PBS attributes types

=head1 SYNOPSIS

  use PBS::Attributes
  
  sub mysub : creator{} ;
  
=head1 DESCRIPTION

=head2 EXPORT

None by default.

=head1 AUTHOR

Khemir Nadim ibn Hamouda. nadim@khemir.net

=head1 SEE ALSO


=cut
