use Test::More;

use Data::Dumper;
sub detect{
    my $diff= shift;
    return Template::Reverse::_detect($diff);
}
BEGIN{
use_ok("Template::Reverse");
use_ok('Template::Reverse::Converter::TT2');
};

my $tt2 = Template::Reverse::Converter::TT2->new;

my $W = Template::Reverse::WILDCARD;

@diff = (qw(A B C D E));
$parts = detect(\@diff);
$temps = $tt2->Convert($parts);
is_deeply( $temps, [] );

@diff = (qw(A B ),$W,qw( D E));
$parts = detect(\@diff);
$temps = $tt2->Convert($parts);
is_deeply( $temps, ['AB[% value %]DE'] );

@diff = (qw(A B C D ),$W,qw( ));
$parts = detect(\@diff);
$temps = $tt2->Convert($parts);
is_deeply( $temps, ['ABCD[% value %]'] );

@diff = (qw(),$W,qw( B C D E));
$parts = detect(\@diff);
$temps = $tt2->Convert($parts);
is_deeply( $temps, ['[% value %]BCDE'] );

@diff = (qw(A ),$W,qw( C ),$W,qw( E));
$parts = detect(\@diff);
$temps = $tt2->Convert($parts);
is_deeply( $temps, ['A[% value %]C','C[% value %]E'] );

@diff = (qw(A B C ),$W,qw( G H I J K ),$W,qw( M N));
$parts = detect(\@diff);
$temps = $tt2->Convert($parts);
is_deeply( $temps, ['ABC[% value %]GHIJK','GHIJK[% value %]MN'] );

@diff = (qw(),$W,qw( A B C ),$W,qw( G H I J K ),$W,qw( M N ),$W,qw( ));
$parts = detect(\@diff);
$temps = $tt2->Convert($parts);
is_deeply( $temps, ['[% value %]ABC','ABC[% value %]GHIJK','GHIJK[% value %]MN','MN[% value %]'] );


@diff = (qw(I went to the ),$W,qw( when i had met the ),$W);
@diff = map{$_,' '}@diff;
$parts = detect(\@diff);
$temps = $tt2->Convert($parts);
is_deeply( $temps, [
          'I went to the [% value %] when i had met the ',
          ' when i had met the [% value %] '
]);

done_testing();
