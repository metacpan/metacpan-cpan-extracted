/*  Last saved: Wed 01 Mar 2017 12:43:24 PM */

/*  Copyright (c) 2015 Bob Free. All rights reserved.
 *  This program is free software; you can redistribute it and/or
 *  modify it under the same terms as Perl itself.
 */

/* OpenGL::Matrix */
#define IN_POGL_MATRIX_XS

#include <stdio.h>
#include <float.h>

#include "pgopogl.h"

#include "gl_util.h"

#define PI (3.14159265359)

#define needs_2D(mat, function) \
if (mat->dimension_count != 2)   \
{croak("OpenGL::Matrix::" function " requires a 2D matrix");}

#define needs_4x4(mat, function) \
if (mat->dimension_count != 2 || mat->dimensions[0] != 4 || mat->dimensions[1] != 4)   \
{croak("OpenGL::Matrix::" function " requires a 4x4 matrix");}

static int get_index(OpenGL__Matrix mat, int col, int row)
{
    int cols = mat->dimensions[0];
    int rows = mat->dimensions[1];
    return(row*cols + col);
}

static OpenGL__Matrix new_matrix(int cols, int rows)
{
	int mat_len = sizeof(oga_struct);
	OpenGL__Matrix mat = malloc(mat_len);
	memset(mat, 0, mat_len);

	int count = cols;
	mat->dimension_count = 1;
	if (rows)
	{
	    count *= rows;
    	mat->dimension_count++;
	}
	mat->dimensions[0] = cols;
	mat->dimensions[1] = rows;

	mat->type_count = 1;
	mat->item_count = count;
	mat->total_types_width = gl_type_size(GL_FLOAT);
	mat->data_length = mat->total_types_width * mat->item_count;
	
	mat->types = malloc(sizeof(GLenum) * mat->type_count);
	mat->type_offset = malloc(sizeof(GLint) * mat->type_count);
	mat->data = malloc(mat->data_length);
	mat->free_data = 1;

	mat->type_offset[0] = 0;
	mat->types[0] = GL_FLOAT;
	
	return(mat);
}

static double vec_length(double* vec, int dimensions)
{
  GLfloat ret = 0;
  int i = 0;
  for (; i<dimensions; i++) ret += pow(vec[i], 2);
  return(pow(ret, .5));
}

static void fetch_arrayref(GLfloat* array, int maxlen, SV* sv, char* function, char* var)
{
    if (!SvROK(sv))
    {
        croak("OpenGL::Matrix::%s %s is not a reference", function, var);
    }

    SV * tmpSV = (SV*)SvRV(sv);
    if (SvTYPE(tmpSV) != SVt_PVAV)
    {
        croak("OpenGL::Matrix::%s %s is not an arrayref", function, var);
    }
    
    AV* arrayref = (AV*)tmpSV;
    int len = av_len(arrayref)+1;
    if (len > maxlen) len = maxlen;
    int i = 0;
    for (; i<len; i++)
    {
        SV** elem = av_fetch(arrayref, i, 0);
        if (elem != NULL)
        {
            array[i] = (GLfloat)SvNV(*elem);
        }
    }
}

static void set_data_identity(GLfloat * data, int size)
{
    int offset = 0;
    int i = 0;
    int j;
	for (; i<size; i++)
	{
	    for(j=0; j<size; j++)
	    {
	        data[offset++] = (i == j) ? 1.0 : 0.0;
	    }
	}
}

static void set_data_frustrum(GLfloat * data,
    GLfloat left, GLfloat right, GLfloat top, GLfloat bottom, GLfloat n, GLfloat f)
{
    GLfloat width = right-left;
    GLfloat height = bottom-top;
    GLfloat depth = f-n;

    data[0]     = n*2.0/width;
    data[1]     = 0.0;
    data[2]     = 0.0;
    data[3]     = 0.0;
    data[4]     = 0.0;
    data[5]     = n*2.0/height;
    data[6]     = 0.0;
    data[7]     = 0.0;
    data[8]     = (right+left)/width;
    data[9]     = (bottom+top)/height;
    data[10]    = -(f+n)/depth;
    data[11]    = -1.0;
    data[12]    = 0.0;
    data[13]    = 0.0;
    data[14]    = -(f*n*2.0)/depth;
    data[15]    = 0.0;
}

static int inverse_lookup[] = {0,3,6,9,1,4,7,10,2,5,8,11};


MODULE = OpenGL::Matrix		PACKAGE = OpenGL::Matrix

#ifdef IN_POGL_MATRIX_XS

#//# $mat = OpenGL::Matrix->new($cols, $rows[, (OGM)matrix]);
#//- Constructor for 2D Matrix OGM - populated with matrix if provided
OpenGL::Matrix
new(Class, cols, rows, ...)
	GLsizei	cols
	GLsizei	rows
	CODE:
	{
	    OpenGL__Matrix mat = new_matrix(cols, rows);
		
		if (items > 3)
		{
    	    oga_struct * src_mat = INT2PTR(OpenGL__Array, SvIV((SV*)SvRV(ST(3))));
    	    
    	    if (mat && src_mat->type_count == 1 && src_mat->types[0] == GL_FLOAT)
    	    {
    		    int src_offset;
    		    int offset = 0;
                if (src_mat->dimension_count == 2)
                {
                    int src_cols = src_mat->dimensions[0];
                    int src_rows = src_mat->dimensions[1];
                    
                    GLfloat * data = (GLfloat*)mat->data;
                    GLfloat * src_data = (GLfloat*)src_mat->data;
                
                    int i = 0;
                    int j;
                    for (; i < rows; i++)
                    {
                        src_offset = i * src_cols;
                        for (j = 0; j < cols; j++)
                        {
                            if (i < src_rows && j < src_cols)
                            {
                                data[offset] = src_data[src_offset++];
                            }
                            else
                            {
                                data[offset] = (i == j) ? 1.0 : 0.0;
                            }
                            offset++;
                        }
                    }
                }
                else if (mat->item_count <= src_mat->item_count)
                {
                    memcpy(mat->data, src_mat->data, mat->data_length);
                }
                else
                {
                    memcpy(mat->data, src_mat->data, src_mat->data_length);
                    int diff = mat->data_length - src_mat->data_length;
                    memset(mat->data+src_mat->data_length, 0.0, diff);
                }
    	    }
		}
		
		RETVAL = mat;
	}
	OUTPUT:
		RETVAL

#//# $mat = OpenGL::Matrix->new_identity($size);
#//- Constructor for 2D Identity Matrix OGM
OpenGL::Matrix
new_identity(Class, size)
	GLsizei	size
	CODE:
	{
	    OpenGL__Matrix mat = new_matrix(size, size);
		set_data_identity((GLfloat*)mat->data, size);

		RETVAL = mat;
	}
	OUTPUT:
		RETVAL

#//# $value = $mat->element($col, $row[, $new_value]);
#//- Get/Set the value of a 2D Matrix element
#//- When setting a new_value, returns the previous value
GLfloat
element(mat, col, row, ...)
    OpenGL::Matrix	mat
    GLsizei	col
    GLsizei	row
	CODE:
	{
        needs_2D(mat, "element");
        if (col >= mat->dimensions[0])
        {
            croak("OpenGL::Matrix::element col exceeds matrix width");
        }
        if (row >= mat->dimensions[1])
        {
            croak("OpenGL::Matrix::element row exceeds matrix height");
        }
	    
	    GLfloat * data = mat->data;
	    int index = get_index(mat, col, row);
	    
	    RETVAL = data[index];
	    
	    if (items > 3)
	    {
	        data[index] = (GLfloat)SvNV(ST(3));
	    }
	}
	OUTPUT:
		RETVAL

#//# @row = $mat->row($row[, $arrayref]);
#//- Get/Set the value of a 2D Matrix row
#//- When setting new values, returns the previous row values
void
row(mat, row, ...)
    OpenGL::Matrix	mat
    GLsizei	row
	PPCODE:
	{
        needs_2D(mat, "row");
        if (row >= mat->dimensions[1])
        {
            croak("OpenGL::Matrix::element row exceeds matrix height");
        }

	    GLfloat * data = mat->data;
		int cols = mat->dimensions[0];
	    int index = row * cols;

		EXTEND(sp, cols);

        int i=0;
		for (; i<cols; i++)
		{
		    PUSHs(sv_2mortal(newSViv(data[index++])));
		}

	    if (items > 2)
	    {
            SV * sv = ST(2);
            fetch_arrayref(data+index, cols, sv, "row", "arrayref");
	    }
	}

#//# @col = $mat->column($col[, $arrayref]);
#//- Get/Set the value of a 2D Matrix column
#//- When setting new values, returns the previous column values
void
column(mat, col, ...)
    OpenGL::Matrix	mat
    GLsizei	col
	PPCODE:
	{
        needs_2D(mat, "column");
        
		int cols = mat->dimensions[0];
        if (col >= cols)
        {
            croak("OpenGL::Matrix::element col exceeds matrix width");
        }

	    GLfloat * data = mat->data;
		int rows = mat->dimensions[1];
	    int index = col;

		EXTEND(sp, rows);

        int i=0;
		for (; i<rows; i++)
		{
		    PUSHs(sv_2mortal(newSViv(data[index])));
		    index += cols;
		}

	    if (items > 2)
	    {
	        GLfloat array[rows];
            SV * sv = ST(2);
            fetch_arrayref(array, rows, sv, "column", "arrayref");
            
            int offset = col;
            for (i=0; i<rows; i++)
            {
                data[offset] = array[i];
                offset += cols;
            }
	    }
	}

#//# $status = $mat->set_quaternion($degrees, @vec|$vec);
#//- Set 4x4 Quaternion Matrix; returns 0 if successful
GLint
set_quaternion(mat, degrees, ...)
	OpenGL::Matrix	mat
	GLfloat         degrees
	CODE:
	{
	    needs_4x4(mat, "set_quaternion");

    	GLfloat vec[3];
	    int count = items - 2;
	    if (count == 3)
	    {
	        int i=0;
	        for (; i<count; i++)
	        {
			    vec[i] = (GLfloat)SvNV(ST(i+2));
	        }
	    }
	    else if (count == 1)
	    {
	        SV * sv = ST(2);
	        fetch_arrayref(vec, 3, sv, "set_quaternion", "vec");
	    }
	    else
	    {
	        croak("OpenGL::Matrix::set_quaternion requires"
	            " a 3 element xyz vector in either an array or an arrayref");
	    }
	    	    
	    double  a_2 = degrees * PI / 360.0;
	    double  sin_a_2 = sin(a_2);
	    double  x = vec[0] * sin_a_2;
	    double  y = vec[1] * sin_a_2;
	    double  z = vec[2] * sin_a_2;
	    GLfloat w = cos(a_2);

	    double  x2 = pow(x,2);
        double  y2 = pow(y,2);
        double  z2 = pow(z,2);
	    
	    GLfloat * data = (GLfloat*)mat->data;
	    data[0]     = 1-2*y2-2*z2;
	    data[1]     = 2*x*y-2*w*z;
	    data[2]     = 2*x*z+2*w*y;
	    data[3]     = 0.0;
	    data[4]     = 2*x*y+2*w*z;
	    data[5]     = 1-2*x2-2*z2;
	    data[6]     = 2*y*z+2*w*x;
	    data[7]     = 0.0;
	    data[8]     = 2*x*z-2*w*y;
	    data[9]     = 2*y*z-2*w*x;
	    data[10]    = 1-2*x2-2*y2;
	    data[11]    = 0.0;
	    data[12]    = 0.0;
	    data[13]    = 0.0;
	    data[14]    = 0.0;
	    data[15]    = 1.0;

        RETVAL = 0;
	}
	OUTPUT:
		RETVAL

#//# $status = $mat->set_frustrum($left, $right, $top, $bottom, $near, $far);
#//- Set 4x4 Frustrum Matrix; returns 0 if successful
GLint
set_frustrum(mat, left, right, top, bottom, n, f)
	OpenGL::Matrix	mat
	GLfloat         left
	GLfloat         right
	GLfloat         top
	GLfloat         bottom
	GLfloat         n
	GLfloat         f
	CODE:
	{
	    needs_4x4(mat, "set_frustrum");

        set_data_frustrum((GLfloat*)mat->data, left, right, top, bottom, n, f);

        RETVAL = 0;
	}
	OUTPUT:
	    RETVAL

#//# $status = $mat->set_perspective($width, $height, $near, $far, $fov);
#//- Set 4x4 Perspective Matrix; returns 0 if successful
GLint
set_perspective(mat, width, height, n, f, fov)
	OpenGL::Matrix	mat
	GLfloat         width
	GLfloat         height
	GLfloat         n
	GLfloat         f
	GLfloat         fov
	CODE:
	{
	    needs_4x4(mat, "set_perspective");

        double aspect = width/height;
        double h_2 = n*tan(fov*PI/360);
        double w_2 = h_2*aspect;
        set_data_frustrum((GLfloat*)mat->data, -w_2, w_2, -h_2, h_2, n, f);

        RETVAL = 0;
	}
    OUTPUT:
        RETVAL
        
#//# $status = $mat->set_ortho($left, $right, $top, $bottom, $near, $far);
#//- Set 4x4 Perspective Matrix; returns 0 if successful
GLint
set_ortho(mat, left, right, top, bottom, n, f)
	OpenGL::Matrix	mat
	GLfloat         left
	GLfloat         right
	GLfloat         top
	GLfloat         bottom
	GLfloat         n
	GLfloat         f
	CODE:
	{
	    needs_4x4(mat, "set_ortho");

        GLfloat width = right-left;
        GLfloat height = bottom-top;
        GLfloat depth = f-n;

		GLfloat * data = (GLfloat*)mat->data;
        data[0]     = 2/width;
        data[1]     = 0.0;
        data[2]     = 0.0;
        data[3]     = 0.0;
        data[4]     = 0.0;
        data[5]     = 2/height;
        data[6]     = 0.0;
        data[7]     = 0.0;
        data[8]     = 0.0;
        data[9]     = 0.0;
        data[10]    = -2/depth;
        data[11]    = 0.0;
        data[12]    = (right+left)/width;
        data[13]    = (bottom+top)/height;
        data[14]    = -(f+n)/depth;
        data[15]    = 1.0;

        RETVAL = 0;
	}
	OUTPUT:
	    RETVAL

#//# $status = $mat->set_lookat($eye_vec, $at_vec, $up_vec);
#//- Set 4x4 LookAt Matrix; returns 0 if successful
GLint
set_lookat(mat, sv_eye, sv_at, sv_up)
	OpenGL::Matrix	mat
	SV * sv_eye
	SV * sv_at
	SV * sv_up
	CODE:
	{
	    needs_4x4(mat, "set_lookat");

    	GLfloat eye_vec[3];
    	GLfloat at_vec[3];
    	GLfloat up_vec[3];

        fetch_arrayref(eye_vec, 3, sv_eye, "set_lookat", "eye_vec");
        fetch_arrayref(at_vec, 3, sv_at, "set_lookat", "at_vec");
        fetch_arrayref(up_vec, 3, sv_up, "set_lookat", "up_vec");
    	
	    GLfloat * data = (GLfloat*)mat->data;

        double  zaxis[] =
        {
          eye_vec[0] - at_vec[0],
          eye_vec[1] - at_vec[1],
          eye_vec[2] - at_vec[2]
        };

        if(!zaxis[0] && !zaxis[1] && !zaxis[2])
        {
          set_data_identity(data, 4);
        }
        else
        {
            double  z = vec_length(zaxis, 3);

            // Normalize distance
            zaxis[0] /= z;
            zaxis[1] /= z;
            zaxis[2] /= z;

            double  xaxis[] =
            {
                up_vec[1]*zaxis[2] - up_vec[2]*zaxis[1],
                up_vec[2]*zaxis[0] - up_vec[0]*zaxis[2],
                up_vec[0]*zaxis[1] - up_vec[1]*zaxis[0],
            };
            double  x = vec_length(xaxis, 3);

            if (x)
            {
                // Normalize xaxis
                xaxis[0] /= x;
                xaxis[1] /= x;
                xaxis[2] /= x;
            }
            else
            {
                xaxis[2] = 0;
            }

            double  yaxis[] =
            {
                zaxis[1]*xaxis[2] - zaxis[2]*xaxis[1],
                zaxis[2]*xaxis[0] - zaxis[0]*xaxis[2],
                zaxis[0]*xaxis[1] - zaxis[1]*xaxis[0]
            };
            double  y = vec_length(yaxis, 3);

            if (y)
            {
                // Normalize yaxis
                yaxis[0] /= y;
                yaxis[1] /= y;
                yaxis[2] /= y;
            }
            else
            {
                yaxis[0] = yaxis[1] = yaxis[2] = 0;
            }

            data[0]     = xaxis[0];
            data[1]     = yaxis[0];
            data[2]     = zaxis[0];
            data[3]     = 0.0;
            data[4]     = xaxis[1];
            data[5]     = yaxis[1];
            data[6]     = zaxis[1];
            data[7]     = 0.0;
            data[8]     = xaxis[2];
            data[9]     = yaxis[2];
            data[10]    = zaxis[2];
            data[11]    = 0.0;
            data[12]    = -(xaxis[0]*eye_vec[0] + xaxis[1]*eye_vec[1] + xaxis[2]*eye_vec[2]);
            data[13]    = -(yaxis[0]*eye_vec[0] + yaxis[1]*eye_vec[1] + yaxis[2]*eye_vec[2]);
            data[14]    = -(zaxis[0]*eye_vec[0] + zaxis[1]*eye_vec[1] + zaxis[2]*eye_vec[2]);
            data[15]    = 1.0;
        }
        
        RETVAL = 0;
	}
	OUTPUT:
	    RETVAL

#//# $status = $mat->translate($x, $y, $z);
#//- Translate a 4x4 Matrix; returns 0 if successful
GLint
translate(mat, x, y, z)
	OpenGL::Matrix	mat
	GLfloat         x
	GLfloat         y
	GLfloat         z
	CODE:
	{
	    needs_4x4(mat, "translate");

        GLfloat * data = (GLfloat*)mat->data;
        int size = mat->dimensions[0];
        int offset = size * (size-1);
        
        data[offset++] += x;
        data[offset++] += y;
        data[offset] += z;

        RETVAL = 0;
	}
	OUTPUT:
	    RETVAL

#//# $status = $mat->scale($x, $y, $z);
#//- Scale a 4x4 Matrix; returns 0 if successful
GLint
scale(mat, x, y, z)
	OpenGL::Matrix	mat
	GLfloat         x
	GLfloat         y
	GLfloat         z
	CODE:
	{
	    needs_4x4(mat, "scale");

        GLfloat * data = (GLfloat*)mat->data;
        int size = mat->dimensions[0];
        int offset = 0;

        data[offset] *= x;
        offset += size+1;
        data[offset] *= y;
        offset += size+1;
        data[offset] *= z;

        RETVAL = 0;
	}
	OUTPUT:
	    RETVAL

#//# $status = $mat->rotate_x($degrees);
#//- Rotate a 4x4 Matrix on the X axis; returns 0 if successful
GLint
rotate_x(mat, degrees)
	OpenGL::Matrix	mat
	GLfloat         degrees
	CODE:
	{
	    needs_4x4(mat, "rotate_x");

        GLfloat *   data = (GLfloat*)mat->data;
        double      a = degrees * PI / 180.0;
        double      y = sin(a);
        double      x = cos(a);
        
        GLfloat     row1[] = {data[4], data[5], data[6], data[7]};
        GLfloat     row2[] = {data[8], data[9], data[10], data[11]};
        
        data[4]     = x*row1[0] + y*row2[0];
        data[5]     = x*row1[1] + y*row2[1];
        data[6]     = x*row1[2] + y*row2[2];
        data[7]     = x*row1[3] + y*row2[3];
        data[8]     = x*row2[0] - y*row1[0];
        data[9]     = x*row2[1] - y*row1[1];
        data[10]    = x*row2[2] - y*row1[2];
        data[11]    = x*row2[3] - y*row1[3];

		RETVAL = 0;
	}
	OUTPUT:
	    RETVAL

#//# $status = $mat->rotate_y($degrees);
#//- Rotate a 4x4 Matrix on the Y axis; returns 0 if successful
GLint
rotate_y(mat, degrees)
	OpenGL::Matrix	mat
	GLfloat         degrees
	CODE:
	{
	    needs_4x4(mat, "rotate_y");

        GLfloat *   data = (GLfloat*)mat->data;
        double      a = degrees * PI / 180.0;
        double      y = sin(a);
        double      x = cos(a);
        
        GLfloat     row0[] = {data[0], data[1], data[2], data[3]};
        GLfloat     row2[] = {data[8], data[9], data[10], data[11]};

        data[0]     = x*row0[0] - y*row2[0];
        data[1]     = x*row0[1] - y*row2[1];
        data[2]     = x*row0[2] - y*row2[2];
        data[3]     = x*row0[3] - y*row2[3];
        data[8]     = x*row2[0] + y*row0[0];
        data[9]     = x*row2[1] + y*row0[1];
        data[10]    = x*row2[2] + y*row0[2];
        data[11]    = x*row2[3] + y*row0[3];

		RETVAL = 0;
	}
	OUTPUT:
	    RETVAL

#//# $status = $mat->rotate_z($degrees);
#//- Rotate a 4x4 Matrix on the Z axis; returns 0 if successful
GLint
rotate_z(mat, degrees)
	OpenGL::Matrix	mat
	GLfloat         degrees
	CODE:
	{
	    needs_4x4(mat, "rotate_z");

        GLfloat *   data = (GLfloat*)mat->data;
        double      a = degrees * PI / 180.0;
        double      y = sin(a);
        double      x = cos(a);
        
        GLfloat     row0[] = {data[0], data[1], data[2], data[3]};
        GLfloat     row1[] = {data[4], data[5], data[6], data[7]};

        data[0]     = x*row0[0] + y*row1[0];
        data[1]     = x*row0[1] + y*row1[1];
        data[2]     = x*row0[2] + y*row1[2];
        data[3]     = x*row0[3] + y*row1[3];
        data[4]     = x*row1[0] - y*row0[0];
        data[5]     = x*row1[1] - y*row0[1];
        data[6]     = x*row1[2] - y*row0[2];
        data[7]     = x*row1[3] - y*row0[3];

		RETVAL = 0;
	}
	OUTPUT:
	    RETVAL

#//# $status = $mat->transpose();
#//- Transposes a 4x4 Matrix; returns 0 if successful
GLint
transpose(mat)
	OpenGL::Matrix	mat
	CODE:
	{
	    needs_4x4(mat, "transpose");

        GLfloat *   data = (GLfloat*)mat->data;
        GLfloat     m1  = data[1];
        GLfloat     m2  = data[2];
        GLfloat     m3  = data[3];
        GLfloat     m6  = data[6];
        GLfloat     m7  = data[7];
        GLfloat     m11 = data[11];

        data[1]     = data[4];
        data[2]     = data[8];
        data[3]     = data[12];
        data[4]     = m1;
        data[6]     = data[9];
        data[7]     = data[13];
        data[8]     = m2;
        data[9]     = m6;
        data[11]    = data[14];
        data[12]    = m3;
        data[13]    = m7;
        data[14]    = m11;

		RETVAL = 0;
	}
	OUTPUT:
	    RETVAL

#//# $mat = OpenGL::Matrix->new_product((OGM)mat1, (OGM)mat2);
#//- Constructor for the product of two 4x4 Matrices
OpenGL::Matrix
new_product(Class, mat1, mat2)
	OpenGL::Matrix	mat1
	OpenGL::Matrix	mat2
	CODE:
	{
        needs_4x4(mat1, "new_product mat1");
        needs_4x4(mat2, "new_product mat2");
        OpenGL__Matrix mat = new_matrix(4, 4);
        
        GLfloat *   m1 = (GLfloat*)mat1->data;
        GLfloat *   m2 = (GLfloat*)mat2->data;
        GLfloat *   data = (GLfloat*)mat->data;
        
        data[0]  = m2[0]*m1[0]  + m2[1]*m1[4]  + m2[2]*m1[8]   + m2[3]*m1[12];
        data[1]  = m2[0]*m1[1]  + m2[1]*m1[5]  + m2[2]*m1[9]   + m2[3]*m1[13];
        data[2]  = m2[0]*m1[2]  + m2[1]*m1[6]  + m2[2]*m1[10]  + m2[3]*m1[14];
        data[3]  = m2[0]*m1[3]  + m2[1]*m1[7]  + m2[2]*m1[11]  + m2[3]*m1[15];
        data[4]  = m2[4]*m1[0]  + m2[5]*m1[4]  + m2[6]*m1[8]   + m2[7]*m1[12];
        data[5]  = m2[4]*m1[1]  + m2[5]*m1[5]  + m2[6]*m1[9]   + m2[7]*m1[13];
        data[6]  = m2[4]*m1[2]  + m2[5]*m1[6]  + m2[6]*m1[10]  + m2[7]*m1[14];
        data[7]  = m2[4]*m1[3]  + m2[5]*m1[7]  + m2[6]*m1[11]  + m2[7]*m1[15];
        data[8]  = m2[8]*m1[0]  + m2[9]*m1[4]  + m2[10]*m1[8]  + m2[11]*m1[12];
        data[9]  = m2[8]*m1[1]  + m2[9]*m1[5]  + m2[10]*m1[9]  + m2[11]*m1[13];
        data[10] = m2[8]*m1[2]  + m2[9]*m1[6]  + m2[10]*m1[10] + m2[11]*m1[14];
        data[11] = m2[8]*m1[3]  + m2[9]*m1[7]  + m2[10]*m1[11] + m2[11]*m1[15];
        data[12] = m2[12]*m1[0] + m2[13]*m1[4] + m2[14]*m1[8]  + m2[15]*m1[12];
        data[13] = m2[12]*m1[1] + m2[13]*m1[5] + m2[14]*m1[9]  + m2[15]*m1[13];
        data[14] = m2[12]*m1[2] + m2[13]*m1[6] + m2[14]*m1[10] + m2[15]*m1[14];
        data[15] = m2[12]*m1[3] + m2[13]*m1[7] + m2[14]*m1[11] + m2[15]*m1[15];

		RETVAL = mat;
	}
	OUTPUT:
		RETVAL

#//# $result = $mat->dot_product((OGM)matrix);
#//- Dot Product of two equal-sized Matrices; returns resulting scalar
GLfloat
dot_product(mat1, mat2)
	OpenGL::Matrix	mat1
	OpenGL::Matrix	mat2
	CODE:
	{
	    if (mat1->item_count != mat2->item_count)
	    {
	        croak("OpenGL::Matrix::dot_product requires an equal size matrix");
	    }
        
        GLfloat *   m1 = (GLfloat*)mat1->data;
        GLfloat *   m2 = (GLfloat*)mat2->data;
        
        GLfloat total = 0;
        int i=0;
        for (; i<mat1->item_count; i++)
        {
            total += m1[i] * m2[i];
        }

		RETVAL = total;
	}
	OUTPUT:
		RETVAL

#//# $status = $mat->invert(transpose);
#//- Invert 4x4 Matrix; returns 0 if successful, otherwise -1 if uninvertable
GLint
invert(mat, transpose)
	OpenGL::Matrix	mat
	GLboolean   	transpose
	CODE:
	{
	    needs_4x4(mat, "invert");

        GLfloat *   data = (GLfloat*)mat->data;
        double      m[] =
        {
            data[0]*data[5]   - data[1]*data[4],
            data[0]*data[6]   - data[2]*data[4],
            data[0]*data[7]   - data[3]*data[4],
            data[1]*data[6]   - data[2]*data[5],
            data[1]*data[7]   - data[3]*data[5],
            data[2]*data[7]   - data[3]*data[6],
            data[8]*data[13]  - data[9]*data[12],
            data[8]*data[14]  - data[10]*data[12],
            data[8]*data[15]  - data[11]*data[12],
            data[9]*data[14]  - data[10]*data[13],
            data[9]*data[15]  - data[11]*data[13],
            data[10]*data[15] - data[11]*data[14],
        };

        double det = m[0]*m[11] - m[1]*m[10] + m[2]*m[9] +
            m[3]*m[8] - m[4]*m[7] + m[5]*m[6];
            
        if (fabs(det) < FLT_EPSILON)
        {
            // Matrix not invertable
            RETVAL = -1;
        }
        else
        {
            double      d = 1.0/det;
            GLfloat     a[16];
            memcpy(a, data, sizeof(a));

            data[0]  = d * (a[5]*m[11]  - a[6]*m[10] + a[7]*m[9]);
            data[5]  = d * (a[0]*m[11]  - a[2]*m[8]  + a[3]*m[7]);
            data[10] = d * (a[12]*m[4]  - a[13]*m[2] + a[15]*m[0]);
            data[15] = d * (a[8]*m[3]   - a[9]*m[1]  + a[10]*m[0]);
            
            if (transpose)
            {
                data[4]  = d * (-a[1]*m[11] + a[2]*m[10] - a[3]*m[9]);
                data[8]  = d * (a[13]*m[5]  - a[14]*m[4] + a[15]*m[3]);
                data[12] = d * (-a[9]*m[5]  + a[10]*m[4] - a[11]*m[3]);
                data[1]  = d * (-a[4]*m[11] + a[6]*m[8]  - a[7]*m[7]);
                data[9]  = d * (-a[12]*m[5] + a[14]*m[2] - a[15]*m[1]);
                data[13] = d * (a[8]*m[5]   - a[10]*m[2] + a[11]*m[1]);
                data[2]  = d * (a[4]*m[10]  - a[5]*m[8]  + a[7]*m[6]);
                data[6]  = d * (-a[0]*m[10] + a[1]*m[8]  - a[3]*m[6]);
                data[14] = d * (-a[8]*m[4]  + a[9]*m[2]  - a[11]*m[0]);
                data[3]  = d * (-a[4]*m[9]  + a[5]*m[7]  - a[6]*m[6]);
                data[7]  = d * (a[0]*m[9]   - a[1]*m[7]  + a[2]*m[6]);
                data[11] = d * (-a[12]*m[3] + a[13]*m[1] - a[14]*m[0]);
            }
            else
            {
                data[1]  = d * (-a[1]*m[11] + a[2]*m[10] - a[3]*m[9]);
                data[2]  = d * (a[13]*m[5]  - a[14]*m[4] + a[15]*m[3]);
                data[3]  = d * (-a[9]*m[5]  + a[10]*m[4] - a[11]*m[3]);
                data[4]  = d * (-a[4]*m[11] + a[6]*m[8]  - a[7]*m[7]);
                data[6]  = d * (-a[12]*m[5] + a[14]*m[2] - a[15]*m[1]);
                data[7]  = d * (a[8]*m[5]   - a[10]*m[2] + a[11]*m[1]);
                data[8]  = d * (a[4]*m[10]  - a[5]*m[8]  + a[7]*m[6]);
                data[9]  = d * (-a[0]*m[10] + a[1]*m[8]  - a[3]*m[6]);
                data[11] = d * (-a[8]*m[4]  + a[9]*m[2]  - a[11]*m[0]);
                data[12] = d * (-a[4]*m[9]  + a[5]*m[7]  - a[6]*m[6]);
                data[13] = d * (a[0]*m[9]   - a[1]*m[7]  + a[2]*m[6]);
                data[14] = d * (-a[12]*m[3] + a[13]*m[1] - a[14]*m[0]);
            }
            
            RETVAL = 0;
        }
	}
	OUTPUT:
	    RETVAL


#endif /* End IN_POGL_MATRIX_XS */
