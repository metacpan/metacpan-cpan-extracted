package Net::Syndic8::RPCXML;
use 5.008002;
use strict;
use warnings;
require RPC::XML;
require RPC::XML::Client;
use Net::Syndic8::Base;
our @ISA = qw(Net::Syndic8::Base);
our $VERSION = '0.01';
# Preloaded methods go here.
attributes (qw/EndPoint Function Params/);
sub _init {
my $self=shift;
$self->Init(@_);
return 1
}

sub Init {
my ($self,$endpoint,$function)=@_;
EndPoint $self $endpoint;
Function $self $function;
Params $self ([])
}

sub NewReq {
my ($self,$function)=@_;
return  new Net::Syndic8::RPCXML:: ($self->EndPoint,$function);
}

sub string {
my $self=shift;
my $params=$self->Params;
push @{$params},RPC::XML::string->new(shift);
return $self
}

sub array {
my $self=shift;
my $params=$self->Params;
push @{$params},RPC::XML::array->new(@_);
return $self
}

sub value {
my $self=shift;
my $req = RPC::XML::request->new($self->Function(),@{$self->Params});
my $cli = RPC::XML::Client->new($self->EndPoint());
my $resp = $cli->send_request($req);
return $resp->value;
}

1;
__END__

=head1 NAME

Net::Syndic8::RPCXML - Class for easy use xml-rpc calls

=head1 SYNOPSIS

  use Net::Syndic8;

=head1 DESCRIPTION

Net::Syndic8::RPCXML - Class for easy use xml-rpc calls


=head1 SEE ALSO

RPC::XML::request,

RPC::XML::Client

=head1 AUTHOR

Zahatski Aliaksandr, E<lt>zagap@users.sourceforge.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004 by Zahatski Aliaksandr

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.2 or,
at your option, any later version of Perl 5 you may have available.


=cut
