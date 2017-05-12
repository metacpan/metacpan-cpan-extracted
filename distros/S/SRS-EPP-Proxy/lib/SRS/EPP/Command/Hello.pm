
package SRS::EPP::Command::Hello;
{
  $SRS::EPP::Command::Hello::VERSION = '0.22';
}

use Moose;

use MooseX::Params::Validate;

extends 'SRS::EPP::Command';

sub match_class {
	"XML::EPP::Hello";
}

sub authenticated {0}
sub simple {1}

sub process {
    my $self = shift;
    
    my ( $session ) = pos_validated_list(
        \@_,
        { isa => 'SRS::EPP::Session' },
    );
    
	$self->make_response("Greeting");
}

1;
