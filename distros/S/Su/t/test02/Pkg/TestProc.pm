package Pkg::TestProc;
use Su::Template;

my $model={};

# The main method for this template process.
sub process{
  if($_[0] eq __PACKAGE__){
    shift;
  }

  my $ctx_hash_ref = shift;
#$Su::Template::DEBUG=1;
  my $ret = expand(<<'__TMPL__');

__TMPL__
#$Su::Template::DEBUG=0;
  return $ret;
}

# This method is called If specified as a map filter class.
sub map_filter{
  if($_[0] eq __PACKAGE__){
    shift;
  }
  my @results = @_;

  for ( @results ){
    
  }

  return @results;
}

# This method is called If specified as a reduce filter class.
sub reduce_filter{
  if($_[0] eq __PACKAGE__){
    shift;
  }
  my @results = @_;
  my $result;
  for ( @results ){
    
  }

  return $result;
}

# This method is called If specified as a scalar filter class.
sub scalar_filter{
  if($_[0] eq __PACKAGE__){
    shift;
  }
  my $result = shift;


  return $result;
}

sub model{
  if($_[0] eq __PACKAGE__){
    shift;
  }
  my $arg = shift;
  if ($arg){
    $model = $arg;
  }else{
    return $model;
  }
}

1;
