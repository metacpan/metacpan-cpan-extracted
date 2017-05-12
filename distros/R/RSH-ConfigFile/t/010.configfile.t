# -*- perl -*-

# ------------------------------------------------------------------------------
#  Copyright © 2003 by Matt Luker.  All rights reserved.
# 
#  Revision:
# 
#  $Header$
# 
# ------------------------------------------------------------------------------

# 10-configfile.t - Test the heck out of ConfigFile.
# 
# @author  Matt Luker
# @version $Revision: 3249 $

# 10-configfile.t - Test the heck out of ConfigFile.
# 
# Copyright (C) 2003, Matt Luker
# 
# This library is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself. 

# If you have any questions about this software,
# or need to report a bug, please contact me.
# 
# Matt Luker
# Port Angeles, WA
# kostya@redstarhackers.com
# 
# TTGOG

# 1 Tests to run
use Test::More tests => 21;

use RSH::ConfigFile;

unlink "t/test-new.config";
unlink "t/test-new.back";
unlink "t/test.config.lock";

my $cf = RSH::ConfigFile->new();

# Test 1
$cf->filename("filename");

diag("\$cf->filename: ". $cf->filename() );
is($cf->filename(), 'filename', 'setting filename (hash overloading 1)');

# Test 2
$cf->{foo} = 'bar';
diag("\$cf->{foo}: ". $cf->{foo} );
is($cf->{foo}, 'bar', 'setting values (hash overloading 2)');

# Test 3
$cf{foo2} = 'bar2';
diag("\$cf{foo2}: ". $cf{foo2} );
is($cf{foo2}, 'bar2', 'setting values (hash overloading 3)');

# Test 4
my $str = "";
$str = RSH::ConfigFile::serialize_value(value => 'foo');
diag("serialize_value('foo'): ". $str );
is($str, "'foo'", 'serialize_value 1');

# Test 5
$str = "";
$str = RSH::ConfigFile::serialize_value(value => ['foo', 'bar']);
diag("serialize_value(ARRAY): ". $str );
is($str, "[ 'foo', 'bar' ]", 'serialize_value 2');

# Test 6
$str = "";
$str = RSH::ConfigFile::serialize_value(value => { foo => 'bar', moo => 'kar'});
diag("serialize_value(HASH): ". $str );
is($str, "{ foo => 'bar', moo => 'kar' }", 'serialize_value 3');

# Test 7
my $val = undef;
$val = RSH::ConfigFile::unserialize_value("'foo'");
diag("unserialize_value(\"'foo'\"): ". $val );
is($val, "foo", 'unserialize_value 1');

# Test 8
$val = undef;
$val = RSH::ConfigFile::unserialize_value('foo');
diag("unserialize_value('foo'): ". $val );
is($val, "foo", 'unserialize_value 1a');

# Test 9
$val = undef;
$val = RSH::ConfigFile::unserialize_value("[ 'foo', 'bar' ]");
diag("unserialize_value(\"[ 'foo', 'bar' ]\"): ". $val );
is(ref($val), "ARRAY", 'unserialize_value 2, ARRAY ref');

# Test 10
$val = undef;
$val = RSH::ConfigFile::unserialize_value("{ foo => 'bar', moo => 'kar' }");
diag("unserialize_value(\"{ foo => 'bar', moo => 'kar' }\"): ". $val );
is(ref($val), "HASH", 'unserialize_value 3, HASH ref');

# Test 11
$val = undef;
my $str = "[ 'foo";
$str .= '\,';
$str .= " EXTRA', 'bar' ]";
$val = RSH::ConfigFile::unserialize_value($str);
diag("unserialize_value(\"[ 'foo, EXTRA', 'bar' ]\"): ". $val );
is(ref($val), "ARRAY", 'unserialize_value 4, ARRAY ref');
diag("\$val:");
for my $elem (@{$val}) {
	diag(" + \"$elem\"");
}
is(($val->[0]), 'foo, EXTRA', 'unserialize_value 4, quoted ARRAY val with comma');

# Test 12
$cf->{array} = ['foo', 'bar'];
$cf->{hash} = { foo => 'bar', moo => 'kar'};
$str = "";
$str .= $cf;
diag("\$cf (as string): ". $str );
ok(($str =~ m/\{.*\}/), 'string overloading');

# Test 13
$rc = $cf->load(filename => "t/test.config");
diag("return code from load: ". $rc );
diag("\$cf = ". $cf . "");
if (not $rc) { 
	diag("return code for load wrong: $rc");
	fail("load");
}
elsif ($cf->{foo} ne 'bar') { 
	diag("\$cf->{foo} ne 'bar'!");
	diag("\$cf->{foo} == \"". $cf->{foo} ."\"");
	fail("load");
}
else { pass("load"); }

# Test 14
# save to another filename--save our bound-case test file
diag("Saving to new filename:");
diag("md5 == ". ($cf->md5 || '') );
$cf->filename("t/test-new.config");
my $rc = $cf->save();
diag("return code from save: ". $rc );
diag("error? ". ($cf->error || '') );
diag("warning? ". ($cf->warning || '') );
diag("md5 == ". ($cf->md5 || '') );
if ($rc == 0) { diag("error: ". $cf->error ); }
is($rc, 1, 'save');

my $cf2 =  RSH::ConfigFile->new(filename => "t/test-new.config");
$cf2->load();

# Test 15
my $values_test = 0;
VALUES_TEST: {
	for my $key (sort keys %{$cf}) {
		if (not defined($cf2->{$key})) { 
			diag($key." is missing from new loaded object.");
			last VALUES_TEST;
		} elsif ((ref($cf->{$key}) eq '') && ($cf2->{$key} ne $cf->{$key})) {
			diag($key." has a different value in new loaded object.");
			diag("orig: $key  == ". $cf->{$key});
			diag("new:  $key  == ". $cf2->{$key});
			last VALUES_TEST;
		} elsif (ref($cf->{$key}) eq 'ARRAY') {
			if (ref($cf2->{$key}) ne 'ARRAY') {
				diag($key." isn't an array in new loaded object.");
				last VALUES_TEST;
			} else {
				for (my $i = 0; $i < scalar(@{$cf->{$key}}); $i++) {
					if ($cf2->{$key}[$i] ne $cf->{$key}[$i]) {
						diag($key." has an array with a different value in new loaded object.");
						diag("orig: $key [$i] == ". $cf2->{$key}[$i]);
						diag("new:  $key [$i] == ". $cf2->{$key}[$i]);
						last VALUES_TEST;
					}
				}
			}
		} elsif (ref($cf->{$key}) eq 'HASH') {
			if (ref($cf2->{$key}) ne 'HASH') {
				diag($key." isn't an hash in new loaded object.");
				last VALUES_TEST;
			} else {
				foreach my $subkey (sort keys %{$cf->{$key}}) {
					if ($cf2->{$key}{$subkey} ne $cf->{$key}{$subkey}) {
						diag($key." has an hash with a different value in new loaded object.");
						diag("orig $key->{$subkey} == ". $cf2->{$key}{$subkey});
						diag("new  $key->{$subkey} == ". $cf2->{$key}{$subkey});
						last VALUES_TEST;
					}
				}
			}
		}
	}
	$values_test = 1;
}
ok($values_test, 'values test after save/load');

# Test 16
diag("Dirty flag test of save (shouldn't save):");
diag("md5 == ". ($cf->md5 || '') );
my $state1 = -C "t/test-new.config";
$cf->save();
diag("return code from save: ". $rc );
diag("error? ". ($cf->error || '') );
diag("warning? ". ($cf->warning || '') );
diag("md5 == ". ($cf->md5 || '') );
#sleep 1;
my $state2 = -C "t/test-new.config";
is($state1, $state2, "save, dirty flag test, file states");

# Test 17
diag("Dirty flag test of save (forced => 1):");
diag("md5 == ". ($cf->md5 || '') );
my $size1 = -s "t/test-new.config";
diag("\$size1 == $size1");
$rc = $cf->save(force => 1);
my $size2 = -s "t/test-new.config";
diag("\$size2 == $size2");
diag("return code from save: ". $rc );
diag("error? ". ($cf->error || '') );
diag("warning? ". ($cf->warning || '') );
diag("md5 == ". ($cf->md5 || '') );
isnt($size2, 0, "save, force test, new file");

# Test 18
diag("Load from file after forced save:");
diag("md5 == ". ($cf->md5 || '') );
$rc = $cf->load();
diag("return code from load: ". $rc );
diag("md5 == ". ($cf->md5 || '') );
diag("\$cf = ". $cf . "");
if (not $rc) { fail("load after save"); }
elsif ($cf->{foo} ne 'bar') { fail("load after save"); }
else { pass("load after save"); }

# Test 19
diag("Save to file when file state has changed:");
diag("md5 == ". ($cf->md5 || '') );
`cp -f t/test.config t/test-new.config`;
$state1 = -s "t/test-new.config";
$rc = $cf->save( force => 1 );
#sleep 1;
$state2 = -s "t/test-new.config";
diag("return code from save: ". $rc );
diag("error? ". ($cf->error || '') );
diag("warning? ". ($cf->warning || '') );
diag("md5 == ". ($cf->md5 || '') );
diag("\$state1 == $state1");
diag("\$state2 == $state2");
ok(($state1 ne $state2), "save, orig file changed");


# Test 20
my %hash = %{$cf};
#use Data::Dumper;
#print STDERRDumper(%hash);
diag("\$hash{foo}: \"". $hash{foo} ."\"");
ok(($hash{foo} eq 'bar'), "assignment to hash");

# DONE!

exit 0;



# ------------------------------------------------------------------------------
# 
#  $Log$
#  Revision 1.7  2004/04/09 06:18:26  kostya
#  Added quote escaping capabilities.
#
#  Revision 1.6  2004/01/15 01:01:24  kostya
#  Updated tests.
#
#  Revision 1.5  2003/12/27 07:40:16  kostya
#  Added more tests for slash continues.
#
#  Revision 1.4  2003/10/23 05:06:55  kostya
#  More portable and readable tests.
#
#  Revision 1.3  2003/10/22 20:51:32  kostya
#  Made the test a little more portable and resistant to lag in file system updates (like SMB shares).
#
#  Revision 1.2  2003/10/15 01:07:00  kostya
#  documentation and license updates--everything is Artistic.
#
#  Revision 1.1.1.1  2003/10/13 01:38:04  kostya
#  First import
#
# 
# ------------------------------------------------------------------------------
