#
# GENERATED WITH PDL::PP! Don't modify!
#
package PDL::Graphics::OpenGLQ;

our @EXPORT_OK = qw(line_3x_3c gl_line_strip_col gl_line_strip_nc gl_lines_col gl_lines_nc gl_points_col gl_points_nc gl_texts gl_triangles_mat gl_triangles_n_mat gl_triangles_wn_mat gl_triangles gl_triangles_n gl_triangles_wn gl_arrows );
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

*gl_line_strip_col = \&PDL::gl_line_strip_col;
#line 67 "OpenGLQ.pm"



#line 1060 "../../../blib/lib/PDL/PP.pm"

*gl_line_strip_nc = \&PDL::gl_line_strip_nc;
#line 74 "OpenGLQ.pm"



#line 1060 "../../../blib/lib/PDL/PP.pm"

*gl_lines_col = \&PDL::gl_lines_col;
#line 81 "OpenGLQ.pm"



#line 1060 "../../../blib/lib/PDL/PP.pm"

*gl_lines_nc = \&PDL::gl_lines_nc;
#line 88 "OpenGLQ.pm"



#line 1060 "../../../blib/lib/PDL/PP.pm"

*gl_points_col = \&PDL::gl_points_col;
#line 95 "OpenGLQ.pm"



#line 1060 "../../../blib/lib/PDL/PP.pm"

*gl_points_nc = \&PDL::gl_points_nc;
#line 102 "OpenGLQ.pm"



#line 1060 "../../../blib/lib/PDL/PP.pm"

*gl_texts = \&PDL::gl_texts;
#line 109 "OpenGLQ.pm"



#line 1060 "../../../blib/lib/PDL/PP.pm"

*gl_triangles_mat = \&PDL::gl_triangles_mat;
#line 116 "OpenGLQ.pm"



#line 1060 "../../../blib/lib/PDL/PP.pm"

*gl_triangles_n_mat = \&PDL::gl_triangles_n_mat;
#line 123 "OpenGLQ.pm"



#line 1060 "../../../blib/lib/PDL/PP.pm"

*gl_triangles_wn_mat = \&PDL::gl_triangles_wn_mat;
#line 130 "OpenGLQ.pm"



#line 1060 "../../../blib/lib/PDL/PP.pm"

*gl_triangles = \&PDL::gl_triangles;
#line 137 "OpenGLQ.pm"



#line 1060 "../../../blib/lib/PDL/PP.pm"

*gl_triangles_n = \&PDL::gl_triangles_n;
#line 144 "OpenGLQ.pm"



#line 1060 "../../../blib/lib/PDL/PP.pm"

*gl_triangles_wn = \&PDL::gl_triangles_wn;
#line 151 "OpenGLQ.pm"



#line 1060 "../../../blib/lib/PDL/PP.pm"

*gl_arrows = \&PDL::gl_arrows;
#line 158 "OpenGLQ.pm"






# Exit with OK status

1;
