#include <GL/gl.h>
#include <GL/glu.h>

/* Reading from perl hashes is annoying.  This simplified function only returns
 * non-NULL if the key existed and the value was defined.
 */
static SV *_fetch_if_defined(HV *self, const char *field, int len) {
	SV **field_p= hv_fetch(self, field, len, 0);
	return (field_p && *field_p && SvOK(*field_p)) ? *field_p : NULL;
}

class Quadric {
	GLUquadric *q;
public:
	Quadric(): q(NULL) {
		q= gluNewQuadric();
	}
	~Quadric() {
		if (q) gluDeleteQuadric(q), q= NULL;
	}
	
	/* Return 'this' for chaining convenience */
	SV* draw_style(int style) {
		Inline_Stack_Vars;
		(void)items; /* silence arning */
		gluQuadricDrawStyle(q, style);
		return Inline_Stack_Item(0);
	}
	SV* draw_fill()       { return draw_style(GLU_FILL); }
	SV* draw_line()       { return draw_style(GLU_LINE); }
	SV* draw_silhouette() { return draw_style(GLU_SILHOUETTE); }
	SV* draw_point()      { return draw_style(GLU_POINT); }
	
	SV* normals(int normals) {
		Inline_Stack_Vars;
		(void)items; /* silence arning */
		gluQuadricNormals(q, normals == 0? GLU_NONE : normals);
		return Inline_Stack_Item(0);
	}
	SV* no_normals()     { return normals(GLU_NONE); }
	SV* flat_normals()   { return normals(GLU_FLAT); }
	SV* smooth_normals() { return normals(GLU_SMOOTH); }
	
	SV* orientation(int orient) {
		Inline_Stack_Vars;
		(void)items; /* silence arning */
		gluQuadricOrientation(q, orient);
		return Inline_Stack_Item(0);
	}
	SV* inside()  { return orientation(GLU_INSIDE); }
	SV* outside() { return orientation(GLU_OUTSIDE); }
	
	SV* texture(bool enabled) {
		Inline_Stack_Vars;
		(void)items; /* silence arning */
		gluQuadricTexture(q, enabled? GLU_TRUE : GLU_FALSE);
		return Inline_Stack_Item(0);
	}
	
	void cylinder(double base, double top, double height, int slices, int stacks) {
		gluCylinder(q, base, top, height, slices, stacks);
	}
	void sphere(double radius, int slices, int stacks) {
		gluSphere(q, radius, slices, stacks);
	}
	void disk(double inner, double outer, int slices, int stacks) {
		gluDisk(q, inner, outer, slices, stacks);
	}
	void partial_disk(double inner, double outer, int slices, int loops, double start, double sweep) {
		gluPartialDisk(q, inner, outer, slices, loops, start, sweep);
	}
};

void _local_gl(SV *code) {
	GLint orig_depth, depth;
	glGetIntegerv(GL_MODELVIEW_STACK_DEPTH, &orig_depth);
	glPushAttrib(GL_ALL_ATTRIB_BITS);
	glPushMatrix();
	call_sv(code, G_ARRAY|G_EVAL);
	glPopMatrix();
	glPopAttrib();
	glGetIntegerv(GL_MODELVIEW_STACK_DEPTH, &depth);
	if (depth > orig_depth) {
		warn("cleaning up matrix stack: depth=%d, orig=%d", depth, orig_depth);
		while (depth-- > orig_depth)
			glPopMatrix();
	}
	if (SvTRUE(ERRSV)) croak(NULL);
}

void _local_matrix(SV *code) {
	GLint orig_depth, depth;
	glGetIntegerv(GL_MODELVIEW_STACK_DEPTH, &orig_depth);
	glPushMatrix();
	call_sv(code, G_ARRAY|G_EVAL);
	glPopMatrix();
	glGetIntegerv(GL_MODELVIEW_STACK_DEPTH, &depth);
	if (depth > orig_depth) {
		warn("cleaning up matrix stack: depth=%d, orig=%d", depth, orig_depth);
		while (depth-- > orig_depth)
			glPopMatrix();
	}
	if (SvTRUE(ERRSV)) croak(NULL);
}

void scale(double scale_x, ...) {
	double scale_y, scale_z;
	Inline_Stack_Vars;
	if (Inline_Stack_Items > 1) {
		scale_y= SvNV(Inline_Stack_Item(1));
		scale_z= (Inline_Stack_Items > 2)? SvNV(Inline_Stack_Item(2)) : 1;
		if (Inline_Stack_Items > 3) warn("extra arguments to scale");
	}
	else {
		scale_y= scale_z= scale_x;
	}
	glScaled(scale_x, scale_y, scale_z);
	Inline_Stack_Void;
}

void trans(double x, double y, ...) {
	Inline_Stack_Vars;
	double z= (Inline_Stack_Items > 2)? SvNV(Inline_Stack_Item(2)) : 0;
	if (Inline_Stack_Items > 3) warn("extra arguments to scale");
	glTranslated(x, y, z);
	Inline_Stack_Void;
}

void trans_scale(double x, double y, double z, double scale_x, ...) {
	double scale_y, scale_z;
	Inline_Stack_Vars;
	glTranslated(x, y, z);
	if (Inline_Stack_Items > 4) {
		scale_y= SvNV(Inline_Stack_Item(4));
		scale_z= (Inline_Stack_Items > 5)? SvNV(Inline_Stack_Item(5)) : 1;
		if (Inline_Stack_Items > 6) warn("extra arguments to trans_scale");
	}
	else {
		scale_y= scale_z= scale_x;
	}
	glScaled(scale_x, scale_y, scale_z);
	Inline_Stack_Void;
}

void rotate(SV *arg0, double arg1, ...) {
	const char *arg0s;
	Inline_Stack_Vars;
	if (Inline_Stack_Items == 4) {
		glRotated(SvNV(arg0), arg1, SvNV(Inline_Stack_Item(2)), SvNV(Inline_Stack_Item(3)));
	}
	else if (Inline_Stack_Items == 2 && SvPOK(arg0)) {
		arg0s= SvPVX(arg0);
		switch(arg0s[0]) {
		case 'x': if (arg0s[1] == '\0') glRotated(arg1, 1.0, 0.0, 0.0); else
		case 'y': if (arg0s[1] == '\0') glRotated(arg1, 0.0, 1.0, 0.0); else
		case 'z': if (arg0s[1] == '\0') glRotated(arg1, 0.0, 0.0, 1.0); else
		default: warn("wrong arguments to rotate");
		}
	}
	else warn("wrong arguments to rotate");
	Inline_Stack_Void;
}

void mirror(const char* axis) {
	while (*axis) {
		switch(*axis++) {
		case 'x': glScaled(-1.0, 0.0, 0.0);
		case 'y': glScaled(0.0, -1.0, 0.0);
		case 'z': glScaled(0.0, 0.0, -1.0);
		default: warn("wrong arguments to mirror");
		}
	}
}

void _quads(SV *code) {
	glBegin(GL_QUADS);
	call_sv(code, G_ARRAY|G_EVAL);
	glEnd();
	if (SvTRUE(ERRSV)) croak(NULL);
}

void _quad_strip(SV *code) {
	glBegin(GL_QUAD_STRIP);
	call_sv(code, G_ARRAY|G_EVAL);
	glEnd();
	if (SvTRUE(ERRSV)) croak(NULL);
}

void _triangles(SV* code) {
	glBegin(GL_TRIANGLES);
	call_sv(code, G_ARRAY|G_EVAL);
	glEnd();
	if (SvTRUE(ERRSV)) croak(NULL);
}

void _triangle_fan(SV *code) {
	glBegin(GL_TRIANGLE_FAN);
	call_sv(code, G_ARRAY|G_EVAL);
	glEnd();
	if (SvTRUE(ERRSV)) croak(NULL);
}

void _triangle_strip(SV *code) {
	glBegin(GL_TRIANGLE_STRIP);
	call_sv(code, G_ARRAY|G_EVAL);
	glEnd();
	if (SvTRUE(ERRSV)) croak(NULL);
}

void _lines(SV *code) {
	glPushAttrib(GL_CURRENT_BIT | GL_ENABLE_BIT);
	glDisable(GL_TEXTURE_2D);
	glBegin(GL_LINES);
	call_sv(code, G_ARRAY|G_EVAL);
	glEnd();
	glPopAttrib();
	if (SvTRUE(ERRSV)) croak(NULL);
}

void _line_strip(SV *code) {
	glPushAttrib(GL_CURRENT_BIT | GL_ENABLE_BIT);
	glDisable(GL_TEXTURE_2D);
	glBegin(GL_LINE_STRIP);
	call_sv(code, G_ARRAY|G_EVAL);
	glEnd();
	glPopAttrib();
	if (SvTRUE(ERRSV)) croak(NULL);
}

void vertex(double x, double y, ...) {
	Inline_Stack_Vars;
	switch (Inline_Stack_Items) {
	case 4: glVertex4d( x, y, SvNV(Inline_Stack_Item(2)), SvNV(Inline_Stack_Item(3)) ); break;
	case 3: glVertex3d( x, y, SvNV(Inline_Stack_Item(2)) ); break;
	case 2: glVertex2d( x, y ); break;
	default: croak("Too many arguments for vertex(): %d", Inline_Stack_Items);
	}
	Inline_Stack_Void;
}

void plot_xy(SV *begin_mode, ...) {
	Inline_Stack_Vars;
	int i, n= Inline_Stack_Items;
	if ((n-1) & 1) warn("Odd number of arguments to plot_xy");
	if (SvOK(begin_mode)) glBegin(SvIV(begin_mode));
	for (i= 1; i+2 <= n; i+= 2) {
		glVertex2d(SvNV(Inline_Stack_Item(i)), SvNV(Inline_Stack_Item(i+1)));
	}
	if (SvOK(begin_mode)) glEnd();
	Inline_Stack_Void;
}

void plot_xyz(SV *begin_mode, ...) {
	Inline_Stack_Vars;
	int i, n= Inline_Stack_Items;
	if ((n-1) % 3) warn("Non-multiple-of-3 arguments to plot_xyz");
	if (SvOK(begin_mode)) glBegin(SvIV(begin_mode));
	for (i= 1; i+3 <= n; i+= 3) {
		glVertex3d(SvNV(Inline_Stack_Item(i)), SvNV(Inline_Stack_Item(i+1)), SvNV(Inline_Stack_Item(i+2)));
	}
	if (SvOK(begin_mode)) glEnd();
	Inline_Stack_Void;
}

void plot_st_xy(SV *begin_mode, ...) {
	Inline_Stack_Vars;
	int i, n= Inline_Stack_Items;
	if ((n-1) & 3) warn("Non-multiple-of-4 arguments to plot_st_xy");
	if (SvOK(begin_mode)) glBegin(SvIV(begin_mode));
	for (i= 1; i+4 <= n; i+= 4) {
		glTexCoord2d(SvNV(Inline_Stack_Item(i)), SvNV(Inline_Stack_Item(i+1)));
		glVertex2d(SvNV(Inline_Stack_Item(i+2)), SvNV(Inline_Stack_Item(i+3)));
	}
	if (SvOK(begin_mode)) glEnd();
	Inline_Stack_Void;
}

void plot_st_xyz(SV *begin_mode, ...) {
	Inline_Stack_Vars;
	int i, n= Inline_Stack_Items;
	if ((n-1) % 5) warn("Non-multiple-of-5 arguments to plot_st_xyz");
	if (SvOK(begin_mode)) glBegin(SvIV(begin_mode));
	for (i= 1; i+5 <= n; i+= 5) {
		glTexCoord2d(SvNV(Inline_Stack_Item(i)), SvNV(Inline_Stack_Item(i+1)));
		glVertex3d(SvNV(Inline_Stack_Item(i+2)), SvNV(Inline_Stack_Item(i+3)), SvNV(Inline_Stack_Item(i+4)));
	}
	if (SvOK(begin_mode)) glEnd();
	Inline_Stack_Void;
}

void plot_norm_st_xyz(SV *begin_mode, ...) {
	Inline_Stack_Vars;
	int i, n= Inline_Stack_Items;
	if ((n-1) & 7) warn("Non-multiple-of-8 arguments to plot_norm_st_xyz");
	if (SvOK(begin_mode)) glBegin(SvIV(begin_mode));
	for (i= 1; i+8 <= n; i+= 8) {
		glNormal3d(SvNV(Inline_Stack_Item(i)), SvNV(Inline_Stack_Item(i+1)), SvNV(Inline_Stack_Item(i+2)));
		glTexCoord2d(SvNV(Inline_Stack_Item(i+3)), SvNV(Inline_Stack_Item(i+4)));
		glVertex3d(SvNV(Inline_Stack_Item(i+5)), SvNV(Inline_Stack_Item(i+6)), SvNV(Inline_Stack_Item(i+7)));
	}
	if (SvOK(begin_mode)) glEnd();
	Inline_Stack_Void;
}

/* Draw a line between (x0,y0,z0) and (x1,y1,z1), and then step by (dX,dY,dZ) and do it again, count times */
void plot_stripe(double x0, double y0, double z0, double x1, double y1, double z1, double dX, double dY, double dZ, int count) {
	for (int i=0; i < count; i++) {
		glVertex3d(x0, y0, z0); glVertex3d(x1, y1, z1);
		x0+= dX; y0+= dY; z0+= dZ;
		x1+= dX; y1+= dY; z1+= dZ;
	}
}

void plot_rect(double x0, double y0, double x1, double y1) {
	glVertex2d(x0, y0); glVertex2d(x1, y0);
	glVertex2d(x1, y1); glVertex2d(x0, y1);
}

void plot_rect3(double x0, double y0, double z0, double x1, double y1, double z1) {
	/* XY plane at z1 */
	glVertex3d(x0, y0, z1); glVertex3d(x1, y0, z1);
	glVertex3d(x1, y1, z1); glVertex3d(x0, y1, z1);
	/* XY plane at z0 */
	glVertex3d(x1, y0, z0); glVertex3d(x0, y0, z0);
	glVertex3d(x0, y1, z0); glVertex3d(x1, y1, z0);
	/* YZ plane at x0 */
	glVertex3d(x0, y0, z0); glVertex3d(x0, y0, z1);
	glVertex3d(x0, y1, z1); glVertex3d(x0, y1, z0);
	/* YZ plane at x1 */
	glVertex3d(x1, y0, z0); glVertex3d(x1, y0, z0);
	glVertex3d(x1, y1, z0); glVertex3d(x1, y1, z1);
	/* XZ plane at y0 */
	glVertex3d(x0, y0, z0); glVertex3d(x1, y0, z0);
	glVertex3d(x1, y0, z0); glVertex3d(x0, y0, z1);
	/* XZ plane at y1 */
	glVertex3d(x0, y1, z1); glVertex3d(x1, y1, z1);
	glVertex3d(x1, y1, z0); glVertex3d(x0, y1, z0);
}

void _setcolor(SV *thing, ...) {
	Inline_Stack_Vars;
	unsigned c;
	if (Inline_Stack_Items == 4) {
		glColor4d(SvNV(thing), SvNV(Inline_Stack_Item(1)), SvNV(Inline_Stack_Item(2)), SvNV(Inline_Stack_Item(3)));
	}
	else if (Inline_Stack_Items == 3) {
		glColor4d(SvNV(thing), SvNV(Inline_Stack_Item(1)), SvNV(Inline_Stack_Item(2)), 1);
	}
	else if (Inline_Stack_Items == 1) {
		c= SvUV(thing);
		glColor4ub((GLbyte)(c>>24), (GLbyte)(c>>16), (GLbyte)(c>>8), (GLbyte)c);
	}
	else warn("wrong arguments");
	Inline_Stack_Void;
}

SV * _displaylist_compile(SV *self, SV *code) {
	int list_id;
	if (SvROK(self) && SvIOK(SvRV(self)))
		list_id= SvIV(SvRV(self));
	else {
		list_id= glGenLists(1);
		if (sv_derived_from(self, "OpenGL::Sandbox::V1::DisplayList"))
			sv_setiv(SvRV(self), list_id);
		else
			/* force self to become a blessed Displaylist, in style of open(my $x) forcing $x to become a filehandle */
			sv_setref_iv(self, "OpenGL::Sandbox::V1::DisplayList", list_id);
	}
	
	glNewList(list_id, GL_COMPILE);
	call_sv(code, G_ARRAY|G_EVAL);
	glEndList();
	if (SvTRUE(ERRSV)) croak(NULL);
	return self;
}

void _displaylist_call(SV *self, ...) {
	Inline_Stack_Vars;
	int list_id;
	SV *code;
	if (SvROK(self) && SvIOK(SvRV(self)))
		glCallList(SvIV(SvRV(self)));
	else if (Inline_Stack_Items > 1 && SvOK(code= Inline_Stack_Item(1))) {
		list_id= glGenLists(1);
		if (sv_derived_from(self, "OpenGL::Sandbox::V1::DisplayList"))
			sv_setiv(SvRV(self), list_id);
		else
			/* force self to become a blessed Displaylist, in style of open(my $x) forcing $x to become a filehandle */
			sv_setref_iv(self, "OpenGL::Sandbox::V1::DisplayList", list_id);
		
		glNewList(list_id, GL_COMPILE_AND_EXECUTE);
		call_sv(code, G_ARRAY|G_EVAL);
		glEndList();
		if (SvTRUE(ERRSV)) croak(NULL);
	}
	else warn("Calling un-initialized display list");
	Inline_Stack_Reset;
	Inline_Stack_Push(self);
	Inline_Stack_Done;
}

static void _parse_color(SV *c, double *rgba);
/* would prefer this to be a function, but the Inline_Stack_* macros seem to get messed up
   if you run them from a called function */
#define _color_from_stack(dest) \
	do { \
		if (Inline_Stack_Items == 1) \
			_parse_color(Inline_Stack_Item(0), dest); \
		else if (Inline_Stack_Items == 3) { \
			for (i= 0; i < 3; i++) \
				dest[i]= SvNV(Inline_Stack_Item(i)); \
			dest[i]= 1.0; \
		} \
		else if (Inline_Stack_Items == 4) { \
			for (i= 0; i < 4; i++) \
				dest[i]= SvNV(Inline_Stack_Item(i)); \
		} \
		else croak("Expected 1, 3, or 4 arguments"); \
	} while (0)

void setcolor(SV *c0, ...) {
	Inline_Stack_Vars;
	double components[4];
	GLfloat components_f[4];
	int i;
	(void)items; /* silence warning */
	
	_color_from_stack(components);
	for (i= 0; i < 4; i++)
		components_f[i]= components[i];
	glColor4fv(components_f);
	Inline_Stack_Void;
}

void color_parts(SV *c, ...) {
	Inline_Stack_Vars;
	double components[4];
	int i;
	(void)items; /* silence warning */
	
	_color_from_stack(components);
	Inline_Stack_Reset;
	for (i=0; i < 4; i++)
		Inline_Stack_Push(sv_2mortal(newSVnv(components[i])));
	Inline_Stack_Done;
}

void color_mult(SV *c0, SV *c1) {
	Inline_Stack_Vars;
	double components[8];
	int i;
	(void)items; /* silence warning */
	
	_parse_color(c0, components);
	_parse_color(c1, components+4);
	Inline_Stack_Reset;
	for (i=0; i < 4; i++)
		Inline_Stack_Push(sv_2mortal(newSVnv(components[i] * components[i+4])));
	Inline_Stack_Done;
}

static void _parse_color(SV *c, double *rgba) {
	SV **field_p;
	int i, n;
	unsigned hex_rgba[4];
	if (!SvOK(c)) {
		rgba[0]= rgba[1]= rgba[2]= 0;
		rgba[3]= 1;
	}
	else if (SvROK(c) && SvTYPE(SvRV(c)) == SVt_PVAV) {
		for (i=0; i < 4; i++) {
			field_p= av_fetch((AV*) SvRV(c), i, 0);
			rgba[i]= (field_p && *field_p && SvOK(*field_p))? SvNV(*field_p) : 0;
		}
	}
	else {
		n= sscanf(SvPV_nolen(c), "#%2x%2x%2x%2x", hex_rgba+0, hex_rgba+1, hex_rgba+2, hex_rgba+3);
		if (n < 3) croak("Not a valid color: %s", SvPV_nolen(c));
		if (n < 4) hex_rgba[3]= 0xFF;
		for (i=0; i < 4; i++)
			rgba[i]= hex_rgba[i] / 255.0;
	}
}

void _texture_render(HV *self, ...) {
	Inline_Stack_Vars;
	SV *value, *w_sv= NULL, *h_sv= NULL, *def_w, *def_h;
	double x= 0, y= 0, z= 0, s= 0, t= 0, s_rep= 1, t_rep= 1;
	double w, h, scale= 1;
	int i, center= 0;
	const char *key;
	
	if (!(Inline_Stack_Items & 1))
		/* stack items includes $self, so an actual odd number is a logical even number */
		croak("Odd number of parameters passed to ->render");

	for (i= 1; i < Inline_Stack_Items-1; i+= 2) {
		key= SvPV_nolen(Inline_Stack_Item(i));
		value= Inline_Stack_Item(i+1);
		if (!SvOK(value)) continue; /* ignore anything that isn't defined */
		switch (*key) {
		case 'x': if (!key[1]) x= SvNV(value);
			else
		case 'y': if (!key[1]) y= SvNV(value);
			else
		case 'z': if (!key[1]) z= SvNV(value);
			else
		case 'w': if (!key[1]) w_sv= value;
			else
		case 'h': if (!key[1]) h_sv= value;
			else
		case 't': if (!key[1]) t= SvNV(value);
			else if (strcmp("t_rep", key) == 0) t_rep= SvNV(value);
			else
		case 's': if (!key[1]) s= SvNV(value);
			else if (strcmp("s_rep", key) == 0) s_rep= SvNV(value);
			else if (strcmp("scale", key) == 0) scale= SvNV(value);
			else
		case 'c': if (strcmp("center", key) == 0) center= SvTRUE(value);
			else
		default:
			croak("Invalid key '%s' in call to render()", key);
		}
	}
	/* width and height default to the src_width and src_height, or width, height.
	 * but, if one one dimension given, then use those defaults as an aspect ratio to calculate the other */
	if (w_sv && h_sv) {
		w= SvNV(w_sv);
		h= SvNV(h_sv);
	}
	else {
		def_w= _fetch_if_defined(self, "src_width", 9);
		if (!def_w) def_w= _fetch_if_defined(self, "width", 5);
		if (!def_w) croak("No width defined on texture");
		def_h= _fetch_if_defined(self, "src_height", 10);
		if (!def_h) def_h= _fetch_if_defined(self, "height", 6);
		if (!def_h) croak("No height defined on texture");
		/* depending which we have, multiply by aspect ratio to calculate the other */
		if (w_sv) {
			w= SvNV(w_sv);
			h= w * SvNV(def_h) / SvNV(def_w);
		}
		else if (h_sv) {
			h= SvNV(h_sv);
			w= h * SvNV(def_w) / SvNV(def_h);
		}
		else {
			w= SvNV(def_w);
			h= SvNV(def_h);
		}
	}
	/* If scaled, adjust w,h */
	w *= scale;
	h *= scale;
	/* If centered, then adjust the x and y */
	if (center) {
		x -= w * .5;
		y -= h * .5;
	}
	//fprintf(stderr, "Rendering texture: x=%.5f y=%.5f w=%.5f h=%.5f s=%.5f t=%.5f s_rep=%.5f t_rep=%.5f\n",
	//	x, y, w, h, s, t, s_rep, t_rep);
	
	/* TODO: If texture is NonPowerOfTwo, then multiply the s_rep and t_rep values. */
	glBegin(GL_QUADS);
	glTexCoord2d(s, t);
	glVertex3d(x, y, z);
	glTexCoord2d(s+s_rep, t);
	glVertex3d(x+w, y, z);
	glTexCoord2d(s+s_rep, t+t_rep);
	glVertex3d(x+w, y+h, z);
	glTexCoord2d(s, t+t_rep);
	glVertex3d(x, y+h, z);
	glEnd();
	Inline_Stack_Void;
}

void get_viewport_rect(...) {
	Inline_Stack_Vars;
	GLint rect[4];
	int i;
	glGetIntegerv(GL_VIEWPORT, rect);
	Inline_Stack_Reset;
	for (i=0; i < 4; i++)
		Inline_Stack_Push(sv_2mortal(newSViv(rect[i])));
	Inline_Stack_Done;
}
