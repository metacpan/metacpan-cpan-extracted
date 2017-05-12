/* tclink.h - Header file for TCLink library.
 *
 * TCLink Copyright (c) 2003 TrustCommerce.
 * http://www.trustcommerce.com
 * developer@trustcommerce.com
 * (626) 744-7700
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 */

#ifndef _TCLINK_H
#define _TCLINK_H

#include "config.h"

/* Handle passed to all TCLink functions.  A unique handle must be created
 * for each concurrent thread, but the same handle can be shared by transactions
 * occurring one after another (such as a for loop).
 */
#define TCLinkHandle void *

/* Parameter names and values cannot exceed this size.
 */
#define PARAM_MAX_LEN 256

/* Create a new TCLinkHandle.
 */
TCLinkHandle TCLinkCreate();

/* Add a parameter to be sent to the server.
 */
void TCLinkPushParam(TCLinkHandle handle, const char *name, const char *value);

/* Flush the parameters to the server.
 */
void TCLinkSend(TCLinkHandle handle);

/* Look up a response value from the server.
 * Returns NULL if no such parameter, or stores the value in 'value' and
 * returns a pointer to value.  value should be at least PARAM_MAX_LEN in size.
 */
char *TCLinkGetResponse(TCLinkHandle handle, const char *name, char *value);

/* Get all response values from the server in one giant string.
 * Stores the string into buf and returns a pointer to it.  Size should be
 * sizeof(buf), which will limit the string so that no buffer overruns occur.
 */
char *TCLinkGetEntireResponse(TCLinkHandle handle, char *buf, int size);

/* Destory a handle, ending that transaction and freeing the memory associated with it. */
void TCLinkDestroy(TCLinkHandle handle);

/* Store version string into buf.  Returns a pointer to buf. */
char *TCLinkGetVersion(char *buf);

#endif

