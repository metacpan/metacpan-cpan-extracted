#
# Copyright 2002-2003 Sun Microsystems, Inc.  All rights reserved.
# Use is subject to license terms.
#
#ident	"@(#)File.pm	1.2	03/03/13 SMI"
#
# File.pm contains wrappers for the exacct file manipulation routines.
# 

require 5.6.1;
use strict;
use warnings;

package Sun::Solaris::Exacct::File;

our $VERSION = '1.2';
use XSLoader;
XSLoader::load(__PACKAGE__, $VERSION);

# @_Constants is set up by the XSUB bootstrap() function.
our (@EXPORT_OK, %EXPORT_TAGS, @_Constants);
@EXPORT_OK = @_Constants;
%EXPORT_TAGS = (CONSTANTS => \@_Constants, ALL => \@EXPORT_OK);

use base qw(Exporter);

#
# Extend the default Exporter::import to do optional inclusion of the
# Fcntl module.
#
sub import
{
	# Do the normal export processing for this module.
	__PACKAGE__->export_to_level(1, @_);

	# Export from Fcntl if the tag is ':ALL'
	if (grep(/^:ALL$/, @_)) {
		require Fcntl;
		Fcntl->export_to_level(1, undef, ':DEFAULT');
	}
}

1;
