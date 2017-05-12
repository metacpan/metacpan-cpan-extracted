#!/usr/bin/perl
# *
# *     Copyright (c) 2000-2006 Alberto Reggiori <areggiori@webweaving.org>
# *                        Dirk-Willem van Gulik <dirkx@webweaving.org>
# *
# * NOTICE
# *
# * This product is distributed under a BSD/ASF like license as described in the 'LICENSE'
# * file you should have received together with this source code. If you did not get a
# * a copy of such a license agreement you can pick up one at:
# *
# *     http://rdfstore.sourceforge.net/LICENSE
# *
$rcsid='$Id: version.pl,v 1.8 2006/06/19 10:10:23 areggiori Exp $';
#
$h=`hostname`;
chop $h;
$id='??';
if ($^O =~ m/solaris/i) {
	$id=`whoami`;
	chop $id;
} else {
	$a=`id -u -n`;
	$id=$1 if $a=~ m/(\w+)/;
}

# $a=`pwd`;
# $a =~ m/dbms-(\d+)\.(\d+)/
# 	or die "no version in $a";
# $version =$1 * 100 +$2;

$rcsid =~ m/Id:\s+\S+\s+([\d\.]+)\s+/
	or die "No version in rcs version";

$version = $1;
$date=gmtime(time);

print qq|\
/*>version.c - $0 generated - $version
 * $rcsid
 */
#include <sys/types.h>

#include "dbms_compat.h"

#if 0
static char rcsid[]="$rcsid";
#endif

static char version[]= "DBMS/$version - $date - $id\@$h - "
#ifdef DB_VERSION_MAJOR
	DB_VERSION_STRING
#else
	"Berkeley DB 1.x (perhaps BSD-ish built in library)"
#endif

#ifdef FORKING
	" - forking"
#else
	" - NON forking"
#endif
#ifdef STATIC_BUFF
	" - recycle structs "
#endif
#ifdef	STATIC_CS_BUFF     
	" - static Client buffs "
#endif
#ifdef STATIC_SC_BUFF
	" - static Server buffs "
#endif

	;

char * get_full( void ) {
	return version;
	}
|;


