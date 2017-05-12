use Test::More;

sub parse_it
	{	
	use File::Spec;

	my $file = File::Spec->catfile( qw(t test_pod), $_[0] );
	ok( -e $file, "Test file [$file] exists" );
	
	use_ok( 'Pod::TOC' );
	
	my $output = '';
	open my( $fh ), ">", \$output;
	
	my $parser = Pod::TOC->new();
	isa_ok( $parser, 'Pod::TOC' );
	
	$parser->output_fh( $fh );
	$parser->parse_file( $file );
	
	#print STDERR "GOT: $output";
	
	return $output;
	}

1;
