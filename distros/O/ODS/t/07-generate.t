use Test::More;

BEGIN {
	use ODS::Table::Generate;	
	my $ods = ODS::Table::Generate->new(
		serializer => 'YAMLOrdered',
		table_from_file_name => 1,
		build_objects => 1,
		in_directory => 't/filedb/generate',
		out_directory => 't/ODS',
		table_base_class => 'Generate'
	)->generate;
}

use lib 't/ODS';

use Generate::Table::Simple;

my $test = Generate::Table::Simple->connect('Directory', {
	directory => 't/filedb/directory/truth/test2',
	cache_directory => 't/filedb/directory/cache/test2',
	serialize_class => 'YAML'
});

my $spec = $test->create({
	__custom_file_name => 'height.yml',
	__serialize => 1,
	one => 123,
	two => 'abc',
	three => \1,
})->rows->[0];

ok( $spec->one(456) );

ok( $spec->update() );

is($spec->one, 456);

opendir(my $dh, 't/filedb/directory/cache/test2') || die "Can't opendir $directory: $!";
my @cfiles = sort { $a <=> $b } grep { $_ !~ m/^\.+$/ } readdir($dh);
closedir $dh;

for (@cfiles) {
	diag explain $_;
	unlink 't/filedb/directory/cache/test2/' . $_;
}

opendir(my $dh, 't/filedb/directory/truth/test2') || die "Can't opendir $directory: $!";
my @files = sort { $a <=> $b } grep { $_ !~ m/^\.+$/ } readdir($dh);
closedir $dh;

for (@files) {
	diag explain $_;
	unlink 't/filedb/directory/truth/test2/' . $_;
}

unlink 't/ODS/Generate/Table/Simple.pm';
rmdir 't/ODS/Generate/Table';
unlink 't/ODS/Generate/Row/Simple.pm';
rmdir 't/ODS/Generate/Row';
unlink 't/ODS/Generate/ResultSet/Simple.pm';
rmdir 't/ODS/Generate/ResultSet';
rmdir 't/ODS/Generate';

done_testing;
