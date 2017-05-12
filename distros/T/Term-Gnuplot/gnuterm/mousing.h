/*  mousing.h

Version 25. 10. 1999

This unit is #included by:
  - a mouse capable terminal; currently used by
	- os2/gclient
	- gplt_x11.c
    in order to use the  gp4mouse  structure
  - .trm file of a mouseable terminal; currently used by
	- pm.trm
	- x11.trm
    in order to use the  gp4mouse  structure
*/

#ifndef MOUSING_H
#define MOUSING_H

/* Structure for mouse used for the recalculation of the mouse coordinates
   in pixels into the true coordinates of the plot.
*/

struct gp4mouse_s {
    int graph;
      /*
      What the mouse is moving over?
	0 ... cannot use mouse with this graph---multiplot, for instance.
	1 ... 2d polar graph
	2 ... 2d graph
	3 ... 3d graph (not implemented, thus pm.trm sends 0)
	// note: 3d picture plotted as a 2d map is treated as 2d graph
      */
    double xmin, ymin, xmax, ymax; /* range of x1 and y1 axes of 2d plot */
    int xleft, ybot, xright, ytop; /* pixel positions of the above */
    int /*TBOOLEAN*/ is_log_x, is_log_y; /* are x and y axes log? */
    double base_log_x, base_log_y; /* bases of log */
    double log_base_log_x, log_base_log_y; /* log of bases */
    int has_grid; /* grid on? */
};

extern struct gp4mouse_s gp4mouse;
#ifdef DEFINE_GP4MOUSE
struct gp4mouse_s gp4mouse;
#endif

enum { no_mouse = 0, graph2dpolar, graph2d, graph3d };

#endif /* MOUSING_H */
