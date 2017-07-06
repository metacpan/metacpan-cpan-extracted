use Test::More;

BEGIN{
use_ok('Template::Reverse');
}
sub detect{
    my $diff= shift;
    my $r = Template::Reverse::_detect($diff, 3);
    return $r;
}

@diff = qw(BOF A B C D E EOF);
$patt = detect(\@diff);
is_deeply($patt, [], 'A B C D E' ) ;

@diff = (BOF, 'A','B', WILDCARD, 'D', 'E', EOF);
$patt = detect(\@diff);
is_deeply($patt, [ {pre=>[BOF, qw(A B)], post=>[qw(D E), EOF]} ] ) ;

@diff = (BOF, qw(A B C D), WILDCARD, EOF);
$patt = detect(\@diff);
is_deeply($patt, [ {pre=>[qw(B C D)],post=>[EOF]} ] ) ;

@diff = (BOF,WILDCARD,qw(B C D E),EOF);
$patt = detect(\@diff);
is_deeply($patt, [ {pre=>[BOF],post=>[qw(B C D)]} ]) ;

@diff = ('A',WILDCARD,'C',WILDCARD,'E');
$patt = detect(\@diff);
is_deeply($patt, [ {pre=>[qw(A)],post=>[qw(C)]}, {pre=>[qw(C)],post=>[qw(E)]} ] ) ;

@diff = (qw(A B C),WILDCARD,qw(G H I J K),WILDCARD,qw(M N));
$patt = detect(\@diff);
is_deeply($patt, [ {pre=>[qw(A B C)],post=>[qw(G H I)]}, {pre=>[qw(I J K)],post=>[qw(M N)]} ] ) ;

@diff = (qw(Q A B C),WILDCARD,qw(G H I J K),WILDCARD,qw(M N O P));
$patt = detect(\@diff);
is_deeply($patt, [ {pre=>[qw(A B C)],post=>[qw(G H I)]}, {pre=>[qw(I J K)],post=>[qw(M N O)]}] ) ;

@diff = (BOF,WILDCARD,qw( A B C),WILDCARD,qw(G H I J K),WILDCARD,qw(M N),WILDCARD,EOF);
$patt = detect(\@diff);
is_deeply($patt, [ {pre=>[BOF],post=>[qw(A B C)]},{pre=>[qw(A B C)],post=>[qw(G H I)]}, {pre=>[qw(I J K)],post=>[qw(M N)]}, {pre=>[qw(M N)],post=>[EOF]}] ) ;


@diff = (BOF, qw(I went to the),WILDCARD,qw(when i had met the),WILDCARD, EOF);
$patt = detect(\@diff);
is_deeply($patt, 
        [
          {pre=>
            [
              'went',
              'to',
              'the'
            ],
            post=>
            [
              'when',
              'i',
              'had',
            ]
          },
          {pre=>
            [
              'had',
              'met',
              'the'
            ],
            post=>
            [EOF]
          }
        ]);

done_testing();
