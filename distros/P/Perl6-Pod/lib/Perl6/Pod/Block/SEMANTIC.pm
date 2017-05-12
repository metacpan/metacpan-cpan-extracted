#===============================================================================
#
#  DESCRIPTION:  Class for semantic blocks
#
#       AUTHOR:  Aliaksandr P. Zahatski, <zag@cpan.org>
#===============================================================================
package Perl6::Pod::Block::SEMANTIC;
use strict;
use warnings;
use Perl6::Pod::Block;
use base 'Perl6::Pod::Block';
our $VERSION = '0.01';

sub to_xhtml {
 my ( $self, $to )  = @_;
 $to->switch_head_level(1);
 $to->w->raw('<h1>')->print($self->name)->raw('</h1>');
 $to->visit_childs($self);
}
1;


