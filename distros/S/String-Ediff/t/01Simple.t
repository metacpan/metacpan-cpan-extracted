#!/usr/bin/env perl -w
use strict;
use Test;
BEGIN { plan tests => 10 }

use String::Ediff;

ok(test1(), "SUCCESS", "FAILED test1()");
ok(test2(), "SUCCESS", "FAILED test2()");
ok(test3(), "SUCCESS", "FAILED test3()");
ok(test4(), "SUCCESS", "FAILED test4()");
ok(test5(), "SUCCESS", "FAILED test5()");
ok(test6(), "SUCCESS", "FAILED test6()");
ok(test7(), "SUCCESS", "FAILED test7()");
ok(test8(), "SUCCESS", "FAILED test8()");
ok(test9(), "SUCCESS", "FAILED test9()");
ok(test10(), "SUCCESS", "FAILED test10()");

sub test1 {
  my $s1 = "hello world";
  my $s2 = "hxello worlyd";

  my $indices = String::Ediff::ediff($s1, $s2);
  if ($indices !~ /^1 10 0 0 2 11 0 0\s*$/) {
    print $indices, "\n";
    return "FAILURE";
  }
  return "SUCCESS";
}

sub test2 {
  my $s1 = "hello world a hello world";
  my $s2 = "hxello worlyd xyz hello";

  my $indices = String::Ediff::ediff($s1, $s2);
  if ($indices !~ /^1 10 0 0 2 11 0 0 13 20 0 0 17 23 0 0\s*$/) {
    print $indices, "\n";
    return "FAILURE";
  }
  return "SUCCESS";
}

sub test3 {
  my $s1 = " &nbsp; &nbsp; &nbsp; &nbsp; &nbsp;crit=&gt;'red', emerg=&gt;'red', warning=&gt;&quot;red&quot;);";

  my $s2 = " &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; crit=&gt;'red', emerg=&gt;'red', warning=&gt;&quot;red&quot;,
 &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; d=&gt;&quot;blue&quot;, w=&gt;&quot;red&quot;,n=&gt;&quot;green&quot;,
 &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; i=&gt;'pink',e=&gt;'red',a=&gt;'red',
 &nbsp; &nbsp; &nbsp; &nbsp; &nbsp; c=&gt;'red');";

  my $indices = String::Ediff::ediff($s1, $s2);
  if ($indices !~ /^0 35 0 0 0 36 0 0 35 95 0 0 35 96 0 0\s*$/) {
    print $indices, "\n";
    return "FAILURE";
  }
  return "SUCCESS";
}

sub test4 {
  my $s1 = "hello work";
  my $s2 = "h  xello
  world";

  my $indices = String::Ediff::ediff($s1, $s2);
  if ($indices !~ /^1 6 0 0 4 11 0 1\s*$/) {
    print $indices, "\n";
    return "FAILURE";
  }
  return "SUCCESS";
}

sub test5 {
  my $s1 = "     int node_idx = find_node(t, ap->m_node_id,  
    
                              t->m_str[ap->m_begin_idx]);  
";
  my $s2 = "     int node_idx = find_node(t, ap->m_node_id, ap_begin_char(t, ap));
  ";

  my $indices = String::Ediff::ediff($s1, $s2);
  if ($indices !~ /^0 85 0 2 0 48 0 0 99 106 2 2 50 57 0 0\s*$/) {
    print $indices, "\n";
    return "FAILURE";
  }
  return "SUCCESS";
}

sub test6 {
  my $s1 = 'for comp in *; do
    if [ -d $comp -a $comp != "build" ]; then
        cd $comp
';
  my $s2 = '
# Build the controller bean
cd controller
';
  my $indices = String::Ediff::ediff($s1, $s2);
  if ($indices !~ /^50 54 1 1 4 9 1 1 58 62 1 1 8 13 1 1 62 75 1 2 27 32 1 2\s*$/) {
    test_dump($indices, $s1, $s2);
    return "FAILURE";
  }
  return "SUCCESS";
}

# test for fixing this bug:
# > 746       ret = (char*)malloc(sizeof(char) * INT_LEN * ix * 8);
# > 747       ret[0] = 0;
# Note if ix == 0, then ret has no memory allocated, ret[0] = 0
#      could core_dump perl
# Reported by: Jonathan Noack
# Analyzed by: Anton Berezin
sub test7 {
  my $left_diff = " 1* \$Id\$";
  my $right_diff = " 1* \$Header\$";
  my $diff_str = String::Ediff::ediff($left_diff, $right_diff);
  return "SUCCESS";
}

sub test8 {
  my $s2 = "
      closeConnection(conn);
    }
    return artifactsList;    
  }

  /**
";
  my $s1 = "
      closeConnection(conn);
    }
    return artifactsList;		
  }

  /**
";

  my $indices = String::Ediff::ediff($s1, $s2);
  if ($indices !~ /^0 75 0 7 0 77 0 7\s*$/) {
    print $indices, "\n";
    return "FAILURE";
  }
  return "SUCCESS";
}

sub test9 {
  {
    my $s2 = "    }
    return artifactInfo;

  }        

  /**
   * ";
    my $s1 = "    }
    return artifactInfo;

  }				

  /**
   * ";
    my $indices = String::Ediff::ediff($s1, $s2);
    if ($indices !~ /^0 52 0 6 0 56 0 6\s*$/) {
      print length($s1), " ", length($s2), "\n";
      print $indices, "\n";
      return "FAILURE";
    }
  }
  {
    my $s2 = "    }
    return artifactInfo;

  }        

  /**
";
    my $s1 = "    }
    return artifactInfo;

  }				

  /**
";

    my $indices = String::Ediff::ediff($s1, $s2);
    if ($indices !~ /^0 47 0 6 0 51 0 6\s*$/) {
      print length($s1), " ", length($s2), "\n";
      print $indices, "\n";
      return "FAILURE";
    }
  }
  return "SUCCESS";
}

sub test10 {
  my $s2 = "  
  static final long serialVersionUID = 647693002927539822L;
  
  static final public String TYPE_SERVICE  				= \"Service\"; 
  static final public String TYPE_BUILDING_BLOCK  = \"BuildingBlock\"; 
  static final public String TYPE_OTHER  					= \"Other\"; 
  
  static final public String STATUS_NOT_DEPLOYED  		= \"STATUS_NOT_DEPLOYED\"; 
  static final public String STATUS_DEPLOYED  	  		= \"STATUS_DEPLOYED\"; 
  static final public String STATUS_PARTIALLY_DEPLOYED  = \"STATUS_PARTIALLY_DEPLOYED\";
  
  static final public String SERVICE_STATE_DISCARDED  	  = \"SERVICE_STATE_DISCARDED\"; 
  static final public String SERVICE_STATE_ACTIVE  	  		= \"SERVICE_STATE_ACTIVE\"; 
  
  protected String name = \"\";                               // maps DB field
  protected String version = \"\";                            // maps DB field";
  my $s1 = "  
  static final long serialVersionUID = 647693002927539822L;
  
  static final public String TYPE_SERVICE          = \"Service\"; 
  static final public String TYPE_BUILDING_BLOCK  = \"BuildingBlock\"; 
  static final public String TYPE_OTHER            = \"Other\"; 
  
  static final public String STATUS_NOT_DEPLOYED      = \"STATUS_NOT_DEPLOYED\"; 
  static final public String STATUS_DEPLOYED          = \"STATUS_DEPLOYED\"; 
  static final public String STATUS_PARTIALLY_DEPLOYED  = \"STATUS_PARTIALLY_DEPLOYED\";
  
  static final public String SERVICE_STATE_DISCARDED      = \"SERVICE_STATE_DISCARDED\"; 
  static final public String SERVICE_STATE_ACTIVE          = \"SERVICE_STATE_ACTIVE\"; 
  
  protected String name = \"\";                               // maps DB field
  protected String version = \"\";                            // maps DB field";

  my $indices = String::Ediff::ediff($s1, $s2);
  if ($indices !~ /^0 117 0 3 0 113 0 3 107 252 3 5 107 243 3 5 240 321 5 7 236 310 5 7 315 401 7 8 306 387 7 8 391 571 8 11 380 556 8 11 391 660 8 12 380 642 8 12 650 843 12 15 635 825 12 15\s*$/) {
    test_dump($indices, $s1, $s2);
    return "FAILURE";
  }
  return "SUCCESS";
}

sub test_dump {
  my ($indices, $s1, $s2) = @_;
  print "\t", $indices, "\n";
  my @indices = split / /, $indices;
  print "\t", scalar(@indices), "\n";
  for (my $i = 0; $i < @indices; $i+=8) {
    my ($i1, $i2, undef, undef, $i3, $i4) = @indices[$i..$i+7];
    print "\t!$i1 $i2 ! $i3 $i4!\n";
    my $len1 = $i2-$i1;
    my $len2 = $i4-$i3;
    print "\t!$len1 ! $len2!\n";
    my ($val1) = ($s1 =~ /^.{$i1}(.{$len1})/s);
    my ($val2) = ($s2 =~ /^.{$i3}(.{$len2})/s);
    print "\t!$val1 ! $val2!\n";
  }
}

exit;

__DATA__
test6

          1         2         3         4         5         6         7         8
01234567890123456789012345678901234567890123456789012345678901234567890123456789012
for comp in *; do^    if [ -d $comp -a $comp != "build" ]; then^        cd $comp^
for comp in *; doif [ -d $comp -a $comp != "build" ]; thencd $comp

          1         2         3         4         5         6         7         8
01234567890123456789012345678901234567890123456789012345678901234567890123456789012
^# Build the controller bean^cd controller^
# Build the controller beancd controller

50 54 1 1 5 9 1 1 58 62 1 1 8 13 1 1 62 75 1 2 28 33 1 2 
45 49     3 7     53 57     7 11     57 61     26 30            # before adjust

fixed!
50 54 1 1 4 9 1 1 58 62 1 1 8 13 1 1 62 75 1 2 27 32 1 2 
