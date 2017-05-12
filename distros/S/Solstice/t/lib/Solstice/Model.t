
use strict;
use warnings;
use 5.006_000;

use Test::More;
use constant TRUE => 1;
use constant FALSE => 0;

use Solstice::DateTime;
use Solstice::Person;
use Solstice::Group;
use Solstice::Tree;
use Solstice::List;


BEGIN{
    use_ok('Solstice::Model');
}

plan(tests => 258);

ok( my $model = Solstice::Model->new(), "Initialize a model");



#Test Data
          my $valid_string        = 'Test String';
          my $obj                = bless { foo => "foo" }, 'Lame::Package';
          my $code_ref            = sub { return "foo"; };
          my $glob                = *Solstice::Model;
          my $glob_ref            = \*Solstice::Model;
          my $valid_date_time    = Solstice::DateTime->new(time);
          my $invalid_date_time    = Solstice::DateTime->new('2000-13-32 12:00:00');

          my $valid_person        = Solstice::Person->new();
          my $valid_group        = Solstice::Group->new();

          my $empty_list        = Solstice::List->new();
          my $full_list            = Solstice::List->new();
          $full_list->add('a');
          $full_list->add('b');
          $full_list->add('c');

          my $tree                = Solstice::Tree->new();
          my $mommatree            = new Solstice::Tree;
          my $child1            = new Solstice::Tree;
          my $child2            = new Solstice::Tree;
          my $child3            = new Solstice::Tree;
          my $child4            = new Solstice::Tree;
          $child3->addChild($child4);
          $child2->addChild($child3);
          $mommatree->addChild($child1);
          $mommatree->addChild($child2);

        my $valid_email1   = 'mcrawfor@u.washington.edu';
        my $valid_email2   = 'mcrawfor+234@u.washington.edu';
        my $valid_email3   = 'mcrawfor.foo@u.washington.net';
        my $valid_email4   = 'mcrawfor@gmail.com';
        my $valid_email5   = 'm@c.tv';
        my $invalid_email1 = 'a';
        my $invalid_email2 = '@gmail.com';
        my $invalid_email3 = 'a@g';
        my $invalid_email4 = '';
        my $invalid_email5 = '<mcrawfor>';
        my $invalid_email6 = 'mcrawfor@gmail.com, vegitron@gmail.com';
        my $invalid_email7 = 'vegitron@';
        my $invalid_email8 = 'Vegitronic <vegitron@gmail.com>';

          my $valid_url1        = "http://test.com";
          my $valid_url2        = "https://example.com/hello.html";
          my $valid_url3        = "ftp://forksu.net/forksu?hello=foo";
          my $valid_url4        = "http://this.is.a.well.namespaced.domain.com/foo?bar=foo&new=blue";
          my $valid_url5        = "https://a.tv/hello.sir/madame.larue/index.rb";
          my $invalid_url1        = "ht:/foo";
          my $invalid_url2        = "foo/bar";
          my $invalid_url3        = "http:///test.com";
          my $invalid_url4        = "https://";
          my $invalid_url5        = "/test/of/relative";

          my $valid_bool1        = 1;
          my $valid_bool2        = 0;

          my $valid_array_ref1    = ['a', 'b', 'c', $tree];
          my $valid_array_ref2    = [undef, undef, undef];
          my $valid_array_ref3    = [['a', 'b'], [undef], [$tree]];

          my $valid_hash_ref1    = { a => 1, b => 2, c => 3 };
          my $valid_hash_ref2    = { a => {b => 1}};
          my $valid_hash_ref3    = { $tree => $mommatree, $valid_email5 => $full_list };
          my $valid_hash_ref4    = {[1,2,3,4] => ['a','b','c','d']};
          my $pseudohash        = [{foo => 1, dork => 2}, 'bar', 'us'];

          my $fh;
          open($fh, "/dev/null");

          
#isValidInt testing
          cmp_ok($model->_isValidInteger($valid_string),                'eq',    FALSE,    "Ints cannot be a valid string");
          cmp_ok($model->_isValidInteger(''),                            'eq',    FALSE,    'Ints cannot be empty strings');
          cmp_ok($model->_isValidInteger(),                                'eq',    TRUE,    "Ints can be undef");
          cmp_ok($model->_isValidInteger(31337),                        'eq',    TRUE,    "Ints can be ints");
          cmp_ok($model->_isValidInteger(31337.001),                    'eq',    FALSE,    "Ints cannot be floats");
          cmp_ok($model->_isValidInteger($obj),                            'eq',    FALSE,    "Ints cannot be objects");
          cmp_ok($model->_isValidInteger([]),                            'eq',    FALSE,    'Ints cannot be array refs');
          cmp_ok($model->_isValidInteger({}),                            'eq',    FALSE,    'Ints cannot be hash refs');
          cmp_ok($model->_isValidInteger(\$valid_string),                'eq',    FALSE,    'Ints cannot be scalar refs');
          cmp_ok($model->_isValidInteger('', ''),                        'eq',    FALSE,    'Ints cannot be arrays');
          cmp_ok($model->_isValidInteger($fh),                            'eq',    FALSE,    'Ints cannot be file handles');
          cmp_ok($model->_isValidInteger($code_ref),                    'eq',    FALSE,    'Ints cannot be code refs');
          cmp_ok($model->_isValidInteger($glob),                        'eq',    FALSE,    'Ints cannot be globs');
          cmp_ok($model->_isValidInteger($glob_ref),                    'eq',    FALSE,    'Ints cannot be glob_refs');

#isValidNumber testing
          cmp_ok($model->_isValidNumber($valid_string),                'eq',    FALSE,    "Floats cannot be a valid string");
          cmp_ok($model->_isValidNumber(''),                            'eq',    FALSE,    'Floats cannot be empty strings');
          cmp_ok($model->_isValidNumber(),                            'eq',    TRUE,    "Floats can be undef");
          cmp_ok($model->_isValidNumber(31337),                        'eq',    TRUE,    "Floats can be ints");
          cmp_ok($model->_isValidNumber(31337.001),                    'eq',    TRUE,    "Floats can be floats");
          cmp_ok($model->_isValidNumber($obj),                        'eq',    FALSE,    "Floats cannot be objects");
          cmp_ok($model->_isValidNumber([]),                            'eq',    FALSE,    'Floats cannot be array refs');
          cmp_ok($model->_isValidNumber({}),                            'eq',    FALSE,    'Floats cannot be hash refs');
          cmp_ok($model->_isValidNumber(\$valid_string),                'eq',    FALSE,    'Floats cannot be scalar refs');
          cmp_ok($model->_isValidNumber('', ''),                        'eq',    FALSE,    'Floats cannot be arrays');
          cmp_ok($model->_isValidNumber($fh),                        'eq',    FALSE,    'Floats cannot be file handles');
          cmp_ok($model->_isValidNumber($code_ref),                    'eq',    FALSE,    'Floats cannot be code refs');
          cmp_ok($model->_isValidNumber($glob),                        'eq',    FALSE,    'Floats cannot be globs');
          cmp_ok($model->_isValidNumber($glob_ref),                    'eq',    FALSE,    'Floats cannot be glob_refs');

#isValidDateTime
          cmp_ok($model->_isValidDateTime($valid_date_time),        'eq',    TRUE,    "DateTimes can be valid Solstice::DateTimes");
          cmp_ok($model->_isValidDateTime($invalid_date_time),        'eq',    FALSE,    "DateTimes cannot be invalid Solstice::DateTimes");
          cmp_ok($model->_isValidDateTime($valid_string),            'eq',    FALSE,    "DateTimes cannot be a valid string");
          cmp_ok($model->_isValidDateTime(''),                        'eq',    FALSE,    'DateTimes cannot be empty strings');
          cmp_ok($model->_isValidDateTime(),                        'eq',    TRUE,    "DateTimes can be undef");
          cmp_ok($model->_isValidDateTime(31337),                    'eq',    FALSE,    "DateTimes cannot be ints");
          cmp_ok($model->_isValidDateTime(31337.001),                'eq',    FALSE,    "DateTimes cannot be floats");
          cmp_ok($model->_isValidDateTime($obj),                    'eq',    FALSE,    "DateTimes cannot be objects");
          cmp_ok($model->_isValidDateTime([]),                        'eq',    FALSE,    'DateTimes cannot be array refs');
          cmp_ok($model->_isValidDateTime({}),                        'eq',    FALSE,    'DateTimes cannot be hash refs');
          cmp_ok($model->_isValidDateTime(\$valid_string),            'eq',    FALSE,    'DateTimes cannot be scalar refs');
          cmp_ok($model->_isValidDateTime('', ''),                    'eq',    FALSE,    'DateTimes cannot be arrays');
          cmp_ok($model->_isValidDateTime($fh),                        'eq',    FALSE,    'DateTimes cannot be file handles');
          cmp_ok($model->_isValidDateTime($code_ref),                'eq',    FALSE,    'DateTimes cannot be code refs');
          cmp_ok($model->_isValidDateTime($glob),                    'eq',    FALSE,    'DateTimes cannot be globs');
          cmp_ok($model->_isValidDateTime($glob_ref),                'eq',    FALSE,    'DateTimes cannot be glob_refs');



#isValidBoolean
          cmp_ok($model->_isValidBoolean($valid_bool1),                'eq',    TRUE,    "Boolean can be valid bool 1");
          cmp_ok($model->_isValidBoolean($valid_bool2),                'eq',    TRUE,    "Boolean can be valid bool 2");
          cmp_ok($model->_isValidBoolean($valid_date_time),            'eq',    FALSE,    "Boolean cannot be valid Solstice::DateTimes");
          cmp_ok($model->_isValidBoolean($invalid_date_time),        'eq',    FALSE,    "Boolean cannot be invalid Solstice::DateTimes");
          cmp_ok($model->_isValidBoolean($valid_string),            'eq',    FALSE,    "Boolean cannot be a valid string");
          cmp_ok($model->_isValidBoolean(''),                        'eq',    FALSE,    'Boolean cannot be empty strings');
          cmp_ok($model->_isValidBoolean(),                            'eq',    TRUE,    "Boolean can be undef");
          cmp_ok($model->_isValidBoolean(31337),                    'eq',    FALSE,    "Boolean cannot be ints");
          cmp_ok($model->_isValidBoolean(31337.001),                'eq',    FALSE,    "Boolean cannot be floats");
          cmp_ok($model->_isValidBoolean($obj),                        'eq',    FALSE,    "Boolean cannot be objects");
          cmp_ok($model->_isValidBoolean([]),                        'eq',    FALSE,    'Boolean cannot be array refs');
          cmp_ok($model->_isValidBoolean({}),                        'eq',    FALSE,    'Boolean cannot be hash refs');
          cmp_ok($model->_isValidBoolean(\$valid_string),            'eq',    FALSE,    'Boolean cannot be scalar refs');
          cmp_ok($model->_isValidBoolean('', ''),                    'eq',    FALSE,    'Boolean cannot be arrays');
          cmp_ok($model->_isValidBoolean($fh),                        'eq',    FALSE,    'Boolean cannot be file handles');
          cmp_ok($model->_isValidBoolean($code_ref),                'eq',    FALSE,    'Boolean cannot be code refs');
          cmp_ok($model->_isValidBoolean($glob),                    'eq',    FALSE,    'Boolean cannot be globs');
          cmp_ok($model->_isValidBoolean($glob_ref),                'eq',    FALSE,    'Boolean cannot be glob_refs');



#isValidPerson
          cmp_ok($model->_isValidPerson($valid_person),                'eq',    TRUE,    "Person can be a valid Solistice::Person");
          cmp_ok($model->_isValidPerson($valid_date_time),            'eq',    FALSE,    "Person cannot be valid Solstice::DateTimes");
          cmp_ok($model->_isValidPerson($invalid_date_time),        'eq',    FALSE,    "Person cannot be invalid Solstice::DateTimes");
          cmp_ok($model->_isValidPerson($valid_string),                'eq',    FALSE,    "Person cannot be a valid string");
          cmp_ok($model->_isValidPerson(''),                        'eq',    FALSE,    'Person cannot be empty strings');
          cmp_ok($model->_isValidPerson(),                            'eq',    TRUE,    "Person can be undef");
          cmp_ok($model->_isValidPerson(31337),                        'eq',    FALSE,    "Person cannot be ints");
          cmp_ok($model->_isValidPerson(31337.001),                    'eq',    FALSE,    "Person cannot be floats");
          cmp_ok($model->_isValidPerson($obj),                        'eq',    FALSE,    "Person cannot be objects");
          cmp_ok($model->_isValidPerson([]),                        'eq',    FALSE,    'Person cannot be array refs');
          cmp_ok($model->_isValidPerson({}),                        'eq',    FALSE,    'Person cannot be hash refs');
          cmp_ok($model->_isValidPerson(\$valid_string),            'eq',    FALSE,    'Person cannot be scalar refs');
          cmp_ok($model->_isValidPerson('', ''),                    'eq',    FALSE,    'Person cannot be arrays');
          cmp_ok($model->_isValidPerson($fh),                        'eq',    FALSE,    'Person cannot be file handles');
          cmp_ok($model->_isValidPerson($code_ref),                    'eq',    FALSE,    'Person cannot be code refs');
          cmp_ok($model->_isValidPerson($glob),                        'eq',    FALSE,    'Person cannot be globs');
          cmp_ok($model->_isValidPerson($glob_ref),                    'eq',    FALSE,    'Person cannot be glob_refs');

#isvalidGroup
          cmp_ok($model->_isValidGroup($valid_group),                'eq',    TRUE,    "Group can be a valid Solistice::Group");
          cmp_ok($model->_isValidGroup($valid_date_time),            'eq',    FALSE,    "Group cannot be valid Solstice::DateTimes");
          cmp_ok($model->_isValidGroup($invalid_date_time),            'eq',    FALSE,    "Group cannot be invalid Solstice::DateTimes");
          cmp_ok($model->_isValidGroup($valid_string),                'eq',    FALSE,    "Group cannot be a valid string");
          cmp_ok($model->_isValidGroup(''),                            'eq',    FALSE,    'Group cannot be empty strings');
          cmp_ok($model->_isValidGroup(),                            'eq',    TRUE,    "Group can be undef");
          cmp_ok($model->_isValidGroup(31337),                        'eq',    FALSE,    "Group cannot be ints");
          cmp_ok($model->_isValidGroup(31337.001),                    'eq',    FALSE,    "Group cannot be floats");
          cmp_ok($model->_isValidGroup($obj),                        'eq',    FALSE,    "Group cannot be objects");
          cmp_ok($model->_isValidGroup([]),                            'eq',    FALSE,    'Group cannot be array refs');
          cmp_ok($model->_isValidGroup({}),                            'eq',    FALSE,    'Group cannot be hash refs');
          cmp_ok($model->_isValidGroup(\$valid_string),                'eq',    FALSE,    'Group cannot be scalar refs');
          cmp_ok($model->_isValidGroup('', ''),                        'eq',    FALSE,    'Group cannot be arrays');
          cmp_ok($model->_isValidGroup($fh),                        'eq',    FALSE,    'Group cannot be file handles');
          cmp_ok($model->_isValidGroup($code_ref),                    'eq',    FALSE,    'Group cannot be code refs');
          cmp_ok($model->_isValidGroup($glob),                        'eq',    FALSE,    'Group cannot be globs');
          cmp_ok($model->_isValidGroup($glob_ref),                    'eq',    FALSE,    'Group cannot be glob_refs');

#isValidList
          cmp_ok($model->_isValidList($empty_list),                    'eq',    TRUE,    "List can be an empty List");
          cmp_ok($model->_isValidList($full_list),                    'eq',    TRUE,    "List can be an filled List");
          cmp_ok($model->_isValidList($tree),                        'eq',    FALSE,    "List cannot be an tree");
          cmp_ok($model->_isValidList($valid_date_time),            'eq',    FALSE,    "List cannot be valid Solstice::DateTimes");
          cmp_ok($model->_isValidList($invalid_date_time),            'eq',    FALSE,    "List cannot be invalid Solstice::DateTimes");
          cmp_ok($model->_isValidList($valid_string),                'eq',    FALSE,    "List cannot be a valid string");
          cmp_ok($model->_isValidList(''),                            'eq',    FALSE,    'List cannot be empty strings');
          cmp_ok($model->_isValidList(),                            'eq',    TRUE,    "List can be undef");
          cmp_ok($model->_isValidList(31337),                        'eq',    FALSE,    "List cannot be ints");
          cmp_ok($model->_isValidList(31337.001),                    'eq',    FALSE,    "List cannot be floats");
          cmp_ok($model->_isValidList($obj),                        'eq',    FALSE,    "List cannot be objects");
          cmp_ok($model->_isValidList([]),                            'eq',    FALSE,    'List cannot be array refs');
          cmp_ok($model->_isValidList({}),                            'eq',    FALSE,    'List cannot be hash refs');
          cmp_ok($model->_isValidList(\$valid_string),                'eq',    FALSE,    'List cannot be scalar refs');
          cmp_ok($model->_isValidList('', ''),                        'eq',    FALSE,    'List cannot be arrays');
          cmp_ok($model->_isValidList($fh),                            'eq',    FALSE,    'List cannot be file handles');
          cmp_ok($model->_isValidList($code_ref),                    'eq',    FALSE,    'List cannot be code refs');
          cmp_ok($model->_isValidList($glob),                        'eq',    FALSE,    'List cannot be globs');
          cmp_ok($model->_isValidList($glob_ref),                    'eq',    FALSE,    'List cannot be glob_refs');

#isValidTree
          cmp_ok($model->_isValidTree($tree),                        'eq',    TRUE,    "List can be an empty tree");
          cmp_ok($model->_isValidTree($mommatree),                    'eq',    TRUE,    "List can be a full tree");
          cmp_ok($model->_isValidTree($mommatree->getChild(0)),        'eq',    TRUE,    "List can be a non-root portion of a tree");
          cmp_ok($model->_isValidTree($empty_list),                    'eq',    FALSE,    "List cannot be an empty List");
          cmp_ok($model->_isValidTree($full_list),                    'eq',    FALSE,    "List cannot be an filled List");
          cmp_ok($model->_isValidTree($valid_date_time),            'eq',    FALSE,    "List cannot be valid Solstice::DateTimes");
          cmp_ok($model->_isValidTree($invalid_date_time),            'eq',    FALSE,    "List cannot be invalid Solstice::DateTimes");
          cmp_ok($model->_isValidTree($valid_string),                'eq',    FALSE,    "List cannot be a valid string");
          cmp_ok($model->_isValidTree(''),                            'eq',    FALSE,    'List cannot be empty strings');
          cmp_ok($model->_isValidTree(),                            'eq',    TRUE,    "List can be undef");
          cmp_ok($model->_isValidTree(31337),                        'eq',    FALSE,    "List cannot be ints");
          cmp_ok($model->_isValidTree(31337.001),                    'eq',    FALSE,    "List cannot be floats");
          cmp_ok($model->_isValidTree($obj),                        'eq',    FALSE,    "List cannot be objects");
          cmp_ok($model->_isValidTree([]),                            'eq',    FALSE,    'List cannot be array refs');
          cmp_ok($model->_isValidTree({}),                            'eq',    FALSE,    'List cannot be hash refs');
          cmp_ok($model->_isValidTree(\$valid_string),                'eq',    FALSE,    'List cannot be scalar refs');
          cmp_ok($model->_isValidTree('', ''),                        'eq',    FALSE,    'List cannot be arrays');
          cmp_ok($model->_isValidTree($fh),                            'eq',    FALSE,    'List cannot be file handles');
          cmp_ok($model->_isValidTree($code_ref),                    'eq',    FALSE,    'List cannot be code refs');
          cmp_ok($model->_isValidTree($glob),                        'eq',    FALSE,    'List cannot be globs');
          cmp_ok($model->_isValidTree($glob_ref),                    'eq',    FALSE,    'List cannot be glob_refs');


#isValidArrayRef
          cmp_ok($model->_isValidArrayRef([]),                        'eq',    TRUE,    'ArrayRef can be an empty array ref');
          cmp_ok($model->_isValidArrayRef($valid_array_ref1),        'eq',    TRUE,    'ArrayRef can be a valid array ref 1');
          cmp_ok($model->_isValidArrayRef($valid_array_ref2),        'eq',    TRUE,    'ArrayRef can be a valid array ref 2');
          cmp_ok($model->_isValidArrayRef($valid_array_ref3),        'eq',    TRUE,    'ArrayRef can be a valid array ref 3');
          cmp_ok($model->_isValidArrayRef($tree),                    'eq',    FALSE,    "ArrayRef cannot be an empty tree");
          cmp_ok($model->_isValidArrayRef($mommatree),                'eq',    FALSE,    "ArrayRef cannot be a full tree");
          cmp_ok($model->_isValidArrayRef($empty_list),                'eq',    FALSE,    "ArrayRef cannot be an empty List");
          cmp_ok($model->_isValidArrayRef($full_list),                'eq',    FALSE,    "ArrayRef cannot be an filled List");
          cmp_ok($model->_isValidArrayRef($valid_date_time),        'eq',    FALSE,    "ArrayRef cannot be valid Solstice::DateTimes");
          cmp_ok($model->_isValidArrayRef($invalid_date_time),        'eq',    FALSE,    "ArrayRef cannot be invalid Solstice::DateTimes");
          cmp_ok($model->_isValidArrayRef($valid_string),            'eq',    FALSE,    "ArrayRef cannot be a valid string");
          cmp_ok($model->_isValidArrayRef(''),                        'eq',    FALSE,    'ArrayRef cannot be empty strings');
          cmp_ok($model->_isValidArrayRef(),                        'eq',    TRUE,    "ArrayRef can be undef");
          cmp_ok($model->_isValidArrayRef(31337),                    'eq',    FALSE,    "ArrayRef cannot be ints");
          cmp_ok($model->_isValidArrayRef(31337.001),                'eq',    FALSE,    "ArrayRef cannot be floats");
          cmp_ok($model->_isValidArrayRef($obj),                    'eq',    FALSE,    "ArrayRef cannot be objects");
          cmp_ok($model->_isValidArrayRef({}),                        'eq',    FALSE,    'ArrayRef cannot be hash refs');
          cmp_ok($model->_isValidArrayRef(\$valid_string),            'eq',    FALSE,    'ArrayRef cannot be scalar refs');
          cmp_ok($model->_isValidArrayRef('', ''),                    'eq',    FALSE,    'ArrayRef cannot be arrays');
          cmp_ok($model->_isValidArrayRef($fh),                        'eq',    FALSE,    'ArrayRef cannot be file handles');
          cmp_ok($model->_isValidArrayRef($code_ref),                'eq',    FALSE,    'ArrayRef cannot be code refs');
          cmp_ok($model->_isValidArrayRef($glob),                    'eq',    FALSE,    'ArrayRef cannot be globs');
          cmp_ok($model->_isValidArrayRef($glob_ref),                'eq',    FALSE,    'ArrayRef cannot be glob_refs');

#isValidHashRef
          cmp_ok($model->_isValidHashRef({}),                        'eq',    TRUE,    'HashRef can be empty hash refs');
          cmp_ok($model->_isValidHashRef($valid_hash_ref1),           'eq',    TRUE,    'HashRef can be valid hash refs1');
          cmp_ok($model->_isValidHashRef($valid_hash_ref2),            'eq',    TRUE,    'HashRef can be valid hash refs2');
          cmp_ok($model->_isValidHashRef($valid_hash_ref3),            'eq',    TRUE,    'HashRef can be valid hash refs3');
          cmp_ok($model->_isValidHashRef($valid_hash_ref4),            'eq',    TRUE,    'HashRef can be valid hash refs4');
          cmp_ok($model->_isValidHashRef($pseudohash),                'eq',    FALSE,    'HashRef cannot be pseudohashes');
          cmp_ok($model->_isValidHashRef([]),                        'eq',    FALSE,    'HashRef cannot be an empty array ref');
          cmp_ok($model->_isValidHashRef($valid_array_ref1),        'eq',    FALSE,    'HashRef cannot be a valid array ref 1');
          cmp_ok($model->_isValidHashRef($valid_array_ref2),        'eq',    FALSE,    'HashRef cannot be a valid array ref 2');
          cmp_ok($model->_isValidHashRef($valid_array_ref3),        'eq',    FALSE,    'HashRef cannot be a valid array ref 3');
          cmp_ok($model->_isValidHashRef($tree),                    'eq',    FALSE,    "HashRef cannot be an empty tree");
          cmp_ok($model->_isValidHashRef($mommatree),                'eq',    FALSE,    "HashRef cannot be a full tree");
          cmp_ok($model->_isValidHashRef($empty_list),                'eq',    FALSE,    "HashRef cannot be an empty List");
          cmp_ok($model->_isValidHashRef($full_list),                'eq',    FALSE,    "HashRef cannot be an filled List");
          cmp_ok($model->_isValidHashRef($valid_date_time),            'eq',    FALSE,    "HashRef cannot be valid Solstice::DateTimes");
          cmp_ok($model->_isValidHashRef($invalid_date_time),        'eq',    FALSE,    "HashRef cannot be invalid Solstice::DateTimes");
          cmp_ok($model->_isValidHashRef($valid_string),            'eq',    FALSE,    "HashRef cannot be a valid string");
          cmp_ok($model->_isValidHashRef(''),                        'eq',    FALSE,    'HashRef cannot be empty strings');
          cmp_ok($model->_isValidHashRef(),                            'eq',    TRUE,    "HashRef can be undef");
          cmp_ok($model->_isValidHashRef(31337),                    'eq',    FALSE,    "HashRef cannot be ints");
          cmp_ok($model->_isValidHashRef(31337.001),                'eq',    FALSE,    "HashRef cannot be floats");
          cmp_ok($model->_isValidHashRef($obj),                        'eq',    FALSE,    "HashRef cannot be objects");
          cmp_ok($model->_isValidHashRef(\$valid_string),            'eq',    FALSE,    'HashRef cannot be scalar refs');
          cmp_ok($model->_isValidHashRef('', ''),                    'eq',    FALSE,    'HashRef cannot be arrays');
          cmp_ok($model->_isValidHashRef($fh),                        'eq',    FALSE,    'HashRef cannot be file handles');
          cmp_ok($model->_isValidHashRef($code_ref),                'eq',    FALSE,    'HashRef cannot be code refs');
          cmp_ok($model->_isValidHashRef($glob),                    'eq',    FALSE,    'HashRef cannot be globs');
          cmp_ok($model->_isValidHashRef($glob_ref),                'eq',    FALSE,    'HashRef cannot be glob_refs');




STRING:

#isValidString testing
          cmp_ok($model->_isValidString($valid_string),                'eq',    TRUE,    "Strings can be a valid string");
          cmp_ok($model->_isValidString(''),                        'eq',    TRUE,    'Strings can be empty strings');
          cmp_ok($model->_isValidString(),                            'eq',    TRUE,    "Strings can be undef");
          cmp_ok($model->_isValidString(31337),                        'eq',    TRUE,    "Strings can be ints");
          cmp_ok($model->_isValidString(31337.001),                    'eq',    TRUE,    "Strings can be floats");
          cmp_ok($model->_isValidString($obj),                        'eq',    FALSE,    "Strings cannot be objects");
          cmp_ok($model->_isValidString([]),                        'eq',    FALSE,    'Strings cannot be array refs');
          cmp_ok($model->_isValidString({}),                        'eq',    FALSE,    'Strings cannot be hash refs');
          cmp_ok($model->_isValidString(\$valid_string),            'eq',    FALSE,    'Strings cannot be scalar refs');
          cmp_ok($model->_isValidString('', ''),                    'eq',    FALSE,    'Strings cannot be arrays');
          cmp_ok($model->_isValidString('', undef, ''),                'eq',    FALSE,    'Strings cannot be arrays (undef 2nd arg)');
          cmp_ok($model->_isValidString($fh),                        'eq',    FALSE,    'Strings cannot be file handles');
          cmp_ok($model->_isValidString($code_ref),                    'eq',    FALSE,    'Strings cannot be code refs');
          cmp_ok($model->_isValidString($glob),                        'eq',    FALSE,    'Strings cannot be globs');
          cmp_ok($model->_isValidString($glob_ref),                    'eq',    FALSE,    'Strings cannot be glob_refs');

EMAIL:
#isValidEmail
          cmp_ok($model->_isValidEmail($valid_email1),                'eq',    TRUE,    "Email can be valid email1");
          cmp_ok($model->_isValidEmail($valid_email2),                'eq',    TRUE,    "Email can be valid email2");
          cmp_ok($model->_isValidEmail($valid_email3),                'eq',    TRUE,    "Email can be valid email3");
          cmp_ok($model->_isValidEmail($valid_email4),                'eq',    TRUE,    "Email can be valid email4");
          cmp_ok($model->_isValidEmail($valid_email5),                'eq',    TRUE,    "Email can be valid email5");
          cmp_ok($model->_isValidEmail($invalid_email1),            'eq',    FALSE,    "Email cannot be invalid email1");
          cmp_ok($model->_isValidEmail($invalid_email2),            'eq',    FALSE,    "Email cannot be invalid email2");
          cmp_ok($model->_isValidEmail($invalid_email3),            'eq',    FALSE,    "Email cannot be invalid email3");
          cmp_ok($model->_isValidEmail($invalid_email4),            'eq',    FALSE,    "Email cannot be invalid email4");
          cmp_ok($model->_isValidEmail($invalid_email5),            'eq',    FALSE,    "Email cannot be invalid email5");
          cmp_ok($model->_isValidEmail($invalid_email6),            'eq',    FALSE,    "Email cannot be invalid email6");
          cmp_ok($model->_isValidEmail($invalid_email7),            'eq',    FALSE,    "Email cannot be invalid email6");
          cmp_ok($model->_isValidEmail($invalid_email8),                'eq', FALSE,    "Email cannot be invalid email8");
          cmp_ok($model->_isValidEmail($valid_date_time),            'eq',    FALSE,    "Email cannot be valid Solstice::DateTimes");
          cmp_ok($model->_isValidEmail($invalid_date_time),            'eq',    FALSE,    "Email cannot be invalid Solstice::DateTimes");
          cmp_ok($model->_isValidEmail($valid_string),                'eq',    FALSE,    "Email cannot be a valid string");
          cmp_ok($model->_isValidEmail(''),                            'eq',    FALSE,    'Email cannot be empty strings');
          cmp_ok($model->_isValidEmail(),                            'eq',    TRUE,    "Email can be undef");
          cmp_ok($model->_isValidEmail(31337),                        'eq',    FALSE,    "Email cannot be ints");
          cmp_ok($model->_isValidEmail(31337.001),                    'eq',    FALSE,    "Email cannot be floats");
          cmp_ok($model->_isValidEmail($obj),                        'eq',    FALSE,    "Email cannot be objects");
          cmp_ok($model->_isValidEmail([]),                            'eq',    FALSE,    'Email cannot be array refs');
          cmp_ok($model->_isValidEmail({}),                            'eq',    FALSE,    'Email cannot be hash refs');
          cmp_ok($model->_isValidEmail(\$valid_string),                'eq',    FALSE,    'Email cannot be scalar refs');
          cmp_ok($model->_isValidEmail('', ''),                        'eq',    FALSE,    'Email cannot be arrays');
          cmp_ok($model->_isValidEmail($fh),                        'eq',    FALSE,    'Email cannot be file handles');
          cmp_ok($model->_isValidEmail($code_ref),                    'eq',    FALSE,    'Email cannot be code refs');
          cmp_ok($model->_isValidEmail($glob),                        'eq',    FALSE,    'Email cannot be globs');
          cmp_ok($model->_isValidEmail($glob_ref),                    'eq',    FALSE,    'Email cannot be glob_refs');

URL:
#isValidURL testing
          cmp_ok($model->_isValidURL($valid_url1),                    'eq',    TRUE,    "URL can be valid url1");
          cmp_ok($model->_isValidURL($valid_url2),                    'eq',    TRUE,    "URL can be valid url2");
          cmp_ok($model->_isValidURL($valid_url3),                    'eq',    TRUE,    "URL can be valid url3");
          cmp_ok($model->_isValidURL($valid_url4),                    'eq',    TRUE,    "URL can be valid url4");
          cmp_ok($model->_isValidURL($valid_url5),                    'eq',    TRUE,    "URL can be valid url5");
          cmp_ok($model->_isValidURL($invalid_url1),                'eq',    FALSE,    "URL cannot be invalid url1");
          cmp_ok($model->_isValidURL($invalid_url2),                'eq',    FALSE,    "URL cannot be invalid url2");
          cmp_ok($model->_isValidURL($invalid_url3),                'eq',    FALSE,    "URL cannot be invalid url3");
          cmp_ok($model->_isValidURL($invalid_url4),                'eq',    FALSE,    "URL cannot be invalid url4");
          cmp_ok($model->_isValidURL($invalid_url5),                'eq',    FALSE,    "URL cannot be invalid url5");
          cmp_ok($model->_isValidURL($valid_date_time),                'eq',    FALSE,    "URL cannot be valid Solstice::DateTimes");
          cmp_ok($model->_isValidURL($invalid_date_time),            'eq',    FALSE,    "URL cannot be invalid Solstice::DateTimes");
          cmp_ok($model->_isValidURL($valid_string),                'eq',    FALSE,    "URL cannot be a valid string");
          cmp_ok($model->_isValidURL(''),                            'eq',    FALSE,    'URL cannot be empty strings');
          cmp_ok($model->_isValidURL(),                                'eq',    TRUE,    "URL can be undef");
          cmp_ok($model->_isValidURL(31337),                        'eq',    FALSE,    "URL cannot be ints");
          cmp_ok($model->_isValidURL(31337.001),                    'eq',    FALSE,    "URL cannot be floats");
          cmp_ok($model->_isValidURL($obj),                            'eq',    FALSE,    "URL cannot be objects");
          cmp_ok($model->_isValidURL([]),                            'eq',    FALSE,    'URL cannot be array refs');
          cmp_ok($model->_isValidURL({}),                            'eq',    FALSE,    'URL cannot be hash refs');
          cmp_ok($model->_isValidURL(\$valid_string),                'eq',    FALSE,    'URL cannot be scalar refs');
          cmp_ok($model->_isValidURL('', ''),                        'eq',    FALSE,    'URL cannot be arrays');
          cmp_ok($model->_isValidURL($fh),                            'eq',    FALSE,    'URL cannot be file handles');
          cmp_ok($model->_isValidURL($code_ref),                    'eq',    FALSE,    'URL cannot be code refs');
          cmp_ok($model->_isValidURL($glob),                        'eq',    FALSE,    'URL cannot be globs');
          cmp_ok($model->_isValidURL($glob_ref),                    'eq',    FALSE,    'URL cannot be glob_refs');





=head1 COPYRIGHT

Copyright  1998-2006 Office of Learning Technologies, University of Washington

Licensed under the Educational Community License, Version 1.0 (the "License");
you may not use this file except in compliance with the License. You may obtain
a copy of the License at: http://www.opensource.org/licenses/ecl1.php

Unless required by applicable law or agreed to in writing, software distributed
under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
CONDITIONS OF ANY KIND, either express or implied.  See the License for the
specific language governing permissions and limitations under the License.

=cut
