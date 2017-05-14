use Test::More tests => 12;
use strict;

# use the module
use_ok('MyLibrary::Stylesheet');

# create a stylesheet object
my $stylesheet = MyLibrary::Stylesheet->new();
isa_ok($stylesheet, "MyLibrary::Stylesheet");

# set the name attribute
$stylesheet->stylesheet_name('Gothic 9999');
is($stylesheet->stylesheet_name(), 'Gothic 9999', 'set stylesheet_name()');

# set the description attribute
$stylesheet->stylesheet_description('Dark colors, gothic script.');
is($stylesheet->stylesheet_description(), 'Dark colors, gothic script.', 'set stylesheet_description()');

# set the stylesheet code
$stylesheet->stylesheet('CSS code');
is($stylesheet->stylesheet(), 'CSS code', 'set stylesheet()');

# save stylesheet to database
$stylesheet->commit();
my $stylesheet_id = $stylesheet->stylesheet_id();
like ($stylesheet_id, qr/^\d+$/, 'get stylesheet_id()');

# get record based on an id
my $stylesheet_2 = MyLibrary::Stylesheet->new(id => $stylesheet_id);
is($stylesheet_2->stylesheet_name(), 'Gothic 9999', 'get stylesheet_description()');
is($stylesheet_2->stylesheet_description(), 'Dark colors, gothic script.', 'get stylesheet_description()');
is($stylesheet_2->stylesheet(), 'CSS code', 'get stylesheet()');

# update stylesheet record
$stylesheet->stylesheet_name('Gothic 99990');
$stylesheet->commit();
my $stylesheet_3 = MyLibrary::Stylesheet->new(name => $stylesheet->stylesheet_name());
is($stylesheet_3->stylesheet_id(), $stylesheet_id, 'commit()');

# create another test stylesheet
my $stylesheet_4 = MyLibrary::Stylesheet->new();
$stylesheet_4->stylesheet_name('Baroque 9999');
$stylesheet_4->stylesheet_description('Golden and silver colors, fancy script');
$stylesheet_4->stylesheet('CSS Code 2');
$stylesheet_4->commit();

# get a list of stylesheets sorted by name
my @stylesheet_ids = MyLibrary::Stylesheet->get_stylesheets(sort => 'name');
my $stylesheet_5 = MyLibrary::Stylesheet->new(id => $stylesheet_ids[0]);
is($stylesheet_5->stylesheet_name(), 'Baroque 9999', 'get_stylesheets()');

# delete extra stylesheet
$stylesheet_4->delete();

# delete stylesheet record
my $rv = $stylesheet->delete();
is($rv, 1, 'delete()');
