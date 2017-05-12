package Net::Connection::Simple;

=head1 NAME

Net::Connection::Simple - Perl extension handling simple connection info within an application

=head1 SYNOPSIS

  use Net::Connection::Simple;
  my $c = Net::Connection::Simple->new(seenFirst => (time()-1800), seenLast => time());

  $c->protocols(Net::Protocol::Simple->new(protocol => tcp, layer => 4));
  $c->protocols(Net::Protocol::Simple->new(protocol => 'ip', layer => 3));
  $c->protocols(Net::Protocol::Simple->new(protocol => 'irc', layer => 7));

  $c->protocols({
  	1 => Net::Protocol::Simple->new(protocol => 6, layer => 4),
  	2 => Net::Protocol::Simple->new(protocol => 'ip', layer => 3),
  	3 => Net::Protocol::Simple->new(protocol => 'irc', layer => 7),
  });

  $c->protocols([
  	Net::Protocol::Simple->new(protocol => 6, layer => 4),
  	Net::Protocol::Simple->new(protocol => 'ip', layer => 3),
  	Net::Protocol::Simple->new(protocol => 'irc', layer => 7),
  ]);

=head1 DESCRIPTION

  This module created to handle simple information about connections.

=cut

use 5.008007;
use strict;
use warnings;

our $VERSION = '1.02';

=head1 OBJECT METHODS

=head2 new

Constructs the Connection object

Accepts:

  	protocols => [ARRAY|HASHREF|Net::Protocol::Simple]

=cut

sub new {
	my ($class,%data) = @_;
	my $self = {};
	bless($self,$class);
	$self->protocols($data{protocols});
	return $self;
}

=head2 protocols

Returns a HASHREF of the protocols composing the connection [See Net::Protocol::Simple] keyed by layer

Accepts:

  	HASHREF:
  		{ $key 	  => Net::Protocol::Simple(...),
  		  $key++  => Net::Protocol::Simple(...),
  		  $key++  => Net::Protocol::Simple(...),
  		}

  	ARRAY:
  		[
  		  Net::Protocol::Simple->new(...),
  		  Net::Protocol::Simple->new(...),
  		  Net::Protocol::Simple->new(...),
  		]

  	Net::Protocol::Simple:
  		Net::Protocol::Simple->new(protocol => 6, layer => 4)

=cut

sub protocols {
	my ($self,$v) = @_;
	if(defined($v)){
		for(ref($v)){
			if(/^HASH$/){
				foreach my $x (keys %$v){ $self->protocols($v->{$x});}
				last;
			}
			if(/^ARRAY$/){
				foreach my $x (@{$v}) { $self->protocols($x); }
				last;
			}
			if(/^Net::Protocol::Simple$/){
				$self->{_protocols}->{$v->layer()} = $v;
				last;
			}
			die('Protocols requires a Net::Protocol::Simple Obj to be passed!');
		}
	}
	return $self->{_protocols};
}

1;
__END__

=head1 SEE ALSO

Net::Protocol::Simple, Time::Timestamp

=head1 AUTHOR

Wes Young, E<lt>saxguard9-cpan@yahoo.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Wes Young

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.7 or,
at your option, any later version of Perl 5 you may have available.


=cut
