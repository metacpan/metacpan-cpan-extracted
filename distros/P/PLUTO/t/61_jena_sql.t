#
# Copyright (c) 2006 IBM Corporation.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html
# 
# File:        $Source: /var/lib/cvs/ODO/t/61_jena_sql.t,v $
# Created by:  Stephen Evanchik( <a href="mailto:evanchik@us.ibm.com">evanchik@us.ibm.com </a>)
# Created on:  10/01/2006
# Revision:	$Id: 61_jena_sql.t,v 1.1 2009-09-22 18:04:55 ubuntu Exp $
# 
# Contributors:
#     IBM Corporation - initial API and implementation
#

use Test::More qw/no_plan/;
use Data::Dumper;

sub BEGIN {
	use_ok( 'ODO::Jena::SQL' );
}


my $sql_lib = ODO::Jena::SQL::Library->new({lib=> 't/data/sql_lib_1.sql'});
isa_ok($sql_lib, 'ODO::Jena::SQL::Library', 'Empty SQL library file created');

cmp_ok(keys(%{ $sql_lib->{'contents'} }), '==', '0', 'No functions are defined');

$sql_lib = ODO::Jena::SQL::Library->new({lib=> 't/data/sql_lib_2.sql'});
isa_ok($sql_lib, 'ODO::Jena::SQL::Library', 'Created object');

cmp_ok(keys(%{ $sql_lib->{'contents'} }), '==', '4', 'Verify the number of functions defined');

my @function_names = qw/function_group_1 function_group_2 empty_function_group comment_function_group/;

foreach my $name (@function_names) {
	isa_ok($sql_lib->{'contents'}->{$name}, 'ARRAY', "Function was defined: $name");
}

# Test SQL::Lib API calls

foreach my $name (@function_names) {
	ok(defined($sql_lib->retr($name)), "Fetching function named: $name");
}

# Test SQL::Lib variable substitution
$sql_lib = ODO::Jena::SQL::Library->new({lib=> 't/data/sql_lib_3.sql'});
isa_ok($sql_lib, 'ODO::Jena::SQL::Library', 'Created object');

my $function_group = $sql_lib->retr('function_group_1');
cmp_ok($function_group, 'eq', '${a} ${b} ${c} ${d};;', 'No variable substitution');

my @var_values = qw/val1 val2 val3 val4/;

$function_group = $sql_lib->retr('function_group_1', @var_values);
cmp_ok($function_group, 'eq', join(' ', @var_values). ';;', 'Library function with variable substitution');

__END__
