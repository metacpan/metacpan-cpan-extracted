#!perl -T

use Test::More ;#tests => 1;

BEGIN {
    use_ok( 'String::Validator::Phone::NANP' ) || print "Bail out!\n";
}

diag( "Testing String::Validator::Phone::NANP $String::Validator::Phone::NANP::VERSION, Perl $], $^X" );

#stringset
# 0 original -- 1 clean-alpha-on -- 2 mustbe-res -- 3 clean-alpha-off -- 4 mustbe-res
my @Stringset = (
    [ '+1 202 418 1440', '202-418-1440', 1, '202-418-1440', 1 ],
    [ '1 202 418 1440',  '202-418-1440', 1, '202-418-1440', 1 ],
    [ '202 418 1440',    '202-418-1440', 1, '202-418-1440', 1 ],
    [ '(202) 418-1440',  '202-418-1440', 1, '202-418-1440', 1 ],
    [ '(202)418-1440',   '202-418-1440', 1, '202-418-1440', 1 ],
    [ '202.418.1440',    '202-418-1440', 1, '202-418-1440', 1 ],
    [ '202-418-1440',    '202-418-1440', 1, '202-418-1440', 1 ],
    [ '202 418 1440',    '202-418-1440', 1, '202-418-1440', 1 ],
    [ '12024181440',     '202-418-1440', 1, '202-418-1440', 1 ],
    [ '786-3162',        '786-316-2', 0, '786-316-2', 0 ],
    [ '718-1786-3162',   '718-178-63162', 0, '718-178-63162', 0 ],
    [ '1 (212) MU7-WXYZ' , '212-687-9999',  1, '212-7-', 0, 1 ],
    [ '415-AKA-THEM' , '415-252-8436', 1, '415--', 0, 1 ],
    [ '1-415-AKA-THEM' , '415-252-8436', 1,  '415--', 0, 1 ] ,
    [ '+1 (609) Adi-JMPT' , '609-234-5678', 1, '609--', 0, 1 ] ,
    [ '777-QRS-TUV8', '777-777-8888', 1, '777-8-', 0 ] ,
    ) ;

my $Validator = String::Validator::Phone::NANP->new() ;
foreach my $string ( @Stringset ) {
    my $b = 2 ;
    my $noalpha = String::Validator::Phone::NANP::_clean( $string->[0], 0 ) ;
    is( $noalpha , $string->[3],
        "ALPHA OFF $string->[0] >> $string->[3]" ) ;
    $b =$Validator->_must_be10( $noalpha ) ;
    is( $b , $string->[4] ,
    "$string->[0] 10 char check with alpha OFF. $noalpha - $b" ) ;
    my $alpha = String::Validator::Phone::NANP::_clean( $string->[0], 1 ) ;
    is( $alpha , $string->[1],
        "ALPHA ON $string->[0] >> $string->[1]" ) ;
    $b =$Validator->_must_be10( $alpha ) ;
    is( $b , $string->[2] ,
    "$string->[0] 10 char check with alpha ON. $alpha - $b" ) ;
}

done_testing() ;