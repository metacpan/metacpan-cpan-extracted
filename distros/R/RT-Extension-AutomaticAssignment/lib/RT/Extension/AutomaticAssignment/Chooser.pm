package RT::Extension::AutomaticAssignment::Chooser;
use strict;
use warnings;
use base 'RT::Base';

sub ChooseOwnerForTicket {
    my $self = shift;
    die "Subclass " . ref($self) . " of " . __PACKAGE__ . " does not implement required method ChooseOwnerForTicket";
}

sub Description {
    my $class = shift;
    return $class;
}

sub CanonicalizeConfig {
    my $class = shift;
    my $config = shift;

    return {};
}

1;

