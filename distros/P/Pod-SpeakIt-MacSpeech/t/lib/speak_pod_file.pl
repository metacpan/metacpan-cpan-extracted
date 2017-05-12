use Test::LongString;
use IO::Null;

my $class = 'Pod::SpeakIt::MacSpeech';
use_ok( $class );

my $input_dir = File::Spec->catfile( qw( t input_pod_dir ) );
ok( -d $input_dir, "Input directory is there" );

my $null = IO::Null->new;

sub speak_pod_file
	{
	my( $pod_file ) = shift;
	
	use File::Spec;
	
	my $parser = $class->new();
	isa_ok( $parser, $class );
	
	my $file = File::Spec->catfile( $input_dir, $pod_file );
	
	ok( -e $file, "Input file is there [$file]" );
	
	$parser->complain_stderr( 1 );
	$parser->output_fh( $null );
	$parser->parse_file( $file );
	}
	
1;