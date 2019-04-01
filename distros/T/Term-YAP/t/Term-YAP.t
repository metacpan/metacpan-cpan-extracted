use strict;
use warnings;
use Test::More;
use Moose 2.1604;
use Test::Moose 2.1604;
use Term::YAP;
use Test::Exception 0.43;
use Test::TempDir::Tiny 0.018;
use IO::File;
use File::Spec;

my @attributes = qw(size start_time usleep name rotatable time running output);

#plan tests => scalar(@attributes) + 1;

foreach my $attrib (@attributes) {
    has_attribute_ok( 'Term::YAP', $attrib );
}

can_ok( 'Term::YAP',
    qw(get_size _set_start _set_start _get_usleep BUILD start _is_enough _keep_pulsing stop _report is_running _set_running to_output _set_output)
);

my $dir      = tempdir();
my $filename = File::Spec->catfile( $dir, 'output.txt' );
my $output   = IO::File->new( $filename, '>' );
my $t        = Term::YAP->new( { output => $output } );

ok( $t,           'have a proper instance' );
ok( !$t->start(), 'returns false when invoking start()' );

dies_ok { $t->_is_enough } '_is_enough() requires overriding';
like(
    $@,
    qr/method must be overrided by subclasses/m,
    'got expected error message'
);

my $data;

# explicit close to force flush on the file handle
$output->close();

{
    local $/;
    open( my $fh, '<', $filename ) or die "Cannot read $filename: $!";
    $data = <$fh>;
    close($fh);
}
like( $data, qr/Working.................Done/m, 'got expected report' )
  or diag( explain($data) );
note('Testing now with rotatable = 1');
my $t2 = Term::YAP->new( { output => $output, rotatable => 1 } );
ok( $t2,           'have a proper instance' );
ok( !$t2->start(), 'returns false when invoking start()' );

# explicit close to force flush on the file handle
$output->close();

{
    local $/;
    open( my $fh, '<', $filename ) or die "Cannot read $filename: $!";
    $data = <$fh>;
    close($fh);
}
like( $data, qr/Working.................Done/m, 'report is the same' )
  or diag( explain($data) );

note('Testing now with time = 1');
my $t3 = Term::YAP->new( { output => $output, time => 1 } );
ok( $t3,           'have a proper instance' );
ok( !$t3->start(), 'returns false when invoking start()' );

# explicit close to force flush on the file handle
$output->close();

{
    local $/;
    open( my $fh, '<', $filename ) or die "Cannot read $filename: $!";
    $data = <$fh>;
    close($fh);
}
like( $data, qr/Working.................Done/m, 'report is the same' )
  or diag( explain($data) );

done_testing;
