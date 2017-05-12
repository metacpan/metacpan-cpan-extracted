package Pikeo::API::Comment;

use strict;
use warnings;

use base qw( Pikeo::API::Base );

use Carp;
use Data::Dumper;

sub _info_fields {qw( owner_id owner_username date picture_id parent_id text )}

=head1 NAME

Pikeo::API::Comment - Abstraction of a pikeo user comment 

=head1 DESCRIPTION

Provides access to a comment details

You should not use this module directly.

=head1 FUNCTIONS

=head2 CONSTRUCTORS

=head3 new( \%args )

Returns a Pikeo::API::Comment object.

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

=head3 id()

The id of the comment

=cut
sub id { return shift->{id} }

=head3 update(\%args)

Updates the text of the comment.

You must be owner

Required args are:

=over 4

=item * text

The text to update

=back

=cut
sub update {
    my $self   = shift;
    my $params = shift;

    croak "missing required param 'text'" unless $params->{text};
    $self->api->request_parsed( 'pikeo.comments.updateComment',
                                { comment_id => $self->id,
                                  text       => $params->{text},
                                }
                              );
    return 1;
}

=head3 delete()

Deletes the comment. You must be owner

=cut
sub delete {
    my $self   = shift;
    my $params = shift;

    $self->api->request_parsed( 'pikeo.comments.deleteComment',
                                { comment_id => $self->id }
                              );
    return 1;
}

=head3 owner_id 

=head3 owner_username 

=head3 date 

=head3 picture_id 

=head3 parent_id 

=head3 text

=cut

sub _init_from_xml {
    my $self = shift;
    my $doc  = shift;
    my $nodes = $doc->findnodes("./*");
    for ($nodes->get_nodelist()) {
       $self->{$_->nodeName} = ( $_->to_literal eq 'null' ? undef :  $_->to_literal );
    }
    croak "could not init from XML, missing id" unless $self->{id};
    $self->{_init} = 1;
}

1;
