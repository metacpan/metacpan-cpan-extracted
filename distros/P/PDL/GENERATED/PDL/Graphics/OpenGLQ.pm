#
# GENERATED WITH PDL::PP! Don't modify!
#
package PDL::Graphics::OpenGLQ;

our @EXPORT_OK = qw(line_3x_3c gl_points gl_lines gl_line_strip gl_texts gl_triangles_mat gl_triangles_n_mat gl_triangles_wn_mat gl_triangles gl_triangles_n gl_triangles_wn gl_arrows );
our %EXPORT_TAGS = (Func=>\@EXPORT_OK);

use PDL::Core;
use PDL::Exporter;
use DynaLoader;


   
   our @ISA = ( 'PDL::Exporter','DynaLoader' );
   push @PDL::Core::PP, __PACKAGE__;
   bootstrap PDL::Graphics::OpenGLQ ;






#line 7 "openglq.pd"

=head1 NAME

PDL::Graphics::OpenGLQ - quick routines to plot lots of stuff from ndarrays.

=head1 SYNOPSIS

only for internal use - see source

=head1 DESCRIPTION

only for internal use - see source

=head1 AUTHOR

Copyright (C) 1997,1998 Tuomas J. Lukka.  
All rights reserved. There is no warranty. You are allowed
to redistribute this software / documentation under certain
conditions. For details, see the file COPYING in the PDL 
distribution. If this file is separated from the PDL distribution, 
the copyright notice should be included in the file.

=cut
#line 49 "OpenGLQ.pm"







#line 1060 "../../../blib/lib/PDL/PP.pm"

*line_3x_3c = \&PDL::line_3x_3c;
#line 60 "OpenGLQ.pm"



#line 1060 "../../../blib/lib/PDL/PP.pm"

*gl_points = \&PDL::gl_points;
#line 67 "OpenGLQ.pm"



#line 1060 "../../../blib/lib/PDL/PP.pm"

*gl_lines = \&PDL::gl_lines;
#line 74 "OpenGLQ.pm"



#line 1060 "../../../blib/lib/PDL/PP.pm"

*gl_line_strip = \&PDL::gl_line_strip;
#line 81 "OpenGLQ.pm"



#line 1060 "../../../blib/lib/PDL/PP.pm"

*gl_texts = \&PDL::gl_texts;
#line 88 "OpenGLQ.pm"



#line 1060 "../../../blib/lib/PDL/PP.pm"

*gl_triangles_mat = \&PDL::gl_triangles_mat;
#line 95 "OpenGLQ.pm"



#line 1060 "../../../blib/lib/PDL/PP.pm"

*gl_triangles_n_mat = \&PDL::gl_triangles_n_mat;
#line 102 "OpenGLQ.pm"



#line 1060 "../../../blib/lib/PDL/PP.pm"

*gl_triangles_wn_mat = \&PDL::gl_triangles_wn_mat;
#line 109 "OpenGLQ.pm"



#line 1060 "../../../blib/lib/PDL/PP.pm"

*gl_triangles = \&PDL::gl_triangles;
#line 116 "OpenGLQ.pm"



#line 1060 "../../../blib/lib/PDL/PP.pm"

*gl_triangles_n = \&PDL::gl_triangles_n;
#line 123 "OpenGLQ.pm"



#line 1060 "../../../blib/lib/PDL/PP.pm"

*gl_triangles_wn = \&PDL::gl_triangles_wn;
#line 130 "OpenGLQ.pm"



#line 1060 "../../../blib/lib/PDL/PP.pm"

*gl_arrows = \&PDL::gl_arrows;
#line 137 "OpenGLQ.pm"






# Exit with OK status

1;
