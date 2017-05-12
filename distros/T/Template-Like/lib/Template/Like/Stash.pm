package Template::Like::Stash;

use strict;

sub new {
  my $class = shift;
  my $args  = shift || {};
  
  return bless $args, $class;
}

sub set {
  my $self = shift;
  my $key  = shift;
  my $val  = shift;
  if (@_) {
    return $_[0]->{ $key } = $val;
  }
  $self->{ $key } = $val;
  return ;
}

sub update {
  my $self = shift;
  my $vars = shift;
  @{ $self }{ keys %{ $vars } } = values %{ $vars };
}

sub clone {
  bless { %{ $_[0] } }, 'Template::Like::Stash';
}

sub get {
  my $self = shift;
  my $key  = shift;
  
  if ( $key=~/([^\.]+)\.(.*)/ ) {
    return unless exists $self->{ $1 };
    return $self->next( $self->{ $1 }, $2, @_ );
  }
  
  return unless exists $self->{ $key };
  
  my $ret  = $self->{ $key };
  
  # execute code ref.
  if ( UNIVERSAL::isa($ret, 'CODE') ) {
    return $ret->( @_ );
  }
  
  return $ret;
}

sub next {
  my $self = shift;
  my $val  = shift;
  my $key  = shift;
  
  if ( UNIVERSAL::can($val, $key) ) {
    $val = $val->$key( @_ );
  }
  
  elsif ( UNIVERSAL::isa($val, "HASH") && exists $val->{$key} ) {
    $val = $val->{$key};
  }
  
  elsif ( UNIVERSAL::isa($val, 'ARRAY') && $key=~/^\d+$/ ) {
    $val = $val->[$key];
  }
  
  elsif ( Template::Like::VMethods->can($key, $val) ) {
    $val = Template::Like::VMethods->exec($key, $val, @_);
  }
  
  else {
    return ;
  }
  
  # execute code ref.
  if ( UNIVERSAL::isa($val, 'CODE') ) {
    return $val->();
  }
  
  return $val;
}

1;