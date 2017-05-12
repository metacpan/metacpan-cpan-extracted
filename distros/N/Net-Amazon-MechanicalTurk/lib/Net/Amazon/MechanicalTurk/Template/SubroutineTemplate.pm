package Net::Amazon::MechanicalTurk::Template::SubroutineTemplate;
use strict;
use warnings;
use Carp;
use IO::File;
use IO::String;
use Net::Amazon::MechanicalTurk::Template;

our $VERSION = '1.00';

our @ISA = qw{ Net::Amazon::MechanicalTurk::Template };

# Makes a sub routine look like a template.

Net::Amazon::MechanicalTurk::Template::SubroutineTemplate->attributes(qw{
    sub
});

sub compiled {
    my $self = shift;
    if ($#_ >= 0) {
        $self->SUPER::compiled(@_);
    }
    return $self->sub;
}

sub merge {
    my ($self, $params) = @_;
    $self->sub->($params);
}

return 1;
