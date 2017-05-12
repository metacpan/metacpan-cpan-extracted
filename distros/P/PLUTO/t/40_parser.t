#
# Copyright (c) 2006 IBM Corporation.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html
# 
# File:        $Source: /var/lib/cvs/ODO/t/40_parser.t,v $
# Created by:  Stephen Evanchik( <a href="mailto:evanchik@us.ibm.com">evanchik@us.ibm.com </a>)
# Created on:  10/01/2006
# Revision:	$Id: 40_parser.t,v 1.1 2009-09-22 18:04:54 ubuntu Exp $
# 
# Contributors:
#     IBM Corporation - initial API and implementation
#

use Test::More qw(no_plan);

use Data::Dumper;

use strict;

sub BEGIN {
	use_ok('ODO::Parser');
}

__END__
