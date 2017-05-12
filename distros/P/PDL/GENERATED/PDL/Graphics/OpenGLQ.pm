
#
# GENERATED WITH PDL::PP! Don't modify!
#
package PDL::Graphics::OpenGLQ;

@EXPORT_OK  = qw( PDL::PP line_3x_3c PDL::PP gl_points PDL::PP gl_lines PDL::PP gl_line_strip PDL::PP gl_texts PDL::PP gl_triangles_mat PDL::PP gl_triangles_n_mat PDL::PP gl_triangles_wn_mat PDL::PP gl_triangles PDL::PP gl_triangles_n PDL::PP gl_triangles_wn PDL::PP gl_arrows );
%EXPORT_TAGS = (Func=>[@EXPORT_OK]);

use PDL::Core;
use PDL::Exporter;
use DynaLoader;



   
   @ISA    = ( 'PDL::Exporter','DynaLoader' );
   push @PDL::Core::PP, __PACKAGE__;
   bootstrap PDL::Graphics::OpenGLQ ;




=head1 NAME

PDL::Graphics::OpenGLQ - quick routines to plot lots of stuff from piddles.

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










*line_3x_3c = \&PDL::line_3x_3c;





*gl_points = \&PDL::gl_points;





*gl_lines = \&PDL::gl_lines;





*gl_line_strip = \&PDL::gl_line_strip;





*gl_texts = \&PDL::gl_texts;





*gl_triangles_mat = \&PDL::gl_triangles_mat;





*gl_triangles_n_mat = \&PDL::gl_triangles_n_mat;





*gl_triangles_wn_mat = \&PDL::gl_triangles_wn_mat;





*gl_triangles = \&PDL::gl_triangles;





*gl_triangles_n = \&PDL::gl_triangles_n;





*gl_triangles_wn = \&PDL::gl_triangles_wn;





*gl_arrows = \&PDL::gl_arrows;



;



# Exit with OK status

1;

		   