use strict;
use warnings;
use Sub::Middler;

my $middler=Sub::Middler->new;

$middler->register(mw1(x=>1));
$middler->register(mw2(y=>10));

my $head=$middler->link(
  sub {
    print "Result: $_[0]\n";
  }
);

$head->(0); # Call the Chain

# Middleware 1
sub mw1 {
  my %options=@_;
  sub {
    my ($next,$index)=@_;
    sub {
      my $work=$_[0]+$options{x};
      $next->($work);
    }
  }
}

# Middleware 2
sub mw2 {
  my %options=@_;
  sub {
    my ($next, $index)=@_;
    sub {
      my $work= $_[0]*$options{y};
      $next->( $work);
    }
  }
}
