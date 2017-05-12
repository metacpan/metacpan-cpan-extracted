# Copyrights 2001-2014 by [Mark Overmeer <perl@overmeer.net>].
#  For other contributors see Changes.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.01.

package Object::Realize::Later;
our $VERSION = '0.19';


use Carp;
use Scalar::Util 'weaken';

use warnings;
use strict;
no strict 'refs';


my $named  = 'ORL_realization_method';
my $helper = 'ORL_fake_realized';


sub init_code($)
{   my $args    = shift;

    <<INIT_CODE;
  package $args->{class};
  require $args->{source_module};

  my \$$helper = bless {}, '$args->{becomes}';
INIT_CODE
}

sub isa_code($)
{   my $args    = shift;

    <<ISA_CODE;
  sub isa(\$)
  {   my (\$thing, \$what) = \@_;
      return 1 if \$thing->SUPER::isa(\$what);  # real dependency?
      \$$helper\->isa(\$what);
  }
ISA_CODE
}


sub can_code($)
{   my $args = shift;
    my $becomes = $args->{becomes};

    <<CAN_CODE;
  sub can(\$)
  {   my (\$thing, \$method) = \@_;
      my \$func;
      \$func = \$thing->SUPER::can(\$method)
         and return \$func;

      \$func = \$$helper\->can(\$method)
         or return;

      # wrap func() to trigger load if needed.
      sub { ref \$thing
            ? \$func->(\$thing->forceRealize, \@_)
            : \$func->(\$thing, \@_)
          };
  }
CAN_CODE
}


sub AUTOLOAD_code($)
{   my $args   = shift;

    <<'CODE1' . ($args->{believe_caller} ? '' : <<NOT_BELIEVE) . <<CODE2;
  our $AUTOLOAD;
  sub AUTOLOAD(@)
  {  my $call = substr $AUTOLOAD, rindex($AUTOLOAD, ':')+1;
     return if $call eq 'DESTROY';
CODE1

     unless(\$$helper->can(\$call) || \$$helper->can('AUTOLOAD'))
     {   use Carp;
         croak "Unknown method \$call called";
     }
NOT_BELIEVE
    # forward as class method if required
    shift and return $args->{becomes}->\$call( \@_ ) unless ref \$_[0];

     \$_[0]->forceRealize;
     my \$made = shift;
     \$made->\$call(\@_);
  }
CODE2
}


sub realize_code($)
{   my $args   = shift;
    my $pkg    = __PACKAGE__;
    my $argspck= join "'\n         , '", %$args;

    <<REALIZE_CODE .($args->{warn_realization} ? <<'WARN' : '') .<<REALIZE_CODE;
  sub forceRealize(\$)
  {
REALIZE_CODE
      require Carp;
      Carp::carp("Realization of $_[0]");
WARN
      ${pkg}->realize
        ( ref_object => \\\${_[0]}
        , caller     => [ caller 1 ]
        , '$argspck'
        );
  }
REALIZE_CODE
}


sub will_realize_code($)
{   my $args = shift;
    my $becomes = $args->{becomes};
    <<WILL_CODE;
sub willRealize() {'$becomes'}
WILL_CODE
}


sub realize(@)
{   my ($class, %args) = @_;
    my $object  = ${$args{ref_object}};
    my $realize = $args{realize};

    my $already = $class->realizationOf($object);
    if(defined $already && ref $already ne ref $object)
    {   if($args{warn_realize_again})
        {   my (undef, $filename, $line) = @{$args{caller}};
            warn "Attempt to realize object again: old reference caught at $filename line $line.\n"
        }

        return ${$args{ref_object}} = $already;
    }

    my $loaded  = ref $realize ? $realize->($object) : $object->$realize;

    warn "Load produces a ".ref($loaded)
       . " where a $args{becomes} is expected.\n"
           unless $loaded->isa($args{becomes});

    ${$args{ref_object}} = $loaded;
    $class->realizationOf($object, $loaded);
} 


my %realization;

sub realizationOf($;$)
{   my ($class, $object) = (shift, shift);
    my $unique = "$object";

    if(@_)
    {   $realization{$unique} = shift;
        weaken $realization{$unique};
    }

    $realization{$unique};
}


sub import(@)
{   my ($class, %args) = @_;

    confess "Require 'becomes'" unless $args{becomes};
    confess "Require 'realize'" unless $args{realize};

    $args{class}                = caller;
    $args{warn_realization}   ||= 0;
    $args{warn_realize_again} ||= 0;
    $args{source_module}      ||= $args{becomes};

    # A reference to code will stringify at the eval below.  To solve
    # this, it is tranformed into a call to a named subroutine.
    if(ref $args{realize} eq 'CODE')
    {   my $named_method = "$args{class}::$named";
        *{$named_method} = $args{realize};
        $args{realize}   = $named_method;
    }

    # Produce the code

    my $args = \%args;
    my $eval
       = init_code($args)
       . isa_code($args)
       . can_code($args)
       . AUTOLOAD_code($args)
       . realize_code($args)
       . will_realize_code($args)
       ;
#warn $eval;

    # Install the code

    eval $eval;
    die $@ if $@;

    1;
}


1;
