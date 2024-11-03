#
# GENERATED WITH PDL::PP from openglq.pd! Don't modify!
#
package PDL::Graphics::OpenGLQ;

our @EXPORT_OK = qw(gl_spheres gl_line_strip_col gl_line_strip_nc gl_lines_col gl_lines_nc gl_points_col gl_points_nc gl_texts gl_triangles_mat gl_triangles_n_mat gl_triangles_wn_mat gl_triangles gl_triangles_n gl_triangles_wn gl_arrows );
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
#line 50 "OpenGLQ.pm"

*gl_spheres = \&PDL::gl_spheres;




*gl_line_strip_col = \&PDL::gl_line_strip_col;




*gl_line_strip_nc = \&PDL::gl_line_strip_nc;




*gl_lines_col = \&PDL::gl_lines_col;




*gl_lines_nc = \&PDL::gl_lines_nc;




*gl_points_col = \&PDL::gl_points_col;




*gl_points_nc = \&PDL::gl_points_nc;




*gl_texts = \&PDL::gl_texts;




*gl_triangles_mat = \&PDL::gl_triangles_mat;




*gl_triangles_n_mat = \&PDL::gl_triangles_n_mat;




*gl_triangles_wn_mat = \&PDL::gl_triangles_wn_mat;




*gl_triangles = \&PDL::gl_triangles;




*gl_triangles_n = \&PDL::gl_triangles_n;




*gl_triangles_wn = \&PDL::gl_triangles_wn;




*gl_arrows = \&PDL::gl_arrows;







# Exit with OK status

1;
