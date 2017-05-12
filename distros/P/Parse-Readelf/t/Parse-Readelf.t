# Before `make install' is performed this script should be runnable with
# `make test'.
# After `make install' it should work as `perl Parse-Readelf.t'
# Without Makefile it could be called with `perl -I../lib
# Parse-Readelf.t'.  This is also the command needed to find out what
# specific tests failed in a `make test' as the later only gives you a
# number and not the description of the test.

#########################################################################

use strict;

use Test::More tests => 141;

use File::Spec;
use File::Temp 'tempfile';

require_ok 'Parse::Readelf';

# for successful run with test coverage use:
# cover -delete
# HARNESS_PERL_SWITCHES=-MDevel::Cover=-silent,on,-summary,off make test
# cover

#########################################################################
# identical part of messages:
my $re_msg_tail = qr/at .*Parse-Readelf\.(?:t|pm) line \d{2,}\.?$/;

#########################################################################
# prepare testing with recorded data:
my ($volume, $directories, ) = File::Spec->splitpath($0);
$directories = '.' unless $directories;
my $path = File::Spec->catpath($volume, $directories, '');
{
    no warnings 'once';
    $Parse::Readelf::Debug::Line::command = $^O eq 'MSWin32' ? 'type' : 'cat';
    $Parse::Readelf::Debug::Info::command = $^O eq 'MSWin32' ? 'type' : 'cat';
}

#########################################################################
# output catcher:
sub check_stdout($&@)
{
    my $test = shift(@_);
    my $rSub = shift(@_);

    # redirect stdout to temporary IO-channel:
    open my $oldout, '>&STDOUT'  or  die "Can't dup STDOUT ($test): $!\n";
    my $tmp = tempfile()  or  die "Can't open temporary ($test): $!\n";
    open STDOUT, '>&'.fileno($tmp)
	or  die "Can't dup temporary ($test): $!\n";

    # call subroutine:
    &$rSub();

    # restore stdout:
    open STDOUT, '>&'.fileno($oldout)
	or  die "Can't restore STDOUT ($test): $!\n";

    seek $tmp, 0, 0  or  die "Can't rewind temporary ($test): $!\n";
    my $line = 0;
    while (<$tmp>)
    {
	chomp;
	like($_, $_[$line], $test.' - '.$line);
	$line++;
    }
    close $tmp  or  die "Can't close temporary ($test): $!\n";
    is($line, @_, $test.' - all done');
}

#########################################################################
# failing tests:
eval { my $x = Parse::Readelf::new() };
like($@,
     qr/^bad call to new of Parse::Readelf $re_msg_tail/,
     'bad creation fails');
eval {
    my $filepath = File::Spec->catfile($path, 'data', 'xxx.xxx');
    my $x = new Parse::Readelf($filepath);
};
like($@,
     qr|^Parse::Readelf can't find .* $re_msg_tail|,
     'bad file name fails');

#########################################################################
# first "real" tests:
my $filepath = File::Spec->catfile($path, 'data', 'debug_info_4.lst');
my $readelf_data = new Parse::Readelf($filepath);
is(ref($readelf_data), 'Parse::Readelf', 'created Parse::Readelf object');

check_stdout('l_cObject2b',
	     sub { $readelf_data->print_structure_layout('l_cObject2b'); },
	     qr'^O\s+STRUCTURE\s+TYPE \(SIZE\)\s+$',
	     qr'^0\s+l_cObject2b\s+const Structure2& \(16\)\s+$'
	    );

check_stdout('l_object2a',
	     sub { $readelf_data->print_structure_layout('l_object2a'); },
	     qr'^O\s+STRUCTURE\s+TYPE \(SIZE\)\s+$',
	     qr'^0\s+l_object2a\s+Structure2 \(16\)\s+$',
	     qr'^0\s+Structure2\s+\(16\)\s+$',
	     qr'^0\s+m_00_char\s+char \(1\)\s+$',
	     qr'^8\s+m_01_long_long\s+long long int \(8\)\s+$'
	    );

check_stdout
    ('l_object2a + loc',
     sub { $readelf_data->print_structure_layout('l_object2a', 1); },
     qr'^O\s+STRUCTURE\s+TYPE \(SIZE\)\s+SOURCE LOCATION\s*$',
     qr'^0\s+l_object2a\s+Structure2 \(16\)\s+StructureLayoutTest\.cpp:\d+\s*$',
     qr'^0\s+Structure2\s+\(16\)\s+StructureLayoutTest\.cpp:\d+\s*$',
     qr'^0\s+m_00_char\s+char \(1\)\s+StructureLayoutTest\.cpp:\d+\s*$',
     qr'^8\s+m_01_long_long\s+long long int \(8\)\s+StructureLayoutTest\.cpp:\d+\s*$'
    );

check_stdout('l_object3',
	     sub { $readelf_data->print_structure_layout('l_object3'); },
	     qr'^O\s+STRUCTURE\s+TYPE \(SIZE\)\s+$',
	     qr'^0\s+l_object3\s+Structure3 \(4\)\s+$',
	     qr'^0\s+Structure3\s+\(4\)\s+$',
	     qr'^0\s+m_00_short\s+short int \(2\)\s+$',
	     qr'^2\s+m_01_short\s+short int \(2\)\s+$'
	    );

check_stdout('l_object4',
	     sub { $readelf_data->print_structure_layout('l_object4'); },
	     qr'^OF\s+STRUCTURE\s+TYPE \(SIZE\)\s+$',
	     qr'^00\s+l_object4\s+<anonymous struct> \(24\)\s+$',
	     qr'^00\s+<anonymous struct>\s+\(24\)\s+$',
	     qr'^00\s+m_00_int\s+int \(4\)\s+$',
	     qr'^08\s+m_string\s+string \(8\)\s+$',
	     qr'^16\s+m_01_int\s+int \(4\)\s+$'
	    );

check_stdout
    ('l_object1',
     sub { $readelf_data->print_structure_layout('l_object1'); },
     qr'^OFFSE\s+STRUCTURE\s+TYPE \(SIZE\)\s+$',
     qr'^00\s+l_object1\s+Structure1 \(48\)\s+$',
     qr'^00\s+Structure1\s+\(48\)\s+$',
     qr'^00\s+m_00_long\s+long int \(8\)\s+$',
     qr'^08\s+m_01_char_followed_by_filler_for_short\s+char \(1\)\s+$',
     qr'^10\s+m_02_short\s+short int \(2\)\s+$',
     qr'^12\s+m_03_char_array_6\[6\]\s+char \(6\)\s+$',
     qr'^24\s+m_04_pointer\s+void\* \(8\)\s+$',
     qr'^32\s+m_06_char_followed_by_filler_for_bit_array\s+char \(1\)\s+$',
     qr'^32\.18\s+m_07_02_3_int_bits\s+unsigned int \(3 in 4\)\s+$',
     qr'^32\.21\s+m_07_01_2_int_bits\s+unsigned int \(2 in 4\)\s+$',
     qr'^32\.23\s+m_07_00_1_int_bit\s+unsigned int \(1 in 4\)\s+$',
     qr'^34\s+m_08_char_between_bit_arrays_followed_by_filler\s+char \(1\)\s+$',
     qr'^35.2\s+m_09_02_3_char_bits\s+unsigned char \(3 in 1\)\s+$',
     qr'^35.5\s+m_09_01_2_char_bits\s+unsigned char \(2 in 1\)\s+$',
     qr'^35.7\s+m_09_00_1_char_bit\s+unsigned char \(1 in 1\)\s+$',
     qr'^36\s+m_10_substructure\s+<anonymous struct> \(4\)\s+$',
     qr'^36\s+<anonymous struct>\s+\(4\)\s+$',
     qr'^36\s+m_10_00_char\s+char \(1\)\s+$',
     qr'^38\s+m_10_01_short\s+short int \(2\)\s+$',
     qr'^40\s+m_11_final_char\s+char \(1\)\s+$'
    );

check_stdout('^l_',
	     sub { $readelf_data->print_structure_layout('^l_'); },
	     qr'^OFFSE\s+STRUCTURE\s+TYPE \(SIZE\)\s+$',
	     (qr'^00') x 5,
	     qr'^08',
	     (qr'^[1-3][024]\s') x 4,
	     (qr'^32\.\d{2}\s') x 3,
	     qr'^34',
	     (qr'^35\.\d\s') x 3,
	     (qr'^36') x 3,
	     qr'^38',
	     qr'^40',
	     (qr'^00') x 3,
	     qr'^08',
	     (qr'^00') x 3,
	     qr'^08',
	     (qr'^00') x 3,
	     qr'^08',
	     (qr'^00') x 3,
	     qr'^08',
	     (qr'^00') x 3,
	     qr'^02',
	     (qr'^00') x 3,
	     qr'^08',
	     qr'^16',
	     (qr'^00') x 5,
	     qr'^08',
	     (qr'^00') x 4,
	     qr'^00\.0',
	     qr'^00\.12',
	     (qr'^02') x 4,
	     qr'^04',
	     (qr'^08') x 3,
	     qr'^12\.8',
	    );

#########################################################################
# special test for Dwarf-4 (different file lookup):
$filepath = File::Spec->catfile($path, 'data', 'debug_info_6.lst');
$readelf_data = new Parse::Readelf($filepath);
is(ref($readelf_data), 'Parse::Readelf', 'created 2nd Parse::Readelf object');

check_stdout
    ('l_object2a + loc in Dwarf-4',
     sub { $readelf_data->print_structure_layout('l_object2a', 1); },
     qr'^O\s+STRUCTURE\s+TYPE \(SIZE\)\s+SOURCE LOCATION\s*$',
     qr'^0\s+l_object2a\s+Structure2 \(16\)\s+StructureLayoutTest\.cpp:\d+\s*$',
     qr'^0\s+Structure2\s+\(16\)\s+StructureLayoutTest\.cpp:\d+\s*$',
     qr'^0\s+m_00_char\s+char \(1\)\s+StructureLayoutTest\.cpp:\d+\s*$',
     qr'^8\s+m_01_long_long\s+long long int \(8\)\s+StructureLayoutTest\.cpp:\d+\s*$'
    );

#########################################################################
# some more tests for special C features:
$filepath = File::Spec->catfile($path, 'data', 'debug_info_0.lst');
$readelf_data = new Parse::Readelf($filepath);
is(ref($readelf_data), 'Parse::Readelf', 'created 3rd Parse::Readelf object');

check_stdout('l_object4',
	     sub { $readelf_data->print_structure_layout('l_objectAT'); },
	     qr'^O\s+STRUCTURE\s+TYPE \(SIZE\)\s+$',
	     qr'^0\s+l_objectATE\s+AnonTypedefEnum \(4\)\s+$',
	     qr'^0\s+AnonTypedefEnum\s+\(4\)\s+$',
	     qr'^0\s+\(4\)\s+$',
	     qr'^0\s+l_objectATU\s+AnonTypedefUnion \(8\)\s+$',
	     qr'^0\s+AnonTypedefUnion\s+\(8\)\s+$'
	    );

#########################################################################
# finally some tests with a cloned object:
my $stderr = '';
$SIG{__WARN__} = sub { $stderr .= join('', @_) };
$readelf_data = $readelf_data->new($filepath);
delete $SIG{__WARN__};
like($stderr,
     qr/^cloning of a Parse::Readelf object is not supported $re_msg_tail/,
     'cloning gives a warning');
is(ref($readelf_data), 'Parse::Readelf', 'created new Parse::Readelf object');
