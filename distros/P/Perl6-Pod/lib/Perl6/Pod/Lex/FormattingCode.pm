#===============================================================================
#
#  DESCRIPTION:  Base block
#
#       AUTHOR:  Aliaksandr P. Zahatski, <zag@cpan.org>
#===============================================================================
package Perl6::Pod::Lex::FormattingCode;
use strict;
use warnings;
use Perl6::Pod::Lex::Block;
use base 'Perl6::Pod::Lex::Block';
our $VERSION = '0.01';

sub new {
    my $class = shift;
    my $self = bless( ( $#_ == 0 ) ? shift : {@_}, ref($class) || $class );
    $self;
}

1;


