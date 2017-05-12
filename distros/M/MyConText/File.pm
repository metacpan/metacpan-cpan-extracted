
package MyConText::File;
use MyConText::String;
use strict;
use vars qw! @ISA !;
@ISA = qw! MyConText::String !;

sub index_document {
	my ($self, $file) = @_;
	my $dbh = $self->{'dbh'};

	open FILE, $file or do {
		$self->{'errstr'} = "Reading the file `$file' failed: $!";
		return;
		};
	my $data;
	{
		local $/ = undef;
		$data = <FILE>;
	}
	close FILE;
	$self->SUPER::index_document($file, $data);
	}

1;

