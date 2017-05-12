/*
 *     Copyright (c) 2000-2006 Alberto Reggiori <areggiori@webweaving.org>
 *                        Dirk-Willem van Gulik <dirkx@webweaving.org>
 *
 * NOTICE
 *
 * This product is distributed under a BSD/ASF like license as described in the 'LICENSE'
 * file you should have received together with this source code. If you did not get a
 * a copy of such a license agreement you can pick up one at:
 *
 *     http://rdfstore.sourceforge.net/LICENSE
 *
 *
 * $Id: conf.h,v 1.6 2006/06/19 10:10:22 areggiori Exp $
 */
#ifndef _H_CONF
#define _H_CONF

typedef enum opstypes { 
	T_ERR, T_NONE, T_RDONLY, T_RDWR, T_CREAT, T_DROP, T_ALL
} tops;

extern const char * op2string(tops op);			/* Translate operation level into a string */
extern tops allowed_ops(u_long ip);			/* Return max operations level in dbase for given IP */
extern tops allowed_ops_on_dbase(u_long ip, char *db); 	/* Return max operations level in dbase for given IP and db */
extern const char * parse_config(char * configfile);	/* Parse a config file or stdin on '-'. return NULL or an error */
#endif
