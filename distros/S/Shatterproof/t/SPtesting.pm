package SPtesting;

use strict;

use base qw(Exporter);

sub dos2unix{
	my $file_path = shift;
	my $conv_file;

	open ($conv_file, "$file_path");
	my $text = join( '', @{ [ <$conv_file> ] } );
	close $conv_file;

	$text =~ s/\r\n/\n/g;

	open ($conv_file, ">", "$file_path");
	print $conv_file $text;
	close ($conv_file);
	}#sub dos2unix

sub test_open{
	my $file_handle = shift;
	my $file_path = shift;

	dos2unix($file_path);

	open($file_handle, $file_path);
	$file_handle;
}

1;
