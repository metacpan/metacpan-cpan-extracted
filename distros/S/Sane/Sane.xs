#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <saneperl.h>

MODULE = Sane		PACKAGE = Sane::Device		PREFIX = sane_

PROTOTYPES: ENABLE
  
void
sane_DESTROY (handle)
		SANE_Handle	handle
        CODE:
       		SV* sv = get_sv("Sane::DEBUG", FALSE);
               	if (SvTRUE(sv)) printf("Closing SANE_Handle %p\n", (void *) handle);
		sane_close(handle);

void
sane_get_option_descriptor (h, n)
		SANE_Handle	h
		SANE_Int	n
	INIT:
		const SANE_Option_Descriptor *	opt;
               	HV* chv = (HV*) sv_2mortal((SV*) newHV());
               	AV* cav = (AV*) sv_2mortal((SV*) newAV());
               	HV* hv = (HV*) sv_2mortal((SV*) newHV());
                int i;
        PPCODE:
       		SV* sv = get_sv("Sane::DEBUG", FALSE);
               	if (SvTRUE(sv)) printf("Getting option description %d from SANE_Handle %p\n", n, (void *) h);
		opt = sane_get_option_descriptor (h, n);
                if (!opt) croak("Error getting sane_get_option_descriptor");
		if (opt->name != NULL) {
			hv_store(hv, "name", 4, newSVpv(opt->name, 0), 0);
		}
		if (opt->title != NULL) {
			hv_store(hv, "title", 5, newSVpv(opt->title, 0), 0);
		}
		if (opt->desc != NULL) {
			hv_store(hv, "desc", 4, newSVpv(opt->desc, 0), 0);
		}
		hv_store(hv, "type", 4, newSViv(opt->type), 0);
		hv_store(hv, "unit", 4, newSViv(opt->unit), 0);
		if (opt->type == SANE_TYPE_STRING)
                 hv_store(hv, "max_values", 10, newSViv(1), 0);
		else
                 hv_store(hv, "max_values", 10, newSViv(opt->size/(SANE_Int) sizeof (SANE_Word)), 0);
		hv_store(hv, "cap", 3, newSViv(opt->cap), 0);
		hv_store(hv, "constraint_type", 15, newSViv(opt->constraint_type), 0);
		switch (opt->constraint_type) {
			case SANE_CONSTRAINT_RANGE:
				if (opt->type == SANE_TYPE_FIXED) {
	                                hv_store(chv, "min", 3, newSVnv(SANE_UNFIX (opt->constraint.range->min)), 0);
					hv_store(chv, "max", 3, newSVnv(SANE_UNFIX (opt->constraint.range->max)), 0);
					hv_store(chv, "quant", 5, newSVnv(SANE_UNFIX (opt->constraint.range->quant)), 0);
					hv_store(hv, "constraint", 10, newRV((SV *)chv), 0);
                                }
                                else {
	                                hv_store(chv, "min", 3, newSViv(opt->constraint.range->min), 0);
					hv_store(chv, "max", 3, newSViv(opt->constraint.range->max), 0);
					hv_store(chv, "quant", 5, newSViv(opt->constraint.range->quant), 0);
					hv_store(hv, "constraint", 10, newRV((SV *)chv), 0);
                                }
				break;
			case SANE_CONSTRAINT_WORD_LIST:
				for (i = 0; i < opt->constraint.word_list[0]; ++i) {
					if (opt->type == SANE_TYPE_INT)
						av_push(cav, newSViv(opt->constraint.word_list[i + 1]));
					else
						av_push(cav, newSVnv(SANE_UNFIX (opt->constraint.word_list[i + 1])));
				}
				hv_store(hv, "constraint", 10, newRV((SV *)cav), 0);
				break;
			case SANE_CONSTRAINT_STRING_LIST:
				for (i = 0; opt->constraint.string_list[i]; ++i) {
					av_push(cav, newSVpv(opt->constraint.string_list[i], 0));
				}
				hv_store(hv, "constraint", 10, newRV((SV *)cav), 0);
				break;
			default:
				break;
		}
		XPUSHs(newRV((SV *)hv));

void
sane_get_option (h, n)
		SANE_Handle	h
		SANE_Int	n
	INIT:
		SANE_Status	status;
		void *		value;
		const SANE_Option_Descriptor *	opt;
        PPCODE:
       		SV* sv = get_sv("Sane::DEBUG", FALSE);
               	if (SvTRUE(sv)) printf("Getting option %d from SANE_Handle %p\n", n, (void *) h);
		opt = sane_get_option_descriptor (h, n);
                if (!opt) croak("Error getting sane_get_option_descriptor");
                if ( opt->size == 0 ) {
                        XSRETURN_UNDEF;
                        return;
                }
		value = malloc (opt->size);
		if (!value) croak("Error allocating memory");
		status = sane_control_option (h, n, SANE_ACTION_GET_VALUE, value, 0);
       		sv = get_sv("Sane::_status", FALSE);
                sv_setiv(sv, status);
		if (status) {
                	XPUSHs(sv_2mortal(newSV(0)));
                }
                else if (opt->type == SANE_TYPE_STRING)
			XPUSHs(sv_2mortal(newSVpv((char *) value, 0)));
                else if (opt->size > (SANE_Int) sizeof (SANE_Word)) {
               		AV* av = (AV*) sv_2mortal((SV*) newAV());
			int vector_length = opt->size / sizeof (SANE_Word);
                        int i;
			for (i = 0; i < vector_length; ++i)
				if (opt->type == SANE_TYPE_INT)
					av_push(av, newSViv(*(SANE_Int *) (value+i*sizeof(SANE_Word))));
				else
					av_push(av, newSVnv(SANE_UNFIX (*(SANE_Word *) (value+i*sizeof(SANE_Word)))));
			XPUSHs(newRV((SV *)av));
                }
                else {
	                switch (opt->type) {
				case SANE_TYPE_BOOL:
					XPUSHs(sv_2mortal(newSViv(*(SANE_Bool *) value)));
					break;
				case SANE_TYPE_INT:
					XPUSHs(sv_2mortal(newSViv(*(SANE_Int *) value)));
					break;
				case SANE_TYPE_FIXED:
                                	XPUSHs(sv_2mortal(newSVnv(SANE_UNFIX (*(SANE_Word *) value))));
					break;
				default:
					break;
			}
                }
		free (value);

void
sane_set_auto (h, n)
		SANE_Handle	h
		SANE_Int	n
	INIT:
		SANE_Status	status;
		SANE_Int	info;
        PPCODE:
       		SV* sv = get_sv("Sane::DEBUG", FALSE);
               	if (SvTRUE(sv)) printf("Setting option %d to automatic on SANE_Handle %p\n", n, (void *) h);
		status = sane_control_option (h, n, SANE_ACTION_SET_AUTO, 0, &info);
       		sv = get_sv("Sane::_status", FALSE);
                sv_setiv(sv, status); 
                XPUSHs(sv_2mortal(newSViv(info)));

void
sane_set_option (h, n, value)
		SANE_Handle	h
		SANE_Int	n
                SV*		value
	INIT:
		SANE_Status	status;
		SANE_Int	info;
		void *		valuep;
		const SANE_Option_Descriptor *	opt;
		SANE_Bool	b;
		SANE_Fixed      fixed;
		int		i, vector_length = 0;
		SV **		svp;
		SANE_Word *	vector;
		char *		string;
        PPCODE:
       		SV* sv = get_sv("Sane::DEBUG", FALSE);
               	if (SvTRUE(sv)) printf("Setting option %d on SANE_Handle %p\n", n, (void *) h);
		opt = sane_get_option_descriptor (h, n);
                if (!opt) croak("Error getting sane_get_option_descriptor");
		switch (opt->type) {
			case SANE_TYPE_BOOL:
				b = (SANE_Bool)SvIV(value);
				valuep = &b;
				break;
			case SANE_TYPE_INT:
			case SANE_TYPE_FIXED:
				if (SvNIOK(value) || SvPOK(value)) {
					if (opt->type == SANE_TYPE_INT)
							fixed = (SANE_Int)SvIV(value);
                                        else
							fixed = (SANE_Fixed)SANE_FIX(SvNV(value));
					valuep = &fixed;
                                }
                                else if (SvROK(value) && SvTYPE(SvRV(value)) == SVt_PVAV) {
	                                AV* array = (AV*) SvRV(value);
                                        vector_length = av_len((AV*) array) + 1;
					if (vector_length > opt->size / sizeof (SANE_Word))
						croak("Array has too many elements");
					vector = malloc (opt->size);
					if (!vector)
						croak("Error allocating memory");
					for (i = 0; i < vector_length; i++) {
						svp = av_fetch(array, i, 0);
						if (SvNIOK(*svp) || SvPOK(*svp)) {
							if (opt->type == SANE_TYPE_INT)
	                                        		vector[i] = (SANE_Int)SvIV(*(svp));
                                        		else
                                        			vector[i] = (SANE_Fixed)SANE_FIX(SvNV(*svp));
                                                }
					}
                                	valuep = vector;
				}
                                else
	                                croak("Value is neither a number, nor an array reference");
                                break;
			case SANE_TYPE_STRING:
				string = (char *)SvPV_nolen(value);
                                valuep = malloc (opt->size);
				if (!valuep) croak("Error allocating memory");
				strncpy (valuep, string, opt->size);
				((char *) valuep)[opt->size - 1] = 0;
				break;
			default:
				break;
		}
		status = sane_control_option (h, n, SANE_ACTION_SET_VALUE, valuep, &info);
       	        if (opt->type == SANE_TYPE_STRING
                    || ((opt->type == SANE_TYPE_INT
                         || opt->type == SANE_TYPE_FIXED) && vector_length))
                	free(valuep);
       		sv = get_sv("Sane::_status", FALSE);
                sv_setiv(sv, status); 
               	XPUSHs(sv_2mortal(newSViv(info)));

void
sane_start (handle)
		SANE_Handle	handle
	INIT:
        	SANE_Status	status;
	CODE:
       		SV* sv = get_sv("Sane::DEBUG", FALSE);
               	if (SvTRUE(sv)) printf("Running sane_start for SANE_Handle %p\n", (void *) handle);
       		status = sane_start(handle);
                sv = get_sv("Sane::_status", FALSE);
                sv_setiv(sv, status); 

void
sane_get_parameters (handle)
		SANE_Handle		handle
	INIT:
		SANE_Status		status;
		SANE_Parameters		params;
               	HV* hv = (HV*) sv_2mortal((SV*) newHV());
        PPCODE:
       		SV* sv = get_sv("Sane::DEBUG", FALSE);
               	if (SvTRUE(sv)) printf("Getting parameters for SANE_Handle %p\n", (void *) handle);
		status = sane_get_parameters (handle, &params);
		sv = get_sv("Sane::_status", FALSE);
                sv_setiv(sv, status);
                if (status) {
                	XPUSHs(sv_2mortal(newSV(0)));
                }
                else {
			hv_store(hv, "format", 6, newSViv(params.format), 0);
			hv_store(hv, "last_frame", 10, newSViv(params.last_frame), 0);
			hv_store(hv, "bytes_per_line", 14, newSViv(params.bytes_per_line), 0);
			hv_store(hv, "pixels_per_line", 15, newSViv(params.pixels_per_line), 0);
			hv_store(hv, "lines", 5, newSViv(params.lines), 0);
			hv_store(hv, "depth", 5, newSViv(params.depth), 0);
			XPUSHs(newRV((SV *)hv));
                }

void
sane_read (handle, max_length)
		SANE_Handle	handle
		SANE_Int	max_length
	INIT:
		SANE_Status	status;
                SANE_Byte *	data;
                SANE_Int	length;
        PPCODE:
		data = malloc (max_length);
		status = sane_read (handle, data, max_length, &length);
       		SV* sv = get_sv("Sane::_status", FALSE);
                sv_setiv(sv, status); 
                if (status) {
                	XPUSHs(sv_2mortal(newSV(0)));
                	XPUSHs(sv_2mortal(newSViv(0)));
                }
                else {
                	XPUSHs(sv_2mortal(newSVpvn(data, length)));
			XPUSHs(sv_2mortal(newSViv(length)));
                }
                free (data);

void
sane_cancel (handle)
	SANE_Handle	handle

void
sane_set_io_mode (handle, non_blocking)
		SANE_Handle	handle
        	SANE_Bool	non_blocking
	INIT:
		SANE_Status	status;
	CODE:
       		SV* sv = get_sv("Sane::DEBUG", FALSE);
               	if (SvTRUE(sv)) printf("Setting IO mode to %d on SANE_Handle %p\n", non_blocking, (void *) handle);
       		status = sane_set_io_mode (handle, non_blocking);
                sv = get_sv("Sane::_status", FALSE);
                sv_setiv(sv, status); 

void
sane_get_select_fd (handle)
		SANE_Handle	handle
	INIT:
		SANE_Status	status;
		SANE_Int	fd;
        PPCODE:
       		SV* sv = get_sv("Sane::DEBUG", FALSE);
               	if (SvTRUE(sv)) printf("Getting file handle of SANE_Handle %p\n", (void *) handle);
		status = sane_get_select_fd (handle, &fd);
                sv = get_sv("Sane::_status", FALSE);
                sv_setiv(sv, status); 
                if (status) {
                	XPUSHs(sv_2mortal(newSV(0)));
                }
                else {
	                XPUSHs(sv_2mortal(newSViv(fd)));
                }


MODULE = Sane		PACKAGE = Sane		  PREFIX = sane_

PROTOTYPES: ENABLE
  
BOOT:
	HV *stash;
	stash = gv_stashpv("Sane", TRUE);

	newCONSTSUB(stash, "SANE_FALSE", newSViv(SANE_FALSE));
	newCONSTSUB(stash, "SANE_TRUE", newSViv(SANE_TRUE));

	newCONSTSUB(stash, "SANE_STATUS_GOOD", newSViv(SANE_STATUS_GOOD));
	newCONSTSUB(stash, "SANE_STATUS_UNSUPPORTED", newSViv(SANE_STATUS_UNSUPPORTED));
	newCONSTSUB(stash, "SANE_STATUS_CANCELLED", newSViv(SANE_STATUS_CANCELLED));
	newCONSTSUB(stash, "SANE_STATUS_DEVICE_BUSY", newSViv(SANE_STATUS_DEVICE_BUSY));
	newCONSTSUB(stash, "SANE_STATUS_INVAL", newSViv(SANE_STATUS_INVAL));
	newCONSTSUB(stash, "SANE_STATUS_EOF", newSViv(SANE_STATUS_EOF));
	newCONSTSUB(stash, "SANE_STATUS_JAMMED", newSViv(SANE_STATUS_JAMMED));
	newCONSTSUB(stash, "SANE_STATUS_NO_DOCS", newSViv(SANE_STATUS_NO_DOCS));
	newCONSTSUB(stash, "SANE_STATUS_COVER_OPEN", newSViv(SANE_STATUS_COVER_OPEN));
	newCONSTSUB(stash, "SANE_STATUS_IO_ERROR", newSViv(SANE_STATUS_IO_ERROR));
	newCONSTSUB(stash, "SANE_STATUS_NO_MEM", newSViv(SANE_STATUS_NO_MEM));
	newCONSTSUB(stash, "SANE_STATUS_ACCESS_DENIED", newSViv(SANE_STATUS_ACCESS_DENIED));

	newCONSTSUB(stash, "SANE_TYPE_BOOL", newSViv(SANE_TYPE_BOOL));
	newCONSTSUB(stash, "SANE_TYPE_INT", newSViv(SANE_TYPE_INT));
	newCONSTSUB(stash, "SANE_TYPE_FIXED", newSViv(SANE_TYPE_FIXED));
	newCONSTSUB(stash, "SANE_TYPE_STRING", newSViv(SANE_TYPE_STRING));
	newCONSTSUB(stash, "SANE_TYPE_BUTTON", newSViv(SANE_TYPE_BUTTON));
	newCONSTSUB(stash, "SANE_TYPE_GROUP", newSViv(SANE_TYPE_GROUP));

	newCONSTSUB(stash, "SANE_UNIT_NONE", newSViv(SANE_UNIT_NONE));
	newCONSTSUB(stash, "SANE_UNIT_PIXEL", newSViv(SANE_UNIT_PIXEL));
	newCONSTSUB(stash, "SANE_UNIT_BIT", newSViv(SANE_UNIT_BIT));
	newCONSTSUB(stash, "SANE_UNIT_MM", newSViv(SANE_UNIT_MM));
	newCONSTSUB(stash, "SANE_UNIT_DPI", newSViv(SANE_UNIT_DPI));
	newCONSTSUB(stash, "SANE_UNIT_PERCENT", newSViv(SANE_UNIT_PERCENT));
	newCONSTSUB(stash, "SANE_UNIT_MICROSECOND", newSViv(SANE_UNIT_MICROSECOND));

	newCONSTSUB(stash, "SANE_CAP_SOFT_SELECT", newSViv(SANE_CAP_SOFT_SELECT));
	newCONSTSUB(stash, "SANE_CAP_HARD_SELECT", newSViv(SANE_CAP_HARD_SELECT));
	newCONSTSUB(stash, "SANE_CAP_SOFT_DETECT", newSViv(SANE_CAP_SOFT_DETECT));
	newCONSTSUB(stash, "SANE_CAP_EMULATED", newSViv(SANE_CAP_EMULATED));
	newCONSTSUB(stash, "SANE_CAP_AUTOMATIC", newSViv(SANE_CAP_AUTOMATIC));
	newCONSTSUB(stash, "SANE_CAP_INACTIVE", newSViv(SANE_CAP_INACTIVE));
	newCONSTSUB(stash, "SANE_CAP_ADVANCED", newSViv(SANE_CAP_ADVANCED));
#ifdef SANE_CAP_ALWAYS_SETTABLE
	newCONSTSUB(stash, "SANE_CAP_ALWAYS_SETTABLE", newSViv(SANE_CAP_ALWAYS_SETTABLE));
#endif

	newCONSTSUB(stash, "SANE_INFO_INEXACT", newSViv(SANE_INFO_INEXACT));
	newCONSTSUB(stash, "SANE_INFO_RELOAD_OPTIONS", newSViv(SANE_INFO_RELOAD_OPTIONS));
	newCONSTSUB(stash, "SANE_INFO_RELOAD_PARAMS", newSViv(SANE_INFO_RELOAD_PARAMS));

	newCONSTSUB(stash, "SANE_CONSTRAINT_NONE", newSViv(SANE_CONSTRAINT_NONE));
	newCONSTSUB(stash, "SANE_CONSTRAINT_RANGE", newSViv(SANE_CONSTRAINT_RANGE));
	newCONSTSUB(stash, "SANE_CONSTRAINT_WORD_LIST", newSViv(SANE_CONSTRAINT_WORD_LIST));
	newCONSTSUB(stash, "SANE_CONSTRAINT_STRING_LIST", newSViv(SANE_CONSTRAINT_STRING_LIST));

	newCONSTSUB(stash, "SANE_FRAME_GRAY", newSViv(SANE_FRAME_GRAY));
	newCONSTSUB(stash, "SANE_FRAME_RGB", newSViv(SANE_FRAME_RGB));
	newCONSTSUB(stash, "SANE_FRAME_RED", newSViv(SANE_FRAME_RED));
	newCONSTSUB(stash, "SANE_FRAME_GREEN", newSViv(SANE_FRAME_GREEN));
	newCONSTSUB(stash, "SANE_FRAME_BLUE", newSViv(SANE_FRAME_BLUE));

	newCONSTSUB(stash, "SANE_NAME_NUM_OPTIONS", newSVpv(SANE_NAME_NUM_OPTIONS, 0));
	newCONSTSUB(stash, "SANE_NAME_PREVIEW", newSVpv(SANE_NAME_PREVIEW, 0));
	newCONSTSUB(stash, "SANE_NAME_GRAY_PREVIEW", newSVpv(SANE_NAME_GRAY_PREVIEW, 0));
	newCONSTSUB(stash, "SANE_NAME_BIT_DEPTH", newSVpv(SANE_NAME_BIT_DEPTH, 0));
	newCONSTSUB(stash, "SANE_NAME_SCAN_MODE", newSVpv(SANE_NAME_SCAN_MODE, 0));
	newCONSTSUB(stash, "SANE_NAME_SCAN_SPEED", newSVpv(SANE_NAME_SCAN_SPEED, 0));
	newCONSTSUB(stash, "SANE_NAME_SCAN_SOURCE", newSVpv(SANE_NAME_SCAN_SOURCE, 0));
	newCONSTSUB(stash, "SANE_NAME_BACKTRACK", newSVpv(SANE_NAME_BACKTRACK, 0));
	newCONSTSUB(stash, "SANE_NAME_SCAN_TL_X", newSVpv(SANE_NAME_SCAN_TL_X, 0));
	newCONSTSUB(stash, "SANE_NAME_SCAN_TL_Y", newSVpv(SANE_NAME_SCAN_TL_Y, 0));
	newCONSTSUB(stash, "SANE_NAME_SCAN_BR_X", newSVpv(SANE_NAME_SCAN_BR_X, 0));
	newCONSTSUB(stash, "SANE_NAME_SCAN_BR_Y", newSVpv(SANE_NAME_SCAN_BR_Y, 0));
	newCONSTSUB(stash, "SANE_NAME_SCAN_RESOLUTION", newSVpv(SANE_NAME_SCAN_RESOLUTION, 0));
	newCONSTSUB(stash, "SANE_NAME_SCAN_X_RESOLUTION", newSVpv(SANE_NAME_SCAN_X_RESOLUTION, 0));
	newCONSTSUB(stash, "SANE_NAME_SCAN_Y_RESOLUTION", newSVpv(SANE_NAME_SCAN_Y_RESOLUTION, 0));
#ifdef SANE_NAME_PAGE_WIDTH
	newCONSTSUB(stash, "SANE_NAME_PAGE_WIDTH", newSVpv(SANE_NAME_PAGE_WIDTH, 0));
#endif
#ifdef SANE_NAME_PAGE_HEIGHT
	newCONSTSUB(stash, "SANE_NAME_PAGE_HEIGHT", newSVpv(SANE_NAME_PAGE_HEIGHT, 0));
#endif
	newCONSTSUB(stash, "SANE_NAME_CUSTOM_GAMMA", newSVpv(SANE_NAME_CUSTOM_GAMMA, 0));
	newCONSTSUB(stash, "SANE_NAME_GAMMA_VECTOR", newSVpv(SANE_NAME_GAMMA_VECTOR, 0));
	newCONSTSUB(stash, "SANE_NAME_GAMMA_VECTOR_R", newSVpv(SANE_NAME_GAMMA_VECTOR_R, 0));
	newCONSTSUB(stash, "SANE_NAME_GAMMA_VECTOR_G", newSVpv(SANE_NAME_GAMMA_VECTOR_G, 0));
	newCONSTSUB(stash, "SANE_NAME_GAMMA_VECTOR_B", newSVpv(SANE_NAME_GAMMA_VECTOR_B, 0));
	newCONSTSUB(stash, "SANE_NAME_BRIGHTNESS", newSVpv(SANE_NAME_BRIGHTNESS, 0));
	newCONSTSUB(stash, "SANE_NAME_CONTRAST", newSVpv(SANE_NAME_CONTRAST, 0));
	newCONSTSUB(stash, "SANE_NAME_GRAIN_SIZE", newSVpv(SANE_NAME_GRAIN_SIZE, 0));
	newCONSTSUB(stash, "SANE_NAME_HALFTONE", newSVpv(SANE_NAME_HALFTONE, 0));
	newCONSTSUB(stash, "SANE_NAME_BLACK_LEVEL", newSVpv(SANE_NAME_BLACK_LEVEL, 0));
	newCONSTSUB(stash, "SANE_NAME_WHITE_LEVEL", newSVpv(SANE_NAME_WHITE_LEVEL, 0));
	newCONSTSUB(stash, "SANE_NAME_WHITE_LEVEL_R", newSVpv(SANE_NAME_WHITE_LEVEL_R, 0));
	newCONSTSUB(stash, "SANE_NAME_WHITE_LEVEL_G", newSVpv(SANE_NAME_WHITE_LEVEL_G, 0));
	newCONSTSUB(stash, "SANE_NAME_WHITE_LEVEL_B", newSVpv(SANE_NAME_WHITE_LEVEL_B, 0));
	newCONSTSUB(stash, "SANE_NAME_SHADOW", newSVpv(SANE_NAME_SHADOW, 0));
	newCONSTSUB(stash, "SANE_NAME_SHADOW_R", newSVpv(SANE_NAME_SHADOW_R, 0));
	newCONSTSUB(stash, "SANE_NAME_SHADOW_G", newSVpv(SANE_NAME_SHADOW_G, 0));
	newCONSTSUB(stash, "SANE_NAME_SHADOW_B", newSVpv(SANE_NAME_SHADOW_B, 0));
	newCONSTSUB(stash, "SANE_NAME_HIGHLIGHT", newSVpv(SANE_NAME_HIGHLIGHT, 0));
	newCONSTSUB(stash, "SANE_NAME_HIGHLIGHT_R", newSVpv(SANE_NAME_HIGHLIGHT_R, 0));
	newCONSTSUB(stash, "SANE_NAME_HIGHLIGHT_G", newSVpv(SANE_NAME_HIGHLIGHT_G, 0));
	newCONSTSUB(stash, "SANE_NAME_HIGHLIGHT_B", newSVpv(SANE_NAME_HIGHLIGHT_B, 0));
	newCONSTSUB(stash, "SANE_NAME_HUE", newSVpv(SANE_NAME_HUE, 0));
	newCONSTSUB(stash, "SANE_NAME_SATURATION", newSVpv(SANE_NAME_SATURATION, 0));
	newCONSTSUB(stash, "SANE_NAME_FILE", newSVpv(SANE_NAME_FILE, 0));
	newCONSTSUB(stash, "SANE_NAME_HALFTONE_DIMENSION", newSVpv(SANE_NAME_HALFTONE_DIMENSION, 0));
	newCONSTSUB(stash, "SANE_NAME_HALFTONE_PATTERN", newSVpv(SANE_NAME_HALFTONE_PATTERN, 0));
	newCONSTSUB(stash, "SANE_NAME_RESOLUTION_BIND", newSVpv(SANE_NAME_RESOLUTION_BIND, 0));
	newCONSTSUB(stash, "SANE_NAME_NEGATIVE", newSVpv(SANE_NAME_NEGATIVE, 0));
	newCONSTSUB(stash, "SANE_NAME_QUALITY_CAL", newSVpv(SANE_NAME_QUALITY_CAL, 0));
	newCONSTSUB(stash, "SANE_NAME_DOR", newSVpv(SANE_NAME_DOR, 0));
	newCONSTSUB(stash, "SANE_NAME_RGB_BIND", newSVpv(SANE_NAME_RGB_BIND, 0));
	newCONSTSUB(stash, "SANE_NAME_THRESHOLD", newSVpv(SANE_NAME_THRESHOLD, 0));
	newCONSTSUB(stash, "SANE_NAME_ANALOG_GAMMA", newSVpv(SANE_NAME_ANALOG_GAMMA, 0));
	newCONSTSUB(stash, "SANE_NAME_ANALOG_GAMMA_R", newSVpv(SANE_NAME_ANALOG_GAMMA_R, 0));
	newCONSTSUB(stash, "SANE_NAME_ANALOG_GAMMA_G", newSVpv(SANE_NAME_ANALOG_GAMMA_G, 0));
	newCONSTSUB(stash, "SANE_NAME_ANALOG_GAMMA_B", newSVpv(SANE_NAME_ANALOG_GAMMA_B, 0));
	newCONSTSUB(stash, "SANE_NAME_ANALOG_GAMMA_BIND", newSVpv(SANE_NAME_ANALOG_GAMMA_BIND, 0));
	newCONSTSUB(stash, "SANE_NAME_WARMUP", newSVpv(SANE_NAME_WARMUP, 0));
	newCONSTSUB(stash, "SANE_NAME_CAL_EXPOS_TIME", newSVpv(SANE_NAME_CAL_EXPOS_TIME, 0));
	newCONSTSUB(stash, "SANE_NAME_CAL_EXPOS_TIME_R", newSVpv(SANE_NAME_CAL_EXPOS_TIME_R, 0));
	newCONSTSUB(stash, "SANE_NAME_CAL_EXPOS_TIME_G", newSVpv(SANE_NAME_CAL_EXPOS_TIME_G, 0));
	newCONSTSUB(stash, "SANE_NAME_CAL_EXPOS_TIME_B", newSVpv(SANE_NAME_CAL_EXPOS_TIME_B, 0));
	newCONSTSUB(stash, "SANE_NAME_SCAN_EXPOS_TIME", newSVpv(SANE_NAME_SCAN_EXPOS_TIME, 0));
	newCONSTSUB(stash, "SANE_NAME_SCAN_EXPOS_TIME_R", newSVpv(SANE_NAME_SCAN_EXPOS_TIME_R, 0));
	newCONSTSUB(stash, "SANE_NAME_SCAN_EXPOS_TIME_G", newSVpv(SANE_NAME_SCAN_EXPOS_TIME_G, 0));
	newCONSTSUB(stash, "SANE_NAME_SCAN_EXPOS_TIME_B", newSVpv(SANE_NAME_SCAN_EXPOS_TIME_B, 0));
	newCONSTSUB(stash, "SANE_NAME_SELECT_EXPOSURE_TIME", newSVpv(SANE_NAME_SELECT_EXPOSURE_TIME, 0));
	newCONSTSUB(stash, "SANE_NAME_CAL_LAMP_DEN", newSVpv(SANE_NAME_CAL_LAMP_DEN, 0));
	newCONSTSUB(stash, "SANE_NAME_SCAN_LAMP_DEN", newSVpv(SANE_NAME_SCAN_LAMP_DEN, 0));
	newCONSTSUB(stash, "SANE_NAME_SELECT_LAMP_DENSITY", newSVpv(SANE_NAME_SELECT_LAMP_DENSITY, 0));
	newCONSTSUB(stash, "SANE_NAME_LAMP_OFF_AT_EXIT", newSVpv(SANE_NAME_LAMP_OFF_AT_EXIT, 0));

void
sane__init (class)
	INIT:
		SANE_Status		status;
                SANE_Int		version_code;
	PPCODE:
       		SV* sv = get_sv("Sane::DEBUG", FALSE);
               	if (SvTRUE(sv)) printf("Running sane_init\n");
		status = sane_init(&version_code, NULL);
                sv = get_sv("Sane::_status", FALSE);
                sv_setiv(sv, status); 
                if (status) {
                	XPUSHs(sv_2mortal(newSV(0)));
                }
                else {
	                XPUSHs(sv_2mortal(newSViv(version_code)));
                }

## Can't test this. If needed, should be integrated into _init above
## void
## CallSubSV(name)
## 		SV *			name
## 		SANE_String_Const	resource
## 		SANE_Char *		username
## 		SANE_Char *		password
## 	CODE:
## 		dSP;
## 		int count;
## 
## 		ENTER;
## 		SAVETMPS;
## 
## 		PUSHMARK(SP);
## 		XPUSHs(sv_2mortal(newSVpv(resource, 0)));
## 		XPUSHs(sv_2mortal(newSVpv(username, 0)));
## 		XPUSHs(sv_2mortal(newSVpv(password, 0)));
## 		PUTBACK;
## 
## 		count = call_sv(name, G_DISCARD, G_ARRAY);
## 
## 		SPAGAIN;
## 
## 		if (count != 2) croak("Big trouble\n");
## 
## 		printf ("Returned %s and %s\n\n", POPs, POPs);
## 
## 		PUTBACK;
## 		FREETMPS;
## 		LEAVE;

void
sane__get_version (class, version_code)
                SANE_Int	version_code
        PPCODE:
		XPUSHs(sv_2mortal(newSViv(SANE_VERSION_MAJOR (version_code))));
		XPUSHs(sv_2mortal(newSViv(SANE_VERSION_MINOR (version_code))));
		XPUSHs(sv_2mortal(newSViv(SANE_VERSION_BUILD (version_code))));

void
sane__get_devices (local=SANE_FALSE)
		SANE_Bool	local
	INIT:
		SANE_Status	status;
		AV * array;
                int i;
                const SANE_Device **	device_list;
		array = (AV *)sv_2mortal((SV *)newAV());
        PPCODE:
       		SV* sv = get_sv("Sane::DEBUG", FALSE);
               	if (SvTRUE(sv)) printf("Running sane_get_devices\n");
                status = sane_get_devices (&device_list, local);
                sv = get_sv("Sane::_status", FALSE);
                sv_setiv(sv, status); 
                if (status) {
                	XPUSHs(sv_2mortal(newSV(0)));
                }
                else {
			for (i = 0; device_list[i]; ++i) {
        	        	HV* hv = (HV*) sv_2mortal((SV*) newHV());
				hv_store(hv, "name", 4, newSVpv(device_list[i]->name, 0), 0);
				hv_store(hv, "vendor", 6, newSVpv(device_list[i]->vendor, 0), 0);
				hv_store(hv, "model", 5, newSVpv(device_list[i]->model, 0), 0);
				hv_store(hv, "type", 4, newSVpv(device_list[i]->type, 0), 0);
				XPUSHs(newRV((SV *)hv));
	                }
                }

void
sane__open(class, name)
		SANE_String_Const	name
	INIT:
		SANE_Status		status;
                SANE_Handle		h;
        PPCODE:
        	status = sane_open(name, &h);
		SV* sv = get_sv("Sane::DEBUG", FALSE);
		if (SvTRUE(sv)) printf("sane_open returned SANE_Handle %p\n", (void *) h);
                sv = get_sv("Sane::_status", FALSE);
                sv_setiv(sv, status); 
                if (status) {
                	XPUSHs(sv_2mortal(newSV(0)));
                }
                else {
	                XPUSHs(sv_2mortal(newSViv(PTR2IV(h))));
                }

SANE_String_Const
sane_strstatus (status)
	SANE_Status	status

void
END ()
	CODE:
       		SV* sv = get_sv("Sane::_vc", FALSE);
               	if (SvTRUE(sv)) {
        		sv = get_sv("Sane::DEBUG", FALSE);
                	if (SvTRUE(sv)) printf("Exiting via sane_exit\n");
			sane_exit;
		}
