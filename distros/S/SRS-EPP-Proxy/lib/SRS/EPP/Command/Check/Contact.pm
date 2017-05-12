
package SRS::EPP::Command::Check::Contact;
{
  $SRS::EPP::Command::Check::Contact::VERSION = '0.22';
}

use Moose;
extends 'SRS::EPP::Command::Check';

use SRS::EPP::Session;
use XML::EPP::Contact;
use MooseX::Params::Validate;

# for plugin system to connect
sub xmlns {
	XML::EPP::Contact::Node::xmlns();
}

sub multiple_responses { 1 }

sub process {
    my $self = shift;
    
    my ( $session ) = pos_validated_list(
        \@_,
        { isa => 'SRS::EPP::Session' },
    );
    
	$self->session($session);
	my $epp = $self->message;

	my $payload = $epp->message->argument->payload;

	return XML::SRS::Handle::Query->new( handle_id_filter => $payload->ids );
}

sub notify {
    my $self = shift;
    
    my ( $rs ) = pos_validated_list(
        \@_,
        { isa => 'ArrayRef[SRS::EPP::SRSResponse]' },
    );    
    
	my $handles = $rs->[0]->message->responses;

	my %used;
	%used = map { $_->handle_id => 1 } @$handles if $handles;

	my $epp = $self->message;
	my $payload = $epp->message->argument->payload;

	my $ids = $payload->ids;

	my @statuses = map {
		my $id = XML::EPP::Contact::Check::ID->new(
			name => $_,
			available => ($used{$_} ? 0 : 1),
			);
        
        XML::EPP::Contact::Check::Status->new(
		  id_status => $id,
	      );			
			
	} @$ids;

	

	my $r = XML::EPP::Contact::Check::Response->new(
		items => \@statuses,
	);

	# from SRS::EPP::Response::Check
	return $self->make_response(
		code => 1000,
		payload => $r,
	);
}

1;
