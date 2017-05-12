
use OpenXML::Properties;
use Data::Dumper;
use File::Basename;

use Test::More 'no_plan';

use_ok('OpenXML::Properties');

$doc = dirname($0) . '\openxml_2010.docx';

$file = OpenXML::Properties->new(FileName => $doc);
$file->verbose(1);

isa_ok($file, 'OpenXML::Properties');
is($file->FileName, $doc, "file name same");

$zip = $file->read_doc();
isa_ok($zip, 'Archive::Zip');

$number_props_before_add = $file->has_custom_properties;
print "number of custom props = $number_props_before_add, ", $file->has_custom_properties , "\n";

$number_of_pids_before_add = $file->count_pids;

$prop_name = "new_prop_1";
$prop_value = "new_prop_value_1";
$SID = "e673666";


ok(! $file->has_custom_property($prop_name), "property $prop_name does not exist");
$err = $file->add_custom_property($prop_name, $prop_value);
ok(! $err, "No error returned from adding custom prop");

$number_props_after_add = $file->has_custom_properties;
print "number of custom props = $number_props_after_add, ", $file->has_custom_properties , "\n";

ok($number_props_after_add - $number_props_before_add == 1, "Number of props increased by 1");

ok($file->has_custom_property($prop_name), "property $prop_name added successfully");

$number_of_pids_after_add = $file->count_pids;
ok($number_of_pids_after_add - $number_of_pids_before_add == 2, "Number of pids increased by 1");

%props = $file->custom_properties();
foreach $key (keys %props)
{
     print "property name = $key, value = $props{$key}\n";
}


$err = $file->remove_custom_property($prop_name);
ok(! $err);

$number_props_after_remove = $file->has_custom_properties;
$number_of_pids_after_remove = $file->count_pids;

ok($number_props_after_add - $number_props_after_remove == 1, "Number of props decreased by 1");
ok($number_of_pids_after_add - $number_of_pids_after_remove == 2, "Number of pids decreased by 1");
ok(! $file->has_custom_property($prop_name), "property $prop_name removed successfully");

$err = $file->save();
ok(! $err);
