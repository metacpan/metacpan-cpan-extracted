# $Source: /Users/clajac/cvsroot//Scripting/Scripting/Engine/js.pm,v $
# $Author: clajac $
# $Date: 2003/07/20 22:30:24 $
# $Revision: 1.4 $

package Scripting::Engine::js;
use Scripting::Expose qw();
use JavaScript qw(:all);
use strict;

my $Runtime = JavaScript::Runtime->new();

sub load {
  my ($pkg, $path, $ns, $source) = @_;

  my $cx = $Runtime->create_context();
  register($cx, $ns);

  my $script = $cx->compile($source);
  
  return sub {
    Scripting::Security->executing($path);
    $script->exec();
  };
}

use Data::Dumper qw(Dumper);

sub register {
  my ($cx, $ns) = @_;

  my %functions = Scripting::Expose->functions_for_namespace($ns);
  while(my ($func_name, $func_cb) = each %functions) {
    $cx->bind_function(name => $func_name, func => $func_cb);
  }

  my @classes = Scripting::Expose->classes_for_namespace($ns);
  foreach my $class (@classes) {
    my %init;
    $init{name} = $class->class;
    $init{package} = $class->package;
    $init{methods} = {};
  
    my $has_class_methods;

    while(my ($name, $cb) = each %{$class->{instance_methods}}) {
      $init{methods}->{$name} = $cb;
    }

    while(my ($name, $cb) = each %{$class->{class_methods}}) {
      $init{methods}->{$name} = $cb;
      $has_class_methods = 1;
    }

    if($class->{constructor}) {
      $init{constructor} = $class->{constructor};
    } else {
      $init{constructor} = sub {};
      $init{flags} |= JS_CLASS_NO_INSTANCE;
    }
    
    $cx->bind_class(%init);
    $cx->bind_object($class->class, bless {}, $class->package) if $has_class_methods;
  }
}

1;
