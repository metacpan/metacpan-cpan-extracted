
use 5.010;
use Test::More 0.88;

use PPI;
use PPIx::Literal;

{
    my $doc    = PPI::Document->new( \q{(1, "one", 'two')} );
    my @values = PPIx::Literal->convert($doc);
    is_deeply( \@values, [ 1, 'one', 'two' ] );
}
{
    my $doc    = PPI::Document->new( \q{ [ 3.14, 'exp', { one => 1 } ] } );
    my @values = PPIx::Literal->convert($doc);
    is_deeply( \@values, [ [ 3.14, 'exp', { one => 1 } ] ] );
}
{
    my $doc    = PPI::Document->new( \q{use zim 'Carp' => qw(carp croak)} );
    my ($use)  = $doc->children;
    my @values = PPIx::Literal->convert( $use->arguments );
    is_deeply( \@values, [ 'Carp', 'carp', 'croak' ] );
}

done_testing;
