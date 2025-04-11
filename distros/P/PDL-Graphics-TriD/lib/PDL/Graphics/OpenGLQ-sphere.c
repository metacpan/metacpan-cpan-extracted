/*
 * Copyright (c) 1999-2000 by Pawel W. Olszta
 * Written by Pawel W. Olszta, <olszta@sourceforge.net>
 *
 * Permission is hereby granted, free of charge, to any person obtaining a
 * copy of this software and associated documentation files (the "Software"),
 * to deal in the Software without restriction, including without limitation
 * the rights to use, copy, modify, merge, publish, distribute, sublicense,
 * and/or sell copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included
 * in all copies or substantial portions of the Sotware.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
 * OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
 * PAWEL W. OLSZTA BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
 * IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
 * CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

#include <stddef.h>
#include <stdlib.h>
#include <math.h>

#ifdef __APPLE__
#include <OpenGL/gl.h>
#else
#include <GL/gl.h>
#endif

/*
 * A note: We do not use the GLuint data type for vertex index arrays
 * in this code as Open GL ES1 only supports GLushort. This affects the
 * cylindrical objects only (Torus, Sphere, Cylinder and Cone) and limits
 * their number of vertices to 65535 (2^16-1). That's about 256*256
 * subdivisions, which is sufficient for just about any usage case, so
 * I am not going to worry about it for now.
 * One could do compile time detection of the gluint type through CMake,
 * but it is likely that we'll eventually move to runtime selection
 * of OpenGL or GLES1/2, which would make that strategy useless...
 */

/* declare for drawing using the different OpenGL versions here so we can
   have a nice code order below */
#ifndef GL_VERSION_1_1
static void fghDrawGeometrySolid10(GLfloat *varr, GLfloat *narr, GLfloat *tarr,
		GLsizei nverts, GLushort *iarr, GLsizei nparts, GLsizei npartverts);
#endif
static void fghDrawGeometrySolid11(GLfloat *vertices, GLfloat *normals, GLfloat *textcs, GLsizei numVertices,
                                   GLushort *vertIdxs, GLsizei numParts, GLsizei numVertIdxsPerPart);
static void fghDrawGeometrySolid20(GLfloat *vertices, GLfloat *normals, GLfloat *textcs, GLsizei numVertices,
                                   GLushort *vertIdxs, GLsizei numParts, GLsizei numVertIdxsPerPart,
                                   GLint attribute_v_coord, GLint attribute_v_normal, GLint attribute_v_texture);

/* Drawing geometry:
 * Explanation of the functions has to be separate for the polyhedra and
 * the non-polyhedra (objects with a circular cross-section).
 * Non-polyhedra:
 *   - We have implemented the sphere, cylinder, cone, and torus.
 *   - All shapes are characterized by two parameters: the number of
 *     subdivisions along two axes used to construct the shape's vertices
 *     (e.g. stacks and slices for the sphere).
 *     As different subdivisions are most suitable for different shapes,
 *     and are thus also named differently, I won't provide general comments
 *     on them here.
 *   - Solids are drawn using glDrawArrays and GL_TRIANGLE_STRIP. Each
 *     strip covers one revolution around one of the two subdivision axes
 *     of the shape.
 */


/* Draw the geometric shape with filled triangles
 *
 * Arguments:
 * GLfloat *vertices, GLfloat *normals, GLfloat *textcs, GLsizei numVertices
 *   The vertex coordinate, normal and texture coordinate buffers, and the
 *   number of entries in those
 * GLushort *vertIdxs
 *   a vertex indices buffer, optional (not passed for the polyhedra with
 *   triangular faces)
 * GLsizei numParts, GLsizei numVertPerPart
 *   polyhedra: not used for polyhedra with triangular faces
       (numEdgePerFace==3), as each vertex+normal pair is drawn only once,
       so no vertex indices are used.
       Else, the shape was triangulated (DECOMPOSE_TO_TRIANGLE), leading to
       reuse of some vertex+normal pairs, and thus the need to draw with
       glDrawElements. numParts is always 1 in this case (we can draw the
       whole object with one call to glDrawElements as the vertex index
       array contains separate triangles), and numVertPerPart indicates
       the number of vertex indices in the vertex array.
 *   non-polyhedra: number of parts (GL_TRIANGLE_STRIPs) to be drawn
       separately (numParts calls to glDrawElements) to create the object.
       numVertPerPart indicates the number of vertex indices to be
       processed at each draw call.
 *   numParts * numVertPerPart gives the number of entries in the vertex
 *     array vertIdxs
 */
void fghDrawGeometrySolid(GLfloat *vertices, GLfloat *normals, GLfloat *textcs, GLsizei numVertices,
                          GLushort *vertIdxs, GLsizei numParts, GLsizei numVertIdxsPerPart)
{
    GLint attribute_v_coord, attribute_v_normal, attribute_v_texture;
#if 0 /* hook for shader stuff */
    if(win) {
        attribute_v_coord   = win->Window.attribute_v_coord;
        attribute_v_normal  = win->Window.attribute_v_normal;
        attribute_v_texture = win->Window.attribute_v_texture;
    } else
#endif
        attribute_v_coord = attribute_v_normal = attribute_v_texture = -1;

#if 0 /* shader stuff */
    if (fgState.HasOpenGL20 && (attribute_v_coord != -1 || attribute_v_normal != -1))
    {
        /* User requested a 2.0 draw */
        fghDrawGeometrySolid20(vertices, normals, textcs, numVertices,
                               vertIdxs, numParts, numVertIdxsPerPart,
                               attribute_v_coord, attribute_v_normal, attribute_v_texture);
    }
    else
#endif
    {
        fghDrawGeometrySolid11(vertices, normals, textcs, numVertices,
                               vertIdxs, numParts, numVertIdxsPerPart);
    }
}

#ifndef GL_VERSION_1_1

static void fghDrawGeometrySolid10(GLfloat *varr, GLfloat *narr, GLfloat *tarr,
		GLsizei nverts, GLushort *iarr, GLsizei nparts, GLsizei npartverts)
{
    int i, j;
	GLfloat *vptr, *nptr, *tptr;
	GLushort *iptr;

	if(!iarr) {
		vptr = varr;
		nptr = narr;
		tptr = tarr;
		glBegin(GL_TRIANGLES);
		for(i=0; i<nverts; i++) {
			if(tarr) {
				glTexCoord2fv(tptr); tptr += 2;
			}
			glNormal3fv(nptr); nptr += 3;
			glVertex3fv(vptr); vptr += 3;
		}
		glEnd();
		return;
	}

	iptr = iarr;
	if(nparts > 1) {
		for(i=0; i<nparts; i++) {
			glBegin(GL_TRIANGLE_STRIP);
			for(j=0; j<npartverts; j++) {
				int idx = *iptr++;
				if(tarr) {
					glTexCoord2fv(tarr + idx * 2);
				}
				idx = idx * 2 + idx;
				glNormal3fv(narr + idx);
				glVertex3fv(varr + idx);
			}
			glEnd();
		}
	} else {
		glBegin(GL_TRIANGLES);
		for(i=0; i<npartverts; i++) {
			int idx = *iptr++;
			if(tarr) {
				glTexCoord2fv(tarr + idx * 2);
			}
			idx = idx * 2 + idx;
			glNormal3fv(narr + idx);
			glVertex3fv(varr + idx);
		}
		glEnd();
	}
}
#endif

static void fghDrawGeometrySolid11(GLfloat *vertices, GLfloat *normals, GLfloat *textcs, GLsizei numVertices,
                                   GLushort *vertIdxs, GLsizei numParts, GLsizei numVertIdxsPerPart)
{
#if defined(GL_VERSION_1_1) || defined(GL_VERSION_ES_CM_1_0)
    int i;

    glEnableClientState(GL_VERTEX_ARRAY);
    glEnableClientState(GL_NORMAL_ARRAY);

    glVertexPointer(3, GL_FLOAT, 0, vertices);
    glNormalPointer(GL_FLOAT, 0, normals);

    if (textcs)
    {
        glEnableClientState(GL_TEXTURE_COORD_ARRAY);
        glTexCoordPointer(2, GL_FLOAT, 0, textcs);
    }

    if (!vertIdxs)
        glDrawArrays(GL_TRIANGLES, 0, numVertices);
    else
        if (numParts>1)
            for (i=0; i<numParts; i++)
                glDrawElements(GL_TRIANGLE_STRIP, numVertIdxsPerPart, GL_UNSIGNED_SHORT, vertIdxs+i*numVertIdxsPerPart);
        else
            glDrawElements(GL_TRIANGLES, numVertIdxsPerPart, GL_UNSIGNED_SHORT, vertIdxs);

    glDisableClientState(GL_VERTEX_ARRAY);
    glDisableClientState(GL_NORMAL_ARRAY);
    if (textcs)
        glDisableClientState(GL_TEXTURE_COORD_ARRAY);
#else
	fghDrawGeometrySolid10(vertices, normals, textcs, numVertices, vertIdxs, numParts, numVertIdxsPerPart);
#endif
}


#if 0 /* shader stuff */
/* Version for OpenGL (ES) >= 2.0 */
static void fghDrawGeometrySolid20(GLfloat *vertices, GLfloat *normals, GLfloat *textcs, GLsizei numVertices,
                                   GLushort *vertIdxs, GLsizei numParts, GLsizei numVertIdxsPerPart,
                                   GLint attribute_v_coord, GLint attribute_v_normal, GLint attribute_v_texture)
{
#if defined(GL_VERSION_1_1) || defined(GL_VERSION_ES_CM_1_0)
    GLuint vbo_coords = 0, vbo_normals = 0, vbo_textcs = 0, ibo_elements = 0;
    GLsizei numVertIdxs = numParts * numVertIdxsPerPart;
    int i;

    if (numVertices > 0 && attribute_v_coord != -1) {
        glGenBuffers(1, &vbo_coords);
        glBindBuffer(GL_ARRAY_BUFFER, vbo_coords);
        glBufferData(GL_ARRAY_BUFFER, numVertices * 3 * sizeof(vertices[0]),
                      vertices, GL_STATIC_DRAW);
        glBindBuffer(GL_ARRAY_BUFFER, 0);
    }

    if (numVertices > 0 && attribute_v_normal != -1) {
        glGenBuffers(1, &vbo_normals);
        glBindBuffer(GL_ARRAY_BUFFER, vbo_normals);
        glBufferData(GL_ARRAY_BUFFER, numVertices * 3 * sizeof(normals[0]),
                      normals, GL_STATIC_DRAW);
        glBindBuffer(GL_ARRAY_BUFFER, 0);
    }

    if (numVertices > 0 && attribute_v_texture != -1 && textcs) {
        glGenBuffers(1, &vbo_textcs);
        glBindBuffer(GL_ARRAY_BUFFER, vbo_textcs);
        glBufferData(GL_ARRAY_BUFFER, numVertices * 2 * sizeof(textcs[0]),
                      textcs, GL_STATIC_DRAW);
        glBindBuffer(GL_ARRAY_BUFFER, 0);
    }

    if (vertIdxs != NULL) {
        glGenBuffers(1, &ibo_elements);
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, ibo_elements);
        glBufferData(GL_ELEMENT_ARRAY_BUFFER, numVertIdxs * sizeof(vertIdxs[0]),
                      vertIdxs, GL_STATIC_DRAW);
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
    }

    if (vbo_coords) {
        glEnableVertexAttribArray(attribute_v_coord);
        glBindBuffer(GL_ARRAY_BUFFER, vbo_coords);
        glVertexAttribPointer(
            attribute_v_coord,  /* attribute */
            3,                  /* number of elements per vertex, here (x,y,z) */
            GL_FLOAT,           /* the type of each element */
            GL_FALSE,           /* take our values as-is */
            0,                  /* no extra data between each position */
            0                   /* offset of first element */
        );
        glBindBuffer(GL_ARRAY_BUFFER, 0);
    };

    if (vbo_normals) {
        glEnableVertexAttribArray(attribute_v_normal);
        glBindBuffer(GL_ARRAY_BUFFER, vbo_normals);
        glVertexAttribPointer(
            attribute_v_normal, /* attribute */
            3,                  /* number of elements per vertex, here (x,y,z) */
            GL_FLOAT,           /* the type of each element */
            GL_FALSE,           /* take our values as-is */
            0,                  /* no extra data between each position */
            0                   /* offset of first element */
        );
        glBindBuffer(GL_ARRAY_BUFFER, 0);
    };

    if (vbo_textcs) {
        glEnableVertexAttribArray(attribute_v_texture);
        glBindBuffer(GL_ARRAY_BUFFER, vbo_textcs);
        glVertexAttribPointer(
            attribute_v_texture,/* attribute */
            2,                  /* number of elements per vertex, here (s,t) */
            GL_FLOAT,           /* the type of each element */
            GL_FALSE,           /* take our values as-is */
            0,                  /* no extra data between each position */
            0                   /* offset of first element */
            );
        glBindBuffer(GL_ARRAY_BUFFER, 0);
    };

    if (vertIdxs == NULL) {
        glDrawArrays(GL_TRIANGLES, 0, numVertices);
    } else {
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, ibo_elements);
        if (numParts>1) {
            for (i=0; i<numParts; i++) {
                glDrawElements(GL_TRIANGLE_STRIP, numVertIdxsPerPart, GL_UNSIGNED_SHORT, (GLvoid*)(sizeof(vertIdxs[0])*i*numVertIdxsPerPart));
            }
        } else {
            glDrawElements(GL_TRIANGLES, numVertIdxsPerPart, GL_UNSIGNED_SHORT, 0);
        }
        /* Clean existing bindings before clean-up */
        /* Android showed instability otherwise */
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
    }

    if (vbo_coords != 0)
        glDisableVertexAttribArray(attribute_v_coord);
    if (vbo_normals != 0)
        glDisableVertexAttribArray(attribute_v_normal);
    if (vbo_textcs != 0)
        glDisableVertexAttribArray(attribute_v_texture);

    if (vbo_coords != 0)
        glDeleteBuffers(1, &vbo_coords);
    if (vbo_normals != 0)
        glDeleteBuffers(1, &vbo_normals);
    if (vbo_textcs != 0)
        glDeleteBuffers(1, &vbo_textcs);
    if (ibo_elements != 0)
        glDeleteBuffers(1, &ibo_elements);
#endif	/* GL version at least 1.1 */
}
#endif

/*
 * Compute lookup table of cos and sin values forming a circle
 * (or half circle if halfCircle==TRUE)
 *
 * Notes:
 *    It is the responsibility of the caller to free these tables
 *    The size of the table is (n+1) to form a connected loop
 *    The last entry is exactly the same as the first
 *    The sign of n can be flipped to get the reverse loop
 */
static char *fghCircleTable(GLfloat **sint, GLfloat **cost, const int n, const GLboolean halfCircle)
{
    int i;

    /* Table size, the sign of n flips the circle direction */
    const int size = abs(n);

    /* Determine the angle between samples */
    const GLfloat angle = (halfCircle?1:2)*(GLfloat)M_PI/(GLfloat)( ( n == 0 ) ? 1 : n );

    /* Allocate memory for n samples, plus duplicate of first entry at the end */
    *sint = malloc(sizeof(GLfloat) * (size+1));
    *cost = malloc(sizeof(GLfloat) * (size+1));

    if (!(*sint) || !(*cost))
    {
        free(*sint);
        free(*cost);
        return "Failed to allocate memory in fghCircleTable";
    }

    /* Compute cos and sin around the circle */
    (*sint)[0] = 0.0;
    (*cost)[0] = 1.0;

    for (i=1; i<size; i++)
    {
        (*sint)[i] = (GLfloat)sin(angle*i);
        (*cost)[i] = (GLfloat)cos(angle*i);
    }


    if (halfCircle)
    {
        (*sint)[size] =  0.0f;  /* sin PI */
        (*cost)[size] = -1.0f;  /* cos PI */
    }
    else
    {
        /* Last sample is duplicate of the first (sin or cos of 2 PI) */
        (*sint)[size] = (*sint)[0];
        (*cost)[size] = (*cost)[0];
    }
    return NULL;
}

static char *fghGenerateSphere(GLfloat radius, GLint slices, GLint stacks, GLfloat **vertices, GLfloat **normals, int* nVert)
{
    int i,j;
    int idx = 0;    /* idx into vertex/normal buffer */
    GLfloat x,y,z;

    /* Pre-computed circle */
    GLfloat *sint1,*cost1;
    GLfloat *sint2,*cost2;

    /* number of unique vertices */
    if (slices==0 || stacks<2)
    {
        /* nothing to generate */
        *nVert = 0;
        return NULL;
    }
    *nVert = slices*(stacks-1)+2;
    if ((*nVert) > 65535)
        /*
         * limit of glushort, that's 256*256 subdivisions, should be enough in practice. See note above
         */
        return "fghGenerateSphere: too many slices or stacks requested, indices will wrap";

    /* precompute values on unit circle */
    char *err = fghCircleTable(&sint1,&cost1,-slices,GL_FALSE);
    if (err) return err;
    err = fghCircleTable(&sint2,&cost2, stacks,GL_TRUE);
    if (err) return err;

    /* Allocate vertex and normal buffers, bail out if memory allocation fails */
    *vertices = malloc((*nVert)*3*sizeof(GLfloat));
    *normals  = malloc((*nVert)*3*sizeof(GLfloat));
    if (!(*vertices) || !(*normals))
    {
        free(*vertices);
        free(*normals);
        return "Failed to allocate memory in fghGenerateSphere";
    }

    /* top */
    (*vertices)[0] = 0.f;
    (*vertices)[1] = 0.f;
    (*vertices)[2] = radius;
    (*normals )[0] = 0.f;
    (*normals )[1] = 0.f;
    (*normals )[2] = 1.f;
    idx = 3;

    /* each stack */
    for( i=1; i<stacks; i++ )
    {
        for(j=0; j<slices; j++, idx+=3)
        {
            x = cost1[j]*sint2[i];
            y = sint1[j]*sint2[i];
            z = cost2[i];

            (*vertices)[idx  ] = x*radius;
            (*vertices)[idx+1] = y*radius;
            (*vertices)[idx+2] = z*radius;
            (*normals )[idx  ] = x;
            (*normals )[idx+1] = y;
            (*normals )[idx+2] = z;
        }
    }

    /* bottom */
    (*vertices)[idx  ] =  0.f;
    (*vertices)[idx+1] =  0.f;
    (*vertices)[idx+2] = -radius;
    (*normals )[idx  ] =  0.f;
    (*normals )[idx+1] =  0.f;
    (*normals )[idx+2] = -1.f;

    /* Done creating vertices, release sin and cos tables */
    free(sint1);
    free(cost1);
    free(sint2);
    free(cost2);
    return NULL;
}

static char *fghSphere( GLfloat radius, GLint slices, GLint stacks )
{
    int i,j,idx, nVert;
    GLfloat *vertices, *normals;

    /* Generate vertices and normals */
    char *err = fghGenerateSphere(radius,slices,stacks,&vertices,&normals,&nVert);
    if (err) return err;

    if (nVert==0)
        /* nothing to draw */
        return NULL;

    /* only solid */
    {
        /* First, generate vertex index arrays for drawing with glDrawElements
         * All stacks, including top and bottom are covered with a triangle
         * strip.
         */
        GLushort  *stripIdx;
        /* Create index vector */
        GLushort offset;

        /* Allocate buffers for indices, bail out if memory allocation fails */
        stripIdx = malloc((slices+1)*2*(stacks)*sizeof(GLushort));
        if (!(stripIdx))
        {
            free(stripIdx);
            return "Failed to allocate memory in fghSphere";
        }

        /* top stack */
        for (j=0, idx=0;  j<slices;  j++, idx+=2)
        {
            stripIdx[idx  ] = j+1;              /* 0 is top vertex, 1 is first for first stack */
            stripIdx[idx+1] = 0;
        }
        stripIdx[idx  ] = 1;                    /* repeat first slice's idx for closing off shape */
        stripIdx[idx+1] = 0;
        idx+=2;

        /* middle stacks: */
        /* Strip indices are relative to first index belonging to strip, NOT relative to first vertex/normal pair in array */
        for (i=0; i<stacks-2; i++, idx+=2)
        {
            offset = 1+i*slices;                    /* triangle_strip indices start at 1 (0 is top vertex), and we advance one stack down as we go along */
            for (j=0; j<slices; j++, idx+=2)
            {
                stripIdx[idx  ] = offset+j+slices;
                stripIdx[idx+1] = offset+j;
            }
            stripIdx[idx  ] = offset+slices;        /* repeat first slice's idx for closing off shape */
            stripIdx[idx+1] = offset;
        }

        /* bottom stack */
        offset = 1+(stacks-2)*slices;               /* triangle_strip indices start at 1 (0 is top vertex), and we advance one stack down as we go along */
        for (j=0; j<slices; j++, idx+=2)
        {
            stripIdx[idx  ] = nVert-1;              /* zero based index, last element in array (bottom vertex)... */
            stripIdx[idx+1] = offset+j;
        }
        stripIdx[idx  ] = nVert-1;                  /* repeat first slice's idx for closing off shape */
        stripIdx[idx+1] = offset;


        /* draw */
        fghDrawGeometrySolid(vertices,normals,NULL,nVert,stripIdx,stacks,(slices+1)*2);

        /* cleanup allocated memory */
        free(stripIdx);
    }

    /* cleanup allocated memory */
    free(vertices);
    free(normals);
    return NULL;
}

/*
 * Draws a solid sphere
 */
char *pdl_3d_solidSphere(double radius, GLint slices, GLint stacks)
{
    return fghSphere((GLfloat)radius, slices, stacks );
}
