package Regexp::CharClasses::Thai;

# Regexp::CharClasses::Thai is designed to enable detailed 
# regular expressions, with the ability to identify important 
# characteristics of Thai alphabetic characters, digits and symbols.
#
# Copyright (C) 2023  Erik Mundall 
#
# This program is free software: you can redistribute it and/or 
# modify it under the terms of the GNU General Public License as 
# published by the Free Software Foundation, either version 3 of 
# the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see: https://www.gnu.org/licenses/.


use 5.008003;
use strict;
use warnings;
use utf8;
use Exporter;

our @ISA = qw(Exporter);

our %EXPORT_TAGS = (

    classes =>
        [ qw(InThai InThaiAlpha InThaiWord InThaiCons InThaiHCons 
        InThaiMCons InThaiLCons InThaiVowel InThaiPreVowel 
        InThaiPostVowel InThaiCompVowel InThaiDigit InThaiTone 
        InThaiMute InThaiPunct InThaiCurrency InThaiFinCons 
        InThaiDualCons InThaiDualC1 InThaiDualC2 InThaiConsVowel
        
        IsThai IsThaiAlpha IsThaiWord IsThaiCons IsThaiHCons 
        IsThaiMCons IsThaiLCons IsThaiVowel IsThaiPreVowel 
        IsThaiPostVowel IsThaiCompVowel IsThaiDigit IsThaiTone 
        IsThaiMute IsThaiPunct IsThaiCurrency IsThaiFinCons 
        IsThaiDualCons IsThaiDualC1 IsThaiDualC2 IsThaiConsVowel) ],
  
    characters =>
        [ qw(InKokai InKhokhai InKhokhuat InKhokhwai InKhokhon 
        InKhorakhang InNgongu InChochan InChoching InChochang InSoso 
        InShochoe InYoying InDochada InTopatak InThothan InThonangmontho 
        InThophuthao InNonen InDodek InTotao InThothung InThothahan 
        InThothong InNonu InBobaimai InPopla InPhophung InFofa InPhophan 
        InFofan InPhosamphao InMoma InYoyak InRorua InRu InLoling InLu 
        InWowaen InSosala InSorusi InSosua InHohip InLochula InOang 
        InHonokhuk InPaiyannoi InSaraa InMaihanakat InSaraaa InSaraam 
        InSarai InSaraii InSaraue InSarauee InSarau InSarauu InPhinthu 
        InBaht InSarae InSaraae InSarao InSaraaimaimuan InSaraaimaimalai 
        InLakkhangyao InMaiyamok InMaitaikhu InMaiek InMaitho InMaitri 
        InMaichattawa InThanthakhat InGaran InNikhahit InYamakkan 
        InFongman InThZero InThOne InThTwo InThThree InThFour InThFive 
        InThSix InThSeven InThEight InThNine InAngkhankhu InKhomut
        
        IsKokai IsKhokhai IsKhokhuat IsKhokhwai IsKhokhon 
        IsKhorakhang IsNgongu IsChochan IsChoching IsChochang IsSoso 
        IsShochoe IsYoying IsDochada IsTopatak IsThothan IsThonangmontho 
        IsThophuthao IsNonen IsDodek IsTotao IsThothung IsThothahan 
        IsThothong IsNonu IsBobaimai IsPopla IsPhophung IsFofa IsPhophan 
        IsFofan IsPhosamphao IsMoma IsYoyak IsRorua IsRu IsLoling IsLu 
        IsWowaen IsSosala IsSorusi IsSosua IsHohip IsLochula IsOang 
        IsHonokhuk IsPaiyannoi IsSaraa IsMaihanakat IsSaraaa IsSaraam 
        IsSarai IsSaraii IsSaraue IsSarauee IsSarau IsSarauu IsPhinthu 
        IsBaht IsSarae IsSaraae IsSarao IsSaraaimaimuan IsSaraaimaimalai 
        IsLakkhangyao IsMaiyamok IsMaitaikhu IsMaiek IsMaitho IsMaitri 
        IsMaichattawa IsThanthakhat IsGaran IsNikhahit IsYamakkan 
        IsFongman IsThZero IsThOne IsThTwo IsThThree IsThFour IsThFive 
        IsThSix IsThSeven IsThEight IsThNine IsAngkhankhu IsKhomut) ], 

);
# add all the other tags to the ":all" class,
# deleting duplicates
 {
   my %seen;
   push @{$EXPORT_TAGS{all}},
     grep {!$seen{$_}++} @{$EXPORT_TAGS{$_}} foreach keys %EXPORT_TAGS;
 }

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = ( @{ $EXPORT_TAGS{'classes'} } );

our $VERSION = '1.01';

#--------------------------------------------------------------
#	ALL THAI UNICODE CHARACTERS IN THIS MODULE
#	FOLLOW THE UNICODE CODEPOINTS DETAILED HERE:
#	http://www.unicode.org/charts/PDF/U0E00.pdf
#--------------------------------------------------------------


#--------------------------------------------------------------
#	CREATE FUNCTIONALITY FOR SHOWING CONTENTS OF EACH CLASS
#--------------------------------------------------------------

my %char_class_dispatch = (
        InThai          => \&InThai,
        InThaiCons      => \&InThaiCons,
        InThaiHCons     => \&InThaiHCons,
        InThaiMCons     => \&InThaiMCons,
        InThaiLCons     => \&InThaiLCons,
        InThaiFinCons   => \&InThaiFinCons,
        InThaiDualCons  => \&InThaiDualCons,
        InThaiDualC1    => \&InThaiDualC1,
        InThaiDualC2    => \&InThaiDualC2,
        InThaiConsVowel => \&InThaiConsVowel,
        InThaiAlpha     => \&InThaiAlpha,
        InThaiWord      => \&InThaiWord,
        InThaiTone      => \&InThaiTone,
        InThaiMute      => \&InThaiMute,
        InThaiPunct     => \&InThaiPunct,
        InThaiCurrency  => \&InThaiCurrency,
        InThaiDigit     => \&InThaiDigit,
        InThaiVowel     => \&InThaiVowel,
        InThaiCompVowel => \&InThaiCompVowel,
        InThaiPreVowel  => \&InThaiPreVowel,
        InThaiPostVowel => \&InThaiPostVowel,
    );

    
# IMPORTANT NOTE: ALL CHARACTER CLASSES IN THIS PACKAGE ARE 
#                 SPELLED OUT IN THEIR ENTIRETY, RATHER THAN
#                 REPRESENTING EACH RANGE VIA OMISSION OF THE
#                 INTERVENING CODEPOINTS.  THIS IS BOTH FOR
#                 EASIER READABILITY WHEN SEARCHING FOR A 
#                 PARTICULAR CODEPOINT TO SEE IN WHICH CLASSES
#                 IT MAY BE FOUND, AND ALSO TO FACILITATE THE
#                 ABILITY TO IDENTIFY ALL THE CHARACTERS 
#                 GROUPED IN A CLASS (MORE ON THIS IN POD).

#--------------------------------------------------------------
#	Start with the "Is..." versions
#--------------------------------------------------------------

sub IsThai { #INCLUDES ENTIRE UNICODE CODEBLOCK FOR THAI
    return join "\n",
         '0E01', '0E02', '0E03', '0E04', '0E05', '0E06', '0E07', 
 '0E08', '0E09', '0E0A', '0E0B', '0E0C', '0E0D', '0E0E', '0E0F', 
 '0E10', '0E11', '0E12', '0E13', '0E14', '0E15', '0E16', '0E17', 
 '0E18', '0E19', '0E1A', '0E1B', '0E1C', '0E1D', '0E1E', '0E1F', 
 '0E20', '0E21', '0E22', '0E23', '0E24', '0E25', '0E26', '0E27', 
 '0E28', '0E29', '0E2A', '0E2B', '0E2C', '0E2D', '0E2E', '0E2F', 
 '0E30', '0E31', '0E32', '0E33', '0E34', '0E35', '0E36', '0E37', 
 '0E38', '0E39', '0E3A', '0E3B', '0E3C', '0E3D', '0E3E', '0E3F', 
 '0E40', '0E41', '0E42', '0E43', '0E44', '0E45', '0E46', '0E47', 
 '0E48', '0E49', '0E4A', '0E4B', '0E4C', '0E4D', '0E4E', '0E4F', 
 '0E50', '0E51', '0E52', '0E53', '0E54', '0E55', '0E56', '0E57', 
 '0E58', '0E59', '0E5A', '0E5B', '0E5C', '0E5D', '0E5E', '0E5F', 
 '0E60', '0E61', '0E62', '0E63', '0E64', '0E65', '0E66', '0E67', 
 '0E68', '0E69', '0E6A', '0E6B', '0E6C', '0E6D', '0E6E', '0E6F', 
 '0E70', '0E71', '0E72', '0E73', '0E74', '0E75', '0E76', '0E77', 
 '0E78', '0E79', '0E7A', '0E7B', '0E7C', '0E7D', '0E7E', '0E7F', 
}

sub IsThaiCons { #THAI CONSONANTS
# ก ข ฃ ค ฅ ฆ ง จ ฉ ช ซ ฌ ญ ฎ ฏ ฐ ฑ ฒ ณ ด ต ถ ท 
# ธ น บ ป ผ ฝ พ ฟ ภ ม ย ร ฤ ล ฦ ว ศ ษ ส ห ฬ อ ฮ 
#NOTE: Most consider 0E24 and 0E26 (ฤ ฦ), included,
#      as vowels, but they act/function as consonants
#      and are listed among the consonants in the 
#      official Unicode character chart for Thai. 
#      See https://en.wiktionary.org/wiki/%E0%B8%A4
#      Thai: https://th.wikipedia.org/wiki/%E0%B8%A4
    return join "\n",
         '0E01', '0E02', '0E03', '0E04', '0E05', '0E06', '0E07', 
 '0E08', '0E09', '0E0A', '0E0B', '0E0C', '0E0D', '0E0E', '0E0F', 
 '0E10', '0E11', '0E12', '0E13', '0E14', '0E15', '0E16', '0E17', 
 '0E18', '0E19', '0E1A', '0E1B', '0E1C', '0E1D', '0E1E', '0E1F', 
 '0E20', '0E21', '0E22', '0E23', '0E24', '0E25', '0E26', '0E27', 
 '0E28', '0E29', '0E2A', '0E2B', '0E2C', '0E2D', '0E2E', 
}

sub IsThaiHCons { #THAI HIGH-CLASS CONSONANTS
# ข ฃ ฉ ฐ ถ ผ ฝ ศ ษ ส ห
    return join "\n",
 '0E02', '0E03', '0E09', '0E10', '0E16', '0E1C', '0E1D', '0E28', 
 '0E29', '0E2A', '0E2B',
}

sub IsThaiMCons { #THAI MID-CLASS CONSONANTS
# ก จ ฎ ฏ ด ต บ ป อ
    return join "\n",
 '0E01', '0E08', '0E0E', '0E0F', '0E14', '0E15', '0E1A', '0E1B', 
 '0E2D', 
}

sub IsThaiLCons { #THAI LOW-CLASS CONSONANTS
# ค ฅ ฆ ง ช ซ ฌ ญ ฑ ฒ ณ ท ธ น พ ฟ ภ ม ย ร ฤ ล ฦ ว ฬ ฮ 
#NOTE: The included ฤ and ฦ are usually classed as vowels, but
#when they function as consonants they would be in this class.
    return join "\n",
 '0E04', '0E05', '0E06', '0E07', '0E0A', '0E0B', '0E0C', '0E0D', 
 '0E11', '0E12', '0E13', '0E17', '0E18', '0E19', '0E1E', '0E1F', 
 '0E20', '0E21', '0E22', '0E23', '0E24', '0E25', '0E26', '0E27', 
 '0E2C', '0E2E', 
}

sub IsThaiFinCons { #THAI SYLLABLE-ENDING CONSONANTS (FINAL)
#ALL CONSONANTS EXCEPT THESE:  ฉ ซ ผ ฝ ห ฮ ห อ ฮ 
#NOTE: Certain others (ย ว อ) may be at the end of a syllable, 
#      but as a vowel; so are not included here.  These consonants 
#      may not, but can, be at the end of a syllable; useful for 
#      some regular expressions. 
    return join "\n",
 '0E01', '0E02', '0E03', '0E04', '0E05', '0E06', '0E07', '0E08', 
 '0E0A', '0E0C', '0E0D', '0E0E', '0E0F', '0E10', '0E11', '0E12', 
 '0E13', '0E14', '0E15', '0E16', '0E17', '0E18', '0E19', '0E1A', 
 '0E1B', '0E1E', '0E1F', '0E20', '0E21', '0E23', '0E24', '0E25', 
 '0E26', '0E28', '0E29', '0E2A', '0E2C', 
}

sub IsThaiDualCons {
# BECAUSE EACH \p{...} CHARACTER DEFINED CAN BE ONLY A SINGLE
# CHARACTER, AND NOT A CHARACTER CLUSTER, THIS CHAR CLASS, AND
# THE TWO WHICH FOLLOW IT, ARE CONSIDERED EXPERIMENTAL AND OF 
# LIMITED USEFULNESS.
#
# NON-EXHAUSTIVE LIST OF EXAMPLES (INITIAL CONSONANT CLUSTERS)
# กว กล กร ขร ขล ขว คร คล คว ตร ปร ปล บร บล ดร ผล พร พล ทร สร จร ซร
# [and with sonorant consonants] หม หน หล หย หง หว หญ อย 
    return join "\n",
  '0E01', '0E02', '0E04', '0E07', '0E08', '0E0B', '0E0D', '0E14', 
  '0E15', '0E17', '0E19', '0E1A', '0E1B', '0E1C', '0E1E', '0E21', 
  '0E22', '0E23', '0E25', '0E27', '0E2A', '0E2B', '0E2D', 
}

sub IsThaiDualC1 { #INITIAL CONSONANTS OF DUAL-CONSONANT LIST
#ก ข ค จ ซ ด ต ท บ ป ผ พ ส ห อ
    return join "\n",
  '0E01', '0E02', '0E04', '0E08', '0E0B', '0E14', '0E15', '0E17', 
  '0E1A', '0E1B', '0E1C', '0E1E', '0E2A', '0E2B', '0E2D',
}

sub IsThaiDualC2 { #SECOND CONSONANTS OF DUAL-CONSONANT LIST
#ง ญ น ม ย ร ล ว 
    return join "\n",
 '0E07', '0E0D', '0E19', '0E21', '0E22', '0E23', '0E25', '0E27',
}

sub IsThaiConsVowel { #THAI CONSONANTS WHICH CAN ALSO BE VOWELS
#NOTE: Thais consider 0E33 to be only a vowel, and it can never
#      function as only a consonant (it must always have a
#      vowel component), so it is NOT included here: but it is 
#      actually a vowel-consonant combination, phonetically, 
#      finishing with the "m" sound.  This class addresses only
#      Thai characters which can be either consonant or vowel,
#      but not both at the same time. The 0E23 is only a vowel if
#      it is doubled--but this doubling cannot be determined when
#      examining an individual code point, so it is included here
#      for thoroughness.
# ย ร ฤ ฦ ว อ
    return join "\n",
 '0E22', '0E23', '0E24', '0E26', '0E27', '0E2D', 
}

sub IsThaiAlpha { #THAI ALPHABETIC CHARACTERS
#Thai consonants + vowels only
    return join "\n",
         '0E01', '0E02', '0E03', '0E04', '0E05', '0E06', '0E07', 
 '0E08', '0E09', '0E0A', '0E0B', '0E0C', '0E0D', '0E0E', '0E0F', 
 '0E10', '0E11', '0E12', '0E13', '0E14', '0E15', '0E16', '0E17', 
 '0E18', '0E19', '0E1A', '0E1B', '0E1C', '0E1D', '0E1E', '0E1F', 
 '0E20', '0E21', '0E22', '0E23', '0E24', '0E25', '0E26', '0E27', 
 '0E28', '0E29', '0E2A', '0E2B', '0E2C', '0E2D', '0E2E', '0E30', 
 '0E31', '0E32', '0E33', '0E34', '0E35', '0E36', '0E37', '0E38', 
 '0E39', '0E3A', '0E40', '0E41', '0E42', '0E43', '0E44', '0E45', 
 '0E47', '0E4D', 
}

sub IsThaiWord { #THAI WORD CHARACTERS
#Thai consonants + vowels + tone marks/diacritics
#but not including punctuation, digits, etc., i.e.
#specifically characters used in Thai words
    return join "\n",
         '0E01', '0E02', '0E03', '0E04', '0E05', '0E06', '0E07', 
 '0E08', '0E09', '0E0A', '0E0B', '0E0C', '0E0D', '0E0E', '0E0F', 
 '0E10', '0E11', '0E12', '0E13', '0E14', '0E15', '0E16', '0E17', 
 '0E18', '0E19', '0E1A', '0E1B', '0E1C', '0E1D', '0E1E', '0E1F', 
 '0E20', '0E21', '0E22', '0E23', '0E24', '0E25', '0E26', '0E27', 
 '0E28', '0E29', '0E2A', '0E2B', '0E2C', '0E2D', '0E2E', '0E30', 
 '0E31', '0E32', '0E33', '0E34', '0E35', '0E36', '0E37', '0E38', 
 '0E39', '0E3A', '0E40', '0E41', '0E42', '0E43', '0E44', '0E45', 
 '0E47', '0E48', '0E49', '0E4A', '0E4B', '0E4C', '0E4D', '0E4E',
}

sub IsThaiTone { #THAI TONE MARKS
# ่ ้ ๊ ๋
    return join "\n",
 '0E48', '0E49', '0E4A', '0E4B', 
}

sub IsThaiMute { #THAI MUTE CHARACTER (THANTHAKHAT/GARAN)
#A special tone mark which silences consonants: ์
    return join "\n",
 '0E4C', 
}

sub IsThaiPunct { #THAI PUNCTUATION
# ฯ ๆ ๏ ๚ ๛
    return join "\n",
 '0E2F', '0E46', '0E4F', '0E5A', '0E5B', 
}

sub IsThaiCurrency { #BAHT SIGN
# ฿ 
    return join "\n",
 '0E3F', 
}

sub IsThaiDigit { #THAI DIGITS
# ๐ ๑ ๒ ๓ ๔ ๕ ๖ ๗ ๘ ๙ 
    return join "\n",
 '0E50', '0E51', '0E52', '0E53', '0E54', 
 '0E55', '0E56', '0E57', '0E58', '0E59', 
}

sub IsThaiVowel { #THAI VOWELS
#NOTE: 0E4D combines with a consonant but may not be considered a vowel
#      0E47 looks/acts like a tone mark, but is actually a form of sara-a
#      which is used in place of sara-a (0E30) when the syllable terminates
#      in a consonant
# ย ฤ ฦ ว อ ะ ั า ํา ิ ี ึ ื ุ ู ฺ เ แ โ ใ ไ ๅ ็ ํ
    return join "\n",
 '0E22', '0E24', '0E26', '0E27', '0E2D', '0E30', '0E31', '0E32', 
 '0E33', '0E34', '0E35', '0E36', '0E37', '0E38', '0E39', '0E3A', 
 '0E40', '0E41', '0E42', '0E43', '0E44', '0E45', '0E47', '0E4D', 
}

sub IsThaiCompVowel { #VOWELS COMPOSITED/COMPILED VERTICALLY WITH CONSONANT
#NOTE: 0E4D combines with a consonant but may not be considered a vowel
#NOTE: 0E33 is a partially-combining vowel but also occupies its own space
# ั  ิ ี ึ ื ุ  ู  ็ ํ
    return join "\n",
 '0E31', '0E34', '0E35', '0E36', '0E37', '0E38', '0E39', '0E3A', 
 '0E47', '0E4D',
}

sub IsThaiPreVowel { #VOWELS PRECEDING CONSONANT
# เ แ โ ใ ไ
    return join "\n",
 '0E40', '0E41', '0E42', '0E43', '0E44', 
}

sub IsThaiPostVowel { #VOWELS AFTER CONSONANT
#NOTE: Consonants which act as vowels also appear after their 
#      consonants but are not included here.
#NOTE: Thais consider 0E33 to be only a vowel, so it is included 
#      here, but it is actually a vowel-consonant combination,
#      phonetically, finishing with the "m" sound.
# ะ า ํา ๅ
    return join "\n",
 '0E30', '0E32', '0E33', '0E45',
}

#--------------------------------------------------------------
#	Alias the "In..." forms (same as above)
#--------------------------------------------------------------

sub InThai          { &IsThai          }            
sub InThaiCons      { &IsThaiCons      }         
sub InThaiHCons     { &IsThaiHCons     }     
sub InThaiMCons     { &IsThaiMCons     }     
sub InThaiLCons     { &IsThaiLCons     }     
sub InThaiFinCons   { &IsThaiFinCons   }    
sub InThaiDualCons  { &IsThaiDualCons  }    
sub InThaiDualC1    { &IsThaiDualC1    }    
sub InThaiDualC2    { &IsThaiDualC2    }    
sub InThaiConsVowel { &IsThaiConsVowel }    
sub InThaiAlpha     { &IsThaiAlpha     }        
sub InThaiWord      { &IsThaiWord      }        
sub InThaiTone      { &IsThaiTone      }        
sub InThaiMute      { &IsThaiMute      }        
sub InThaiPunct     { &IsThaiPunct     }        
sub InThaiCurrency  { &IsThaiCurrency  }    
sub InThaiDigit     { &IsThaiDigit     }        
sub InThaiVowel     { &IsThaiVowel     }        
sub InThaiCompVowel { &IsThaiCompVowel }    
sub InThaiPreVowel  { &IsThaiPreVowel  }    
sub InThaiPostVowel { &IsThaiPostVowel }    


#--------------------------------------------------------------
#	Provide spelled-out forms of the individual characters
#--------------------------------------------------------------
sub IsKokai          { return '0E01' }     # ก - THAI CHARACTER KO KAI
sub IsKhokhai        { return '0E02' }     # ข - THAI CHARACTER KHO KHAI
sub IsKhokhuat       { return '0E03' }     # ฃ - THAI CHARACTER KHO KHUAT
sub IsKhokhwai       { return '0E04' }     # ค - THAI CHARACTER KHO KHWAI
sub IsKhokhon        { return '0E05' }     # ฅ - THAI CHARACTER KHO KHON
sub IsKhorakhang     { return '0E06' }     # ฆ - THAI CHARACTER KHO RAKHANG
sub IsNgongu         { return '0E07' }     # ง - THAI CHARACTER NGO NGU
sub IsChochan        { return '0E08' }     # จ - THAI CHARACTER CHO CHAN
sub IsChoching       { return '0E09' }     # ฉ - THAI CHARACTER CHO CHING
sub IsChochang       { return '0E0A' }     # ช - THAI CHARACTER CHO CHANG
sub IsSoso           { return '0E0B' }     # ซ - THAI CHARACTER SO SO
sub IsShochoe        { return '0E0C' }     # ฌ - THAI CHARACTER CHO CHOE
sub IsYoying         { return '0E0D' }     # ญ - THAI CHARACTER YO YING
sub IsDochada        { return '0E0E' }     # ฎ - THAI CHARACTER DO CHADA
sub IsTopatak        { return '0E0F' }     # ฏ - THAI CHARACTER TO PATAK
sub IsThothan        { return '0E10' }     # ฐ - THAI CHARACTER THO THAN
sub IsThonangmontho  { return '0E11' }     # ฑ - THAI CHARACTER THO NANGMONTHO
sub IsThophuthao     { return '0E12' }     # ฒ - THAI CHARACTER THO PHUTHAO
sub IsNonen          { return '0E13' }     # ณ - THAI CHARACTER NO NEN
sub IsDodek          { return '0E14' }     # ด - THAI CHARACTER DO DEK
sub IsTotao          { return '0E15' }     # ต - THAI CHARACTER TO TAO
sub IsThothung       { return '0E16' }     # ถ - THAI CHARACTER THO THUNG
sub IsThothahan      { return '0E17' }     # ท - THAI CHARACTER THO THAHAN
sub IsThothong       { return '0E18' }     # ธ - THAI CHARACTER THO THONG
sub IsNonu           { return '0E19' }     # น - THAI CHARACTER NO NU
sub IsBobaimai       { return '0E1A' }     # บ - THAI CHARACTER BO BAIMAI
sub IsPopla          { return '0E1B' }     # ป - THAI CHARACTER PO PLA
sub IsPhophung       { return '0E1C' }     # ผ - THAI CHARACTER PHO PHUNG
sub IsFofa           { return '0E1D' }     # ฝ - THAI CHARACTER FO FA
sub IsPhophan        { return '0E1E' }     # พ - THAI CHARACTER PHO PHAN
sub IsFofan          { return '0E1F' }     # ฟ - THAI CHARACTER FO FAN
sub IsPhosamphao     { return '0E20' }     # ภ - THAI CHARACTER PHO SAMPHAO
sub IsMoma           { return '0E21' }     # ม - THAI CHARACTER MO MA
sub IsYoyak          { return '0E22' }     # ย - THAI CHARACTER YO YAK
sub IsRorua          { return '0E23' }     # ร - THAI CHARACTER RO RUA
sub IsRu             { return '0E24' }     # ฤ - THAI CHARACTER RU
sub IsLoling         { return '0E25' }     # ล - THAI CHARACTER LO LING
sub IsLu             { return '0E26' }     # ฦ - THAI CHARACTER LU
sub IsWowaen         { return '0E27' }     # ว - THAI CHARACTER WO WAEN
sub IsSosala         { return '0E28' }     # ศ - THAI CHARACTER SO SALA
sub IsSorusi         { return '0E29' }     # ษ - THAI CHARACTER SO RUSI
sub IsSosua          { return '0E2A' }     # ส - THAI CHARACTER SO SUA
sub IsHohip          { return '0E2B' }     # ห - THAI CHARACTER HO HIP
sub IsLochula        { return '0E2C' }     # ฬ - THAI CHARACTER LO CHULA
sub IsOang           { return '0E2D' }     # อ - THAI CHARACTER O ANG
sub IsHonokhuk       { return '0E2E' }     # ฮ - THAI CHARACTER HO NOKHUK
sub IsPaiyannoi      { return '0E2F' }     # ฯ - THAI CHARACTER PAIYANNOI
sub IsSaraa          { return '0E30' }     # ะ - THAI CHARACTER SARA A
sub IsMaihanakat     { return '0E31' }     #  ั - THAI CHARACTER MAI HAN-AKAT
sub IsSaraaa         { return '0E32' }     # า - THAI CHARACTER SARA AA
sub IsSaraam         { return '0E33' }     # ำ - THAI CHARACTER SARA AM
sub IsSarai          { return '0E34' }     #  ิ - THAI CHARACTER SARA I
sub IsSaraii         { return '0E35' }     #  ี - THAI CHARACTER SARA II
sub IsSaraue         { return '0E36' }     #  ึ - THAI CHARACTER SARA UE
sub IsSarauee        { return '0E37' }     #  ื - THAI CHARACTER SARA UEE
sub IsSarau          { return '0E38' }     #  ุ - THAI CHARACTER SARA U
sub IsSarauu         { return '0E39' }     #  ู - THAI CHARACTER SARA UU
sub IsPhinthu        { return '0E3A' }     #  ฺ - THAI CHARACTER PHINTHU
sub IsBaht           { return '0E3F' }     # ฿ - THAI CURRENCY SYMBOL BAHT
sub IsSarae          { return '0E40' }     # เ - THAI CHARACTER SARA E
sub IsSaraae         { return '0E41' }     # แ - THAI CHARACTER SARA AE
sub IsSarao          { return '0E42' }     # โ - THAI CHARACTER SARA O
sub IsSaraaimaimuan  { return '0E43' }     # ใ - THAI CHARACTER SARA AI MAIMUAN
sub IsSaraaimaimalai { return '0E44' }     # ไ - THAI CHARACTER SARA AI MAIMALAI
sub IsLakkhangyao    { return '0E45' }     # ๅ - THAI CHARACTER LAKKHANGYAO
sub IsMaiyamok       { return '0E46' }     # ๆ - THAI CHARACTER MAIYAMOK
sub IsMaitaikhu      { return '0E47' }     #  ็ - THAI CHARACTER MAITAIKHU
sub IsMaiek          { return '0E48' }     #  ่ - THAI CHARACTER MAI EK
sub IsMaitho         { return '0E49' }     #  ้ - THAI CHARACTER MAI THO
sub IsMaitri         { return '0E4A' }     #  ๊ - THAI CHARACTER MAI TRI
sub IsMaichattawa    { return '0E4B' }     #  ๋ - THAI CHARACTER MAI CHATTAWA
sub IsThanthakhat    { return '0E4C' }     #  ์ - THAI CHARACTER THANTHAKHAT/GARAN
sub IsGaran          { return '0E4C' }     #  ์ - THAI CHARACTER THANTHAKHAT/GARAN
sub IsNikhahit       { return '0E4D' }     #  ํ - THAI CHARACTER NIKHAHIT
sub IsYamakkan       { return '0E4E' }     #  ๎ - THAI CHARACTER YAMAKKAN
sub IsFongman        { return '0E4F' }     # ๏ - THAI CHARACTER FONGMAN
sub IsThZero         { return '0E50' }     # ๐ - THAI DIGIT ZERO
sub IsThOne          { return '0E51' }     # ๑ - THAI DIGIT ONE
sub IsThTwo          { return '0E52' }     # ๒ - THAI DIGIT TWO
sub IsThThree        { return '0E53' }     # ๓ - THAI DIGIT THREE
sub IsThFour         { return '0E54' }     # ๔ - THAI DIGIT FOUR
sub IsThFive         { return '0E55' }     # ๕ - THAI DIGIT FIVE
sub IsThSix          { return '0E56' }     # ๖ - THAI DIGIT SIX
sub IsThSeven        { return '0E57' }     # ๗ - THAI DIGIT SEVEN
sub IsThEight        { return '0E58' }     # ๘ - THAI DIGIT EIGHT
sub IsThNine         { return '0E59' }     # ๙ - THAI DIGIT NINE
sub IsAngkhankhu     { return '0E5A' }     # ๚ - THAI CHARACTER ANGKHANKHU
sub IsKhomut         { return '0E5B' }     # ๛ - THAI CHARACTER KHOMUT

#--------------------------------------------------------------
#	Alias the spelled-out individual characters
#--------------------------------------------------------------

sub InKokai          { &IsKokai          }
sub InKhokhai        { &IsKhokhai        }
sub InKhokhuat       { &IsKhokhuat       }
sub InKhokhwai       { &IsKhokhwai       }
sub InKhokhon        { &IsKhokhon        }
sub InKhorakhang     { &IsKhorakhang     }
sub InNgongu         { &IsNgongu         }
sub InChochan        { &IsChochan        }
sub InChoching       { &IsChoching       }
sub InChochang       { &IsChochang       }
sub InSoso           { &IsSoso           }
sub InShochoe        { &IsShochoe        }
sub InYoying         { &IsYoying         }
sub InDochada        { &IsDochada        }
sub InTopatak        { &IsTopatak        }
sub InThothan        { &IsThothan        }
sub InThonangmontho  { &IsThonangmontho  }
sub InThophuthao     { &IsThophuthao     }
sub InNonen          { &IsNonen          }
sub InDodek          { &IsDodek          }
sub InTotao          { &IsTotao          }
sub InThothung       { &IsThothung       }
sub InThothahan      { &IsThothahan      }
sub InThothong       { &IsThothong       }
sub InNonu           { &IsNonu           }
sub InBobaimai       { &IsBobaimai       }
sub InPopla          { &IsPopla          }
sub InPhophung       { &IsPhophung       }
sub InFofa           { &IsFofa           }
sub InPhophan        { &IsPhophan        }
sub InFofan          { &IsFofan          }
sub InPhosamphao     { &IsPhosamphao     }
sub InMoma           { &IsMoma           }
sub InYoyak          { &IsYoyak          }
sub InRorua          { &IsRorua          }
sub InRu             { &IsRu             }
sub InLoling         { &IsLoling         }
sub InLu             { &IsLu             }
sub InWowaen         { &IsWowaen         }
sub InSosala         { &IsSosala         }
sub InSorusi         { &IsSorusi         }
sub InSosua          { &IsSosua          }
sub InHohip          { &IsHohip          }
sub InLochula        { &IsLochula        }
sub InOang           { &IsOang           }
sub InHonokhuk       { &IsHonokhuk       }
sub InPaiyannoi      { &IsPaiyannoi      }
sub InSaraa          { &IsSaraa          }
sub InMaihanakat     { &IsMaihanakat     }
sub InSaraaa         { &IsSaraaa         }
sub InSaraam         { &IsSaraam         }
sub InSarai          { &IsSarai          }
sub InSaraii         { &IsSaraii         }
sub InSaraue         { &IsSaraue         }
sub InSarauee        { &IsSarauee        }
sub InSarau          { &IsSarau          }
sub InSarauu         { &IsSarauu         }
sub InPhinthu        { &IsPhinthu        }
sub InBaht           { &IsBaht           }
sub InSarae          { &IsSarae          }
sub InSaraae         { &IsSaraae         }
sub InSarao          { &IsSarao          }
sub InSaraaimaimuan  { &IsSaraaimaimuan  }
sub InSaraaimaimalai { &IsSaraaimaimalai }
sub InLakkhangyao    { &IsLakkhangyao    }
sub InMaiyamok       { &IsMaiyamok       }
sub InMaitaikhu      { &IsMaitaikhu      }
sub InMaiek          { &IsMaiek          }
sub InMaitho         { &IsMaitho         }
sub InMaitri         { &IsMaitri         }
sub InMaichattawa    { &IsMaichattawa    }
sub InThanthakhat    { &IsThanthakhat    }
sub InGaran          { &IsGaran          }
sub InNikhahit       { &IsNikhahit       }
sub InYamakkan       { &IsYamakkan       }
sub InFongman        { &IsFongman        }
sub InThZero         { &IsThZero         }
sub InThOne          { &IsThOne          }
sub InThTwo          { &IsThTwo          }
sub InThThree        { &IsThThree        }
sub InThFour         { &IsThFour         }
sub InThFive         { &IsThFive         }
sub InThSix          { &IsThSix          }
sub InThSeven        { &IsThSeven        }
sub InThEight        { &IsThEight        }
sub InThNine         { &IsThNine         }
sub InAngkhankhu     { &IsAngkhankhu     }
sub InKhomut         { &IsKhomut         }




1;

__END__

=pod

=encoding utf8

=head1 NAME

  Regexp::CharClasses::Thai - useful character properties f​or
                              Thai regular expressions (regex)

=head1 SYNOPSIS

  use Regexp::CharClasses::Thai;

  $c = "...";  # some UTF8 string

  $c =~ /\p{InThaiCons}/;  # match only Thai consonants
  $c =~ /\p{InThaiTone}/;  # match only Thai tone marks

	- OR -

  $c =~ /\p{IsThaiCons}/;  # match only Thai consonants
  $c =~ /\p{IsThaiTone}/;  # match only Thai tone marks

 # see description for full set of terms

=head1 DESCRIPTION

  This module supplements the UTF-8 character-class definitions 
  available to regular expressions (regex) w​ith special groups 
  relevant to Thai linguistics.  The following classes are d​efined:

	โมดูลนี้เป็นส่วนเสริมคำจำกัดความคลาสอักขระ UTF-8
	ใช้ได้กับ (regex) ทั่วไป ด้วยกลุ่มพิเศษ
	ที่เกี่ยวข้องกับภาษาไทย มีการกำหนดคลาสต่อไปนี้:

=over 4

=item InThai / IsThai

  Matches ALL characters in the Thai unicode code-point range.
  
  จับคู่อักขระทั้งหมดในช่วงจุดโค้ดยูนิโค้ดภาษาไทย

=item InThaiCons / IsThaiCons

  Matches Thai consonant letters, leaving out vowels (but including
  those vowels which are sometimes consonants).
  
  จับคู่พยัญชนะไทย (รวมสระที่บางครั้งเป็นพยัญชนะด้วย)

=item InThaiVowel / IsThaiVowel

  Matches Thai vowels only, including compounded and free-standing 
  vowels.  Exceptions here include several of the “consonants” which 
  also serve as vowels: o-ang, yo-yak, double ro-rua, lu and ru, and 
  wo-waen (อ, ย, รร, ฦ, ฤ, ว), which are also included except f​or 
  the two-character รร.

  NOTE: Thai vowels cannot stand alone: they are always connected 
  w​ith a consonant.  Many of these, without their consonant 
  companions, will appear w​ith the unicode dotted-circle character 
  (U+25CC) when rendered, showing a character is missing.  
  Conversely, Thai consonants c​an exist without a vowel, and some 
  Thai words d​o not have written vowels (the vowel is implied).
  
  จับคู่สระไทยเท่านั้น รวมทั้งสระประกอบ และสระอิสระ ข้อยกเว้น
  ในที่นี้รวมถึง “พยัญชนะ” หลายตัวซึ่งทำหน้าที่เป็นสระด้วย เช่น 
  (อ, ย, รร, ฦ, ฤ, ว) ซึ่งรวมอยู่ด้วยยกเว้นอักขระสองตัว รร
  
=item InThaiAlpha / IsThaiAlpha

  Matches only the Thai alphabetic characters (consonants & vowels),
  excluding all digits, tone marks, and punctuation marks.
  
  จับคู่เฉพาะตัวอักษรไทย (พยัญชนะและสระ) ไม่รวมตัวเลข 
  เครื่องหมายวรรณยุกต์ และเครื่องหมายวรรคตอนทั้งหมด
  
=item InThaiWord / IsThaiWord

  Matches all Thai characters used to form words, including:
  consonants, vowels, and tone marks; but excluding all digits
  and punctuation marks.
  
  จับคู่ตัวอักษรไทยทั้งหมดที่ใช้สร้างคำ รวมทั้ง
  พยัญชนะ สระ และเครื่องหมายวรรณยุกต์ แต่ไม่รวมตัวเลขทั้งหมด
  และเครื่องหมายวรรคตอน
  
=item InThaiTone / IsThaiTone

  Matches only the Thai tone marks, leaving out all letters,
  digits and punctuation marks.
  
  จับคู่เฉพาะเครื่องหมายวรรณยุกต์ไทยโดยไม่รวม ตัวอักษร
  ตัวเลข หรือ เครื่องหมายวรรคตอน ทั้งหมด

=item InThaiMute / IsThaiMute

  The single character U+0E4C (Thai Thanthakhat/Garan), as it seems 
  neither typical of a tone mark, nor a punctuation mark.  It comes 
  nearer to usage as a tone mark, but instead of affecting the tone 
  of a vowel, it silences one or more consonants.
  
  อักษรตัวเดียว ธัณฑฆาต/การันต์ 

=item InThaiPunct / IsThaiPunct

  Matches Thai punctuation characters, not including tone marks,
  white space, digits or alphabetic characters, and not including
  non-Thai punctuation marks (such as English [.,'"!?] etc.).
  
  จับคู่อักขระเครื่องหมายวรรคตอนภาษาไทย ไม่รวมเครื่องหมายวรรณยุกต์
  ช่องว่าง ตัวเลข หรือ ตัวอักษร และไม่รวม เครื่องหมายวรรคตอน
  ที่ไม่ใช่ภาษาไทย (เช่น อังกฤษ [.,'"!?] เป็นต้น)

=item InThaiCompVowel / IsThaiCompVowel

  Matches only the Thai vowels which are compounded w​ith a Thai 
  consonant, and matching only the vowel portion of the compounded 
  character:  ◌ั ◌ิ ◌ี ◌ึ ◌ื ◌ุ ◌ู ◌็ ◌ํ
  
  จับคู่เฉพาะสระไทยที่ประกอบกับพยัญชนะไทยเท่านั้น
  และจับคู่เฉพาะส่วนสระของตัวอักษรนั้นที่ประสมเท่านั้น
  นั่นคือ: ◌ั ◌ิ ◌ี ◌ึ ◌ื ◌ุ ◌ู ◌็ ◌ํ

=item InThaiPreVowel / IsThaiPreVowel

  Matches only the subset of vowels which appear before the 
  consonant w​ith which they are associated (though in Thai they 
  are sounded after said consonant); this excludes all 
  consonant-vowels and does not include any of the compounded vowels.
  
  จับคู่เฉพาะชุดย่อยของสระที่ปรากฏ ก่อน พยัญชนะที่เกี่ยวข้อง 
  (แต่เป็นภาษาไทยถูกฟัง หลัง พยัญชนะดังกล่าว); 
  นี่ไม่รวมทั้งหมด พยัญชนะ-สระ และไม่รวมถึงสระประสมใดๆ

=item InThaiPostVowel / IsThaiPostVowel

  Matches only the vowels which appear after the consonant 
  w​ith which they are associated; this excludes all consonant-vowels 
  and does not include any of the compounded vowels.
  
  จับคู่เฉพาะสระนั้นที่ปรากฏ หลัง พยัญชนะ ที่เกี่ยวข้อง 
  ไม่รวมพยัญชนะ-สระทั้งหมด และ ไม่รวมถึงสระประสมใดๆ

=item InThaiHCons / IsThaiHCons

  Matches Thai high-class consonants: ข ฃ ฉ ฐ ถ ผ ฝ ศ ษ ส ห.
  
  จับคู่พยัญชนะไทยชั้นสูง: ข ฃ ฉ ฐ ถ ผ ฝ ศ ษ ส ห.

=item InThaiMCons / IsThaiMCons

  Matches Thai middle-class consonants: ก จ ฎ ฏ ด ต บ ป อ.
  
  จับคู่พยัญชนะไทยชนชั้นกลาง: ก จ ฎ ฏ ด ต บ ป อ.

=item InThaiLCons / IsThaiLCons

  Matches Thai low-class consonants: จับคู่พยัญชนะไทยชั้นต่ำ:
  
  ค ฅ ฆ ง ช ซ ฌ ญ ฑ ฒ ณ ท ธ น พ ฟ ภ ม ย ร ฤ ล ฦ ว ฬ ฮ.

=item InThaiFinCons / IsThaiFinCons

  Matches Thai consonants which c​an occur as the final consonant
  of a syllable.  This excludes ฉ, ซ, ผ, ฝ, ห, ฮ, which never 
  appear at the end of a Thai syllable, as well as ย, ว, อ, which 
  only appear at the end of a syllable when used as a vowel.

  NOTE: Any Thai consonant c​an be an initial consonant, so there is 
  no separate designation f​or these: just u​se 'InThaiCons' or 
  'IsThaiCons'.
  
  จับคู่พยัญชนะไทยซึ่งอาจเป็นพยัญชนะตัวสุดท้ายของพยางค์ได้ 
  ทั้งนี้ ไม่รวมถึง ฉ ซ ผ ฝ ห ห ฮ ซึ่งไม่เคยปรากฏต่อท้ายพยางค์ไทย 
  และ ไม่รวมถึง ย ว อ ซึ่งปรากฏที่ท้ายพยางค์เมื่อใช้เป็นสระเท่านั้น

  หมายเหตุ: พยัญชนะไทยใดๆ ก็สามารถเป็นพยัญชนะเริ่มต้นได้ 
  ดังนั้นจึงไม่มีการกำหนดแยกสำหรับพยัญชนะเหล่านี้: 
  เพียงใช้ 'InThaiCons' หรือ 'IsThaiCons'

=item InThaiDualCons / IsThaiDualCons

  Matches Thai consonants which are often paired as the primary 
  “consonant” of the syllable (the leading ones), around which a 
  single vowel or vowel combination will be centered.  Many 
  combinations of consonants, unassociated by a single vowel, may 
  occur in Thai: this does not address them.   For example: 
  the “hm” in “hma” (dog) function together as i​f they were 
  a single consonant--the high-class “h” giving its tone to the “m”.
  This attempts to address these common consonant pairs.  
  IT MAY NOT BE EXHAUSTIVE.

  Pairs considered:
  กว กล กร ขร ขล ขว คร คล คว ตร ปร ปล บร บล ดร ผล พร พล ทร สร จร ซร
  [and the sonorant consonants] หม หน หล หย หง หว หญ อย 
  
  จับคู่พยัญชนะไทยซึ่งมักจับคู่เป็น “พยัญชนะ” หลักของพยางค์ (ตัวนำ) 
  โดยจะเน้นการใช้สระเดี่ยวหรือสระรวมกัน 
  พยัญชนะหลายตัวที่ไม่เกี่ยวข้องกันด้วยสระตัวเดียวอาจเกิดขึ้นในภาษาไทย 
  แต่ไม่ได้กล่าวถึง ตัวนั้น เช่น: “หม” ใน “หมา” ทำงานร่วมกันราวกับว่า
  เป็นพยัญชนะตัวเดียว - “ห” ระดับสูงที่ให้เสียงของ “ม”
  นี่เป็นการพยายามพูดถึงคู่พยัญชนะทั่วไปเหล่านี้
  มันอาจจะไม่ละเอียดถี่ถ้วน

=item InThaiDualC1 / IsThaiDualC1

  Matches the initial consonant of a dual-consonant as described 
  above: ก ข ค จ ซ ด ต ท บ ป ผ พ ส ห อ.
  
  จับคู่พยัญชนะเริ่มต้นของพยัญชนะคู่ตามที่อธิบายไว้ข้างบน: 
  ก ข ค จ ซ ด ต ท บ ป ผ พ ส ห อ.

=item InThaiDualC2 / IsThaiDualC2

  Matches the second consonant of a dual-consonant as described 
  above: ง ญ น ม ย ร ล ว.
  
  จับคู่พยัญชนะตัวที่สองของพยัญชนะคู่ตามที่อธิบายไว้ข้างต้น: ง ญ น ม ย ร ล ว.

=item InThaiConsVowel / IsThaiConsVowel

  Matches Thai characters which c​an function as either consonants 
  or vowels: ย ร ฤ ฦ ว อ.
  
  จับคู่ตัวอักษรไทยซึ่งทำหน้าที่เป็นพยัญชนะหรือสระได้: ย ร ฤ ฦ ว อ.
  
  Note: Thais consider 0E33 (◌ำ) to be only a vowel, and it c​an 
  never function as only a consonant (it must always have a vowel 
  component), so it is NOT included here: but it is actually a 
  vowel-consonant combination, phonetically, finishing w​ith the 
  “m” sound.  This class addresses only Thai characters which c​an 
  be either consonant or vowel, but not both at the same t​ime.
  Additionally, 0E23 (ร) is a consonant which, when doubled (รร), 
  functions as a vowel.  (In actual fact, it functions as a
  vowel-consonant combination as well, w​ith the final consonant sound
  varying based on its usage context.)  Though it can never be a 
  vowel i​f it occurs singly, these properties cannot be d​efined to 
  span two consecutive characters, so it IS included here.

  หมายเหตุ: คนไทยถือว่า 0E33 (◌ำ) เป็นเพียงสระเท่านั้น และไม่สามารถ
  ทำหน้าที่เป็นเพียงพยัญชนะได้ (จะต้องมีส่วนประกอบของสระเสมอ) 
  จึงไม่รวมไว้ที่นี่ แต่จริงๆ แล้วเป็นสระผสมพยัญชนะ ตามสัทศาสตร์ 
  ลงท้ายด้วยเสียง “ม” กลุ่มนี้ี้เน้นเฉพาะตัวอักษรไทย
  ที่เป็นพยัญชนะหรือสระก็ได้ แต่ไม่ใช่ทั้งสองตัวพร้อมกัน 
  นอกจากนี้ 0E23 (ร) ยังเป็นพยัญชนะซึ่งเมื่อเติม (รร) สองตัวแล้ว 
  จะทำหน้าที่เป็นสระ (ในความเป็นจริง มันทำหน้าที่เป็นเสียงสระ
  ผสมพยัญชนะด้วย โดยเสียงพยัญชนะตัวสุดท้ายจะแตกต่างกันไปตามบริบท
  การใช้งาน) แม้ว่าจะเป็นสระเดี่ยวไม่ได้หากเกิดขึ้นเพียงตัวเดียว 
  แต่คุณสมบัติเหล่านี้ไม่สามารถกำหนดให้ขยายสองช่วงติดต่อกันได้ 
  ตัวอักษร จึงรวมไว้ที่นี่

=item InThaiDigit / IsThaiDigit

  Matches Thai numerical digits only: ๐ ๑ ๒ ๓ ๔ ๕ ๖ ๗ ๘ ๙.
  
  จับคู่ตัวเลขไทยเท่านั้น: ๐ ๑ ๒ ๓ ๔ ๕ ๖ ๗ ๘ ๙.
  
=item InThaiCurrency / IsThaiCurrency

  Matches the Thai baht currency character: ฿.
  
  จับคู่อักขระสกุลเงินบาทไทย: ฿.
  
=back

=head1 EXPORTS

  Exports 'classes' by default.

=head1 PROPERTIES

The following properties are exported from Regexp::CharClasses::Thai:

  :classes
    InThai InThaiAlpha InThaiWord InThaiCons InThaiHCons InThaiMCons 
    InThaiLCons InThaiVowel InThaiPreVowel InThaiPostVowel 
    InThaiCompVowel InThaiDigit InThaiTone InThaiMute InThaiPunct 
    InThaiCurrency InThaiFinCons InThaiDualCons InThaiDualC1 
    InThaiDualC2 InThaiConsVowel
        
    IsThai IsThaiAlpha IsThaiWord IsThaiCons IsThaiHCons IsThaiMCons 
    IsThaiLCons IsThaiVowel IsThaiPreVowel IsThaiPostVowel 
    IsThaiCompVowel IsThaiDigit IsThaiTone IsThaiMute IsThaiPunct 
    IsThaiCurrency IsThaiFinCons IsThaiDualCons IsThaiDualC1
    IsThaiDualC2 IsThaiConsVowel

  :characters
    InKokai InKhokhai InKhokhuat InKhokhwai InKhokhon 
    InKhorakhang InNgongu InChochan InChoching InChochang InSoso 
    InShochoe InYoying InDochada InTopatak InThothan InThonangmontho 
    InThophuthao InNonen InDodek InTotao InThothung InThothahan 
    InThothong InNonu InBobaimai InPopla InPhophung InFofa InPhophan 
    InFofan InPhosamphao InMoma InYoyak InRorua InRu InLoling InLu 
    InWowaen InSosala InSorusi InSosua InHohip InLochula InOang 
    InHonokhuk InPaiyannoi InSaraa InMaihanakat InSaraaa InSaraam 
    InSarai InSaraii InSaraue InSarauee InSarau InSarauu InPhinthu 
    InBaht InSarae InSaraae InSarao InSaraaimaimuan InSaraaimaimalai 
    InLakkhangyao InMaiyamok InMaitaikhu InMaiek InMaitho InMaitri 
    InMaichattawa InThanthakhat InGaran InNikhahit InYamakkan 
    InFongman InThZero InThOne InThTwo InThThree InThFour InThFive 
    InThSix InThSeven InThEight InThNine InAngkhankhu InKhomut
    
    IsKokai IsKhokhai IsKhokhuat IsKhokhwai IsKhokhon 
    IsKhorakhang IsNgongu IsChochan IsChoching IsChochang IsSoso 
    IsShochoe IsYoying IsDochada IsTopatak IsThothan IsThonangmontho 
    IsThophuthao IsNonen IsDodek IsTotao IsThothung IsThothahan 
    IsThothong IsNonu IsBobaimai IsPopla IsPhophung IsFofa IsPhophan 
    IsFofan IsPhosamphao IsMoma IsYoyak IsRorua IsRu IsLoling IsLu 
    IsWowaen IsSosala IsSorusi IsSosua IsHohip IsLochula IsOang 
    IsHonokhuk IsPaiyannoi IsSaraa IsMaihanakat IsSaraaa IsSaraam 
    IsSarai IsSaraii IsSaraue IsSarauee IsSarau IsSarauu IsPhinthu 
    IsBaht IsSarae IsSaraae IsSarao IsSaraaimaimuan IsSaraaimaimalai 
    IsLakkhangyao IsMaiyamok IsMaitaikhu IsMaiek IsMaitho IsMaitri 
    IsMaichattawa IsThanthakhat IsGaran IsNikhahit IsYamakkan 
    IsFongman IsThZero IsThOne IsThTwo IsThThree IsThFour IsThFive 
    IsThSix IsThSeven IsThEight IsThNine IsAngkhankhu IsKhomut

=head1 EXAMPLES

  use Regexp::CharClasses::Thai qw( :all );

  'ก' =~ /\p{InThai}/;		 # Match
  'ก' =~ /\p{InThaiAlpha}/;	 # Match
  'ก' =~ /\p{InThaiCons}/;	 # Match
  'ก' =~ /\p{InThaiHCons}/;	 # No match
  'ก' =~ /\p{InThaiMCons}/;	 # Match
  'ก' =~ /\p{InThaiLCons}/;	 # No match
  'ก' =~ /\p{InThaiDigit}/;	 # No match
  'ก' =~ /\p{InThaiTone}/;	 # No match
  'ก' =~ /\p{InThaiVowel}/;	 # No match
  'ก' =~ /\p{InThaiCompVowel}/;	 # No match
  'ก' =~ /\p{InThaiPreVowel}/;	 # No match
  'ก' =~ /\p{InThaiPostVowel}/;	 # No match
  'ก' =~ /\p{InThaiPunct}/;	 # No match
  'ก' =~ /\p{IsKokai}/;		 # Match 

  'ไ' =~ /\p{InThai}/;		 # Match
  'ไ' =~ /\p{InThaiAlpha}/;	 # Match
  'ไ' =~ /\p{InThaiCons}/;	 # No match
  'ไ' =~ /\p{InThaiHCons}/;	 # No match
  'ไ' =~ /\p{InThaiMCons}/;	 # No match
  'ไ' =~ /\p{InThaiLCons}/;	 # No match
  'ไ' =~ /\p{InThaiDigit}/;	 # No match
  'ไ' =~ /\p{InThaiTone}/;	 # No match
  'ไ' =~ /\p{InThaiVowel}/;	 # Match
  'ไ' =~ /\p{InThaiCompVowel}/;	 # No match
  'ไ' =~ /\p{InThaiPreVowel}/;	 # Match
  'ไ' =~ /\p{InThaiPostVowel}/;	 # No match
  'ไ' =~ /\p{InThaiPunct}/;	 # No match
  'ไ' =~ /\p{IsSaraaimaimalai}/; # Match 

=head1 MORE COMPLEX USAGE EXAMPLE

    my $phrase = 'ข่าวนี้ได้แพร่สะพัดออกไปอย่างรวดเร็ว';
    print "A phrase with multiple syllables: $phrase\n";

    my $prevowel_syllables = $phrase  =~ s/
    (
      (?:\p{InThaiPreVowel})
      (?:
        (?:\p{InThaiDualC1}\p{InThaiDualC2})
        |
        (?:\p{InThaiCons}){1}
      )
      (?:[\p{InThaiTone}\p{InThaiCompVowel}\p{InThaiPostVowel}]){0,3}
      (?:
        (?:[\p{InThaiFinCons}\p{IsYoyak}\p{IsWowaen}]){0,5}
        (?!\p{InThaiPostVowel})
      )*
      (?:\p{InThaiMute})?
    )
    /($1)/gx;

    print "Syllables with pre-vowels marked: $phrase\n";
    print "Number of these marked syllables: $prevowel_syllables\n"; 

=head1 UNICODE

  All of the character codepoints in this module are based on the 
  official unicode designations f​or Thai as found in this chart:

  จุดโค้ดอักขระทั้งหมดในโมดูลนี้อิงตามการกำหนดยูนิโค้ดอย่าง
  เป็นทางการสำหรับภาษาไทยดังที่พบในแผนภูมินี้:  
  
  http://www.unicode.org/charts/PDF/U0E00.pdf
  
  The spellings of these latinized/transliterated character names
  as used in the property definitions f​or e​ach character come 
  directly from this unicode chart, sans spaces, and w​ith only their 
  first letter in uppercase.  The “Garan” (a common name) is added 
  as an alias f​or its official name, Thanthakhat (of uncommon usage).
  
  การสะกดของชื่ออักขระแบบลาติน/ทับศัพท์ที่ใช้ในคำจำกัดความของ
  คุณสมบัติสำหรับอักขระแต่ละตัวนั้นมาจากแผนภูมิยูนิโค้ดนี้ 
  การเว้นวรรคแบบไม่มี และมีเพียงอักษรตัวแรกเป็นตัวพิมพ์ใหญ่เท่านั้น 
  มีการเพิ่ม “Garan” (การันต์ - ชื่อสามัญ) เป็นนามแฝงสำหรับชื่อ
  อย่างเป็นทางการว่า ธัณฑฆาต (ซึ่งเป็นคำที่ใช้ไม่ธรรมดา)
  
=head1 USAGE NOTES

  Each of the d​efined properties may be accessed by either form:
  
  \p{InProperty} -OR-
  \p{IsProperty}
  
  For example, \p{InThaiVowel} and \p{IsThaiVowel} have identical
  implementation--there is no difference between them.  This 
  flexibility is built-in on account of ambiguities in the formats
  used by various codebases, and the fact that Perl supports both.
  
=head1 TO VIEW ALL CHARACTERS OF A CLASS...

  You may list the codepoints of a character class by simply
  calling that class as an ordinary function.  For example:
  
      my @chars = &InThaiCompVowel;
      print @chars;
  
  This will p​rint:
  
      0E31
      0E34
      0E35
      0E36
      0E37
      0E38
      0E39
      0E3A
      0E47
      0E4D

  To p​rint them as the actual UTF8 characters these codepoints
  represent, try this:
  
      my @chars = split(/\n/, InThaiPreVowel);
      foreach my $char (@chars) {
          print chr(hex($char));
      }

=head1 INSTALLATION

  To install this module type the following:

    perl Makefile.PL
    make
    make test
    make install

=head1 BUGS

  COMBINATIONS
    Combinations cannot be handled by this module.
    The doubled ร consonant (รร) in some syllables becomes 
    vowel + consonant; whereas it will only be counted as 
    a consonant here.
    
  CONSONANT CLUSTERS
    This feature (InThaiDualCons, InThaiDualC1, InThaiDualC2, etc.)
    is considered experimental and likely incomplete.  Please s​end
    the author additions f​or this list i​f you find it incomplete.

  AMBIGUITIES
    Where a character c​an function as either consonant or vowel, 
    it may get included in both categories, i.e. it may match 
    either one. This includes the Thai 0E24 (ฤ) and 0E26 (ฦ) 
    characters which are considered “sonorant” consonants by some, 
    and strictly as vowels by others.

=head1 PREREQUISITES

  Perl 5.8.3 or newer
  Exporter 5.57 or newer
  utf8
  
=head1 AUTHOR

  Erik Mundall <emundall@biblasia.com>.

=head1 COPYRIGHT and LICENSE

    Regexp::CharClasses::Thai is designed to enable detailed 
    regular expressions, w​ith the ability to identify important 
    characteristics of Thai alphabetic characters, digits and symbols.

    Copyright (C) 2023  Erik Mundall

    This program is free software: you c​an redistribute it and/or 
    modify it under the terms of the GNU General Public License as 
    published by the Free Software Foundation, either version 3 of 
    the License, or (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License f​or more details.

    You should have received a copy of the GNU General Public License
    along w​ith this program.  If not, see: 
    https://www.gnu.org/licenses/.

=head1 CHALLENGE

“Whatever your hand finds to d​o, d​o it with your might; 
f​or there is no work, nor device, nor knowledge, nor wisdom, 
in the grave, where you go.” --Ecclesiastes 9:10

“มือของเจ้าจับทำการงานอะไร จงกระทำการนั้นด้วยเต็มกำลังของเจ้า 
เพราะว่าในแดนคนตายที่เจ้าจะไปนั้นไม่มีการงาน หรือแนวความคิด 
หรือความรู้ หรือสติปัญญา” --ปัญญาจารย์ ๙:๑๐

=cut

