#!/usr/bin/perl

# Before 'make install' is performed this script should be runnable with
# 'make test'. After 'make install' it should work as 'perl Regexp-CharClasses-Thai.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use 5.008;
use utf8;
use strict;
use warnings;
use FindBin qw($Bin);
use lib "$Bin/lib";
use blib './lib/';
use Regexp::CharClasses::Thai qw( :all );

use Test::More;

binmode STDOUT, ":utf8";

BEGIN {plan tests => 208};

# TWO TESTS FOR MODULE USES
BEGIN {use_ok('Regexp::CharClasses::Thai')};


# TEN TESTS WITH INTHAI
my $inthai = &InThai;
is( $inthai =~ /\b0E01\b/,1,' Match for  \$inthai =~ /\b0E01\b/');
is( $inthai =~ /\b0E02\b/,1,' Match for  \$inthai =~ /\b0E02\b/');
is( $inthai =~ /\b0E03\b/,1,' Match for  \$inthai =~ /\b0E03\b/');
is( $inthai =~ /\b0E04\b/,1,' Match for  \$inthai =~ /\b0E04\b/');
is( $inthai =~ /\b0E05\b/,1,' Match for  \$inthai =~ /\b0E05\b/');
is( $inthai =~ /\b0F01\b/,'',' Match for  \$inthai =~ /\b0E01\b/');
is( $inthai =~ /\b0F02\b/,'',' Match for  \$inthai =~ /\b0E02\b/');
is( $inthai =~ /\b0F03\b/,'',' Match for  \$inthai =~ /\b0E03\b/');
is( $inthai =~ /\b0F04\b/,'',' Match for  \$inthai =~ /\b0E04\b/');
is( $inthai =~ /\b0F05\b/,'',' Match for  \$inthai =~ /\b0E05\b/');

# ONE TEST FOR A VOWEL CLASS
my $vowels = &InThaiVowel; is( $vowels =~ /\b0E40\b/,1,' Match for  $vowels =~ /\b0E40\b/');


my $a_InThaiCons      = prepCodepointsArray(&InThaiCons);      is( $a_InThaiCons,46,' Check count of codepoints in InThaiCons'); 
my $a_InThaiHCons     = prepCodepointsArray(&InThaiHCons);     is( $a_InThaiHCons,11,' Check count of codepoints in InThaiHCons'); 
my $a_InThaiMCons     = prepCodepointsArray(&InThaiMCons);     is( $a_InThaiMCons,9,' Check count of codepoints in InThaiMCons'); 
my $a_InThaiLCons     = prepCodepointsArray(&InThaiLCons);     is( $a_InThaiLCons,26,' Check count of codepoints in InThaiLCons'); 
my $a_InThaiFinCons   = prepCodepointsArray(&InThaiFinCons);   is( $a_InThaiFinCons,37,' Check count of codepoints in InThaiFinCons'); 
my $a_InThaiDualCons  = prepCodepointsArray(&InThaiDualCons);  is( $a_InThaiDualCons,23,' Check count of codepoints in InThaiDualCons'); 
my $a_InThaiDualC1    = prepCodepointsArray(&InThaiDualC1);    is( $a_InThaiDualC1,15,' Check count of codepoints in InThaiDualC1'); 
my $a_InThaiDualC2    = prepCodepointsArray(&InThaiDualC2);    is( $a_InThaiDualC2,8,' Check count of codepoints in InThaiDualC2'); 
my $a_InThaiConsVowel = prepCodepointsArray(&InThaiConsVowel); is( $a_InThaiConsVowel,6,' Check count of codepoints in InThaiConsVowel'); 
my $a_InThaiAlpha     = prepCodepointsArray(&InThaiAlpha);     is( $a_InThaiAlpha,65,' Check count of codepoints in InThaiAlpha'); 
my $a_InThaiWord      = prepCodepointsArray(&InThaiWord);      is( $a_InThaiWord,71,' Check count of codepoints in InThaiWord'); 
my $a_InThaiTone      = prepCodepointsArray(&InThaiTone);      is( $a_InThaiTone,4,' Check count of codepoints in InThaiTone'); 
my $a_InThaiMute      = prepCodepointsArray(&InThaiMute);      is( $a_InThaiMute,1,' Check count of codepoints in InThaiMute'); 
my $a_InThaiPunct     = prepCodepointsArray(&InThaiPunct);     is( $a_InThaiPunct,5,' Check count of codepoints in InThaiPunct'); 
my $a_InThaiCurrency  = prepCodepointsArray(&InThaiCurrency);  is( $a_InThaiCurrency,1,' Check count of codepoints in InThaiCurrency'); 
my $a_InThaiDigit     = prepCodepointsArray(&InThaiDigit);     is( $a_InThaiDigit,10,' Check count of codepoints in InThaiDigit'); 
my $a_InThaiVowel     = prepCodepointsArray(&InThaiVowel);     is( $a_InThaiVowel,24,' Check count of codepoints in InThaiVowel'); 
my $a_InThaiCompVowel = prepCodepointsArray(&InThaiCompVowel); is( $a_InThaiCompVowel,10,' Check count of codepoints in InThaiCompVowel'); 
my $a_InThaiPreVowel  = prepCodepointsArray(&InThaiPreVowel);  is( $a_InThaiPreVowel,5,' Check count of codepoints in InThaiPreVowel'); 
my $a_InThaiPostVowel = prepCodepointsArray(&InThaiPostVowel); is( $a_InThaiPostVowel,4,' Check count of codepoints in InThaiPostVowel'); 


# ONE TEST FOR EACH NAMED CHARACTER (88)
my $f_IsKokai          = &IsKokai         ; is( $f_IsKokai          =~ /\b0E01\b/,1,' Match for \$f_IsKokai          =~ /\b0E01\b/');
my $f_IsKhokhai        = &IsKhokhai       ; is( $f_IsKhokhai        =~ /\b0E02\b/,1,' Match for \$f_IsKhokhai        =~ /\b0E02\b/');
my $f_IsKhokhuat       = &IsKhokhuat      ; is( $f_IsKhokhuat       =~ /\b0E03\b/,1,' Match for \$f_IsKhokhuat       =~ /\b0E03\b/');
my $f_IsKhokhwai       = &IsKhokhwai      ; is( $f_IsKhokhwai       =~ /\b0E04\b/,1,' Match for \$f_IsKhokhwai       =~ /\b0E04\b/');
my $f_IsKhokhon        = &IsKhokhon       ; is( $f_IsKhokhon        =~ /\b0E05\b/,1,' Match for \$f_IsKhokhon        =~ /\b0E05\b/');
my $f_IsKhorakhang     = &IsKhorakhang    ; is( $f_IsKhorakhang     =~ /\b0E06\b/,1,' Match for \$f_IsKhorakhang     =~ /\b0E06\b/');
my $f_IsNgongu         = &IsNgongu        ; is( $f_IsNgongu         =~ /\b0E07\b/,1,' Match for \$f_IsNgongu         =~ /\b0E07\b/');
my $f_IsChochan        = &IsChochan       ; is( $f_IsChochan        =~ /\b0E08\b/,1,' Match for \$f_IsChochan        =~ /\b0E08\b/');
my $f_IsChoching       = &IsChoching      ; is( $f_IsChoching       =~ /\b0E09\b/,1,' Match for \$f_IsChoching       =~ /\b0E09\b/');
my $f_IsChochang       = &IsChochang      ; is( $f_IsChochang       =~ /\b0E0A\b/,1,' Match for \$f_IsChochang       =~ /\b0E0A\b/');
my $f_IsSoso           = &IsSoso          ; is( $f_IsSoso           =~ /\b0E0B\b/,1,' Match for \$f_IsSoso           =~ /\b0E0B\b/');
my $f_IsShochoe        = &IsShochoe       ; is( $f_IsShochoe        =~ /\b0E0C\b/,1,' Match for \$f_IsShochoe        =~ /\b0E0C\b/');
my $f_IsYoying         = &IsYoying        ; is( $f_IsYoying         =~ /\b0E0D\b/,1,' Match for \$f_IsYoying         =~ /\b0E0D\b/');
my $f_IsDochada        = &IsDochada       ; is( $f_IsDochada        =~ /\b0E0E\b/,1,' Match for \$f_IsDochada        =~ /\b0E0E\b/');
my $f_IsTopatak        = &IsTopatak       ; is( $f_IsTopatak        =~ /\b0E0F\b/,1,' Match for \$f_IsTopatak        =~ /\b0E0F\b/');
my $f_IsThothan        = &IsThothan       ; is( $f_IsThothan        =~ /\b0E10\b/,1,' Match for \$f_IsThothan        =~ /\b0E10\b/');
my $f_IsThonangmontho  = &IsThonangmontho ; is( $f_IsThonangmontho  =~ /\b0E11\b/,1,' Match for \$f_IsThonangmontho  =~ /\b0E11\b/');
my $f_IsThophuthao     = &IsThophuthao    ; is( $f_IsThophuthao     =~ /\b0E12\b/,1,' Match for \$f_IsThophuthao     =~ /\b0E12\b/');
my $f_IsNonen          = &IsNonen         ; is( $f_IsNonen          =~ /\b0E13\b/,1,' Match for \$f_IsNonen          =~ /\b0E13\b/');
my $f_IsDodek          = &IsDodek         ; is( $f_IsDodek          =~ /\b0E14\b/,1,' Match for \$f_IsDodek          =~ /\b0E14\b/');
my $f_IsTotao          = &IsTotao         ; is( $f_IsTotao          =~ /\b0E15\b/,1,' Match for \$f_IsTotao          =~ /\b0E15\b/');
my $f_IsThothung       = &IsThothung      ; is( $f_IsThothung       =~ /\b0E16\b/,1,' Match for \$f_IsThothung       =~ /\b0E16\b/');
my $f_IsThothahan      = &IsThothahan     ; is( $f_IsThothahan      =~ /\b0E17\b/,1,' Match for \$f_IsThothahan      =~ /\b0E17\b/');
my $f_IsThothong       = &IsThothong      ; is( $f_IsThothong       =~ /\b0E18\b/,1,' Match for \$f_IsThothong       =~ /\b0E18\b/');
my $f_IsNonu           = &IsNonu          ; is( $f_IsNonu           =~ /\b0E19\b/,1,' Match for \$f_IsNonu           =~ /\b0E19\b/');
my $f_IsBobaimai       = &IsBobaimai      ; is( $f_IsBobaimai       =~ /\b0E1A\b/,1,' Match for \$f_IsBobaimai       =~ /\b0E1A\b/');
my $f_IsPopla          = &IsPopla         ; is( $f_IsPopla          =~ /\b0E1B\b/,1,' Match for \$f_IsPopla          =~ /\b0E1B\b/');
my $f_IsPhophung       = &IsPhophung      ; is( $f_IsPhophung       =~ /\b0E1C\b/,1,' Match for \$f_IsPhophung       =~ /\b0E1C\b/');
my $f_IsFofa           = &IsFofa          ; is( $f_IsFofa           =~ /\b0E1D\b/,1,' Match for \$f_IsFofa           =~ /\b0E1D\b/');
my $f_IsPhophan        = &IsPhophan       ; is( $f_IsPhophan        =~ /\b0E1E\b/,1,' Match for \$f_IsPhophan        =~ /\b0E1E\b/');
my $f_IsFofan          = &IsFofan         ; is( $f_IsFofan          =~ /\b0E1F\b/,1,' Match for \$f_IsFofan          =~ /\b0E1F\b/');
my $f_IsPhosamphao     = &IsPhosamphao    ; is( $f_IsPhosamphao     =~ /\b0E20\b/,1,' Match for \$f_IsPhosamphao     =~ /\b0E20\b/');
my $f_IsMoma           = &IsMoma          ; is( $f_IsMoma           =~ /\b0E21\b/,1,' Match for \$f_IsMoma           =~ /\b0E21\b/');
my $f_IsYoyak          = &IsYoyak         ; is( $f_IsYoyak          =~ /\b0E22\b/,1,' Match for \$f_IsYoyak          =~ /\b0E22\b/');
my $f_IsRorua          = &IsRorua         ; is( $f_IsRorua          =~ /\b0E23\b/,1,' Match for \$f_IsRorua          =~ /\b0E23\b/');
my $f_IsRu             = &IsRu            ; is( $f_IsRu             =~ /\b0E24\b/,1,' Match for \$f_IsRu             =~ /\b0E24\b/');
my $f_IsLoling         = &IsLoling        ; is( $f_IsLoling         =~ /\b0E25\b/,1,' Match for \$f_IsLoling         =~ /\b0E25\b/');
my $f_IsLu             = &IsLu            ; is( $f_IsLu             =~ /\b0E26\b/,1,' Match for \$f_IsLu             =~ /\b0E26\b/');
my $f_IsWowaen         = &IsWowaen        ; is( $f_IsWowaen         =~ /\b0E27\b/,1,' Match for \$f_IsWowaen         =~ /\b0E27\b/');
my $f_IsSosala         = &IsSosala        ; is( $f_IsSosala         =~ /\b0E28\b/,1,' Match for \$f_IsSosala         =~ /\b0E28\b/');
my $f_IsSorusi         = &IsSorusi        ; is( $f_IsSorusi         =~ /\b0E29\b/,1,' Match for \$f_IsSorusi         =~ /\b0E29\b/');
my $f_IsSosua          = &IsSosua         ; is( $f_IsSosua          =~ /\b0E2A\b/,1,' Match for \$f_IsSosua          =~ /\b0E2A\b/');
my $f_IsHohip          = &IsHohip         ; is( $f_IsHohip          =~ /\b0E2B\b/,1,' Match for \$f_IsHohip          =~ /\b0E2B\b/');
my $f_IsLochula        = &IsLochula       ; is( $f_IsLochula        =~ /\b0E2C\b/,1,' Match for \$f_IsLochula        =~ /\b0E2C\b/');
my $f_IsOang           = &IsOang          ; is( $f_IsOang           =~ /\b0E2D\b/,1,' Match for \$f_IsOang           =~ /\b0E2D\b/');
my $f_IsHonokhuk       = &IsHonokhuk      ; is( $f_IsHonokhuk       =~ /\b0E2E\b/,1,' Match for \$f_IsHonokhuk       =~ /\b0E2E\b/');
my $f_IsPaiyannoi      = &IsPaiyannoi     ; is( $f_IsPaiyannoi      =~ /\b0E2F\b/,1,' Match for \$f_IsPaiyannoi      =~ /\b0E2F\b/');
my $f_IsSaraa          = &IsSaraa         ; is( $f_IsSaraa          =~ /\b0E30\b/,1,' Match for \$f_IsSaraa          =~ /\b0E30\b/');
my $f_IsMaihanakat     = &IsMaihanakat    ; is( $f_IsMaihanakat     =~ /\b0E31\b/,1,' Match for \$f_IsMaihanakat     =~ /\b0E31\b/');
my $f_IsSaraaa         = &IsSaraaa        ; is( $f_IsSaraaa         =~ /\b0E32\b/,1,' Match for \$f_IsSaraaa         =~ /\b0E32\b/');
my $f_IsSaraam         = &IsSaraam        ; is( $f_IsSaraam         =~ /\b0E33\b/,1,' Match for \$f_IsSaraam         =~ /\b0E33\b/');
my $f_IsSarai          = &IsSarai         ; is( $f_IsSarai          =~ /\b0E34\b/,1,' Match for \$f_IsSarai          =~ /\b0E34\b/');
my $f_IsSaraii         = &IsSaraii        ; is( $f_IsSaraii         =~ /\b0E35\b/,1,' Match for \$f_IsSaraii         =~ /\b0E35\b/');
my $f_IsSaraue         = &IsSaraue        ; is( $f_IsSaraue         =~ /\b0E36\b/,1,' Match for \$f_IsSaraue         =~ /\b0E36\b/');
my $f_IsSarauee        = &IsSarauee       ; is( $f_IsSarauee        =~ /\b0E37\b/,1,' Match for \$f_IsSarauee        =~ /\b0E37\b/');
my $f_IsSarau          = &IsSarau         ; is( $f_IsSarau          =~ /\b0E38\b/,1,' Match for \$f_IsSarau          =~ /\b0E38\b/');
my $f_IsSarauu         = &IsSarauu        ; is( $f_IsSarauu         =~ /\b0E39\b/,1,' Match for \$f_IsSarauu         =~ /\b0E39\b/');
my $f_IsPhinthu        = &IsPhinthu       ; is( $f_IsPhinthu        =~ /\b0E3A\b/,1,' Match for \$f_IsPhinthu        =~ /\b0E3A\b/');
my $f_IsBaht           = &IsBaht          ; is( $f_IsBaht           =~ /\b0E3F\b/,1,' Match for \$f_IsBaht           =~ /\b0E3F\b/');
my $f_IsSarae          = &IsSarae         ; is( $f_IsSarae          =~ /\b0E40\b/,1,' Match for \$f_IsSarae          =~ /\b0E40\b/');
my $f_IsSaraae         = &IsSaraae        ; is( $f_IsSaraae         =~ /\b0E41\b/,1,' Match for \$f_IsSaraae         =~ /\b0E41\b/');
my $f_IsSarao          = &IsSarao         ; is( $f_IsSarao          =~ /\b0E42\b/,1,' Match for \$f_IsSarao          =~ /\b0E42\b/');
my $f_IsSaraaimaimuan  = &IsSaraaimaimuan ; is( $f_IsSaraaimaimuan  =~ /\b0E43\b/,1,' Match for \$f_IsSaraaimaimuan  =~ /\b0E43\b/');
my $f_IsSaraaimaimalai = &IsSaraaimaimalai; is( $f_IsSaraaimaimalai =~ /\b0E44\b/,1,' Match for \$f_IsSaraaimaimalai =~ /\b0E44\b/');
my $f_IsLakkhangyao    = &IsLakkhangyao   ; is( $f_IsLakkhangyao    =~ /\b0E45\b/,1,' Match for \$f_IsLakkhangyao    =~ /\b0E45\b/');
my $f_IsMaiyamok       = &IsMaiyamok      ; is( $f_IsMaiyamok       =~ /\b0E46\b/,1,' Match for \$f_IsMaiyamok       =~ /\b0E46\b/');
my $f_IsMaitaikhu      = &IsMaitaikhu     ; is( $f_IsMaitaikhu      =~ /\b0E47\b/,1,' Match for \$f_IsMaitaikhu      =~ /\b0E47\b/');
my $f_IsMaiek          = &IsMaiek         ; is( $f_IsMaiek          =~ /\b0E48\b/,1,' Match for \$f_IsMaiek          =~ /\b0E48\b/');
my $f_IsMaitho         = &IsMaitho        ; is( $f_IsMaitho         =~ /\b0E49\b/,1,' Match for \$f_IsMaitho         =~ /\b0E49\b/');
my $f_IsMaitri         = &IsMaitri        ; is( $f_IsMaitri         =~ /\b0E4A\b/,1,' Match for \$f_IsMaitri         =~ /\b0E4A\b/');
my $f_IsMaichattawa    = &IsMaichattawa   ; is( $f_IsMaichattawa    =~ /\b0E4B\b/,1,' Match for \$f_IsMaichattawa    =~ /\b0E4B\b/');
my $f_IsThanthakhat    = &IsThanthakhat   ; is( $f_IsThanthakhat    =~ /\b0E4C\b/,1,' Match for \$f_IsThanthakhat    =~ /\b0E4C\b/');
my $f_IsGaran          = &IsGaran         ; is( $f_IsGaran          =~ /\b0E4C\b/,1,' Match for \$f_IsGaran          =~ /\b0E4C\b/');
my $f_IsNikhahit       = &IsNikhahit      ; is( $f_IsNikhahit       =~ /\b0E4D\b/,1,' Match for \$f_IsNikhahit       =~ /\b0E4D\b/');
my $f_IsYamakkan       = &IsYamakkan      ; is( $f_IsYamakkan       =~ /\b0E4E\b/,1,' Match for \$f_IsYamakkan       =~ /\b0E4E\b/');
my $f_IsFongman        = &IsFongman       ; is( $f_IsFongman        =~ /\b0E4F\b/,1,' Match for \$f_IsFongman        =~ /\b0E4F\b/');
my $f_IsThZero         = &IsThZero        ; is( $f_IsThZero         =~ /\b0E50\b/,1,' Match for \$f_IsThZero         =~ /\b0E50\b/');
my $f_IsThOne          = &IsThOne         ; is( $f_IsThOne          =~ /\b0E51\b/,1,' Match for \$f_IsThOne          =~ /\b0E51\b/');
my $f_IsThTwo          = &IsThTwo         ; is( $f_IsThTwo          =~ /\b0E52\b/,1,' Match for \$f_IsThTwo          =~ /\b0E52\b/');
my $f_IsThThree        = &IsThThree       ; is( $f_IsThThree        =~ /\b0E53\b/,1,' Match for \$f_IsThThree        =~ /\b0E53\b/');
my $f_IsThFour         = &IsThFour        ; is( $f_IsThFour         =~ /\b0E54\b/,1,' Match for \$f_IsThFour         =~ /\b0E54\b/');
my $f_IsThFive         = &IsThFive        ; is( $f_IsThFive         =~ /\b0E55\b/,1,' Match for \$f_IsThFive         =~ /\b0E55\b/');
my $f_IsThSix          = &IsThSix         ; is( $f_IsThSix          =~ /\b0E56\b/,1,' Match for \$f_IsThSix          =~ /\b0E56\b/');
my $f_IsThSeven        = &IsThSeven       ; is( $f_IsThSeven        =~ /\b0E57\b/,1,' Match for \$f_IsThSeven        =~ /\b0E57\b/');
my $f_IsThEight        = &IsThEight       ; is( $f_IsThEight        =~ /\b0E58\b/,1,' Match for \$f_IsThEight        =~ /\b0E58\b/');
my $f_IsThNine         = &IsThNine        ; is( $f_IsThNine         =~ /\b0E59\b/,1,' Match for \$f_IsThNine         =~ /\b0E59\b/');
my $f_IsAngkhankhu     = &IsAngkhankhu    ; is( $f_IsAngkhankhu     =~ /\b0E5A\b/,1,' Match for \$f_IsAngkhankhu     =~ /\b0E5A\b/');
my $f_IsKhomut         = &IsKhomut        ; is( $f_IsKhomut         =~ /\b0E5B\b/,1,' Match for \$f_IsKhomut         =~ /\b0E5B\b/');


# ONE TEST FOR EACH NAMED CHARACTER (In...) (88)
my $f_InKokai          = &InKokai         ; is( $f_InKokai          =~ /\b0E01\b/,1,' Match for \$f_InKokai          =~ /\b0E01\b/');
my $f_InKhokhai        = &InKhokhai       ; is( $f_InKhokhai        =~ /\b0E02\b/,1,' Match for \$f_InKhokhai        =~ /\b0E02\b/');
my $f_InKhokhuat       = &InKhokhuat      ; is( $f_InKhokhuat       =~ /\b0E03\b/,1,' Match for \$f_InKhokhuat       =~ /\b0E03\b/');
my $f_InKhokhwai       = &InKhokhwai      ; is( $f_InKhokhwai       =~ /\b0E04\b/,1,' Match for \$f_InKhokhwai       =~ /\b0E04\b/');
my $f_InKhokhon        = &InKhokhon       ; is( $f_InKhokhon        =~ /\b0E05\b/,1,' Match for \$f_InKhokhon        =~ /\b0E05\b/');
my $f_InKhorakhang     = &InKhorakhang    ; is( $f_InKhorakhang     =~ /\b0E06\b/,1,' Match for \$f_InKhorakhang     =~ /\b0E06\b/');
my $f_InNgongu         = &InNgongu        ; is( $f_InNgongu         =~ /\b0E07\b/,1,' Match for \$f_InNgongu         =~ /\b0E07\b/');
my $f_InChochan        = &InChochan       ; is( $f_InChochan        =~ /\b0E08\b/,1,' Match for \$f_InChochan        =~ /\b0E08\b/');
my $f_InChoching       = &InChoching      ; is( $f_InChoching       =~ /\b0E09\b/,1,' Match for \$f_InChoching       =~ /\b0E09\b/');
my $f_InChochang       = &InChochang      ; is( $f_InChochang       =~ /\b0E0A\b/,1,' Match for \$f_InChochang       =~ /\b0E0A\b/');
my $f_InSoso           = &InSoso          ; is( $f_InSoso           =~ /\b0E0B\b/,1,' Match for \$f_InSoso           =~ /\b0E0B\b/');
my $f_InShochoe        = &InShochoe       ; is( $f_InShochoe        =~ /\b0E0C\b/,1,' Match for \$f_InShochoe        =~ /\b0E0C\b/');
my $f_InYoying         = &InYoying        ; is( $f_InYoying         =~ /\b0E0D\b/,1,' Match for \$f_InYoying         =~ /\b0E0D\b/');
my $f_InDochada        = &InDochada       ; is( $f_InDochada        =~ /\b0E0E\b/,1,' Match for \$f_InDochada        =~ /\b0E0E\b/');
my $f_InTopatak        = &InTopatak       ; is( $f_InTopatak        =~ /\b0E0F\b/,1,' Match for \$f_InTopatak        =~ /\b0E0F\b/');
my $f_InThothan        = &InThothan       ; is( $f_InThothan        =~ /\b0E10\b/,1,' Match for \$f_InThothan        =~ /\b0E10\b/');
my $f_InThonangmontho  = &InThonangmontho ; is( $f_InThonangmontho  =~ /\b0E11\b/,1,' Match for \$f_InThonangmontho  =~ /\b0E11\b/');
my $f_InThophuthao     = &InThophuthao    ; is( $f_InThophuthao     =~ /\b0E12\b/,1,' Match for \$f_InThophuthao     =~ /\b0E12\b/');
my $f_InNonen          = &InNonen         ; is( $f_InNonen          =~ /\b0E13\b/,1,' Match for \$f_InNonen          =~ /\b0E13\b/');
my $f_InDodek          = &InDodek         ; is( $f_InDodek          =~ /\b0E14\b/,1,' Match for \$f_InDodek          =~ /\b0E14\b/');
my $f_InTotao          = &InTotao         ; is( $f_InTotao          =~ /\b0E15\b/,1,' Match for \$f_InTotao          =~ /\b0E15\b/');
my $f_InThothung       = &InThothung      ; is( $f_InThothung       =~ /\b0E16\b/,1,' Match for \$f_InThothung       =~ /\b0E16\b/');
my $f_InThothahan      = &InThothahan     ; is( $f_InThothahan      =~ /\b0E17\b/,1,' Match for \$f_InThothahan      =~ /\b0E17\b/');
my $f_InThothong       = &InThothong      ; is( $f_InThothong       =~ /\b0E18\b/,1,' Match for \$f_InThothong       =~ /\b0E18\b/');
my $f_InNonu           = &InNonu          ; is( $f_InNonu           =~ /\b0E19\b/,1,' Match for \$f_InNonu           =~ /\b0E19\b/');
my $f_InBobaimai       = &InBobaimai      ; is( $f_InBobaimai       =~ /\b0E1A\b/,1,' Match for \$f_InBobaimai       =~ /\b0E1A\b/');
my $f_InPopla          = &InPopla         ; is( $f_InPopla          =~ /\b0E1B\b/,1,' Match for \$f_InPopla          =~ /\b0E1B\b/');
my $f_InPhophung       = &InPhophung      ; is( $f_InPhophung       =~ /\b0E1C\b/,1,' Match for \$f_InPhophung       =~ /\b0E1C\b/');
my $f_InFofa           = &InFofa          ; is( $f_InFofa           =~ /\b0E1D\b/,1,' Match for \$f_InFofa           =~ /\b0E1D\b/');
my $f_InPhophan        = &InPhophan       ; is( $f_InPhophan        =~ /\b0E1E\b/,1,' Match for \$f_InPhophan        =~ /\b0E1E\b/');
my $f_InFofan          = &InFofan         ; is( $f_InFofan          =~ /\b0E1F\b/,1,' Match for \$f_InFofan          =~ /\b0E1F\b/');
my $f_InPhosamphao     = &InPhosamphao    ; is( $f_InPhosamphao     =~ /\b0E20\b/,1,' Match for \$f_InPhosamphao     =~ /\b0E20\b/');
my $f_InMoma           = &InMoma          ; is( $f_InMoma           =~ /\b0E21\b/,1,' Match for \$f_InMoma           =~ /\b0E21\b/');
my $f_InYoyak          = &InYoyak         ; is( $f_InYoyak          =~ /\b0E22\b/,1,' Match for \$f_InYoyak          =~ /\b0E22\b/');
my $f_InRorua          = &InRorua         ; is( $f_InRorua          =~ /\b0E23\b/,1,' Match for \$f_InRorua          =~ /\b0E23\b/');
my $f_InRu             = &InRu            ; is( $f_InRu             =~ /\b0E24\b/,1,' Match for \$f_InRu             =~ /\b0E24\b/');
my $f_InLoling         = &InLoling        ; is( $f_InLoling         =~ /\b0E25\b/,1,' Match for \$f_InLoling         =~ /\b0E25\b/');
my $f_InLu             = &InLu            ; is( $f_InLu             =~ /\b0E26\b/,1,' Match for \$f_InLu             =~ /\b0E26\b/');
my $f_InWowaen         = &InWowaen        ; is( $f_InWowaen         =~ /\b0E27\b/,1,' Match for \$f_InWowaen         =~ /\b0E27\b/');
my $f_InSosala         = &InSosala        ; is( $f_InSosala         =~ /\b0E28\b/,1,' Match for \$f_InSosala         =~ /\b0E28\b/');
my $f_InSorusi         = &InSorusi        ; is( $f_InSorusi         =~ /\b0E29\b/,1,' Match for \$f_InSorusi         =~ /\b0E29\b/');
my $f_InSosua          = &InSosua         ; is( $f_InSosua          =~ /\b0E2A\b/,1,' Match for \$f_InSosua          =~ /\b0E2A\b/');
my $f_InHohip          = &InHohip         ; is( $f_InHohip          =~ /\b0E2B\b/,1,' Match for \$f_InHohip          =~ /\b0E2B\b/');
my $f_InLochula        = &InLochula       ; is( $f_InLochula        =~ /\b0E2C\b/,1,' Match for \$f_InLochula        =~ /\b0E2C\b/');
my $f_InOang           = &InOang          ; is( $f_InOang           =~ /\b0E2D\b/,1,' Match for \$f_InOang           =~ /\b0E2D\b/');
my $f_InHonokhuk       = &InHonokhuk      ; is( $f_InHonokhuk       =~ /\b0E2E\b/,1,' Match for \$f_InHonokhuk       =~ /\b0E2E\b/');
my $f_InPaiyannoi      = &InPaiyannoi     ; is( $f_InPaiyannoi      =~ /\b0E2F\b/,1,' Match for \$f_InPaiyannoi      =~ /\b0E2F\b/');
my $f_InSaraa          = &InSaraa         ; is( $f_InSaraa          =~ /\b0E30\b/,1,' Match for \$f_InSaraa          =~ /\b0E30\b/');
my $f_InMaihanakat     = &InMaihanakat    ; is( $f_InMaihanakat     =~ /\b0E31\b/,1,' Match for \$f_InMaihanakat     =~ /\b0E31\b/');
my $f_InSaraaa         = &InSaraaa        ; is( $f_InSaraaa         =~ /\b0E32\b/,1,' Match for \$f_InSaraaa         =~ /\b0E32\b/');
my $f_InSaraam         = &InSaraam        ; is( $f_InSaraam         =~ /\b0E33\b/,1,' Match for \$f_InSaraam         =~ /\b0E33\b/');
my $f_InSarai          = &InSarai         ; is( $f_InSarai          =~ /\b0E34\b/,1,' Match for \$f_InSarai          =~ /\b0E34\b/');
my $f_InSaraii         = &InSaraii        ; is( $f_InSaraii         =~ /\b0E35\b/,1,' Match for \$f_InSaraii         =~ /\b0E35\b/');
my $f_InSaraue         = &InSaraue        ; is( $f_InSaraue         =~ /\b0E36\b/,1,' Match for \$f_InSaraue         =~ /\b0E36\b/');
my $f_InSarauee        = &InSarauee       ; is( $f_InSarauee        =~ /\b0E37\b/,1,' Match for \$f_InSarauee        =~ /\b0E37\b/');
my $f_InSarau          = &InSarau         ; is( $f_InSarau          =~ /\b0E38\b/,1,' Match for \$f_InSarau          =~ /\b0E38\b/');
my $f_InSarauu         = &InSarauu        ; is( $f_InSarauu         =~ /\b0E39\b/,1,' Match for \$f_InSarauu         =~ /\b0E39\b/');
my $f_InPhinthu        = &InPhinthu       ; is( $f_InPhinthu        =~ /\b0E3A\b/,1,' Match for \$f_InPhinthu        =~ /\b0E3A\b/');
my $f_InBaht           = &InBaht          ; is( $f_InBaht           =~ /\b0E3F\b/,1,' Match for \$f_InBaht           =~ /\b0E3F\b/');
my $f_InSarae          = &InSarae         ; is( $f_InSarae          =~ /\b0E40\b/,1,' Match for \$f_InSarae          =~ /\b0E40\b/');
my $f_InSaraae         = &InSaraae        ; is( $f_InSaraae         =~ /\b0E41\b/,1,' Match for \$f_InSaraae         =~ /\b0E41\b/');
my $f_InSarao          = &InSarao         ; is( $f_InSarao          =~ /\b0E42\b/,1,' Match for \$f_InSarao          =~ /\b0E42\b/');
my $f_InSaraaimaimuan  = &InSaraaimaimuan ; is( $f_InSaraaimaimuan  =~ /\b0E43\b/,1,' Match for \$f_InSaraaimaimuan  =~ /\b0E43\b/');
my $f_InSaraaimaimalai = &InSaraaimaimalai; is( $f_InSaraaimaimalai =~ /\b0E44\b/,1,' Match for \$f_InSaraaimaimalai =~ /\b0E44\b/');
my $f_InLakkhangyao    = &InLakkhangyao   ; is( $f_InLakkhangyao    =~ /\b0E45\b/,1,' Match for \$f_InLakkhangyao    =~ /\b0E45\b/');
my $f_InMaiyamok       = &InMaiyamok      ; is( $f_InMaiyamok       =~ /\b0E46\b/,1,' Match for \$f_InMaiyamok       =~ /\b0E46\b/');
my $f_InMaitaikhu      = &InMaitaikhu     ; is( $f_InMaitaikhu      =~ /\b0E47\b/,1,' Match for \$f_InMaitaikhu      =~ /\b0E47\b/');
my $f_InMaiek          = &InMaiek         ; is( $f_InMaiek          =~ /\b0E48\b/,1,' Match for \$f_InMaiek          =~ /\b0E48\b/');
my $f_InMaitho         = &InMaitho        ; is( $f_InMaitho         =~ /\b0E49\b/,1,' Match for \$f_InMaitho         =~ /\b0E49\b/');
my $f_InMaitri         = &InMaitri        ; is( $f_InMaitri         =~ /\b0E4A\b/,1,' Match for \$f_InMaitri         =~ /\b0E4A\b/');
my $f_InMaichattawa    = &InMaichattawa   ; is( $f_InMaichattawa    =~ /\b0E4B\b/,1,' Match for \$f_InMaichattawa    =~ /\b0E4B\b/');
my $f_InThanthakhat    = &InThanthakhat   ; is( $f_InThanthakhat    =~ /\b0E4C\b/,1,' Match for \$f_InThanthakhat    =~ /\b0E4C\b/');
my $f_InGaran          = &InGaran         ; is( $f_InGaran          =~ /\b0E4C\b/,1,' Match for \$f_InGaran          =~ /\b0E4C\b/');
my $f_InNikhahit       = &InNikhahit      ; is( $f_InNikhahit       =~ /\b0E4D\b/,1,' Match for \$f_InNikhahit       =~ /\b0E4D\b/');
my $f_InYamakkan       = &InYamakkan      ; is( $f_InYamakkan       =~ /\b0E4E\b/,1,' Match for \$f_InYamakkan       =~ /\b0E4E\b/');
my $f_InFongman        = &InFongman       ; is( $f_InFongman        =~ /\b0E4F\b/,1,' Match for \$f_InFongman        =~ /\b0E4F\b/');
my $f_InThZero         = &InThZero        ; is( $f_InThZero         =~ /\b0E50\b/,1,' Match for \$f_InThZero         =~ /\b0E50\b/');
my $f_InThOne          = &InThOne         ; is( $f_InThOne          =~ /\b0E51\b/,1,' Match for \$f_InThOne          =~ /\b0E51\b/');
my $f_InThTwo          = &InThTwo         ; is( $f_InThTwo          =~ /\b0E52\b/,1,' Match for \$f_InThTwo          =~ /\b0E52\b/');
my $f_InThThree        = &InThThree       ; is( $f_InThThree        =~ /\b0E53\b/,1,' Match for \$f_InThThree        =~ /\b0E53\b/');
my $f_InThFour         = &InThFour        ; is( $f_InThFour         =~ /\b0E54\b/,1,' Match for \$f_InThFour         =~ /\b0E54\b/');
my $f_InThFive         = &InThFive        ; is( $f_InThFive         =~ /\b0E55\b/,1,' Match for \$f_InThFive         =~ /\b0E55\b/');
my $f_InThSix          = &InThSix         ; is( $f_InThSix          =~ /\b0E56\b/,1,' Match for \$f_InThSix          =~ /\b0E56\b/');
my $f_InThSeven        = &InThSeven       ; is( $f_InThSeven        =~ /\b0E57\b/,1,' Match for \$f_InThSeven        =~ /\b0E57\b/');
my $f_InThEight        = &InThEight       ; is( $f_InThEight        =~ /\b0E58\b/,1,' Match for \$f_InThEight        =~ /\b0E58\b/');
my $f_InThNine         = &InThNine        ; is( $f_InThNine         =~ /\b0E59\b/,1,' Match for \$f_InThNine         =~ /\b0E59\b/');
my $f_InAngkhankhu     = &InAngkhankhu    ; is( $f_InAngkhankhu     =~ /\b0E5A\b/,1,' Match for \$f_InAngkhankhu     =~ /\b0E5A\b/');
my $f_InKhomut         = &InKhomut        ; is( $f_InKhomut         =~ /\b0E5B\b/,1,' Match for \$f_InKhomut         =~ /\b0E5B\b/');

exit 0;

sub prepCodepointsArray {
my @data = @_;
my $datum = join("\n", @data);
my @results = split(/\n+/, $datum);
return scalar @results;
}


