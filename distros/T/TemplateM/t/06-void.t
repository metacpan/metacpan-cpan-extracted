#########################################################################
#
# Serz Minus (Lepenkov Sergey), <minus@mail333.com>
#
# Copyright (C) 1998-2013 D&D Corporation. All Rights Reserved
# 
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# $Id: 06-void.t 3 2013-04-02 12:06:25Z abalama $
#
#########################################################################

use Test::More tests => 2;
use TemplateM;

# Void ('') value
my $t1 = new TemplateM ( -template => '' );
is( $t1->output, '' ,'Void("") value' );

# Void (0) value
my $t2 = new TemplateM ( -template => 0 );
is( $t2->output, 0 ,'Void(0) value' );
