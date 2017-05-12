# Pragmas.
use strict;
use warnings;

# Modules.
use File::Object;
use PYX::SGML::Tags;
use Tags::Output::Raw;
use Test::More 'tests' => 3;
use Test::NoWarnings;

# Directories.
my $data_dir = File::Object->new->up->dir('data');

# Test.
my $tags = Tags::Output::Raw->new(
	'xml' => 1,
);
my $obj = PYX::SGML::Tags->new(
	'tags' => $tags,
);
$obj->parse_file($data_dir->file('instruction1.pyx')->s);
is($tags->flush, '<?target code?>');

# Test.
$tags->reset;
$obj->parse_file($data_dir->file('instruction2.pyx')->s);
is($tags->flush, "<?target data\\ndata?>");
