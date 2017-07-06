use Test::More;

sub detect{
    my $diff= shift;
    return Template::Reverse::_detect($diff, 10);
}
BEGIN{
use_ok("Template::Reverse");
use_ok('Template::Reverse::Converter::TT2');
};

my $tt2 = Template::Reverse::Converter::TT2->new;

@diff = (BOF, qw(A B C D E), EOF);
$parts = detect(\@diff);
$temps = $tt2->Convert($parts);
is_deeply( $temps, [] );

@diff = (BOF, qw(A B ),WILDCARD,qw( D E), EOF);
$parts = detect(\@diff);
$temps = $tt2->Convert($parts);
is_deeply( $temps, ['AB[% value %]DE'] );

@diff = (BOF, qw(A B C D ),WILDCARD,EOF);
$parts = detect(\@diff);
$temps = $tt2->Convert($parts);
is_deeply( $temps, ['ABCD[% value %]'] );

@diff = (BOF,WILDCARD,qw( B C D E),EOF);
$parts = detect(\@diff);
$temps = $tt2->Convert($parts);
is_deeply( $temps, ['[% value %]BCDE'] );

@diff = (qw(A ),WILDCARD,qw( C ),WILDCARD,qw( E));
$parts = detect(\@diff);
$temps = $tt2->Convert($parts);
is_deeply( $temps, ['A[% value %]C','C[% value %]E'] );

@diff = (BOF,qw(A B C ),WILDCARD,qw( G H I J K ),WILDCARD,qw( M N), EOF);
$parts = detect(\@diff);
$temps = $tt2->Convert($parts);
is_deeply( $temps, ['ABC[% value %]GHIJK','GHIJK[% value %]MN']);

@diff = (BOF,WILDCARD,qw( A B C ),WILDCARD,qw( G H I J K ),WILDCARD,qw( M N ),WILDCARD,EOF);
$parts = detect(\@diff);
$temps = $tt2->Convert($parts);
is_deeply( $temps, ['[% value %]ABC','ABC[% value %]GHIJK','GHIJK[% value %]MN','MN[% value %]'] );


@diff = (BOF,q(I went to the ),WILDCARD,q( when i had met the ), WILDCARD, EOF);
$parts = detect(\@diff);
$temps = $tt2->Convert($parts);
is_deeply( $temps, [
          'I went to the [% value %] when i had met the ',
          ' when i had met the [% value %]'
]);

done_testing();
