package Pikeo::API::Base;

use strict;
use Carp;
use Pikeo::API::Photos;

=head1 NAME

Pikeo::API::Base - Base class for Pikeo::API modules 

=head1 DESCRIPTION

This is a base class, you shouldn't need to use this class
directly. See Pikeo::API

=cut

our $AUTOLOAD;

sub AUTOLOAD {
    my $self = shift;
    my $type = ref($self)
            or croak "$self is not an object";

    my $name = $AUTOLOAD;
    $name =~ s/.*://;

    if ( $self->_info_fields && 
         (grep {/^${name}$/} $self->_info_fields) ){
        $self->_init() unless $self->_init_done();
        return $self->{$name};
    }

    croak "Can't locate `$name' in class $type";
}


sub _info_fields {}

=head2 new(\%args)

Returns a Pikeo::API object

=cut

sub new {
    my $class  = shift;
    my $params = shift;

    unless ( $params->{'api'} ) {
      croak "need an api";
    }

    return bless { _api => $params->{'api'} }, $class;
}

=head2 api()

Returns the current api instance

=cut

sub api { return shift->{_api} }

sub _init {
    my $self = shift;
    $self->{_init} = 1;
}

sub _init_done {
    my $self = shift;
    return 0 unless $self->{_init};
    return 0 if     $self->{_dirty};
}

sub _photos_from_xml {
  my $self   = shift;
  my $params = shift;

  my @photos = ();
  for my $ph ( @{$params->{xml}} ) {
    next unless my $id = $ph->find("id")->to_literal->value;
    push @photos , Pikeo::API::Photo->new( { 
                                             id  => $id, 
                                             api => $self->api,
                                           } );
  }

  return \@photos;
}

1;
