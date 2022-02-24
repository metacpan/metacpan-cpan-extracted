use strict;
use warnings;

use lib 'lib';

use ODS::Table::Generate::Data;

use Getopt::Long;

our (
	$table_class, 
	$table_class_type, 
	$table_class_connect,
	$total, 
	$data_class,
	$data_class_theme, 
	$data_class_total,
	$lib
);

BEGIN {
	GetOptions (
		"class:s" => \$table_class,
		"type:s" => \$table_class_type,
		"connect:s" => sub {
			my ($option, $string) = @_;
			my @pairs = split ",", $string;
			for (@pairs) {
				my ($key, $value) = split "=", $_;
				$table_class_connect->{$key} = $value;
			}
		},
		"total:i" => \$total,
		"data_class:s" => \$data_class,
		"data_class_theme:s" => \$data_class_theme,
		"data_class_total:s" => \$data_class_total,
		"lib:s" => \$lib
	) or die $!;
}

if ($lib) {
	use lib "$lib";
}

ODS::Table::Generate::Data->new(
	table_class => $table_class,
	table_class_type => $table_class_type,
	table_class_connect => $table_class_connect,
	total => $total,
	($data_class ? (data_class => $data_class) : ()),
	($data_class_theme ? (data_class_theme => $data_class_theme) : ()),
	($data_class_total ? (data_class_total => $data_class_total) : ())
)->generate;
