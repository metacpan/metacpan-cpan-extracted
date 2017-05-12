
package SRS::EPP::Command::Logout;
{
  $SRS::EPP::Command::Logout::VERSION = '0.22';
}

use Moose;
extends 'SRS::EPP::Command';

use MooseX::Params::Validate;

sub action {
	"logout";
}

sub simple {1}

sub process {
    my $self = shift;
    
    my ( $session ) = pos_validated_list(
        \@_,
        { isa => 'SRS::EPP::Session' },
    );    
    
	$session->shutdown;
	$self->make_response(code => 1500);
}

1;
