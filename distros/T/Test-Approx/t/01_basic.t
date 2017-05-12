use strict;
use warnings;

use lib 'lib';

use Test::More tests => 35;
use Test::Builder::Tester;

use_ok( 'Test::Approx' );

is_approx( 'abcd', 'abcd', 'equal strings' );
is_approx( 1234, 1234, 'equal integers' );
is_approx( 1.234, 1.234, 'equal decimal numbers' );
is_approx( '1.234000', '1.234', 'equal decimal numbers, extra zeros' );
is_approx( 1.0, 1, 'equal decimal number & integer' );
is_approx( 2, 2.0, 'equal integer & decimal number' );

is_approx( 'abcdefgh', 'abcdefg', 'approx strings' );
is_approx( 1.0, 1, 'approx decimal number & integer' );
is_approx( 1, 1.001, 'approx given decimal number & integer' );
is_approx( 2.001, 2, 'approx given integer & decimal number' );

is_approx( 51.60334, 51.603335, 'approx decimal numbers' );
is_approx( 51, 52, 'approx integers' );

is_approx_num( 1, 1.05, 'approx_num: default tolerance' );
is_approx_int( 1, 2, 'approx_int: default tolerance' );
is_approx_int( 100, 105, 'approx_int: default tolerance' );

is_approx_num( '1.23e-4 abc', '1.23e-4 def', 'approx_num given numbers in string' );
is_approx_num( 'abc', 'def', 'approx_num given 2 different strings' );
is_approx_num( 333.123, 401.624, 'similar integers, high threshold', 75 );

is_approx_int( '1.987', '1.001', 'approx_int given decimal numbers' );
is_approx_int( '123 def', '123 abc', 'approx_int given numbers in string' );
is_approx_int( 'abc', 'def', 'approx_int given 2 different strings' );
is_approx_int( 333, 300, 'similar integers, high threshold', 50 );

{
    test_out('not ok 1 - diff strings');
    test_fail(+1);
    is_approx_str( 'abcdefg', 'gfedcba', 'diff strings' );
    test_diag( "  test: 'abcdefg' =~ 'gfedcba'" );
    test_diag( "  error: edit distance (6) was greater than threshold (1)");
    test_test('completely different strings');
}

{
    test_out('not ok 1 - approx_num: tolerance');
    test_fail(+1);
    is_approx_num( 1, 1.1, 'approx_num: tolerance' );
    test_diag( "  test: '1' =~ '1.1'" );
    test_diag( "  error: distance (0.1) was greater than threshold (0.05)");
    test_test('approx_num: tolerance');
}

{
    test_out('not ok 1 - approx_int: tolerance');
    test_fail(+1);
    is_approx( 100, 106, 'approx_int: tolerance' );
    test_diag( "  test: '100' =~ '106'" );
    test_diag( "  error: distance (6) was greater than threshold (5)");
    test_test('approx_int: tolerance');
}



{
    test_out('not ok 1 - approx_str given equal decimal numbers, extra zeros');
    test_fail(+1);
    is_approx_str( '1.234000', '1.234', 'approx_str given equal decimal numbers, extra zeros' );
    test_diag( "  test: '1.234000' =~ '1.234'" );
    test_diag( "  error: edit distance (3) was greater than threshold (1)");
    test_test('approx_str given equal decimal numbers, extra zeros');
}

{
    my ($str1, $str2) = ('abcdefghijklmnopqrstuvwxyz', 'abcdef ijklmmopqrstuvwxyz');
    is_approx( $str1, $str2, 'similar strings, 20% threshold', '20%' );

    test_out('not ok 1 - similar strings, 10% threshold');
    test_fail(+1);
    is_approx( $str1, $str2, 'similar strings, 10% threshold', '10%' );
    test_diag( "  test: 'abcde...' =~ 'abcde...'" );
    test_diag( "  error: edit distance (3) was greater than threshold (2)");
    test_test('similar strings, 10% threshold');
}

{
    # try a big string... that's what this module is for
    my $str1 = '_gkxEv}|vNyB{CwA}@kKg@sAsBcB_@w@q@}AsCMwCr@yEl@gdA_MaBqJ[yBk@aPm[oBqAgAKu@aAOuANa@lA]Fi@q@mAFsC{@kEgBnFUdEiGbL]H\\mGtCaI?uAlAsHlAsDjH_D|EmA~@VvJwCTeAdD_CuArHBpBmAl@IfAVn@lCh@p@KdHqJnChJ?hB\\ZdC?lCp@hBFjFkDe@KMk@L}BlGFK}AsB~B_AJwCzCk@BsAnB_AJ_F`DmDaFM_JsBeAfAgAGoCxJjIv@HjHoBn@e@p@wCxA^dAUfCeDjG}DYaAkIcFcC{@QuCdCcEJyI[iKwAUyEoOoSC{Cd@cApHkCyDuSkAaPbAeLnFkGrB{DdDsBL_A{@kC]}EsBp@yB@gIqA}FAw@c@E{CvAiEcEgLs@i@kDtAg@c@q@eQuCyJ{@k@mCCm@w@wCuNm@_@eIWoBiA}A{D]wC_BwE_AgS]{@kFuCcABkBnB}AhIoDjDcCxAoAJ{JyCoDNoAa@cD{HiG_FaCBuElAq@kHZqPUwC_A_CiMlD{BFeC}@{@{@wA{DuFRyB]iCkDsBsAyBh@mEtC}BTcC_@uJiOe@aKk@cAsBgA{DWqB{@_DoDyFuLcHaDaBwBsEoPCwAlAaCr@e@lGwBn@cCQwC_EcNUqCTmC~CwKnAwBnBuAjSaFbFmHzFwD~CyEnH]tDqAnEkHhHwGD}Cm@cDyAcC}FaCcCuIoBmAyFv@mK~G_Cx@yJ`AsBe@yHyJwKcDmCcC]cAr@aEFyCbBaJq@mCaB_B{DF}Hw@aBxAi@lCiAtB_AL}HuCgG{@sBqA{CqF_@{Cf@cDvEqI|@oHgAaCwHmCe@_AVaISyCqDiI_GwEYyCvBgHCeFXaAvBqAdIg@hBaAlAwBn@oIq@sF{DyEkCu@qE[a@o@UyCn@sHQaAy@m@eAMuJhCwBA_CeEaEaA}OsJ_CwC_AeCGgAr@cFUyCyFsF_EeAsKhA{DEiTmEcBeBuE{M_H_L?cDlAkHY}CuAmEGyCfHqQl@yYv@mCr@q@hCg@hPdC`C?jNmE~Ld@xFs@zGsCtJkGnAkBOkC}AyAeDmAeLiBgKuJyBzB}@HiR_@sQsFgByAoAcHmAoBuWBkBy@b@ZoAoA}@eCe@gC]gK}BwF_L}HuGuH}LoJ}CeGkEgO_CsDkDoBiIaAgBmAsDwEiF{BgEuD{JcE]cA?kFg@_DaAgCoCyD}FuDqIoCuDsBwJ}AuFwDaBe@{DMsFhAw@Y{@kAg@oKsFeNgAeJkBsCuPeEaG_CkH_F{IiIeCe@wFCqA}AsAsGaByAcEQgYzG{@KqA}Bw@oI{BmMd@{@xA}AbFuClIiIfFmLrK{DzFwEbF{BfByAdHyJbBmGvAeBrBO~Db@xBc@`A}BtAeHhCgGz@mLlCoHhDaErIqDxCeE`@_DUgCuFoIm@yCDuAvDsI`BaHbDqFdBqGv@_@|Fp@xAoB?uAkD_Nw@uF|DiV`BgB~BgAxHeBn@eAh@}CKkDuDcFWoAm@_KHkHhAsC`ByBrIeGvDiG~faC~LsHJoAwIt@cHKu@d@kA`CcBdBgRnIyGbGwBt@{KEm@e@U{CdByNw@uEaBsAoFVkF{@{@T}DnDiKrDuJ`@{@e@a@{@]{Cc@w@eHyAoFgF{@WyMJkJ{@wD_AuH|@oHEsFgO_B{AcF}BgC\\oFfC{@Bs@a@sHwM_F}CaKY{KhEaGrDC_ApBsAtB_ETkCc@{@cE_sDkHsDmEwE{BoDY{DoHTevBHxAxAm@f@y@E';
    my $str2 = '_gkxEv{|vNyB{CwA}@Khg@sAsBcB_@w@q@}sCMwCr@yEl@gdA_MaBqJ[yBk@aPm[oBqAgAKu@aAOuANa@lA]Fi@q@mAFsC{@kEgBnFUdEiGbL]H\\mGtCaI?uAlAsHlAsDjH_D|EmA~@VvJwCTeAdD_CuArHBpBmAl@IfAVn@lChp@KdHqJnChJ?hB\\ZdC?lCp@hBFjFkDe@KMk@L}BlGuFK}AsB~B_AJwCzCk@BsAnB_AJ_F`DmDaFM_JsBeAfAgAGoCxJjv@HjHoBn@e@p@wCxA^dAUfCeDjG}DYaAkIcJaFcC{@QuCdCcEJyI[iKwAUyEoOoSC{Cd@cApHkCyDuSkAaPbAeLnFkGrDdDsBL_A{@kC]}EsBp@yB@gIqA}FAw@c@E{CvAiEcEgLs@i@kDtAg@c@q@eQuCyJ{@k@mCCm@w@wCuNm@_@eIWoBiA}A{D]wC_BwE_AgS]{@kFuCcABkBnB}AhIoDjDcCxAoAJ{JyCoDNfoAa@cD{HiG_FaCBatsuElkHZqPUwC_A_CiMlD{BFeC}@{@{@wA{DuFRyB]iCkDsBsAyBh@mEtC}BTcC_@uJiOe@aKk@cAsBgA{DWqB{@_DoDyFuLcHaDaBwBsEoPCwAlAaCr@e@lGwBn@cCQwC_EcNUqCTmC~CwKnAwBnBuAjSaFbFmHzFwD~CyEnH]tDqAnEkHhHwGD}Cm@cDyAcC}FaCcCuIoBmAyFv@mK~G_Cx@yJ`AsBe@yHyJwKcDmCcC]cAr@aEFyCbBaJq@mCaB_B{DF}Hw@aBxAi@L}HugG{@sBqA{CqF_@{Cf@cDvEqI|@oHgAaCwHmCe@_AVaISyCqDiI_GwEYyCvBgHCeFXaAvBqAdIg@hBaAlAwBn@oIq@sF{DyEkCu@qE[a@o@UyCn@sHQaAy@m@eAMuJhCwBA_CeEaEaA}OsJ_CwC_AeCGgAr@cFUyCyFsF_EeAsKhA{DEiTmEcBeBuE{M_H_L?cDlAkHY}CuAmEGyCfHqQl@yYv@mCr@q@hCg@hPdC`C?jNmE~Ld@xFs@zGsCtJkGnAkBOkC}AyAeDmAeLiBgKuJyBzB}@HiR_@sQsFgByAoAcHmAoBuWBkBy@b@ZoAoA}@eCe@gC]gK}BwF_L}HuGuH}LoJ}CeGkEgO_CsDkDoBiIaAgBmAsDwEiF{BgEuD{JcE]cA?kFg@_DaAgCoCyD}FuDqIoCuDsBwJ}AuFwDaBe@{DMssFhAw@Y{@kAg@oKsFeNgeJkBsCuPeEaG_CkH_F{IiIeCe@wFCqA}AsAsGaByAcEQgYzG{@KqAw@oI{BmMd@{@xA}AlFuClIiIflFmLrK{DzFwEbF{BfByAdHyJbmGvAeBrBO~Db@xBc@`A}BtAeHhCgGz@mLlCoHhDaErIqDxCeE`@_DUgCuFoIm@yCDuAvDsI`BaHbDqFdjqGv@_@|Fp@xAoB?uAkD_Nw@uFjDiV`BgB~BgAxHeBn@eAd@}CKkDuDcFWoAm@_KHkHhAsC`ByBrIeGvDiG~jaC~LsHJoAwIt@cHKu@d@kA`CcBdBgRnIyGbGwBt@sdfhgEm@e@U{CdByNw@uEaBsAoFVkFsd{@{@T}DnDiKrDuJ`@{@e@a@{@]{Cc@w@eHyAoF{@WyMJkasdf{@wD_AuH|@oHEsFgO_B{AcF}BgC\\oFfC{@Bs@a@sHwM_F}CaKY{KhEaGrDC_ApBsAasdf_ETkCc@{@cE_DsDkHsDmEwE{BoDY{DoHTeAvBHxAxAm@f@y@E';
    is_approx( $str1, $str2, 'big strings, default threshold' );
}

{
    test_out('not ok 1 - completely different decimal numbers');
    test_fail(+1);
    is_approx_num( -51.6033, 51.6033, 'completely different decimal numbers' );
    test_diag( "  test: '-51.6033' =~ '51.6033'" );
    test_diag( "  error: distance (103.2066) was greater than threshold (2.580165)");
    test_test('completely different decimal numbers');
}

{
    test_out('not ok 1 - different decimal numbers with threshold');
    test_fail(+1);
    is_approx_num( -51.6033, 51.6033, 'different decimal numbers with threshold', 1e-05 );
    test_diag( "  test: '-51.6033' =~ '51.6033'" );
    test_diag( "  error: distance (103.2066) was greater than threshold (1e-05)");
    test_test('completely different decimal numbers');
}

is_approx_num( -456.333, -430, 'similar integers, high threshold', 50 );

{
    test_out('not ok 1 - completely different integers');
    test_fail(+1);
    is_approx_int( 5, 33, 'completely different integers' );
    test_diag( "  test: '5' =~ '33'" );
    test_diag( "  error: distance (28) was greater than threshold (1)");
    test_test('completely different integers');
}

{
    test_out('not ok 1 - different integers, bigger first num');
    test_fail(+1);
    is_approx_int( 345, 5, 'different integers, bigger first num' );
    test_diag( "  test: '345' =~ '5'" );
    test_diag( "  error: distance (340) was greater than threshold (17)");
    test_test('different integers, bigger first num');
}

