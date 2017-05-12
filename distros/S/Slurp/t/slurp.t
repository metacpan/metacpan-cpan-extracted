use Fcntl;
use IO::File;
use Test::More 'tests' => 6;


BEGIN {
    use_ok( 'Slurp' );
}


can_ok( 'Slurp', 'slurp', 'to_array', 'to_scalar' );

my $contents;
{
    local $/ = undef;
    $contents = <DATA>;
}
my @contents = split $/, $contents;

my $filename = 'test.text';
my $fh = IO::File->new( $filename, O_WRONLY | O_CREAT );
if ( defined $fh ) {
    print $fh $contents;
    $fh->close;
}

-e $filename ? ok( 1 ) : fail();

my @array = Slurp::to_array( $filename );
is( @array, @contents, 'Slurp::to_array (array)' );

my $array = Slurp::to_array( $filename );
ok( ref $array eq 'ARRAY', 'Slurp::to_array (arrayref)' );

is( Slurp::to_scalar( $filename ), $contents, 'Slurp::to_scalar' );


exit 0;


END {
    unlink $filename if defined $filename and -e $filename and -w $filename;
}


__DATA__
This is a temporary file which is generated as part of the testing 
procedure for the Slurp perl module and should be deleted following
the completion of the test slurp.t.  If this file persists following 
the completion of testing, it can be safely deleted.
