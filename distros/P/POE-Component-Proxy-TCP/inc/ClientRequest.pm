package ClientRequest;
# test client for proxy test - Andrew V. Purshottam
# ClientRequest object
use warnings;
use strict;
use diagnostics;
use Carp qw(carp croak);

my $debug_flag = 99;
our $test_count = 1;
use fields qw(count text delay_secs test_name);

sub new {
  my ClientRequest $self = shift;
  unless (ref $self) {
    $self = fields::new($self);

  }

  my %param = @_;

  # Extract parameters.
  $self->{count}      = delete $param{Count};
  $self->{count} = 1 unless defined ($self->{count});

  $self->{text}      = delete $param{Text};
  $self->{text} = "chunny" unless defined ($self->{text});

  $self->{delay_secs}      = delete $param{DelaySecs};
  $self->{delay_secs} = 2 unless defined ($self->{delay_secs});

  foreach (sort keys %param) {
    carp "ClientRequest doesn't recognize \"$_\" as a parameter";
  }

  $self->{test_name} = $test_count++ . 
    "bounce $self->{count} copies of $self->{text} with delay: $self->{delay_secs}";
  return $self;


}

sub get_request {
   my $self = shift;
   return $self->{count} . ":" . $self->{text};
}

sub get_test_name {
 my $self = shift;
 return $self->{test_name};
}
  
sub cmp_with_responce {
   my $self = shift;
   my $responce = shift;
   my ($resp_index, $resp_text) = split /:/, $responce;
   my $ok = $self->{text} eq $resp_text;
   return $ok;
}

sub dump {
  my $self = shift;
  return "ClientRequest(count:$self->{count} text:$self->{text} delay_secs::$self->{delay_secs})";
}

1;

