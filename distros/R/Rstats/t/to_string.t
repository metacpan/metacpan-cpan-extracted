use Test::More 'no_plan';
use strict;
use warnings;

use Rstats;

# complex
{
  # complex - image number is 0
  {
    my $z1 = r->c_complex({re => 1, im => 0});
    is("$z1", "[1] 1+0i\n");
  }
  
  # complex - basic
  {
    my $z1 = r->c_complex({re => 1, im => 2});
    is("$z1", "[1] 1+2i\n");
  }
  
  # complex - image number is minus
  {
    my $z1 = r->c_complex({re => 1, im => -1});
    is("$z1", "[1] 1-1i\n");
  }
}

# to_string
{
  # to_string - TRUE
  {
    my $x1 = TRUE;
    is("$x1", "[1] TRUE\n");
  }

  # to_string - FALSE
  {
    my $x1 = FALSE;
    is("$x1", "[1] FALSE\n");
  }

  # to_string - NA
  {
    my $x1 = NA;
    is("$x1", "[1] NA\n");
  }

  # to_string - NaN
  {
    my $x1 = NaN;
    is("$x1", "[1] NaN\n");
  }

  # to_string - Inf
  {
    my $x1 = Inf;
    is("$x1", "[1] Inf\n");
  }

  # to_string - -Inf
  {
    my $x1 = -Inf;
    is("$x1", "[1] -Inf\n");
  }
}


# to_string
{
  # to_string - character, 1 dimention
  {
    my $x1 = array(c_("a", "b"));
    my $x1_str = "$x1";
    $x1_str =~ s/[ \t]+/ /;
    my $expected = qq/[1] "a" "b"\n/;
    is($x1_str, $expected);
  }

  # to_string - character, 2 dimention
  {
    my $x1 = array(C_('1:4'), c_(4, 1));
    my $x2 = r->as->character($x1);
    my $x2_str = "$x2";
    $x2_str =~ s/[ \t]+/ /;

  my $expected = <<'EOS';
     [,1]
[1,] "1"
[2,] "2"
[3,] "3"
[4,] "4"
EOS
    $expected =~ s/[ \t]+/ /;
    
    is($x2_str, $expected);
  }

  # to_string - character,3 dimention
  {
    my $x1 = array(C_('1:24'), c_(4, 3, 2));
    $x1 = r->as->character($x1);
    my $x1_str = "$x1";
    $x1_str =~ s/[ \t]+/ /;

  my $expected = <<'EOS';
,,1
     [,1] [,2] [,3]
[1,] "1" "5" "9"
[2,] "2" "6" "10"
[3,] "3" "7" "11"
[4,] "4" "8" "12"
,,2
     [,1] [,2] [,3]
[1,] "13" "17" "21"
[2,] "14" "18" "22"
[3,] "15" "19" "23"
[4,] "16" "20" "24"
EOS
    $expected =~ s/[ \t]+/ /;
    
    is($x1_str, $expected);
  }

  # to_string - one element
  {
    my $x1 = array(0);
    my $x1_str = "$x1";
    $x1_str =~ s/[ \t]+/ /;
    my $expected = "[1] 0\n";
    is($x1_str, $expected);
  }

  # to_string - 2-dimention
  {
    my $x1 = array(C_('1:12'), c_(4, 3));
    my $x1_str = "$x1";
    $x1_str =~ s/[ \t]+/ /;

  my $expected = <<'EOS';
     [,1] [,2] [,3]
[1,] 1 5 9
[2,] 2 6 10
[3,] 3 7 11
[4,] 4 8 12
EOS
    $expected =~ s/[ \t]+/ /;
    
    is($x1_str, $expected);
  }

  # to_string - 1-dimention
  {
    my $x1 = array(C_('1:4'));
    my $x1_str = "$x1";
    $x1_str =~ s/[ \t]+/ /;

  my $expected = <<'EOS';
[1] 1 2 3 4
EOS
    $expected =~ s/[ \t]+/ /;
    
    is($x1_str, $expected);
  }

  # to_string - 1-dimention, as_vector
  {
    my $x1 = array(C_('1:4'));
    my $x2 = r->as->vector($x1);
    my $x2_str = "$x2";
    $x2_str =~ s/[ \t]+/ /;

  my $expected = <<'EOS';
[1] 1 2 3 4
EOS
    $expected =~ s/[ \t]+/ /;
    
    is($x2_str, $expected);
  }

  # to_string - 1-dimention, as_matrix
  {
    my $x1 = array(C_('1:4'));
    my $x2 = r->as->matrix($x1);
    my $x2_str = "$x2";
    $x2_str =~ s/[ \t]+/ /;

  my $expected = <<'EOS';
   [,1]
[1,] 1
[2,] 2
[3,] 3
[4,] 4
EOS
    $expected =~ s/[ \t]+/ /;
    
    is($x2_str, $expected);
  }
  

  # to_string - 1-dimention, TRUE, FALSE
  {
    my $x1 = array(c_(r->TRUE, r->FALSE));
    my $x1_str = "$x1";
    $x1_str =~ s/[ \t]+/ /;

  my $expected = <<'EOS';
[1] TRUE FALSE
EOS
    $expected =~ s/[ \t]+/ /;
    
    is($x1_str, $expected);
  }

  # to_string - 2-dimention
  {
    my $x1 = array(C_('1:12'), c_(4, 3));
    my $x2 = r->as->matrix($x1);
    my $x2_str = "$x2";
    $x2_str =~ s/[ \t]+/ /;

  my $expected = <<'EOS';
     [,1] [,2] [,3]
[1,] 1 5 9
[2,] 2 6 10
[3,] 3 7 11
[4,] 4 8 12
EOS
    $expected =~ s/[ \t]+/ /;
    
    is($x2_str, $expected);
  }

  # to_string - 2-dimention, as_vector
  {
    my $x1 = array(C_('1:12'), c_(4, 3));
    my $x2 = r->as->vector($x1);
    my $x2_str = "$x2";
    $x2_str =~ s/[ \t]+/ /;

  my $expected = <<'EOS';
[1] 1 2 3 4 5 6 7 8 9 10 11 12
EOS
    $expected =~ s/[ \t]+/ /;
    
    is($x2_str, $expected);
  }

  # to_string - 2-dimention, as_matrix
  {
    my $x1 = array(C_('1:12'), c_(4, 3));
    my $x2 = r->as->matrix($x1);
    my $x2_str = "$x2";
    $x2_str =~ s/[ \t]+/ /;

  my $expected = <<'EOS';
     [,1] [,2] [,3]
[1,] 1 5 9
[2,] 2 6 10
[3,] 3 7 11
[4,] 4 8 12
EOS
    $expected =~ s/[ \t]+/ /;
    
    is($x2_str, $expected);
  }
  
  # to_string - 3-dimention
  {
    my $x1 = array(C_('1:24'), c_(4, 3, 2));
    my $x1_str = "$x1";
    $x1_str =~ s/[ \t]+/ /;

  my $expected = <<'EOS';
,,1
     [,1] [,2] [,3]
[1,] 1 5 9
[2,] 2 6 10
[3,] 3 7 11
[4,] 4 8 12
,,2
     [,1] [,2] [,3]
[1,] 13 17 21
[2,] 14 18 22
[3,] 15 19 23
[4,] 16 20 24
EOS
    $expected =~ s/[ \t]+/ /;
    
    is($x1_str, $expected);
  }

  # to_string - 3-dimention, as_vector
  {
    my $x1 = array(C_('1:24'), c_(4, 3, 2));
    my $x2 = r->as->vector($x1);
    my $x2_str = "$x2";
    $x2_str =~ s/[ \t]+/ /;

  my $expected = <<'EOS';
[1] 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24
EOS
    $expected =~ s/[ \t]+/ /;
    
    is($x2_str, $expected);
  }

  # to_string - 3-dimention, as_matrix
  {
    my $x1 = array(C_('1:24'), c_(4, 3, 2));
    my $x2 = r->as->matrix($x1);
    my $x2_str = "$x2";
    $x2_str =~ s/[ \t]+/ /;
    my $expected = <<'EOS';
     [,1]
[1,] 1
[2,] 2
[3,] 3
[4,] 4
[5,] 5
[6,] 6
[7,] 7
[8,] 8
[9,] 9
[10,] 10
[11,] 11
[12,] 12
[13,] 13
[14,] 14
[15,] 15
[16,] 16
[17,] 17
[18,] 18
[19,] 19
[20,] 20
[21,] 21
[22,] 22
[23,] 23
[24,] 24
EOS
    $expected =~ s/[ \t]+/ /;
    
    is($x2_str, $expected);
  }
  
  # to_string - 4 dimention
  {
    my $x1 = array(C_('1:120'), c_(5, 4, 3, 2));
    my $x1_str = "$x1";
    $x1_str =~ s/[ \t]+/ /;

  my $expected = <<'EOS';
,,,1
,,1
     [,1] [,2] [,3] [,4]
[1,] 1 6 11 16
[2,] 2 7 12 17
[3,] 3 8 13 18
[4,] 4 9 14 19
[5,] 5 10 15 20
,,2
     [,1] [,2] [,3] [,4]
[1,] 21 26 31 36
[2,] 22 27 32 37
[3,] 23 28 33 38
[4,] 24 29 34 39
[5,] 25 30 35 40
,,3
     [,1] [,2] [,3] [,4]
[1,] 41 46 51 56
[2,] 42 47 52 57
[3,] 43 48 53 58
[4,] 44 49 54 59
[5,] 45 50 55 60
,,,2
,,1
     [,1] [,2] [,3] [,4]
[1,] 61 66 71 76
[2,] 62 67 72 77
[3,] 63 68 73 78
[4,] 64 69 74 79
[5,] 65 70 75 80
,,2
     [,1] [,2] [,3] [,4]
[1,] 81 86 91 96
[2,] 82 87 92 97
[3,] 83 88 93 98
[4,] 84 89 94 99
[5,] 85 90 95 100
,,3
     [,1] [,2] [,3] [,4]
[1,] 101 106 111 116
[2,] 102 107 112 117
[3,] 103 108 113 118
[4,] 104 109 114 119
[5,] 105 110 115 120
EOS
    $expected =~ s/[ \t]+/ /;
    
    is($x1_str, $expected);
  }
}
