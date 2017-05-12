package Pikeo::API::Contact;

use strict;
use warnings;

use base qw( Pikeo::API::Base );

use Carp;
use Data::Dumper;

sub _info_fields {qw( user_id owner_id is_contact is_friend is_family )}

=head1 NAME

Pikeo::API::Contact - Abstraction of a pikeo use contact 

=head1 DESCRIPTION

Provides access to a Pikeo::API::User contact details

You should not use this module directly. See Pikeo::API::User documentation.

=head1 FUNCTIONS

=head2 CONSTRUCTORS

=head3 new( \%args )

Returns a Pikeo::API::Contact object.

Required args are:

=over 4

=item * api

Pikeo::API object

=item * from_xml

XML::LibXML node containing the contact details

=back

=cut 
sub new {
    my $class  = shift;
    my $params = shift;

    my $self = $class->SUPER::new($params);

    if ( $params->{from_xml} ) {
	  $self->_init_from_xml( $params->{from_xml} );
      return $self;
    }
    croak "Need an xml object";
}

=head2 INSTANCE METHODS

=head3 owner()

Pikeo::API::User that owns the contact

=cut

sub owner {
    my $self = shift;
    return Pikeo::API::User->new({ id => $self->owner_id, api => $self->api });
}

=head3 user()

Pikeo::API::User that is the contact

=cut

sub user {
    my $self = shift;
    return Pikeo::API::User->new({ id => $self->user_id, api => $self->api });
}

=head3 user_id()

=head3 owner_id()

=head3 is_contact() 

=head3 is_friend()

=head3 is_family()

=cut

sub _init_from_xml {
    my $self = shift;
    my $doc  = shift;
    my $nodes = $doc->findnodes("./*");
    for ($nodes->get_nodelist()) {
       if ( $_->to_literal eq 'null' ) {
         $self->{$_->nodeName} = undef;
       }
       elsif ( $_->to_literal eq 'true' ) {
         $self->{$_->nodeName} = 1;
       }
       elsif ( $_->to_literal eq 'false' ) {
         $self->{$_->nodeName} = 0;
       }
       else {
         $self->{$_->nodeName} = $_->to_literal;
       }
    }
    $self->{_init} = 1;
}

1;
