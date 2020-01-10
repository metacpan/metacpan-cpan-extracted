# Before `make install' is performed this script should be runnable with
# `make test'.
# After `make install' it should work as `perl Parse-Readelf-Debug-Info.t'
# Without Makefile it could be called with `perl -I../lib
# Parse-Readelf-Debug-Info.t'.  This is also the command needed to
# find out what specific tests failed in a `make test' as the later
# only gives you a number and not the description of the test.

#########################################################################

use strict;

use Test::More tests => 167;

use File::Spec;

require_ok 'Parse::Readelf::Debug::Info';

# for successful run with test coverage use:
# cover -delete
# HARNESS_PERL_SWITCHES=-MDevel::Cover=-silent,on,-summary,off make test
# cover

#########################################################################
# identical part of messages:
my $re_msg_tail = qr/at .*Parse-Readelf-Debug-Info\.(?:t|pm) line \d{2,}\.?$/;

#########################################################################
# import tests:
sub reset_globals()
{
    local $_;
    foreach (qw(command re_section_start re_dwarf_version
))
    { delete $main::{$_} if defined *$_ }
}
sub test_globals($%)
{
    my ($export, $globals) = @_;
    local $_;
    foreach (keys %$globals)
    {
	if ($globals->{$_})
	{
	    ok(eval($_), $_.' is exported with "'.$export.'"');
	    if ($_ =~ m/^\$/)
	    {
		is(eval($_), $globals->{$_},
		   $_.' has correct value in "'.$export.'"')
	    }
	    else
	    {
		is_deeply([eval($_)], $globals->{$_},
		   $_.' has correct value in "'.$export.'"')
	    }
	}
	else
	{ ok(! eval($_), $_.' is not exported with "'.$export.'"') }
    }
}

eval { import Parse::Readelf::Debug::Info ':command' };
is($@, '', "import with ':command'");
test_globals(':command',
	     {'$command' => 'readelf --debug-dump=info',
	      '$re_section_start' => undef,
	      '$re_dwarf_version' => undef});
reset_globals();

eval { import Parse::Readelf::Debug::Info qw($command) };
is($@, '', "import with '\$command'");
test_globals('$command',
	     {'$command' => 'readelf --debug-dump=info',
	      '$re_section_start' => undef,
	      '$re_dwarf_version' => undef});
reset_globals();

eval { import Parse::Readelf::Debug::Info ':fixed_regexps' };
is($@, '', "import with ':fixed_regexps'");
test_globals(':fixed_regexps',
	     {'$command' => undef,
	      '$re_section_start' => qr(^The section \.debug_info contains:|^Contents of the \.debug_(?:info|types) section:),
	      '$re_section_stop'  => qr(^The section \.debug_.* contains:|^Contents of the \.debug_.* section:|^(?:Raw dump|Dump) of debug contents of section \.debug_line:),
	      '$re_dwarf_version' => qr(^\s*Version:\s+(\d+)\s*$)}
	    );
reset_globals();

eval { import Parse::Readelf::Debug::Info ':versioned_regexps' };
is($@, '', "import with ':versioned_regexps'");
test_globals(':versioned_regexps',
	     {'$command' => undef,
	      '$re_section_start' => undef,
	      '$re_dwarf_version' => undef});
reset_globals();

eval { import Parse::Readelf::Debug::Info ':all' };
is($@, '', "import with ':all'");
test_globals(':all',
	     {'$command' => 'readelf --debug-dump=info',
	      '$re_section_start' => qr(^The section \.debug_info contains:|^Contents of the \.debug_(?:info|types) section:),
	      '$re_section_stop'  => qr(^The section \.debug_.* contains:|^Contents of the \.debug_.* section:|^(?:Raw dump|Dump) of debug contents of section \.debug_line:),
	      '$re_dwarf_version' => qr(^\s*Version:\s+(\d+)\s*$)}
	    );
reset_globals();

eval { import Parse::Readelf::Debug::Info };
is($@, '', "import with '<empty import list>'");
test_globals('<empty import list>',
	     {'$command' => undef,
	      '$re_section_start' => undef,
	      '$re_dwarf_version' => undef});


#########################################################################
# prepare testing with recorded data:
my ($volume, $directories, ) = File::Spec->splitpath($0);
$directories = '.' unless $directories;
my $path = File::Spec->catpath($volume, $directories, '');
{
    no warnings 'once';
    $Parse::Readelf::Debug::Line::command = $^O eq 'MSWin32' ? 'type' : 'cat';
}
$Parse::Readelf::Debug::Info::command = $^O eq 'MSWin32' ? 'type' : 'cat';

#########################################################################
# failing tests:
eval { my $x = Parse::Readelf::Debug::Info::new() };
like($@,
     qr|^bad call to new of Parse::Readelf::Debug::Info $re_msg_tail|,
     'bad creation fails');
eval {
    my $filepath = File::Spec->catfile($path, 'data', 'xxx.xxx');
    my $x = new Parse::Readelf::Debug::Info($filepath);
};
like($@,
     qr|^Parse::Readelf::Debug::Info can't find .* $re_msg_tail|,
     'bad file name fails');
eval {
    my $filepath = File::Spec->catfile($path, 'data', 'debug_info_1.lst');
    my $x = new Parse::Readelf::Debug::Info($filepath, '')
};
like($@,
     qr|^bad Parse::Readelf::Debug::Line object passed to Parse::Readelf::Debug::Info $re_msg_tail|,
     'bad line info object');
my $stderr = '';
$SIG{__WARN__} = sub { $stderr .= join('', @_) };
eval {
    local $Parse::Readelf::Debug::Info::command	= 'failing-test-expected-here';
    my $filepath = File::Spec->catfile($path, 'data', 'debug_info_1.lst');
    my $x = new Parse::Readelf::Debug::Info($filepath);
};
# Windows fails on closing of pipe, not on opening, therefore we
# accept both messages here:
like($@,
     qr!^can't parse .* with ".*" in Parse::Readelf::Debug::Info: .* $re_msg_tail|^error while attempting to parse .* \(maybe not an object file\?\) $re_msg_tail!,
     'non-existing command fails');
delete $SIG{__WARN__};
like($@,
     qr!^can't parse .* with ".*" in Parse::Readelf::Debug::Info: .* $re_msg_tail|^error while attempting to parse .* \(maybe not an object file\?\) $re_msg_tail!,
     'non-existing command fails');
like($stderr,
     qr/^(?:TODO: Is there some possible message here\?)?/,
     'non-existing command may have error message on stderr');
eval {
    no warnings 'once';
    local @Parse::Readelf::Debug::Info::re_item_start =
	(undef, undef, undef);
    my $filepath = File::Spec->catfile($path, 'data', 'debug_info_1.lst');
    my $x = new Parse::Readelf::Debug::Info($filepath);
};
like($@,
     qr|^DWARF version 2 not supported in Parse::Readelf::Debug::Info .* $re_msg_tail|s,
     'bad @re_item_start fails');
eval {
    my $filepath = File::Spec->catfile($path, 'data', 'broken_info-2.lst');
    my $x = new Parse::Readelf::Debug::Info($filepath);
};
like($@,
     qr|^aborting: debug info section seems empty in .* $re_msg_tail|s,
     'missing or empty debug info section (header) fails');
eval {
    local $Parse::Readelf::Debug::Info::command = 'perl -e "exit(-1);"';
    my $filepath = File::Spec->catfile($path, 'data', 'debug_info_1.lst');
    my $x = new Parse::Readelf::Debug::Info($filepath);
};
like($@,
     qr|^error while attempting to parse .* $re_msg_tail|,
     'command returning -1 fails');

#########################################################################
# tests with with imported data (currently 3 different formats):
my $filepath = undef;
my $debug_info = undef;

# arrays with results depending on input file:
my @ids_matching__l_   = (6,   6,   7,   8,  11,  12, 13);
my @ids_matching__l_o2 = (2,   2,   2,   2,   4,   4,  4);
my @ids_matching_l_    = (6,  14,  15,  15,  18,  19, 20);
my @ids_matching_var   = (8, 122, 128, 120, 125, 123, 16);
my @ids_matching_npos  = (0,   3,   3,   3,   3,   3,  0);
my @ids_matching_S1    = (0,   1,   1,   1,   1,   1,  2);

foreach my $format (0..6)	# each should do 15 tests
{
    $filepath =
	File::Spec->catfile($path, 'data', 'debug_info_'.$format.'.lst');
    $debug_info = new Parse::Readelf::Debug::Info($filepath);
    is(ref($debug_info), 'Parse::Readelf::Debug::Info',
       'created Parse::Readelf::Debug::Info object');

    my @item_ids = $debug_info->item_ids('l_object2a');
    is(@item_ids, 1, '1 l_object2a found');
    my $l_object2a = $item_ids[0];

    @item_ids = $debug_info->item_ids('object_x');
    is(@item_ids, 0, '0 object_x found');

    @item_ids = $debug_info->item_ids_matching('^l_');
    is(@item_ids, $ids_matching__l_[$format],
       $ids_matching__l_[$format].' IDs matching "^l_"');

    @item_ids = $debug_info->item_ids_matching('^l_object2');
    is(@item_ids, $ids_matching__l_o2[$format],
       $ids_matching__l_o2[$format].' IDs matching "^l_object2"');
    my $l_object2b = $item_ids[ $item_ids[0] eq $l_object2a ? 1 : 0 ];
    isnt($l_object2a, $l_object2b, '2 l_object2N distinguished');

    @item_ids = $debug_info->item_ids_matching('l_');
    is(@item_ids, $ids_matching_l_[$format],
       $ids_matching_l_[$format].' IDs matching "l_"');

    @item_ids = $debug_info->item_ids_matching('l_', 'variable');
    is(@item_ids, $ids_matching__l_[$format],
       $ids_matching__l_[$format].' variable IDs matching "l_"');

    @item_ids = $debug_info->item_ids_matching('', 'variable');
    is(@item_ids, $ids_matching_var[$format],
       $ids_matching_var[$format].' variable IDs');

    # tests not feasible for special C test source:
    if ($format > 0)
    {
	@item_ids = $debug_info->item_ids('npos');
	is(@item_ids, $ids_matching_npos[$format],
	   $ids_matching_npos[$format].' npos found');

	my @structure_layout_1 = $debug_info->structure_layout($l_object2a);
	my @structure_layout_2 = $debug_info->structure_layout($l_object2b);
	$structure_layout_2[0][1] = 'l_object2a';
	$structure_layout_2[0][4][2] = $structure_layout_1[0][4][2];
	is_deeply(\@structure_layout_1, \@structure_layout_2,
		  'l_object2N similar');

	@item_ids = $debug_info->item_ids('Structure1');
	is(@item_ids, $ids_matching_S1[$format],
	   $ids_matching_S1[$format].' Structure1 found');
	my $structure1 = $item_ids[0];

	@structure_layout_1 = $debug_info->structure_layout($structure1);
	{
	    no warnings 'once';
	    $Parse::Readelf::Debug::Info::display_nested_items = 1;
	}
	@structure_layout_2 = $debug_info->structure_layout($structure1);
	if ($format < 6)
	{
	    isnt(@structure_layout_1, @structure_layout_2,
		 'display_nested_items makes a difference unless Dwarf-4');
	}
	else
	{
	    is(@structure_layout_1, @structure_layout_2,
	       'display_nested_items makes no difference in Dwarf-4');
	}
	{
	    no warnings 'once';
	    $Parse::Readelf::Debug::Info::display_nested_items = 0;
	}

	# older code paths (removed in later versions):
	if ($format <= 2)
	{
	    @item_ids = $debug_info->item_ids('money_base');
	    is(@item_ids, 2, '2 money_base found');
	    @structure_layout_1 = $debug_info->structure_layout($item_ids[1]);
	    is($structure_layout_1[0][1], 'money_base', 'money_base is ok');
	}

	# check newer code paths (e.g. TAGs added in later versions):
	if ($format > 1)
	{
	    @item_ids = $debug_info->item_ids('l_cvInt');
	    is(@item_ids, 1, '1 l_cvInt found');
	    @structure_layout_1 = $debug_info->structure_layout($item_ids[0]);
	    is($structure_layout_1[0][2], 'const volatile int&',
	       'const volatile int& is ok');
	}
    }
}

#########################################################################
# some tests with a cloned object:
$stderr = '';
$SIG{__WARN__} = sub { $stderr .= join('', @_) };
$debug_info = $debug_info->new($filepath);
delete $SIG{__WARN__};
like($stderr,
     qr|^cloning of a Parse::Readelf::Debug::Info object is not supported $re_msg_tail|,
     'cloning gives a warning');
is(ref($debug_info), 'Parse::Readelf::Debug::Info',
   'created new Parse::Readelf::Debug::Info object');

#########################################################################
# some tests for special bugs:
$filepath = File::Spec->catfile($path, 'data', 'debug_info_0.lst');
$debug_info = new Parse::Readelf::Debug::Info($filepath);
is(scalar($debug_info->item_ids('stdout')), 1, 'last item can be found');

$filepath = File::Spec->catfile($path, 'data', 'debug_info_3.lst');
$debug_info = new Parse::Readelf::Debug::Info($filepath);
my @item_ids = $debug_info->item_ids('StructureWithUnion');
is(scalar(@item_ids), 1, 'StructureWithUnion can be found');
my $item = $debug_info->{item_map}{$item_ids[0]}{sub_items}[1];
ok($item, 'StructureWithUnion has 2nd item');
is($item->{name}, '<anonymous union>', 'StructureWithUnion has union');
$item = $item->{sub_items}[1];
ok($item, "StructureWithUnion's union has 2nd item");
is($item->{member_location}, 0, "StructureWithUnion's union's location is 0");

@item_ids = $debug_info->item_ids('__max');
is(scalar(@item_ids), 5, 'five __max can be found');
my $value = $debug_info->{item_map}{$item_ids[0]}{'const_value'};
is($value, '0x7fffffff', '__max #0 is correct');
my $value = $debug_info->{item_map}{$item_ids[1]}{'const_value'};
is($value, undef, '__max #1 is correct');
my $value = $debug_info->{item_map}{$item_ids[2]}{'const_value'};
is($value, 127, '__max #2 is correct');
my $value = $debug_info->{item_map}{$item_ids[3]}{'const_value'};
is($value, 32767, '__max #3 is correct');
my $value = $debug_info->{item_map}{$item_ids[4]}{'const_value'};
is($value, '0xffffffff 0x7fffffff', '__max #4 is correct');

$filepath = File::Spec->catfile($path, 'data', 'debug_info_4.lst');
$debug_info = new Parse::Readelf::Debug::Info($filepath);
my @item_ids = $debug_info->item_ids('l_object2_foo');
is(scalar(@item_ids), 1, 'l_object2_foo can be found');

$filepath = File::Spec->catfile($path, 'data', 'debug_info_snippets.lst');
$debug_info = new Parse::Readelf::Debug::Info($filepath);
my @item_ids = $debug_info->item_ids('TopLevelUnion');
is(scalar(@item_ids), 1, 'TopLevelUnion can be found');
my $ra_sub_items = $debug_info->{item_map}{$item_ids[0]}{sub_items};
is(@$ra_sub_items, 2, 'TopLevelUnion has 2 items');

my @item_ids = $debug_info->item_ids('context128');
is(scalar(@item_ids), 1, 'context128 can be found');
my $value = $debug_info->{item_map}{$item_ids[0]}{'member_location'};
is($value, '0x10840', 'location of context128 is correct');

#########################################################################
# finally some tests with broken data:
$filepath = File::Spec->catfile($path, 'data', 'broken_data.lst');
$stderr = '';
$SIG{__WARN__} = sub { $stderr .= join('', @_) };
$debug_info = new Parse::Readelf::Debug::Info($filepath);
delete $SIG{__WARN__};

like($stderr,
     qr|^unknown attribute type DW_AT_BROKEN found at position .* DW_AT_BROKEN .* $re_msg_tail.*|s,
     'broken attribute gives a warning');
like($stderr,
     qr|.*unknown item type DW_TAG_BROKEN.* $re_msg_tail|s,
     'broken item type gives a warning');
