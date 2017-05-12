#===============================================================================
#  DESCRIPTION:  
#       AUTHOR:  Aliaksandr P. Zahatski (Mn), <zag@cpan.org>
#===============================================================================

use strict;
use warnings;
use lib 't/lib';
use T::Block::code;
use T::Block::para;
use T::Block::table;
use T::Block::output;
use T::Block::input;
use T::Block::nested;
#use T::Directive::alias;
use T::Block::item;
Test::Class->runtests;



