# Error object for RPC::Switch::Client::Tiny
#
package RPC::Switch::Client::Tiny::Error;

use strict;
use warnings;

our $VERSION = 1.1;

sub new {
	my ($class, $type, $message, $extra) = @_;
	return bless({type => $type, message => $message, $extra ? %$extra : ()}, $class);
}
use overload 'fallback' => 1, '""' => 'stringify'; # allow to print object as "$err"

sub stringify {
	my ($self) = @_;
	return "$self->{type} error: $self->{message}";
}

1;

__END__

=head1 NAME

RPC::Switch::Client::Tiny::Error - rpc error object

=head1 SYNOPSIS

  use RPC::Switch::Client::Tiny::Error;

  my $err = RPC::Switch::Client::Tiny::Error->new('rpcswitch', "unsupported req");
  print "rpc error: $err\n";

=head1 AUTHORS

Barnim Dzwillo @ Strato AG

=cut

