package Monitoring::TT::Object::Contact;

use strict;
use warnings;
use utf8;
use base 'Monitoring::TT::Object';

#####################################################################

=head1 NAME

Monitoring::TT::Object::Contact - Object representation of a contact

=head1 DESCRIPTION

contains generic methods which can be used in templates for each contact

=cut

#####################################################################

=head1 METHODS

=head2 BUILD

return new object

=cut
sub BUILD {
    my($class, $self) = @_;
    bless $self, $class;
    return $self;
}

#####################################################################

=head1 AUTHOR

Sven Nierlein, 2013, <sven.nierlein@consol.de>

=cut

1;
