package Templates::ReturnArrayProc;
use strict;
use warnings;
use Su::Template;

my $model = {};

sub new {
  return bless { model => $model }, shift;
}

# The main method for this process class.
sub process {
  my $self = shift if ref $_[0] eq __PACKAGE__;
  my $model = keys %{ $self->{model} } ? $self->{model} : $model;

  my $ret = expand( <<'__TMPL__', $model );
% my $model = shift;
key1:<%= $model->{key1}%>
key2:<%= $model->{key2}%>
key3:<%= $model->{key3}%>
__TMPL__

  my @result = split( "\n", $ret );

  return @result;

} ## end sub process

# This method is called If specified as a map filter class.
sub map_filter {
  my $self = shift if ref $_[0] eq __PACKAGE__;
  my @results = @_;

  for (@results) {
    s/key/modified_key/g;
  }

  return @results;
} ## end sub map_filter

# This method is called If specified as a reduce filter class.
sub reduce_filter {
  my $self = shift if ref $_[0] eq __PACKAGE__;
  my @results = @_;

  # Just join result and return.
  return join( ',', @results );

} ## end sub reduce_filter

# This method is called If specified as a scalar filter class.
sub scalar_filter {
  my $self = shift if ref $_[0] eq __PACKAGE__;
  my $result = shift;

  return '<' . $result . '>';
} ## end sub scalar_filter

sub model {
  my $self = shift if ref $_[0] eq __PACKAGE__;
  my $arg = shift;
  if ($arg) {
    if ($self) { $self->{model} = $arg; }
    else {
      $model = $arg;
    }
  } else {
    if ($self) {
      return $self->{model};
    } else {
      return $model;
    }
  } ## end else [ if ($arg) ]
} ## end sub model

1;
