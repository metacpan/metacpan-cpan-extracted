#
# Copyright (c) 2006 IBM Corporation.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html
# 
# File:        $Source: /var/lib/cvs/ODO/t/library.pl,v $
# Created by:  Stephen Evanchik( <a href="mailto:evanchik@us.ibm.com">evanchik@us.ibm.com </a>)
# Created on:  10/01/2006
# Revision:	$Id: library.pl,v 1.1 2009-09-22 18:04:52 ubuntu Exp $
# 
# Contributors:
#     IBM Corporation - initial API and implementation
#

use ODO::Node;

sub make_node {
	return $ODO::Node::ANY
		unless(defined($_[0]));
	
	if($_[0] =~ /^var:(.*)/) {
		return ODO::Node::Variable->new($1);
	}
	elsif($_[0] =~ /^uri:(.*)/) {	
		return ODO::Node::Resource->new($1);
	}
	elsif($_[0] =~ /^lit:(.*)/) {
		return ODO::Node::Literal->new($1);
	}
	else {
	}
}


1;