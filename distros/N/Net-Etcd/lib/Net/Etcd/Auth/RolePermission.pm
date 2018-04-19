use utf8;
package Net::Etcd::Auth::RolePermission;

use strict;
use warnings;

use Moo;
use Types::Standard qw(Str Int Bool HashRef ArrayRef);
use MIME::Base64;
use Carp;
use JSON;
use Data::Dumper;

with 'Net::Etcd::Role::Actions';

use namespace::clean;

=head1 NAME

Net::Etcd::Auth::RolePermission

=cut

our $VERSION = '0.020';

=head1 DESCRIPTION

Permission


=head2 endpoint

=cut

has endpoint => (
    is       => 'ro',
    isa      => Str,
);

=head2 name

name of role

=cut

has name => (
    is       => 'ro',
    isa      => Str,
);

=head2 role

name of role
* only used in revoke, use name for grant... not my idea.

=cut

has role => (
    is       => 'ro',
    isa      => Str,
);

=head2 key

name of key

=cut

has key => (
    is       => 'ro',
    isa      => Str,
    required => 1,
    coerce   => sub { return encode_base64( $_[0], '' ) },
);

=head2 range_end

End of key range

=cut

has range_end => (
    is       => 'ro',
    isa      => Str,
    coerce   => sub { return encode_base64( $_[0], '' ) },
);

=head2 permType

valid options are READ, WRITE, and READWRITE

=cut

has permType =>(  
    is       => 'ro',
    isa      => Str,
);

=head2 perm

Perm

=cut

has perm => (
    is       => 'lazy',
);

sub _build_perm {
    my ($self) = @_;
    my $perm;
    for my $key ( keys %{$self} ) { 
        unless ( $key =~ /(?:name|etcd|cb|endpoint)$/ ) { 
            $perm->{$key} = $self->{$key};
        }
    }   
    return $perm;
}

=head2 grant

Grant permission to role

=cut

sub grant {;
    my ($self) = @_;
    $self->{endpoint} = '/auth/role/grant';
    $self->{json_args} = to_json( {name => $self->name, perm => $self->perm } );
    $self->request;
    return $self;
}

=head2 revoke

Revoke permission to role

=cut

sub revoke {;
    my ($self) = @_;
    $self->{endpoint} = '/auth/role/revoke';
    $self->request;
    return $self;
}

1;
