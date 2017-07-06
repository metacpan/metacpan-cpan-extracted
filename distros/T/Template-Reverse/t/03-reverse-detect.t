use Test::More;

BEGIN{
use_ok('Template::Reverse');
}
sub detect{
my $diff= shift;
my $r = Template::Reverse::_detect($diff, 10);
return $r;
}



@diff = (BOF, qw(A B C D E), EOF);
$patt = detect(\@diff);
is_deeply($patt, [] ) ;

@diff = (BOF, qw(A B),WILDCARD,qw(D E), EOF);
$patt = detect(\@diff);
is_deeply($patt, [ {pre=>[BOF,qw(A B)],post=>[qw(D E),EOF]} ] ) ;

@diff = (BOF,qw(A B C D),WILDCARD,EOF);
$patt = detect(\@diff);
is_deeply($patt, [ {pre=>[BOF,qw(A B C D)],post=>[EOF]} ] ) ;

@diff = (BOF,WILDCARD,qw(B C D E),EOF);
$patt = detect(\@diff);
is_deeply($patt, [ {pre=>[BOF],post=>[qw(B C D E), EOF]} ] ) ;


@diff = (BOF,WILDCARD,qw(C),WILDCARD,qw(E),EOF);
$patt = detect(\@diff);
is_deeply($patt, [ {pre=>[BOF],post=>[qw(C)]},{pre=>[qw(C)],post=>[qw(E),EOF]} ] ) ;

@diff = (BOF,qw(A B C),WILDCARD,qw(G H I J K),WILDCARD,qw(M N),EOF);
$patt = detect(\@diff);
is_deeply($patt, [ {pre=>[BOF,qw(A B C)],post=>[qw(G H I J K)]}, {pre=>[qw(G H I J K)],post=>[qw(M N), EOF]}] ) ;

@diff = (BOF,WILDCARD,qw( A B C),WILDCARD,qw(G H I J K),WILDCARD,qw(M N),WILDCARD,EOF);
$patt = detect(\@diff);
is_deeply($patt, [ {pre=>[BOF],post=>[qw(A B C)]},{pre=>[qw(A B C)],post=>[qw(G H I J K)]}, {pre=>[qw(G H I J K)],post=>[qw(M N)]}, {pre=>[qw(M N)],post=>[EOF]}] ) ;


@diff = (BOF,qw(I went to the),WILDCARD,qw(when i had met the),WILDCARD,EOF);
$patt = detect(\@diff);
is_deeply($patt, 
        [
          {
            pre=>
            [
              BOF,
              'I',
              'went',
              'to',
              'the'
            ],
            post=>
            [
              'when',
              'i',
              'had',
              'met',
              'the'
            ]
          },
          {
            pre=>
            [
              'when',
              'i',
              'had',
              'met',
              'the'
            ],
            post=>
            [EOF]
          }
        ]);

done_testing();
