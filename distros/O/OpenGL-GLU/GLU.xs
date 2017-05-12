/*  Copyright (c) 2017 Chris Marshall. All rights reserved.
 *  Copyright (c) 2011 Paul Seamons. All rights reserved.
 *  Copyright (c) 2009 Chris Marshall. All rights reserved.
 *  Copyright (c) 2007 Bob Free. All rights reserved.
 *  Copyright (c) 1998 Kenneth Albanowski. All rights reserved.
 *
 *  This program is free software; you can redistribute it
 *  and/or modify it under the same terms as Perl itself.
 */

/* OpenGL GLU bindings */
#include <stdio.h>

#include "gl_util.h"

#if defined(__APPLE__)
#include <OpenGL/glu.h>
#else
#include <GL/glu.h>
#endif

#ifndef GLU_VERSION_1_0
#define GLU_VERSION_1_0 1
#endif

#ifdef GLU_VERSION_1_0
#ifndef GLU_VERSION_1_1
typedef GLUnurbs                GLUnurbsObj;
typedef GLUtriangulatorObj      GLUtriangulatorObj;
typedef GLUquadricObj           GLUquadricObjObj;
#endif
#endif

#include "const-c.inc"

#ifndef CALLBACK
#define CALLBACK
#endif

struct PGLUtess {
    GLUtesselator * triangulator;
#ifdef GLU_VERSION_1_2
    SV * begin_callback;
    SV * edgeFlag_callback;
    SV * vertex_callback;
    SV * end_callback;
    SV * error_callback;
    SV * combine_callback;
#endif
    bool do_colors;
    bool do_normals;
    bool use_vertex_data;
    GLdouble * vertex_data; /* used during non-GLU_TESS_VERTEX_DATA */
    SV * polygon_data;
    AV * vertex_datas;
    AV * tess_datas;
};

typedef struct PGLUtess PGLUtess;

#define delete_vertex_datas() \
    if (tess->vertex_datas) {                    \
        AV * vds = tess->vertex_datas;             \
        SV** svp;                                  \
        I32 i;                                     \
        for (i=0; i<=av_len(vds); i++) {           \
            svp = av_fetch(vds, i, FALSE);           \
            free(INT2PTR(GLdouble*, SvIV(*svp)));    \
        }                                          \
        SvREFCNT_dec(tess->vertex_datas);          \
        tess->vertex_datas = 0;                    \
    }

#define delete_tess_datas() \
    if (tess->tess_datas) {                      \
        AV * tds = tess->tess_datas;               \
        SV** svp;                                  \
        I32 i;                                     \
        for (i=0; i<=av_len(tds); i++) {           \
            svp = av_fetch(tds, i, FALSE);           \
            free(INT2PTR(PGLUtess*, SvIV(*svp)));    \
        }                                          \
        SvREFCNT_dec(tess->tess_datas);            \
        tess->tess_datas = 0;                      \
    }

#define delete_polygon_data()                             \
    if (tess->polygon_data) {                 \
        SvREFCNT_dec(tess->polygon_data); \
        tess->polygon_data = 0;           \
    }



#ifdef GLU_VERSION_1_2


/* Begin a named callback handler */
#define begin_tess_marshaller(name, type, params, croak_msg, default_handler) \
    void CALLBACK _s_marshal_glu_t_callback_ ## name params                 \
{                                                                       \
    dSP;                                                                \
    int i; int j = 3;                                                   \
    PGLUtess * t = (PGLUtess*)gl_polygon_data;                          \
    SV * handler = t-> type ## _callback;                               \
    if (!handler) croak(croak_msg);                                     \
    if (! SvROK(handler)) { /* default */                               \
        default_handler;                                                  \
        return;                                                           \
    }                                                                   \
    PUSHMARK(sp);

    /* End a gluTess callback handler */
#define end_tess_marshaller()                                           \
    PUTBACK;                                                        \
    perl_call_sv(handler, G_DISCARD);                               \
}


/* Declare gluTess BEGIN */
begin_tess_marshaller(begin, begin, (GLenum type, void * gl_polygon_data), "Missing tess callback for begin", glBegin(type))
XPUSHs(sv_2mortal(newSViv(type)));
end_tess_marshaller()

    /* Declare gluTess BEGIN_DATA */
    begin_tess_marshaller(begin_data, begin, (GLenum type, void * gl_polygon_data), "Missing tess callback for begin_data", glBegin(type))
    XPUSHs(sv_2mortal(newSViv(type)));
    if (t->polygon_data) XPUSHs((SV*)t->polygon_data);
end_tess_marshaller()

    /* Declare gluTess END */
    begin_tess_marshaller(end, end, (void * gl_polygon_data), "Missing tess callback for end", glEnd())
end_tess_marshaller()

    /* Declare gluTess END_DATA */
    begin_tess_marshaller(end_data, end, (void * gl_polygon_data), "Missing tess callback for end_data", glEnd())
    if (t->polygon_data) XPUSHs((SV*)t->polygon_data);
end_tess_marshaller()

    /* Declare gluTess EDGEFLAG */
    begin_tess_marshaller(edgeFlag, edgeFlag, (GLboolean flag, void * gl_polygon_data), "Missing tess callback for edgeFlag", glEdgeFlag(flag))
    XPUSHs(sv_2mortal(newSViv(flag)));
end_tess_marshaller()

    /* Declare gluTess EDGEFLAG_DATA */
    begin_tess_marshaller(edgeFlag_data, edgeFlag, (GLboolean flag, void * gl_polygon_data), "Missing tess callback for edgeFlag_data", glEdgeFlag(flag))
    XPUSHs(sv_2mortal(newSViv(flag)));
    if (t->polygon_data) XPUSHs((SV*)t->polygon_data);
end_tess_marshaller()

    /* Declare gluTess VERTEX */
    begin_tess_marshaller(vertex, vertex, (void * gl_polygon_data), "Missing tess callback for vertex", \
            GLdouble * vd = t->vertex_data;                                   \
            if (t->do_colors) { \
            glColor4f(vd[j], vd[j+1], vd[j+2], vd[j+3]); \
            j += 4; \
            } \
            if (t->do_normals) glNormal3f(vd[j], vd[j+1], vd[j+2]);           \
            glVertex3f(vd[0], vd[1], vd[2]);                                  \
            )
{
    GLdouble * vd = (GLdouble*) t->vertex_data;
    for (i = 0; i < 3; i++)
        XPUSHs(sv_2mortal(newSVnv(vd[i])));
    if (t->do_colors) {
        int J = j + 4;
        for ( ; j < J; j++)
            XPUSHs(sv_2mortal(newSVnv(vd[j])));
    }
    if (t->do_normals)
        for (i = 0; i < 3; i++)
            XPUSHs(sv_2mortal(newSVnv(vd[j++])));
    if (t->polygon_data) XPUSHs((SV*)t->polygon_data);
}
end_tess_marshaller()

    /* Declare gluTess VERTEX_DATA */
    begin_tess_marshaller(vertex_data, vertex, (void * vertex_data, void * gl_polygon_data), "Missing tess callback for vertex_data", \
            GLdouble * vd = (GLdouble*) vertex_data;                          \
            if (t->do_colors) { \
            glColor4f(vd[j], vd[j+1], vd[j+2], vd[j+3]); \
            j += 4; \
            } \
            if (t->do_normals) glNormal3f(vd[j], vd[j+1], vd[j+2]);           \
            glVertex3f(vd[0], vd[1], vd[2]);                                  \
            )
    if (! vertex_data) croak("Missing vertex data in tess vertex_data callback");
{
    GLdouble * vd = (GLdouble*) vertex_data;
    for (i = 0; i < 3; i++)
        XPUSHs(sv_2mortal(newSVnv(vd[i])));
    if (t->do_colors) {
        int J = j + 4;
        for ( ; j < J; j++)
            XPUSHs(sv_2mortal(newSVnv(vd[j])));
    }
    if (t->do_normals)
        for (i = 0; i < 3; i++)
            XPUSHs(sv_2mortal(newSVnv(vd[j++])));
    if (t->polygon_data) XPUSHs((SV*)t->polygon_data);
}
end_tess_marshaller()

    /* Declare gluTess ERROR */
    begin_tess_marshaller(error, error, (GLenum errno_, void * gl_polygon_data), "Missing tess callback for error", \
            warn("Tesselation error: %s", gluErrorString(errno_)); \
            )
    XPUSHs(sv_2mortal(newSViv(errno_)));
end_tess_marshaller()

    /* Declare gluTess ERROR_DATA */
    begin_tess_marshaller(error_data, error, (GLenum errno_, void * gl_polygon_data), "Missing tess callback for error_data", \
            warn("Tesselation error: %s", gluErrorString(errno_)); \
            )
    XPUSHs(sv_2mortal(newSViv(errno_)));
    if (t->polygon_data) XPUSHs((SV*)t->polygon_data);
end_tess_marshaller()

    /* Declare gluTess COMBINE AND COMBINE_DATA */
void CALLBACK _s_marshal_glu_t_callback_combine (GLdouble coords[3], void * vertex_data[4],
        GLfloat weight[4], void ** out_data,
        void * gl_polygon_data)
{
    SV * handler;
    AV * vds;
    SV * item;
    I32 n;
    int i, j = 3;
    dSP;
    GLdouble *vd[4];
    PGLUtess *t = (PGLUtess*)gl_polygon_data;
    bool has_data = FALSE;
    int size = 3 + (t->do_colors ? 4 : 0) + (t->do_normals ? 3 : 0);
    GLdouble *vertex = malloc(sizeof(GLdouble) * size);
    if (vertex == NULL) croak("Couldn't allocate combination vertex during tesselation");
    vds = t->vertex_datas;
    if (!vds) croak("Missing vertex data storage");
    av_push(vds, newSViv(PTR2IV(vertex)));

    handler = t->combine_callback;
    if (!handler) croak("Missing tess callback for combine_data");

    if (t->use_vertex_data) {
        PGLUtess * opaque = malloc(sizeof(PGLUtess));
        if (!opaque) croak("Couldn't allocate storage for vertex opaque data");
        opaque->triangulator     = t->triangulator;
        opaque->vertex_datas     = t->vertex_datas;
        opaque->vertex_callback  = t->vertex_callback;
        opaque->combine_callback = t->combine_callback;
        opaque->vertex_data      = vertex;
        opaque->polygon_data     = &PL_sv_undef;
        opaque->use_vertex_data  = TRUE;
        opaque->do_colors        = t->do_colors;
        opaque->do_normals       = t->do_normals;
        if (! t->tess_datas) t->tess_datas = newAV();
        av_push(t->tess_datas, newSViv(PTR2IV(opaque)));
        *out_data = opaque;
        for (i = 0; i < 4; i++) {
            PGLUtess* ot = (PGLUtess*)vertex_data[i];
            vd[i] = (GLdouble*)ot->vertex_data;
        }
    } else {
        *out_data = vertex;
        for (i = 0; i < 4; i++)
            vd[i] = (GLdouble*)vertex_data[i];
    }

    if (! SvROK(handler)) { /* default */
        vertex[0] = coords[0];
        vertex[1] = coords[1];
        vertex[2] = coords[2];
        if (t->do_colors) {
            int J = j + 4;
            for ( ; j < J; j++) {
                vertex[j] = 0;
                for (i = 0; i < 4; i++)
                    if (weight[i]) vertex[j] += weight[i] * vd[i][j];
            }
        }
        if (t->do_normals) {
            int J = j + 3;
            for ( ; j < J; j++) {
                vertex[j] = 0;
                for (i = 0; i < 4; i++)
                    if (weight[i]) vertex[j] += weight[i] * vd[i][j];
            }
        }
    } else {
        PUSHMARK(sp);
        for (i = 0; i < 3; i++)
            XPUSHs(sv_2mortal(newSVnv(coords[i])));
        for (i = 0; i < 4; i++) {
            AV* vec = (AV*)sv_2mortal((SV*)newAV());
            XPUSHs(newRV_inc((SV*)vec));
            for (j = 0 ; j < 3; j++)
                av_push(vec, sv_2mortal(newSVnv(weight[i] ? vd[i][j] : 0)));
            if (t->do_colors) {
                int J = j + 4;
                for ( ; j < J; j++)
                    av_push(vec, sv_2mortal(newSVnv(weight[i] ? vd[i][j] : 0)));
            }
            if (t->do_normals) {
                int J = j + 3;
                for ( ; j < J; j++)
                    av_push(vec, sv_2mortal(newSVnv(weight[i] ? vd[i][j] : 0)));
            }
            if (t->use_vertex_data) {
                PGLUtess* ot = (PGLUtess*)vertex_data[i];
                av_push(vec, ot->polygon_data ? ot->polygon_data : &PL_sv_undef);
            }
        }
        for (i = 0; i < 4; i++)
            XPUSHs(sv_2mortal(newSVnv(weight[i])));
        XPUSHs(t->polygon_data ? t->polygon_data : &PL_sv_undef); /* would be nice to have the option to only do this on COMBINE_DATA */

        PUTBACK;

        n = perl_call_sv(handler, G_ARRAY);

        SPAGAIN;

        if (t->do_colors) {
            if (t->do_normals) {
                if (n == 11 && t->use_vertex_data) has_data = TRUE;
                else if (n != 10) {
                    if (t->use_vertex_data) croak("Callback expects (x,y,z, r,g,b,a, nx,ny,nz [,polygon_data])");
                    else  croak("Callback expects (x,y,z, r,g,b,a, nx,ny,nz)");
                }
            } else {
                if (n == 8 && t->use_vertex_data) has_data = TRUE;
                else if (n != 7) {
                    if (t->use_vertex_data) croak("Callback expects (x,y,z, r,g,b,a [,polygon_data])");
                    else  croak("Callback expects (x,y,z, r,g,b,a)");
                }
            }
        } else {
            if (t->do_normals) {
                if (n == 7 && t->use_vertex_data) has_data = TRUE;
                else if (n != 6) {
                    if (t->use_vertex_data) croak("Callback expects (x,y,z, nx,ny,nz [,polygon_data])");
                    else  croak("Callback expects (x,y,z, nx,ny,nz)");
                }
            } else {
                if (n == 4 && t->use_vertex_data) has_data = TRUE;
                else if (n != 3) {
                    if (t->use_vertex_data) croak("Callback expects (x,y,z [,polygon_data])");
                    else  croak("Callback expects (x,y,z)");
                }
            }
        }

        if (t->use_vertex_data) {
            PGLUtess* opaque = (PGLUtess*)*out_data;
            opaque->polygon_data = (has_data) ? POPs : 0;
        }

        for (i = n - (has_data ? 2 : 1); i >= 0; i--) {
            GLdouble val;
            item = POPs;
            if (! item || (! SvIOK(item) && ! SvNOK(item)))
                croak("Value returned in index %d was not a valid number", i);
            val = (GLdouble)SvNV(item);
            vertex[i] = val;
        }
        PUTBACK;
    }
}

#endif


MODULE = OpenGL::GLU            PACKAGE = OpenGL::GLU


##################### GLU #########################

#// $nurb->gluBeginCurve($nurb);
void
gluBeginCurve(nurb)
    GLUnurbsObj *   nurb

#// gluEndCurve($nurb);
void
gluEndCurve(nurb)
    GLUnurbsObj *   nurb

#// gluBeginPolygon($tess);
void
gluBeginPolygon(tess)
    PGLUtess *      tess
    CODE:
    gluBeginPolygon(tess->triangulator);

#// gluEndPolygon($tess);
void
gluEndPolygon(tess)
    PGLUtess *      tess
    CODE:
    gluEndPolygon(tess->triangulator);

#// gluBeginSurface($nurb);
void
gluBeginSurface(nurb)
    GLUnurbsObj *   nurb

#// gluEndSurface($nurb);
void
gluEndSurface(nurb)
    GLUnurbsObj *   nurb

#// gluBeginTrim($nurb);
void
gluBeginTrim(nurb)
    GLUnurbsObj *   nurb

#// gluEndTrim($nurb);
void
gluEndTrim(nurb)
    GLUnurbsObj *   nurb

#//# gluBuild1DMipmaps_c($target, $internalformat, $width, $format, $type, (CPTR)data);
GLint
gluBuild1DMipmaps_c(target, internalformat, width, format, type, data)
    GLenum  target
    GLuint  internalformat
    GLsizei width
    GLenum  format
    GLenum  type
    void *  data
    CODE:
{
    RETVAL=gluBuild1DMipmaps(target, internalformat,
            width, format, type, data);
}
OUTPUT:
RETVAL

#//# gluBuild1DMipmaps_s($target, $internalformat, $width, $format, $type, (PACKED)data);
GLint
gluBuild1DMipmaps_s(target, internalformat, width, format, type, data)
    GLenum  target
    GLuint  internalformat
    GLsizei width
    GLenum  format
    GLenum  type
    SV *    data
    CODE:
{
    GLvoid * ptr = ELI(data, width, 1, format, type, gl_pixelbuffer_unpack);
    RETVAL=gluBuild1DMipmaps(target, internalformat, width, format, type, ptr);
}
OUTPUT:
RETVAL

#//# gluBuild2DMipmaps_c($target, $internalformat, $width, $height, $format, $type, (CPTR)data);
GLint
gluBuild2DMipmaps_c(target, internalformat, width, height, format, type, data)
    GLenum  target
    GLuint  internalformat
    GLsizei width
    GLsizei height
    GLenum  format
    GLenum  type
    void *  data
    CODE:
{
    RETVAL=gluBuild2DMipmaps(target, internalformat,
            width, height, format, type, data);
}
OUTPUT:
RETVAL

#//# gluBuild2DMipmaps_s($target, $internalformat, $width, $height, $format, $type, (PACKED)data);
GLint
gluBuild2DMipmaps_s(target, internalformat, width, height, format, type, data)
    GLenum  target
    GLuint  internalformat
    GLsizei width
    GLsizei height
    GLenum  format
    GLenum  type
    SV *    data
    CODE:
{
    GLvoid * ptr = ELI(data, width, height, format, type, gl_pixelbuffer_unpack);
    RETVAL=gluBuild2DMipmaps(target, internalformat, width, height, format, type, ptr);
}
OUTPUT:
RETVAL

#// gluCylinder($quad, $base, $top, $height, $slices, $stacks);
void
gluCylinder(quad, base, top, height, slices, stacks)
    GLUquadricObj * quad
    GLdouble        base
    GLdouble        top
    GLdouble        height
    GLint   slices
    GLint   stacks

#// gluDeleteNurbsRenderer($nurb);
void
gluDeleteNurbsRenderer(nurb)
    GLUnurbsObj *   nurb

#// gluDeleteQuadric($quad);
void
gluDeleteQuadric(quad)
    GLUquadricObj * quad

#// gluDeleteTess($tess);
void
gluDeleteTess(tess)
    PGLUtess *      tess
    CODE:
{
    if (tess->triangulator)
        gluDeleteTess(tess->triangulator);
#ifdef GLU_VERSION_1_2
    if (tess->begin_callback)
        SvREFCNT_dec(tess->begin_callback);
    if (tess->edgeFlag_callback)
        SvREFCNT_dec(tess->edgeFlag_callback);
    if (tess->vertex_callback)
        SvREFCNT_dec(tess->vertex_callback);
    if (tess->end_callback)
        SvREFCNT_dec(tess->end_callback);
    if (tess->error_callback)
        SvREFCNT_dec(tess->error_callback);
    if (tess->combine_callback)
        SvREFCNT_dec(tess->combine_callback);
#endif
    delete_vertex_datas()
        delete_tess_datas()
        delete_polygon_data()
        free(tess);
}

#// gluDisk($quad, $inner, $outer, $slices, $loops);
void
gluDisk(quad, inner, outer, slices, loops)
    GLUquadricObj * quad
    GLdouble        inner
    GLdouble        outer
    GLint   slices
    GLint   loops

#//# gluErrorString($error);
char *
gluErrorString(error)
    GLenum  error
    CODE:
    RETVAL = (char*)gluErrorString(error);
OUTPUT:
RETVAL

#// gluGetNurbsProperty_p($nurb, $property);
GLfloat
gluGetNurbsProperty_p(nurb, property)
    GLUnurbsObj *   nurb
    GLenum  property
    CODE:
{
    GLfloat param;
    gluGetNurbsProperty(nurb, property, &param);
    RETVAL = param;
}
OUTPUT:
RETVAL

#// gluNurbsProperty(nurb, property, value);
void
gluNurbsProperty(nurb, property, value)
    GLUnurbsObj *   nurb
    GLenum  property
    GLfloat value

#ifdef GLU_VERSION_1_1

#//# gluGetString($name);
char *
gluGetString(name)
    GLenum  name
    CODE:
    RETVAL = (char*)gluGetString(name);
OUTPUT:
RETVAL

#endif

#// gluLoadSamplingMatrices_p(nurb, m1,m2,m3,m4,m5,m6,m7,m8,m9,m10,m11,m12,m13,m14,m15,m16, o1,o2,o3,o4,o5,o6,o7,o8,o9,o10,o11,o12,o13,o14,o15,o16, v1,v2,v3,v4);
void
gluLoadSamplingMatrices_p(nurb, m1,m2,m3,m4,m5,m6,m7,m8,m9,m10,m11,m12,m13,m14,m15,m16, o1,o2,o3,o4,o5,o6,o7,o8,o9,o10,o11,o12,o13,o14,o15,o16, v1,v2,v3,v4)
    GLUnurbsObj *   nurb
    CODE:
{
    GLfloat m[16], p[16];
    GLint v[4];
    int i;
    for (i=0;i<16;i++)
        m[i] = (GLfloat)SvNV(ST(i+1));
    for (i=0;i<16;i++)
        p[i] = (GLfloat)SvNV(ST(i+1+16));
    for (i=0;i<4;i++)
        v[i] = SvIV(ST(i+1+16+16));
    gluLoadSamplingMatrices(nurb, m, p, v);
}

#//# gluLookAt($eyeX, $eyeY, $eyeZ, $centerX, $centerY, $centerZ, $upX, $upY, $upZ);
void
gluLookAt(eyeX, eyeY, eyeZ, centerX, centerY, centerZ, upX, upY, upZ)
    GLdouble        eyeX
    GLdouble        eyeY
    GLdouble        eyeZ
    GLdouble        centerX
    GLdouble        centerY
    GLdouble        centerZ
    GLdouble        upX
    GLdouble        upY
    GLdouble        upZ

#// gluNewNurbsRenderer();
GLUnurbsObj *
gluNewNurbsRenderer()

#// gluNewQuadric();
GLUquadricObj *
gluNewQuadric()

#// gluNewTess();
PGLUtess *
gluNewTess(...)
    CODE:
{
    RETVAL = malloc(sizeof(PGLUtess));
    memset(RETVAL, 0, sizeof(PGLUtess));
    RETVAL->do_colors  = (items > 0) ? SvTRUE(ST(0)) : FALSE;
    RETVAL->do_normals = (items > 1) ? SvTRUE(ST(1)) : FALSE;
    RETVAL->triangulator = gluNewTess();
}
OUTPUT:
RETVAL

#// gluNextContour(tess, type);
void
gluNextContour(tess, type)
    PGLUtess *      tess
    GLenum  type
    CODE:
    gluNextContour(tess->triangulator, type);

#// gluNurbsCurve_c(nurb, nknots, knot, stride, ctlarray, order, type);
void
gluNurbsCurve_c(nurb, nknots, knot, stride, ctlarray, order, type)
    GLUnurbsObj *   nurb
    GLint   nknots
    void *  knot
    GLint   stride
    void *  ctlarray
    GLint   order
    GLenum  type
    CODE:
    gluNurbsCurve(nurb, nknots, knot, stride, ctlarray, order, type);

#// gluNurbsSurface_c(nurb, sknot_count, sknot, tknot_count, tknot, s_stride, t_stride, ctrlarray, sorder, torder, type);
void
gluNurbsSurface_c(nurb, sknot_count, sknot, tknot_count, tknot, s_stride, t_stride, ctrlarray, sorder, torder, type)
    GLUnurbsObj *   nurb
    GLint   sknot_count
    void *  sknot
    GLint   tknot_count
    void *  tknot
    GLint   s_stride
    GLint   t_stride
    void *  ctrlarray
    GLint   sorder
    GLint   torder
    GLenum  type
    CODE:
    gluNurbsSurface(nurb, sknot_count, sknot, tknot_count, tknot, s_stride, t_stride, ctrlarray, sorder, torder, type);

#//# gluOrtho2D($left, $right, $bottom, $top);
void
gluOrtho2D(left, right, bottom, top)
    GLdouble        left
    GLdouble        right
    GLdouble        bottom
    GLdouble        top

#// gluPartialDisk(quad, inner, outer, slices, loops, start, sweep);
void
gluPartialDisk(quad, inner, outer, slices, loops, start, sweep)
    GLUquadricObj*  quad
    GLdouble        inner
    GLdouble        outer
    GLint   slices
    GLint   loops
    GLdouble        start
    GLdouble        sweep

#//# gluPerspective($fovy, $aspect, $zNear, $zFar);
void
gluPerspective(fovy, aspect, zNear, zFar)
    GLdouble        fovy
    GLdouble        aspect
    GLdouble        zNear
    GLdouble        zFar

#//# gluPickMatrix_p($x, $y, $delX, $delY, $m1,$m2,$m3,$m4);
void
gluPickMatrix_p(x, y, delX, delY, m1,m2,m3,m4)
    GLdouble        x
    GLdouble        y
    GLdouble        delX
    GLdouble        delY
    CODE:
{
    GLint m[4];
    int i;
    for (i=0;i<4;i++)
        m[i] = SvIV(ST(i+4));
    gluPickMatrix(x, y, delX, delY, &m[0]);
}

#//# gluProject_p($objx, $objy, $objz, @m4x4, @o4x4, $v1,$v2,$v3,$v4);
void
gluProject_p(objx, objy, objz, m1,m2,m3,m4,m5,m6,m7,m8,m9,m10,m11,m12,m13,m14,m15,m16, o1,o2,o3,o4,o5,o6,o7,o8,o9,o10,o11,o12,o13,o14,o15,o16, v1,v2,v3,v4)
    GLdouble        objx
    GLdouble        objy
    GLdouble        objz
    PPCODE:
{
    GLdouble m[16], p[16], winx, winy, winz;
    GLint v[4];
    int i;
    for (i=0;i<16;i++)
        m[i] = SvNV(ST(i+3));
    for (i=0;i<16;i++)
        p[i] = SvNV(ST(i+3+16));
    for (i=0;i<4;i++)
        v[i] = SvIV(ST(i+3+16+16));
    i = gluProject(objx, objy, objz, m, p, v, &winx, &winy, &winz);
    if (i) {
        EXTEND(sp, 3);
        PUSHs(sv_2mortal(newSVnv(winx)));
        PUSHs(sv_2mortal(newSVnv(winy)));
        PUSHs(sv_2mortal(newSVnv(winz)));
    }
}

#// gluPwlCurve_c(nurb, count, data, stride, type);
void
gluPwlCurve_c(nurb, count, data, stride, type)
    GLUnurbsObj *   nurb
    GLint   count
    void *  data
    GLint   stride
    GLenum  type
    CODE:
    gluPwlCurve(nurb, count, data, stride, type);


#// gluQuadricDrawStyle(quad, draw);
void
gluQuadricDrawStyle(quad, draw)
    GLUquadricObj * quad
    GLenum  draw

#// gluQuadricNormals(quad, normal);
void
gluQuadricNormals(quad, normal)
    GLUquadricObj * quad
    GLenum  normal

#// gluQuadricOrientation(quad, orientation);
void
gluQuadricOrientation(quad, orientation)
    GLUquadricObj * quad
    GLenum  orientation

#// gluQuadricTexture(quad, texture);
void
gluQuadricTexture(quad, texture)
    GLUquadricObj * quad
    GLboolean       texture

#//# gluScaleImage_s($format, $wIn, $hIn, $typeIn, (PACKED)dataIn, $wOut, $hOut, $typeOut, (PACKED)dataOut);
GLint
gluScaleImage_s(format, wIn, hIn, typeIn, dataIn, wOut, hOut, typeOut, dataOut)
    GLenum  format
    GLsizei wIn
    GLsizei hIn
    GLenum  typeIn
    SV *    dataIn
    GLsizei wOut
    GLsizei hOut
    GLenum  typeOut
    SV *    dataOut
    CODE:
{
    GLvoid * inptr, * outptr;
    STRLEN discard;
    ELI(dataIn, wIn, hIn, format, typeIn, gl_pixelbuffer_unpack);
    ELI(dataOut, wOut, hOut, format, typeOut, gl_pixelbuffer_pack);
    inptr = SvPV(dataIn, discard);
    outptr = SvPV(dataOut, discard);
    RETVAL = gluScaleImage(format, wIn, hIn, typeIn, inptr, wOut, hOut, typeOut, outptr);
}
OUTPUT:
RETVAL

#// gluSphere(quad, radius, slices, stacks);
void
gluSphere(quad, radius, slices, stacks)
    GLUquadricObj * quad
    GLdouble        radius
    GLint   slices
    GLint   stacks

#ifdef GLU_VERSION_1_2

#// gluGetTessProperty_p(tess, property);
GLdouble
gluGetTessProperty_p(tess, property)
    PGLUtess *      tess
    GLenum  property
    CODE:
{
    GLdouble param;
    gluGetTessProperty(tess->triangulator, property, &param);
    RETVAL = param;
}
OUTPUT:
RETVAL

#// #gluNurbsCallback_p(nurb, which, handler, ...);
#void
#gluNurbsCallback_p(nurb, which, handler, ...)

#// gluNurbsCallbackDataEXT
#void
#gluNurbsCallbackDataEXT

#// gluQuadricCallback
#void
#gluQuadricCallback

#// gluTessBeginContour(tess);
void
gluTessBeginContour(tess)
    PGLUtess *      tess
    CODE:
    gluTessBeginContour(tess->triangulator);

#// gluTessEndContour(tess);
void
gluTessEndContour(tess)
    PGLUtess *      tess
    CODE:
    gluTessEndContour(tess->triangulator);

#// gluTessBeginPolygon(tess, ...);
void
gluTessBeginPolygon(tess, ...)
    PGLUtess *      tess
    CODE:
{
    delete_polygon_data()
        if (items > 1) {
            tess->polygon_data = newSVsv(ST(1));
        }
    if (!tess->vertex_datas)
        tess->vertex_datas = newAV();
    gluTessBeginPolygon(tess->triangulator, tess);
}

#// gluTessEndPolygon(tess);
void
gluTessEndPolygon(tess)
    PGLUtess *      tess
    CODE:
{
    gluTessEndPolygon(tess->triangulator);
    delete_vertex_datas()
        delete_tess_datas()
        delete_polygon_data()
}

#// gluTessNormal(tess, valueX, valueY, valueZ)
void
gluTessNormal(tess, valueX, valueY, valueZ)
    PGLUtess *      tess
    GLdouble        valueX
    GLdouble        valueY
    GLdouble        valueZ
    CODE:
    gluTessNormal(tess->triangulator, valueX, valueY, valueZ);

#// gluTessProperty(tess, which, data);
void
gluTessProperty(tess, which, data)
    PGLUtess *      tess
    GLenum  which
    GLdouble        data
    CODE:
    gluTessProperty(tess->triangulator, which, data);

#// gluTessCallback(tess, which, ...);
void
gluTessCallback(tess, which, ...)
    PGLUtess *      tess
    GLenum  which
    CODE:
{
    switch (which) {
        case GLU_TESS_BEGIN:
        case GLU_TESS_BEGIN_DATA:
            if (tess->begin_callback) {
                SvREFCNT_dec(tess->begin_callback);
                tess->begin_callback = 0;
            }
            break;
        case GLU_TESS_END:
        case GLU_TESS_END_DATA:
            if (tess->end_callback) {
                SvREFCNT_dec(tess->end_callback);
                tess->end_callback = 0;
            }
            break;
        case GLU_TESS_VERTEX:
        case GLU_TESS_VERTEX_DATA:
            if (tess->vertex_callback) {
                SvREFCNT_dec(tess->vertex_callback);
                tess->vertex_callback = 0;
            }
            break;
        case GLU_TESS_ERROR:
        case GLU_TESS_ERROR_DATA:
            if (tess->error_callback) {
                SvREFCNT_dec(tess->error_callback);
                tess->error_callback = 0;
            }
            break;
        case GLU_TESS_COMBINE:
        case GLU_TESS_COMBINE_DATA:
            if (tess->combine_callback) {
                SvREFCNT_dec(tess->combine_callback);
                tess->combine_callback = 0;
            }
            break;
        case GLU_TESS_EDGE_FLAG:
        case GLU_TESS_EDGE_FLAG_DATA:
            if (tess->edgeFlag_callback) {
                SvREFCNT_dec(tess->edgeFlag_callback);
                tess->edgeFlag_callback = 0;
            }
            break;
    }

    if (items > 2) {
        SV * callback;
        if (SvPOK(ST(2))
                && sv_eq(ST(2), sv_2mortal(newSVpv("DEFAULT", 0)))) {
            callback = newSViv(1);
            switch (which) {
                case GLU_TESS_BEGIN_DATA:
                    which = GLU_TESS_BEGIN; break;
                case GLU_TESS_END_DATA:
                    which = GLU_TESS_END; break;
                case GLU_TESS_ERROR_DATA:
                    which = GLU_TESS_ERROR; break;
                case GLU_TESS_EDGE_FLAG_DATA:
                    which = GLU_TESS_EDGE_FLAG; break;
                case GLU_TESS_VERTEX:
                    which = GLU_TESS_VERTEX_DATA; break; /* vertex data handler has less overhead and both pass opaque pointers anyway */
            }
        } else if (!SvROK(ST(2)) || SvTYPE(SvRV(ST(2))) != SVt_PVCV) {
            croak("3rd argument to gluTessCallback must be a perl code ref");
        } else {
            callback = newSVsv(ST(2));
        }
        switch (which) {
            case GLU_TESS_BEGIN:
                tess->begin_callback = callback;
                gluTessCallback(tess->triangulator, GLU_TESS_BEGIN_DATA, (void (CALLBACK*)()) _s_marshal_glu_t_callback_begin);
                break;
            case GLU_TESS_BEGIN_DATA:
                tess->begin_callback = callback;
                gluTessCallback(tess->triangulator, GLU_TESS_BEGIN_DATA, (void (CALLBACK*)()) _s_marshal_glu_t_callback_begin_data);
                break;
            case GLU_TESS_END:
                tess->end_callback = callback;
                gluTessCallback(tess->triangulator, GLU_TESS_END_DATA, (void (CALLBACK*)()) _s_marshal_glu_t_callback_end);
                break;
            case GLU_TESS_END_DATA:
                tess->end_callback = callback;
                gluTessCallback(tess->triangulator, GLU_TESS_END_DATA, (void (CALLBACK*)()) _s_marshal_glu_t_callback_end_data);
                break;
            case GLU_TESS_VERTEX:
                tess->use_vertex_data = TRUE;
                tess->vertex_callback = callback;
                gluTessCallback(tess->triangulator, GLU_TESS_VERTEX, (void (CALLBACK*)()) _s_marshal_glu_t_callback_vertex);
                break;
            case GLU_TESS_VERTEX_DATA:
                tess->use_vertex_data = FALSE;
                tess->vertex_callback = callback;
                gluTessCallback(tess->triangulator, GLU_TESS_VERTEX_DATA, (void (CALLBACK*)()) _s_marshal_glu_t_callback_vertex_data);
                break;
            case GLU_TESS_ERROR:
                tess->error_callback = callback;
                gluTessCallback(tess->triangulator, GLU_TESS_ERROR_DATA, (void (CALLBACK*)()) _s_marshal_glu_t_callback_error);
                break;
            case GLU_TESS_ERROR_DATA:
                tess->error_callback = callback;
                gluTessCallback(tess->triangulator, GLU_TESS_ERROR_DATA, (void (CALLBACK*)()) _s_marshal_glu_t_callback_error_data);
                break;
            case GLU_TESS_COMBINE:
            case GLU_TESS_COMBINE_DATA:
                tess->combine_callback = callback;
                gluTessCallback(tess->triangulator, GLU_TESS_COMBINE_DATA, (void (CALLBACK*)()) _s_marshal_glu_t_callback_combine);
                break;
            case GLU_TESS_EDGE_FLAG:
                tess->edgeFlag_callback = callback;
                gluTessCallback(tess->triangulator, GLU_TESS_EDGE_FLAG_DATA, (void (CALLBACK*)()) _s_marshal_glu_t_callback_edgeFlag);
                break;
            case GLU_TESS_EDGE_FLAG_DATA:
                tess->edgeFlag_callback = callback;
                gluTessCallback(tess->triangulator, GLU_TESS_EDGE_FLAG_DATA, (void (CALLBACK*)()) _s_marshal_glu_t_callback_edgeFlag_data);
                break;
        }
    }
}


#endif

#// gluTessVertex(tess, x, y, z);
void
gluTessVertex_p(tess, x, y, z, ...)
    PGLUtess *      tess
    GLdouble        x
    GLdouble        y
    GLdouble        z
    CODE:
{
    int i;
    int j = 3;
    AV * vds = tess->vertex_datas;
    int size = 3 + (tess->do_colors ? 4 : 0) + (tess->do_normals ? 3 : 0);
    GLdouble* data = malloc(sizeof(GLdouble) * size);
    if (!vds) croak("Missing vertex data storage during gluTessVertex");
    if (data == NULL) croak("Couldn't allocate vertex during gluTessVertex");
    data[0] = x;
    data[1] = y;
    data[2] = z;
    av_push(vds, newSViv(PTR2IV(data))); /* store for freeing later */
    if (tess->do_colors) {
        int J = j + 4;
        if (tess->do_normals) {
            if (items != 12 && items != 11) croak("gluTessVertex_p(tess, x,y,z, r,g,b,a, nx,ny,nz [,polygon_data])");
        } else {
            if (items != 9  && items != 8 ) croak("gluTessVertex_p(tess, x,y,z, r,g,b,a [,polygon_data])");
        }
        for ( ; j < J; j++) data[j] = (GLdouble)SvNV(ST(j+1));
    } else {
        if (tess->do_normals) {
            if (items != 8 && items != 7) croak("gluTessVertex_p(tess, x,y,z, nx,ny,nz [,polygon_data])");
        } else {
            if (items != 5 && items != 4) croak("gluTessVertex_p(tess, x,y,z [,polygon_data])");
        }
    }
    if (tess->do_normals) {
        int J = j + 3;
        for ( ; j < J; j++) data[j] = (GLdouble)SvNV(ST(j+1));
    }
    if (tess->use_vertex_data) {
        PGLUtess * opaque = malloc(sizeof(PGLUtess));
        if (!opaque) croak("Couldn't allocate storage for vertex opaque data");
        opaque->triangulator     = tess->triangulator;
        opaque->vertex_datas     = tess->vertex_datas;
        opaque->vertex_callback  = tess->vertex_callback;
        opaque->combine_callback = tess->combine_callback;
        opaque->vertex_data      = data;
        opaque->polygon_data     = (items > j+1) ? newSVsv(ST(j+1)) : 0;
        opaque->use_vertex_data  = TRUE;
        opaque->do_colors        = tess->do_colors;
        opaque->do_normals       = tess->do_normals;
        if (! tess->tess_datas) tess->tess_datas = newAV();
        av_push(tess->tess_datas, newSViv(PTR2IV(opaque)));
        gluTessVertex(tess->triangulator, data, (void*)opaque);
    } else {
        gluTessVertex(tess->triangulator, data, data);
    }
}

#//# gluUnProject_p($winx,$winy,$winz, @m4x4, @o4x4, $v1,$v2,$v3,$v4);
void
gluUnProject_p(winx,winy,winz, m1,m2,m3,m4,m5,m6,m7,m8,m9,m10,m11,m12,m13,m14,m15,m16, o1,o2,o3,o4,o5,o6,o7,o8,o9,o10,o11,o12,o13,o14,o15,o16, v1,v2,v3,v4)
    GLdouble        winx
    GLdouble        winy
    GLdouble        winz
    PPCODE:
{
    GLdouble m[16], p[16], objx, objy, objz;
    GLint v[4];
    int i;

    for (i=0;i<16;i++)
        m[i] = SvNV(ST(i+3));
    for (i=0;i<16;i++)
        p[i] = SvNV(ST(i+3+16));
    for (i=0;i<4;i++)
        v[i] = SvIV(ST(i+3+16+16));

    i = gluUnProject(winx,winy,winz, m, p, v, &objx,&objy,&objz);

    if (i) {
        EXTEND(sp, 3);
        PUSHs(sv_2mortal(newSVnv(objx)));
        PUSHs(sv_2mortal(newSVnv(objy)));
        PUSHs(sv_2mortal(newSVnv(objz)));
    }
}

INCLUDE: const-xs.inc
