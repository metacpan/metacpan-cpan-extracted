/* This file provides the code that wraps scalars with Magic to expost a read/write buffer to perl-space */
#include "buffer_scalar.c"

static void carp_croak_sv(SV* value) {
	dSP;
	PUSHMARK(SP);
	XPUSHs(value);
	PUTBACK;
	call_pv("Carp::croak", G_VOID | G_DISCARD);
}
#define carp_croak(format_args...) carp_croak_sv(sv_2mortal(newSVpvf(format_args)))

#include "glducktape.c"

/* These macros are used to access the OpenGL::Sandbox::MMap object data */
#define SCALAR_REF_DATA(obj) (SvROK(obj) && SvPOK(SvRV(obj))? (void*)SvPVX(SvRV(obj)) : (void*)0)
#define SCALAR_REF_LEN(obj)  (SvROK(obj) && SvPOK(SvRV(obj))? SvCUR(SvRV(obj)) : 0)

int sv_contains_integer(SV *sv) {
	const char *p;
	if (SvIOK(sv)) return 1;
	if (SvPOK(sv)) {
		p= SvPV_nolen(sv);
		if (*p == '-') p++;
		while (*p) {
			if (*p < '0' || *p > '9') return 0;
			p++;
		}
		return 1;
	}
	return 0;
}

/* Reading from perl hashes is annoying.  This simplified function only returns
 * non-NULL if the key existed and the value was defined.
 */
SV *_fetch_if_defined(HV *self, const char *field, int len) {
	SV **field_p= hv_fetch(self, field, len, 0);
	return (field_p && *field_p && SvOK(*field_p)) ? *field_p : NULL;
}

void _get_buffer_from_sv(SV *s, char **data, unsigned long *size) {
	dSP;
	STRLEN len;
	if (!s || !SvOK(s)) carp_croak("Data is undefined");
	if (sv_isa(s, "OpenGL::Array")) {
		/* OpenGL::Array has an internal struct and the only way to correctly
		 * access its ->data field is by calling the perl method ->ptr */
		ENTER;
		SAVETMPS;
		PUSHMARK(SP);
		EXTEND(SP, 1);
		PUSHs(sv_mortalcopy(s));
		PUTBACK;
		if (call_method("ptr", G_SCALAR) != 1)
			croak("stack assertion failed");
		SPAGAIN;
		*data= (char*) POPi;
		PUTBACK;
		FREETMPS;
		LEAVE;
		
		ENTER;
		SAVETMPS;
		PUSHMARK(SP);
		EXTEND(SP, 1);
		PUSHs(sv_mortalcopy(s));
		PUTBACK;
		if (call_method("length", G_SCALAR) != 1)
			croak("stack assertion failed");
		SPAGAIN;
		*size= POPi;
		PUTBACK;
		FREETMPS;
		LEAVE;
	}
	else if (sv_isa(s, "OpenGL::Sandbox::MMap") || (SvROK(s) && SvPOK(SvRV(s)))) {
		*data= SCALAR_REF_DATA(s);
		*size= SCALAR_REF_LEN(s);
	}
	else if (SvPOK(s)) {
		*data= SvPV(s, len);
		*size= len;
	}
	else
		carp_croak("Don't know how to get data buffer from %s", SvPV_nolen(s));
}

void _recursive_pack(void *dest, int *dest_i, int dest_lim, int component_type, SV *val) {
	int i, lim;
	SV **elem;
	AV *array;
	if (SvROK(val) && SvTYPE(SvRV(val)) == SVt_PVAV) {
		array= (AV*) SvRV(val);
		for (i= 0, lim=av_len(array)+1; i < lim; i++) {
			elem= av_fetch(array, i, 0);
			if (!elem || !*elem)
				carp_croak("Undefined value in array");
			_recursive_pack(dest, dest_i, dest_lim, component_type, *elem);
		}
	}
	else {
		if (*dest_i < dest_lim) {
			switch (component_type) {
			case GL_INT:          ((GLint*)dest)[*dest_i]= SvIV(val); break;
			case GL_UNSIGNED_INT: ((GLuint*)dest)[*dest_i]= SvUV(val); break;
			case GL_FLOAT:        ((GLfloat*)dest)[*dest_i]= SvNV(val); break;
			#ifdef GL_VERSION_4_1
			case GL_DOUBLE:       ((GLdouble*)dest)[*dest_i]= SvNV(val); break;
			#endif
			default: carp_croak("Unimplemented: pack data of type %d", component_type);
			}
		}
		/* increment regardless, so we can count how many extra arguments there were */
		++(*dest_i);
	}
}

/* This function operates on the idea that a power of two texture composed of
 * RGB or RGBA pixels must either be 4*4*4...*4 or 4*4*4...*3 bytes long.
 * So, it will either be a clean power of 4, or a power of 4 times 3.
 * This iteratively divides by 4, then checks to see if the result is 1 or 3.
 */
int _dimension_from_filesize(int filesize, int *has_alpha_out) {
	int dim= 1, size= filesize;
	if (size) {
		/* Count size's powers of 4, in dim */
		while ((size & 3) == 0) {
			size >>= 2;
			dim <<= 1;
		}
	}
	if (size != 1 && size != 3)
		carp_croak("File length 0x%X is not a power of 2 quare of pixels", size);
	if (size == 1) { /* RGBA, even power of 4 bytes */
		*has_alpha_out= 1;
		return dim >> 1;
	} else { /* RGB */
		*has_alpha_out= 0;
		return dim;
	}
}

int _get_format_info(int format, int *components_p, int *has_alpha_p, int *internal_format_p) {
	int components, has_alpha, internal_format;
	switch (format) {
	#ifdef GL_RED
	case GL_RED:   components= 1; has_alpha= 0; internal_format= GL_RED; break;
	#endif
	#ifdef GL_GREEN
	case GL_GREEN: components= 1; has_alpha= 0; internal_format= 1; break;
	case GL_BLUE:  components= 1; has_alpha= 0; internal_format= 1; break;
	case GL_ALPHA: components= 1; has_alpha= 1; internal_format= 1; break;
	#endif
	#ifdef GL_RED_INTEGER
	case GL_RED_INTEGER: components= 1; has_alpha= 0; internal_format= GL_RED; break;
	#endif
	#ifdef GL_RG
	case GL_RG:         components= 2; has_alpha= 0; internal_format= GL_RG; break;
	#endif
	#ifdef GL_RG_INTEGER
	case GL_RG_INTEGER: components= 2; has_alpha= 0; internal_format= GL_RG; break;
	#endif
	#ifdef GL_RGB_INTEGER
	case GL_RGB_INTEGER: 
	#endif
	#ifdef GL_BGR_INTEGER
	case GL_BGR_INTEGER:
	#endif
	#ifdef GL_BGR
	case GL_BGR:
	#endif
	case GL_RGB:   components= 3; has_alpha= 0; internal_format= GL_RGB; break;
	#ifdef GL_BGRA
	case GL_BGRA:
	#endif
	#ifdef GL_RGBA_INTEGER
	case GL_RGBA_INTEGER:
	#endif
	#ifdef GL_BGRA_INTEGER
	case GL_BGRA_INTEGER:
	#endif
	case GL_RGBA: components= 4; has_alpha= 1; internal_format= GL_RGBA; break;
	#ifdef GL_DEPTH_COMPONENT
	case GL_DEPTH_COMPONENT: components= 1; has_alpha= 0; internal_format= GL_DEPTH_COMPONENT; break;
	case GL_DEPTH_STENCIL:   components= 2; has_alpha= 0; internal_format= GL_DEPTH_STENCIL; break;
	#endif
	#ifdef GL_STENCIL_INDEX
	case GL_STENCIL_INDEX:   components= 1; has_alpha= 0; internal_format= GL_STENCIL_INDEX8; break;
	#endif
	#ifdef GL_LUMINANCE
	case GL_LUMINANCE:       components= 1; has_alpha= 0; internal_format= GL_RGB; break;
	case GL_LUMINANCE_ALPHA: components= 2; has_alpha= 1; internal_format= GL_RGBA; break;
	#endif
	#ifdef GL_COLOR_INDEX
	case GL_COLOR_INDEX:     components= 1; has_alpha= 0; internal_format= 1; break;
	#endif
	default:
		return 0;
	}
	if (components_p) *components_p= components;
	if (has_alpha_p) *has_alpha_p= has_alpha;
	if (internal_format_p) *internal_format_p= internal_format;
	return 1;
}

/* Given the 'format' and 'type' arguments of glTexImage2D, calculate how big each pixel is,
 * so that we can validate whether the user passed enough data.
 * Honestly I probably don't know enough to fully implement this correctly, but I figure these
 * guesses should cover any typical thing someone might try with Sandbox, and provide a small
 * level of safety against overrunning a buffer.
 */
int _get_pixel_size(int format, int type) {
	int mul, components;
	switch (type) {
	#ifdef GL_UNSIGNED_BYTE_3_3_2
	case GL_UNSIGNED_BYTE_3_3_2:
	case GL_UNSIGNED_BYTE_2_3_3_REV: return 1;
	#endif
	case GL_UNSIGNED_SHORT_5_6_5:
	case GL_UNSIGNED_SHORT_4_4_4_4:
	case GL_UNSIGNED_SHORT_5_5_5_1:
	#ifdef GL_UNSIGNED_SHORT_5_6_5_REV
	case GL_UNSIGNED_SHORT_5_6_5_REV:
	case GL_UNSIGNED_SHORT_4_4_4_4_REV:
	case GL_UNSIGNED_SHORT_1_5_5_5_REV:
	#endif
		return 2;
	#ifdef GL_UNSIGNED_INT_8_8_8_8
	case GL_UNSIGNED_INT_8_8_8_8:
	case GL_UNSIGNED_INT_10_10_10_2:
	case GL_UNSIGNED_INT_8_8_8_8_REV:
	case GL_UNSIGNED_INT_2_10_10_10_REV: return 4;
	#endif
	case GL_UNSIGNED_BYTE:
	case GL_BYTE:
		mul= 1;
		if (0)
	case GL_UNSIGNED_SHORT:
	case GL_SHORT:
			mul= 2;
		if (0)
	case GL_UNSIGNED_INT:
	case GL_INT:
	case GL_FLOAT:
			mul= 4;
		if (_get_format_info(format, &components, NULL, NULL))
			return mul * components;
	}
	return 0;
}
