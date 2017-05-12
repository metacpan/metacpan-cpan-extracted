use strict;
use warnings;

package Template::Pure::DataProxy;

use Scalar::Util;
use Data::Dumper;

sub new {
  my ($proto, $data, %extra) = @_;
  my $class = ref($proto) || $proto;
  bless +{
    data => $data,
    extra => \%extra,
  }, $class;
}

sub can { 
  my ($self, $target) = @_;
  if(Scalar::Util::blessed $self->{data}) {
    if($self->{data}->can($target)) {
      return 1;
    } elsif(exists $self->{extra}{$target}) {
      return 1;
    } else {
      return 0;
    }
  } else {
    if(exists $self->{data}{$target}) {
      return 1;
    } elsif(exists $self->{extra}{$target}) {
      return 1;
    } else {
      return 0;
    }
  }
}

sub AUTOLOAD {
  return if our $AUTOLOAD =~ /DESTROY/;
  my $self = shift;
  ( my $method = $AUTOLOAD ) =~ s{.*::}{};

  if(Scalar::Util::blessed $self->{data}) {
    #warn "Proxy inside Proxy..." if $self->{data}->isa(ref $self);
    if($self->{data}->can($method)) {
      return $self->{data}->$method;
    } elsif(exists $self->{extra}{$method}) {
      return $self->{extra}{$method};
    } else {
      return;
      #die "No value at $method for $self";
    }
  } else {
    ## I think we can assume its a hashref then.
    if(exists $self->{data}{$method}) {
      return $self->{data}{$method};
    } elsif(exists $self->{extra}{$method}) {
      return $self->{extra}{$method};
    } else {
      return;
      #die "No value at $method in: ".Dumper($self->{data}) ."\n or \n". Dumper($self->{extra});
    }
  }
}

1;

