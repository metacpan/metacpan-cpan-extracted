use Test::More;

BEGIN{
use_ok('Template::Reverse');
}
use Data::Dumper;
sub detect{
    my $diff= shift;
    my $r = Template::Reverse::_detect($diff, 3);
    return [map{$_->as_arrayref}@{$r}];
}

my $W = Template::Reverse::WILDCARD;

@diff = qw(A B C D E);
$patt = detect(\@diff);
is_deeply($patt, [], 'A B C D E' ) ;

@diff = ('A','B', $W, 'D', 'E');
$patt = detect(\@diff);
is_deeply($patt, [ [[qw(A B)],[qw(D E)]] ] ) ;

@diff = (qw(A B C D ), $W);
$patt = detect(\@diff);
is_deeply($patt, [ [[qw(B C D)],[]] ] ) ;

@diff = ($W,qw( B C D E));
$patt = detect(\@diff);
is_deeply($patt, [ [[],[qw(B C D)]] ] ) ;

@diff = ('A',$W,'C',$W,'E');
$patt = detect(\@diff);
is_deeply($patt, [ [[qw(A)],[qw(C)]], [[qw(C)],[qw(E)]]] ) ;

@diff = (qw(A B C),$W,qw(G H I J K),$W,qw(M N));
$patt = detect(\@diff);
is_deeply($patt, [ [[qw(A B C)],[qw(G H I)]], [[qw(I J K)],[qw(M N)]]] ) ;

@diff = (qw(Q A B C),$W,qw(G H I J K),$W,qw(M N O P));
$patt = detect(\@diff);
is_deeply($patt, [ [[qw(A B C)],[qw(G H I)]], [[qw(I J K)],[qw(M N O)]]] ) ;

@diff = ($W,qw( A B C),$W,qw(G H I J K),$W,qw(M N),$W);
$patt = detect(\@diff);
is_deeply($patt, [ [[],[qw(A B C)]],[[qw(A B C)],[qw(G H I)]], [[qw(I J K)],[qw(M N)]], [[qw(M N)],[]]] ) ;


@diff = (qw(I went to the),$W,qw(when i had met the),$W);
$patt = detect(\@diff);
is_deeply($patt, 
        [
          [
            [
              'went',
              'to',
              'the'
            ],
            [
              'when',
              'i',
              'had',
            ]
          ],
          [
            [
              'had',
              'met',
              'the'
            ],
            []
          ]
        ]);

done_testing();
