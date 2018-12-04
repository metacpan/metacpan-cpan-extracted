use Test::More;
use Data::Printer;
use Test::MockObject;

if ( $OSNAME =~ /win/ ) {
    unless ( $OSNAME =~ /cygwin/ ) {
        BAIL_OUT(
            'Windows is not a currently supported OS. 
		Cygwin might work but not ActivePerl or Strawberry Perl.'
        );
    }
}

use_ok(Pg::BulkLoad);

my %args = (
    pg        => Test::MockObject->new(),
    errorfile => '/tmp/pgbulk.error',
);

my $pgc = Pg::BulkLoad->new(%args);

isa_ok( $pgc, 'Pg::BulkLoad' );
can_ok( $pgc, 'new' );
can_ok( $pgc, 'load' );

done_testing();
