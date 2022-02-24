use strict;
use warnings;


use Getopt::Long;

our (
	$serialize_class,
	$table_from_file_name_or_passed,
	$build_objects,
	$keyfield,
	$file,
	$directory,
	$out_directory,
	$table_base_class,
	$lib
);

BEGIN {
	GetOptions (
		"serialize:s" => \$serialize_class,
		"type:s" => \$table_from_file_name_or_passed,
		"objects:i" => \$build_objects,
		"keyfield:s" => \$keyfield,
		"file:s" => \$file,
		"in_directory:s" => \$directory,
		"out_directory:s" => \$out_directory,
		"table_base_class:s" => \$table_base_class,
		"lib:s" => \$lib
	) or die $!;
	
	use lib (defined $lib ? qw/lib $lib/ : qw/lib/);
}

use ODS::Table::Generate;

use Data::Dumper;
warn Dumper 'lib';
warn Dumper $lib;

# perl scripts/generate.pl --serialize YAML --type 1 --objects 1 --in_directory t/filedb/generate --out_directory t/ODS/Generate --table_base_class Generate

ODS::Table::Generate->new(
	serializer => $serialize_class,
	($table_from_file_name_or_passed =~ m/1/ ? (
		table_from_file_name => 1
	) : (
		table_class => $table_from_file_name_or_passed
	)),
	build_objects => $build_objects,
	in_directory => $directory,
	out_directory => $out_directory,
	keyfield => $keyfield
)->generate;
