#!/usr/local/bin/perl

while(<>) {
    # Discard 'if exists ... drop'
    if (/^\s*if exists/) {
	while(<>) {
	    if (/^\s*[Gg][Oo]\s*$/) {
		last;
	    }
	}
	next;
    }
    if (/^\s*alter\s+table/) {
	($table) = /^\s*alter\s+table\s+(\S+)/;
	$_ = <>;
	($fkey) = /^\s*add\s+foreign\s+key\s+\(([^\)]+)\)/;
	@fkey = split(',',$fkey);
	$_ = <>;
	($parent, $pref) = /^\s*references\s+(\S+)\s+\(([^\)]+)\)/;
	@pref = split(',',$pref);
	$cfield = $fkey[0];
	$pfield = $pref[0];
	$where = "new.$cfield <> ${parent}.${pfield}";
	map {
	    s/^\s*//;
	    s/\s*$//;
	} @fkey;
	map {
	    s/^\s*//;
	    s/\s*$//;
	} @pref;
	for ($i = 1;$i <= $#fkey;$i++) {
	    $cfield = $fkey[$i];
	    $pfield = $pref[$i];
	    $where .= "\n\t\tAND new.$cfield <> ${parent}.${pfield}";
	}
	push @{$FK_RELATION{$table}}, (" ( $where ) ");
	undef $where;
	for ($i = 0;$i <= $#pref;$i++) {
	    if (!defined($RELATION{"$parent\t$table"})) {
		push @{$PARENT{$parent}}, ($table);
	    }
	    $RELATION{"$parent\t$table"}->{$pref[$i]} = $fkey[$i];
	}
	$_ = <>;		# no go
	next;
    }
    # Delete 'null' as field declaration ('not null' OK)
    s/([^Nn][^Oo][^Tt]\s+)[Nn][Uu][Ll][Ll]\s+/$1 /g;
    # Change datatypes
    s/smalldatetime/datetime/g;
    s/tinyint/int/g;
    s/float\(\d+\)/float/g;
    # Change go to ';'
    s/go/;/g;
    if (/^\s*$/) {
	$blank_count++;
    } else {
	$blank_count = 0;
    }
    if ($blank_count < 2) {
	print;
    }
}

print "/* ============================================================ */\n";
print "/* Foreign key relation rules                                   */\n";
print "/* ============================================================ */\n";
map {
    $table = $_;
    $where = join("\n\t\tOR ",@{$FK_RELATION{$table}});
    print "CREATE RULE fk_${table}_insert AS ON INSERT TO $table\n";
    print "\tWHERE $where\n\tDO INSTEAD NOTHING;\n";
    print "CREATE RULE fk_${table}_update AS ON UPDATE TO $table\n";
    print "\tWHERE $where\n\tDO INSTEAD NOTHING;\n";
} (sort (keys %FK_RELATION));
undef $table;
undef $where;
print "/* ============================================================ */\n";
print "/* Primary key relation rules                                   */\n";
print "/* ============================================================ */\n";
# Rules for parent tables reference all children
map {
    $parent = $_;
    map {
	$child = $_;
	map {
	    $pfield = $_;
	    $cfield = $RELATION{"$parent\t$child"}->{$pfield};
	    if (defined($where)) {
		$where .= "\n\t\tAND old.$pfield = $child.$cfield";
	    } else {
		$where = "old.$pfield = $child.$cfield";
	    }
	} (sort (keys %{$RELATION{"$parent\t$child"}}));
    } @{$PARENT{$parent}};
    print "CREATE RULE pk_${parent}_update AS ON UPDATE TO $parent\n";
    print "\tWHERE $where\n\tDO INSTEAD NOTHING;\n";
    print "CREATE RULE pk_${parent}_delete AS ON DELETE TO $parent\n";
    print "\tWHERE $where\n\tDO INSTEAD NOTHING;\n";
    undef $where;
} (sort (keys %PARENT));

# Translate a foreign key reference into PostgreSQL rules:
#
# FROM:
#     alter table table2
#         add foreign key  (field1, field2)
#            references table1 (field1, field2)
#     go
#
# TO:
#
#Insert RI:
#	create rule fk_table2_insert as on insert to table2
#	where new.field1 <> table1.field1 and new.field2 <> table1.field1
#       do instead nothing;
#
#Update RI:
#	create rule fk_table2_update as on update to table2
#	where new.field1 <> table1.field1 and new.field2 <> table1.field2
#       do instead nothing;
#
#	create rule pk_table1_update as on update to table1
#	where old.field1 = table2.field1 and old.field2 = table2.field2
#       do instead nothing;
#NOTE: the pk_update rule must list all children!
#
#Delete RI:
#	create rule pk_table1_delete as on delete to table1
#	where old.field1 = table2.field1 and old.field2 = table2.field2
#       do instead nothing;
#NOTE: the delete rule must list all children!
