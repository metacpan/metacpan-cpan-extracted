
sub do_it {
	state $rc = require ConfigReader::Simple;
	}

my $rc = require Mojo::Util;

my %data = (
    require	=> 42,	# Should not report '=>'.
);

1;
