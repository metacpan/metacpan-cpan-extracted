package Rstats::Object;
use Object::Simple -base;

use overload
  '+' => sub {
    my $x1 = shift;
    my $r = $x1->r;

    return Rstats::Func::add($r, Rstats::Func::_fix_pos($r, $x1, @_));
  },
  '-' => sub {
    my $x1 = shift;
    my $r = $x1->r;

    return Rstats::Func::subtract($r, Rstats::Func::_fix_pos($r, $x1, @_));
  },
  '*' => sub {
    my $x1 = shift;
    my $r = $x1->r;

    return Rstats::Func::multiply($r, Rstats::Func::_fix_pos($r, $x1, @_));
  },
  '/' => sub {
    my $x1 = shift;
    my $r = $x1->r;

    Rstats::Func::divide($r, Rstats::Func::_fix_pos($r, $x1, @_));
  },
  '%' => sub {
    my $x1 = shift;
    my $r = $x1->r;

    return Rstats::Func::remainder($r, Rstats::Func::_fix_pos($r, $x1, @_));
  },
  '**' => sub {
    my $x1 = shift;
    my $r = $x1->r;

    return Rstats::Func::pow($r, Rstats::Func::_fix_pos($r, $x1, @_));
  },
  '<' => sub {
    my $x1 = shift;
    my $r = $x1->r;

    return Rstats::Func::less_than($r, Rstats::Func::_fix_pos($r, $x1, @_));
  },
  '<=' => sub {
    my $x1 = shift;
    my $r = $x1->r;

    return Rstats::Func::less_than_or_equal($r, Rstats::Func::_fix_pos($r, $x1, @_));
  },
  '>' => sub {
    my $x1 = shift;
    my $r = $x1->r;

    return Rstats::Func::more_than($r, Rstats::Func::_fix_pos($r, $x1, @_));
  },
  '>=' => sub {
    my $x1 = shift;
    my $r = $x1->r;

    return Rstats::Func::more_than_or_equal($r, Rstats::Func::_fix_pos($r, $x1, @_));
  },
  '==' => sub {
    my $x1 = shift;
    my $r = $x1->r;

    return Rstats::Func::equal($r, Rstats::Func::_fix_pos($r, $x1, @_));
  },
  '!=' => sub {
    my $x1 = shift;
    my $r = $x1->r;

    return Rstats::Func::not_equal($r, Rstats::Func::_fix_pos($r, $x1, @_));
  },
  '&' => sub {
    my $x1 = shift;
    my $r = $x1->r;

    return Rstats::Func::and($r, Rstats::Func::_fix_pos($r, $x1, @_));
  },
  '|' => sub {
    my $x1 = shift;
    my $r = $x1->r;

    return Rstats::Func::or($r, Rstats::Func::_fix_pos($r, $x1, @_));
  },
  'x' => sub {
    my $x1 = shift;
    my $r = $x1->r;

    return Rstats::Func::inner_product($r, Rstats::Func::_fix_pos($r, $x1, @_));
  },
  bool => sub {
    my $x1 = shift;
    my $r = $x1->r;
    
    return Rstats::Func::bool($r, $x1, @_);
  },
  'neg' => sub {
    my $x1 = shift;
    my $r = $x1->r;
    
    return Rstats::Func::negate($r, $x1, @_);
  },
  '""' => sub {
    my $x1 = shift;
    my $r = $x1->r;
    
    return Rstats::Func::to_string($r, $x1, @_);
  },
  fallback => 1;

use Rstats::Func;

has 'r';
has list => sub { [] };
has 'vector';

sub AUTOLOAD {
  my $self = shift;
  
  my ($package, $method) = split /::(\w+)$/, our $AUTOLOAD;
  Carp::croak "Undefined subroutine &${package}::$method called"
    unless Scalar::Util::blessed $self && $self->isa(__PACKAGE__);

  my $r = $self->r;

  # Call helper with current controller
  Carp::croak qq{Can't locate object method "$method" via package "$package"}
    unless $r && (my $helper = $r->get_helper($method));
  
  # Helper
  if (ref $helper eq 'CODE') {
    return $helper->($r, $self, @_);
  }
  #Proxy
  else {
    $helper->{args} = [$self];
    return $helper;
  }
}

sub DESTROY {}

1;

=head1 NAME

Rstats::Object - Rstats object

1;
