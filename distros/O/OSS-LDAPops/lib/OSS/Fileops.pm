use strict;

package OSS::Fileops;

sub new
{
	my($class) = shift;
	my($self) = {};
	bless($self,$class);
	return($self);
};

sub read_file
{
	my($self) = shift;
	my($filename) = shift;
	open(FILE, $filename) or die($!);
	my(@file) = <FILE>;
	close(FILE);
	return(@file);
};

1;
