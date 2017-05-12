/* Copyright (c) 2011 The Perl Review, LLC
 *
 *
 * This program is free software. You can modify it and/or distribute it under
 * the terms of the GNU General Public License, version 2. 
 * See L<http://www.gnu.org/licenses/gpl-2.0.html
 *
 *                        NO WARRANTY
 *
 * 11. BECAUSE THE PROGRAM IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
 * FOR THE PROGRAM, TO THE EXTENT PERMITTED BY APPLICABLE LAW.  EXCEPT WHEN
 * OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES PROVIDE
 * THE PROGRAM "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
 * FITNESS FOR A PARTICULAR PURPOSE.  THE ENTIRE RISK AS TO THE QUALITY AND
 * PERFORMANCE OF THE PROGRAM IS WITH YOU.  SHOULD THE PROGRAM PROVE DEFECTIVE,
 * YOU ASSUME THE COST OF ALL NECESSARY SERVICING, REPAIR OR CORRECTION.
 * 
 * 12. IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
 * WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
 * REDISTRIBUTE THE PROGRAM AS PERMITTED ABOVE, BE LIABLE TO YOU FOR DAMAGES,
 * INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL OR CONSEQUENTIAL DAMAGES ARISING
 * OUT OF THE USE OR INABILITY TO USE THE PROGRAM (INCLUDING BUT NOT LIMITED
 * TO LOSS OF DATA OR DATA BEING RENDERED INACCURATE OR LOSSES SUSTAINED BY
 * YOU OR THIRD PARTIES OR A FAILURE OF THE PROGRAM TO OPERATE WITH ANY OTHER
 * PROGRAMS), EVEN IF SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGES.
 *
 */

/* Perl interface to libsharktools
 *
 * Example invocation:
 *
 * use Data::Dumper;
 * use Net::Sharktools qw( perlshark_read_xs );
 *
 * my $result = perlshark_read_xs(
 *     'capture1.pcap',
 *     [qw( frame.number tcp.seq frame.len udp.dstport ip.version )],
 *     'ip.version eq 4',
 * );
 *
 * print Dumper $result->[0];
 */

/*
 * Contact: A. Sinan Unur <nanis@cpan.org>
 */

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>

#include "sharktools_core.h"

/* Structure of the module
 *
 * This module provides the perlshark_read_xs function which uses the
 * Sharktools library by Armen Babikyan. Sharktools can be found at
 * <http://www.mit.edu/~armenb/sharktools/>.
 *
 * perlshark_read_xs invokes three callbacks as necessary. These are:
 *
 * cb_row_new : Creates the a new instance of the data structure that
 * corresponds to a new row to be added to the list of rows returned. For Perl,
 * this an anonymous hash.
 *
 * cb_row_add : Invokes the appropriate operation to append a newly created row
 * to the end of the list of rows to be returned. For Perl, this is av_push.
 *
 * cb_row_set : Invokes the appropriate operation to set the value
 * corresponding to a given key in the current row. For Perl, this is
 * hv_store_ent
 *
 * The structure of the code is pretty much identical to the Python2 interface
 * bundled with Sharktools (see pyshark.c). The main difference is that I
 * maintain pointers to the elements of the arrayref of field names passed to
 * perlshark_read_xs rather than creating a fresh array for keys. Given that
 * hv_store_ent only reads the keys and does not modify reference counts, this
 * takes away one hassle and only the memory allocated for the array of
 * pointers to the original members of the arrayref passed to
 * perlshark_read_xs needs to be freed in clean up.
 *
 * I set up the array of field names to be passed to sharktools_get_cb and the
 * array of pointers to the field names in one pass.
 *
 * 64-bit values are returned as strings due to my concern for portability
 * (which may not be well founded).
 *
 * Absolute and relative time values are also returned as strings, mainly due
 * to my ignorance of the best way to handle those. Suggestions welcome.
 *
 */

static gpointer
cb_row_new(sharktools_callbacks *cb)
{
    return newHV();
}

static gpointer
cb_row_add(sharktools_callbacks *cb, gpointer row)
{
    AV *list = cb->root;
    av_push(list, newRV_noinc((SV *)row));
    return NULL;    
}

static gpointer
cb_row_set
(
    sharktools_callbacks *cb,
    gpointer row,
    gpointer key,
    gulong type,
    fvalue_t *val_native,
    const gchar *val_string
)
{
    SV *val_sv;
    HE *he;
    
    switch (type)
    {
        case FT_NONE:    /* used for text labels with no value */
            val_sv = newSV(0);
            break;
        
        case FT_BOOLEAN: /* TRUE and FALSE come from <glib.h> */
        /* Wireshark implements FT_BOOLEANs as uintegers. See epan/ftype/ftype-integer.c */
        
        case FT_FRAMENUM:  /* a UINT32, but if selected lets you go to frame with that number */
        /* Wireshark implements FT_FRAMENUMs as uintegers. See epan/ftype/ftype-integer.c */
        
        case FT_IPXNET:
        /* Wireshark implements FT_IPXNETs as uintegers. See epan/ftype/ftype-integer.c */
        case FT_UINT8:
        case FT_UINT16:
        case FT_UINT24:	/* really a UINT32, but displayed as 3 hex-digits if FD_HEX*/
        case FT_UINT32:
        /* FIXME: does fvalue_get_uinteger() work properly with FT_UINT{8,16,24} types? */
            val_sv = newSVuv( fvalue_get_uinteger(val_native) );
            break;
        
        case FT_INT8:
        case FT_INT16:
        case FT_INT24:	/* same as for UINT24 */
        case FT_INT32:
        /* FIXME: does fvalue_get_sinteger() work properly with FT_INT{8,16,24} types? */
            val_sv = newSViv( fvalue_get_sinteger(val_native) );
            break;
        
        case FT_FLOAT:
        case FT_DOUBLE:
            val_sv = newSVnv( fvalue_get_floating(val_native) );
            break;

        /*
         * case FT_ABSOLUTE_TIME:
         * case FT_RELATIVE_TIME:
         * TODO: Deviating from pyshark here to convert these
         * to strings as well because I haven't been able to 
         * decide how to properly handle them.
         */

        /*
         * case FT_INT64: // Wireshark doesn't seem to distinguish between INT64 and UINT64
         * case FT_UINT64:
         * TODO: Convert these to strings as well assuming they will be
         * handled by the caller depending on whether perl has 64 bit
         * support
         */

        /* Convert all the rest to strings:
         * case FT_PROTOCOL:
         * case FT_UINT_STRING:	// for use with proto_tree_add_item()
         * case FT_ETHER:
         * case FT_BYTES:
         * case FT_UINT_BYTES:
         * case FT_IPv4:
         * case FT_IPv6:
         * case FT_PCRE:		// a compiled Perl-Compatible Regular Expression object
         * case FT_GUID:		// GUID, UUID
         * case FT_OID:			// OBJECT IDENTIFIER
         */ 
        
        default:
            val_sv = newSVpvn( val_string, strlen(val_string) );
            break;
    }

    he = hv_store_ent(row, key, val_sv, 0);

    if ( he == NULL )
    {
        croak("Adding key/value pair to dictionary failed");
    }

    return NULL; 
}

static void
init_perlshark(void)
{
    gsize i;
    gulong native_type_array_size;
    gulong dummy_value;

    GTree *native_types;

    gulong native_type_array[] = { 
        FT_BOOLEAN, 
        FT_UINT8,
        FT_UINT16,
        FT_UINT24,
        FT_UINT32,
        FT_INT8,
        FT_INT16,
        FT_INT24,
        FT_INT32,
        FT_FLOAT,
        FT_DOUBLE,
    };

    sharktools_init();

    native_types = 
        g_tree_new((GCompareFunc)sharktools_gulong_cmp);
    
    native_type_array_size = 
        (sizeof(native_type_array)/sizeof(native_type_array[0]));
            
    /* NB: We only care about the keys, not the values */
    dummy_value = 1;
        
    for(i = 0; i < native_type_array_size; ++i)
    {
        g_tree_insert
        (
            native_types, 
            (gpointer) native_type_array[i], 
            (gpointer) dummy_value
        );
    }
    
    sharktools_register_native_types(native_types);

    return;
}

MODULE = Net::Sharktools		PACKAGE = Net::Sharktools		

SV *
perlshark_read_xs(filename, fieldnamelist, dfilter, ...)
        char *filename
        AV *fieldnamelist
        const char *dfilter

    PREINIT:
        char *decode_as = NULL;
        int i;
        int nfields;
        int ret;
        gchar **fieldnames;
        gchar *dfilter_copy;
        AV *results;
        SV **keys;
        sharktools_callbacks cb;
    
    INIT:
        nfields = av_len(fieldnamelist);
        
        nfields += 1;

        keys = g_new(SV*, nfields); 
        fieldnames = g_new(char*, nfields);

        results = newAV();
        
    CODE:
        if ( items > 3 ) 
        {
            decode_as = (char *) SvPV_nolen(ST(3));
            sharktools_add_decode_as(decode_as);
        }
        
        for (i = 0; i < nfields; ++i)
        {
            STRLEN len;
            SV **name = av_fetch(fieldnamelist, i, 0);
            if ( name == NULL )
            {
                int j;
                for (j = 0; j < i; ++j)
                {
                    g_free(fieldnames[i]);
                }
                g_free(fieldnames);
                g_free(keys);
                croak("Failed to fetch field name %d", i);
            }

            len = SvLEN(*name);
            fieldnames[i] = g_new(gchar, len + 1);
            strncpy(fieldnames[i], SvPV_nolen(*name), len);
            fieldnames[i][len] = 0;

            keys[i] = *name;
        }

        cb.root = (gpointer) results;
        cb.keys = (gpointer *) keys;
        cb.row_add = cb_row_add;
        cb.row_new = cb_row_new;
        cb.row_set = cb_row_set;

        dfilter_copy = g_strdup(dfilter);

        ret = sharktools_get_cb
        (
            (gchar *) filename,
            nfields,
            (const gchar **) fieldnames,
            dfilter_copy,
            &cb
        );

        if ( ret ) 
        {
            croak("Call to sharktools_get_cb failed with error: '%s'",
                sharktools_errmsg);
        }

        RETVAL = newRV_noinc((SV *) results);

    OUTPUT:
        RETVAL

    CLEANUP:
        if ( decode_as != NULL )
        {
            sharktools_remove_decode_as( decode_as );
        }

        /* free keys */
        g_free( keys );

        /* free field names */
        for ( i = 0; i < nfields; ++i )
        {
            g_free(fieldnames[i]);
        }
        g_free(fieldnames);

        g_free(dfilter_copy);


BOOT:
init_perlshark();

