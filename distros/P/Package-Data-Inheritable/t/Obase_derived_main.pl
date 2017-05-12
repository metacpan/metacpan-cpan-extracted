#!perl
use strict;
use warnings;

use lib qw( t t/lib ./lib ../lib );

{
  package Base;
  use base qw( Package::Data::Inheritable );
  #Package::Data::Inheritable->inherit();
  BEGIN {
      our @EXPORT_INHERIT = qw( $staticData1 $staticData2 $staticData3 );
  }
  our $staticData1 = 1;   # overidden in Derived
  our $staticData2 = 2;   # untouched in Derived
  our $staticData3 = 3;   # reassigned in Derived
  
  sub new {
      my $class = ref $_[0] || $_[0];
  
      bless {
          instanceData1 => 1,
      }, $class;
  }
  
  sub staticMethodA {
      print "- staticMethodA\n";
  }
  
  sub staticMethodB {
      print "- Base staticMethodB  $staticData1\n";
  }
  
  sub staticDump {
      print "Base.staticDump()\n",
            "\tstaticData1: $staticData1\n",
            "\tstaticData2: $staticData2\n",
            "\tstaticData3: $staticData3\n";
  }
  sub instanceDump {
      my $self = shift;
      print "Base.instanceDump() ", ref $self, "\n",
            "\tstaticData1: $staticData1\n",
            "\tinstanceData1: $self->{instanceData1}\n";
  }
}


########################################
{
  package Derived;
  use base qw( Base );
  BEGIN {
      # must be before inherit() below, otherwise will not override
      our @EXPORT_INHERIT = qw( $staticData1 );
  
      inherit Base;
  };
  # must be outside BEGIN block if not inherited. our scoping applies.
  our $staticData1 = "111";

  $staticData3 = "333";
  
  sub new {
      my $class = ref $_[0] || $_[0];
  
      bless {
          %{ $class->SUPER::new(@_) },
          instanceData2 => "222",
      }, $class;
  }
  
  
  sub staticMethodB {
      print "- Derived staticMethodB  $staticData1\n";
  }
  
  sub staticDumpB {
      print "Derived.staticDumpB()\n",
            "\tstaticData1: $staticData1\n",
            "\tstaticData2: $staticData2\n",
            "\tstaticData3: $staticData3\n";
  }
  sub instanceDumpB {
      my $self = shift;
      print "Derived.instanceDumpB() ", ref($self), "\n",
            "\tstaticData1: $staticData1\n";
  }
}

########################################
my    $base = Base->new();
my $derived = Derived->new();

# static methods defined in a base class always see the base class data
#  even when invoked on a derived class
$base->staticMethodA();
$derived->staticMethodA();
$base->staticMethodB();
$derived->staticMethodB();

$base->staticDump();
$base->instanceDump();
$derived->staticDump();
print "\n";
# even *instance* methods defined in a base class see the base class data
#  even when invoked on a derived class
# *furthermore*, they don't see the derived instance data either
$derived->instanceDump();

$derived->staticDumpB();
$derived->instanceDumpB();

