#
# Copyright (c) 2006 IBM Corporation.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html
# 
# File:        $Source: /var/lib/cvs/ODO/t/data/sql_lib_2.sql,v $
# Created by:  Stephen Evanchik( <a href="mailto:evanchik@us.ibm.com">evanchik@us.ibm.com </a>)
# Created on:  10/01/2006
# Revision:	$Id: sql_lib_2.sql,v 1.1 2009-09-22 18:04:51 ubuntu Exp $
# 
# Contributors:
#     IBM Corporation - initial API and implementation
#
# Test library function group parsing
function_group_1
This is function group 1. It does not contain any SQL but it does demonstrate;;
that the parser is working properly as the lines are terminated by double semi-colons;;

# Next function group
function_group_2
Single line function group

# Empty function group
empty_function_group

# Function group with comment should be an empty function group
comment_function_group
# Comment
