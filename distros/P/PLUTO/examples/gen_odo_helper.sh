#!/bin/bash
#
# Copyright (c) 2007 IBM Corporation.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html
# 
# File:        $Source: /var/lib/cvs/ODO/examples/gen_odo_helper.sh,v $
# Created by:  Stephen Evanchik( <a href="mailto:evanchik@us.ibm.com">evanchik@us.ibm.com </a>)
# Created on:  01/23/2007
# Revision:	$Id: gen_odo_helper.sh,v 1.1 2009-09-22 18:05:05 ubuntu Exp $
# 
# Contributors:
#     IBM Corporation - initial API and implementation
#
perl examples/rdfs2perl.pl --output=lib/ODO/Jena/DB/Settings.pm --rdf-file-type=N3 --base-namespace='ODO::Jena::DB' lib/ODO/Jena/DB/Settings.n3 
perl examples/rdfs2perl.pl --output=lib/ODO/Jena/Graph/Settings.pm --rdf-file-type=N3 --base-namespace='ODO::Jena::Graph' lib/ODO/Jena/Graph/Settings.n3 
perl examples/rdfs2perl.pl --output=lib/RDFS.pm --rdf-file-type=XML --rdfs-schema t/data/rdfs.xml

