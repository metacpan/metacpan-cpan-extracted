package Parallel::Workers::Backend::Eval;

use warnings;
use strict;
use Carp;
 
sub new {
  my $class = shift;
  
  my $self = {};
  bless $self, $class;
  return $self;
}

sub post {
  my $this=shift;
  return $this->do(@_);
}

sub pre {
  my $this=shift;
  return $this->do(@_);
}

sub do {
  my ($this, $id, $host, $cmd ,$params)=@_;
  my $ret=-33;
  return "ERROR: command not defined" unless defined $cmd;
  if (ref(\$params) eq "SCALAR" && $params){
#    print "$id, $host, $cmd(".$params."); \n";
    eval "\$ret=$cmd(".$params.");";
  }elsif (ref($params) eq "ARRAY" && @$params){
    my $array=join(' ',@$params);
    eval "\$ret=$cmd(".$array.");";
  }elsif (ref($params) eq "HASH"){
  }elsif (ref($cmd) eq "CODE"){
    print "FIXME: code not implemented ".__PACKAGE__.":L".__LINE__."\n";
  }else{
    eval "\$ret=$cmd;";
  }
  return $@ if ($@);
  return $ret;
}


1; # Magic true value required at end of module
__END__
