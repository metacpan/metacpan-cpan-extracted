package SRS::EPP::Command::Transfer::Contact;
{
  $SRS::EPP::Command::Transfer::Contact::VERSION = '0.22';
}

use Moose;
extends 'SRS::EPP::Command::Transfer';
use SRS::EPP::Session;
use MooseX::Params::Validate;

# for plugin system to connect
sub xmlns {
	XML::EPP::Contact::Node::xmlns();
}

sub process {
    my $self = shift;
    
    my ( $session ) = pos_validated_list(
        \@_,
        { isa => 'SRS::EPP::Session' },
    );
    
	return $self->make_response(code => 2101);
}

1;
