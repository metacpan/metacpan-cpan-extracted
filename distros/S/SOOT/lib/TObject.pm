package # Hide from PAUSE
  TObject;
use strict;
use warnings;
use vars qw/$AUTOLOAD $isROOT/;
BEGIN {$isROOT = 1}

use overload 
  '==' => sub {
    if ($_[2] or not ref $_[1] or not $_[1]->isa('TObject')) {
      return();
    }
    return SOOT::API::is_same_object($_[0], $_[1]);
  },
  'bool' => sub {
    return defined($_[1]);
  };
#  '&{}' => sub {
#    my $obj = shift;
#    my $class = ref($obj);
#    return sub {
#      if (@_ == 1 and ref($_[0]) and ref($_[0])->isa($class)) {
#        return SOOT::CallAssignmentOperator($class, $obj, $_[0]);
#      }
#      else {
#        Carp::croak("Trying to call assignment operator without an object to copy");
#      }
#    };
#  };

sub AUTOLOAD {
  $AUTOLOAD =~ s/::([^:]+)$//;
  my $method = $1;

  my @args = @_;
  @_ = ($AUTOLOAD, $method, \@args);
  goto &SOOT::CallMethod;
}

1;
