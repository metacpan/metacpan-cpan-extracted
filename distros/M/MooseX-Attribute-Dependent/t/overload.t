use Test::Most;
use MooseX::Attribute::Dependency;

sub All {
    my $args = shift;
    my $dep = MooseX::Attribute::Dependency->new( parameters => $args );
    return @_ ? ( $dep, @_ ) : $dep;
}

ok( All ['abc'] );
my %hash = ( dependency => All ['abc'], is => 'ro' );
is( $hash{is}, 'ro', "don't swallow params" );

done_testing;
