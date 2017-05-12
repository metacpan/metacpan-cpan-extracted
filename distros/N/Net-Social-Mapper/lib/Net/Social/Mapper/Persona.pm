package Net::Social::Mapper::Persona;

use strict;
use JSON::Any;

=head1 NAME

Net::Social::Mapper::Persona - an object representing an internet persona

=head1 SYNOPSIS

See C<Net::Social::Mapper>

=head1 METHODS

=cut

=head2 new <user> <service> [opt[s]]

Create a new persona.

=cut
sub new {
    my $class      = shift;
    my $user       = shift || return undef;
    my $service    = shift || return undef;
    my %opts       = @_;

    $opts{user}    = $user;
    $opts{service} = $service;
    my $self       = bless \%opts, $class;

    $self->_init || return;
    return $self;
}

sub _init { 1 }

=head2 user 

The user name of this persona

=cut
sub user { shift->_do('user', @_) }

=head2 service 

The service for this persona

=cut
sub service { shift->_do('service', @_) }

=head2 domain 

The domain for this service

=cut
sub domain { shift->_do('domain', @_) }


=head2 favicon 

The url to the favicon for this service

=cut
sub favicon {
    my $self = shift;
    return $self->_do('favicon') || "http://".$self->domain."/favicon.ico";
}

=head2 name

The canonical name of the service.

=cut
sub name  { shift->_do('name', @_) }

=head2 feeds

Returns a hash of feeds (which might be empty)

=cut
sub feeds { shift->_do_array('feeds', @_) }

sub _do {
    my $self       = shift;
    my $what       = shift;
    $self->{$what} = shift if @_;
    return $self->{$what};
}

sub _do_array {
    my $self       = shift;
    my $what       = shift;
    $self->{$what} = [@_] if @_;
    return @{$self->{$what}||[]};
}

sub _do_array_with_defaults {
    my $self       = shift;
    my $what       = shift;
    my $default    = shift;
    my @return     = $self->_do_array($what, @_);
    @return        = ($default) unless @return;
    return @return;
}

=head2 types 

Return what type(s) feed objects are.

Will almost certainly be one of - posts (default), notes, photos, videos

=cut
sub types { shift->_do_array_with_defaults('types', 'posts', @_) }

=head2 verbs 

Return what verb(s) feed objects are.

Will almost certainly be one of  - post (default), favorite

=cut
sub verbs { shift->_do_array_with_defaults('verbs', 'post', @_) }

=head2 persona_name 

A canonical short name for this persona. Generally C<user>@C<service>

=cut
sub persona_name {
    my $self = shift;
    return $self->user.'@'.$self->service;
}

=head2 elsewhere

Get other personas for this user 

=cut
sub elsewhere {
    my $self  = shift;
    my $url   = URI->new("http://socialgraph.apis.google.com/otherme");
    $url->query_form( q => $self->_elsewhere_param );
    my $page  = $self->mapper->get("$url")      || return ();
    my $info  = eval { $self->_json->decode($page) } || return ();    
    my @personas;
    foreach my $url (keys %$info) {
        my $attributes = $info->{$url}->{attributes};
        next unless keys %$attributes;
        my $persona = $self->_attributes_to_persona($url, $attributes) || next;
        push @personas, $persona;
    }
    return @personas;
}

=head2 mapper

Return the C<Net::Social::Mapper> object for this persona.

=cut
sub mapper { shift->{_mapper} }

=head1 METHODS WHICH MIGHT RETURN UNDEF

=cut

=head2 homepage

The url of their homepage on this service

=cut
sub homepage { shift->_do('homepage', @_) }

=head2 profile

The url of their profile on this service.

=cut
sub profile { shift->_do('profile', @_) }

=head2 foaf

The url of their foaf feed on this service.

=cut
sub foaf { shift->_do('foaf', @_) }

=head2 full_name 

Returns the full name of the persona if available

=cut
sub full_name { shift->_do('full_name', @_) }

=head2 id

Returns the id of the persona on the service if applicable

=cut
sub id { shift->_do('id', @_) }

=head2 photo

Returns the profile picture of the person on the service if available

=cut
sub photo { shift->_do('photo', @_) }

my %_attribute_map = (
    fn      => "fullname",
    url     => "homepage",
    profile => "profile",
    photo   => "photo",
    foaf    => "foaf",
    feed    => "feed",
);


sub _attributes_to_persona {
    my $self       = shift;
    my $url        = shift;
    my $attributes = shift;
    my $mapper     = $self->mapper;
    
    # work out what persona this is
    my ($user, $service) = $mapper->sitemap->url_to_service($url);
    # and instantiate it 
    my $persona          = $mapper->persona($user, $service);

    # collapse the atom and rss feeds down
    foreach my $feed (qw(atom rss)) {
        push @{$attributes->{feeds}}, delete $attributes->{$feed} if exists $attributes->{$feed};
    }

    # Now go through and add an additional data in
    foreach my $key (keys %$attributes) {
        # Skip what we're not interested in
        my $name          = $_attribute_map{$key} || next;

        # If either is an array already then combine the values
        if (ref $persona->{$name} eq 'ARRAY' || ref $attributes->{$key} eq 'ARRAY') {
            my @to   = ref($persona->{$name})   ? @{$persona->{$name}}   : ($persona->{$name});
            my @from = ref($attributes->{$key}) ? @{$attributes->{$key}} : ($attributes->{$key}); 
            my %tmp = map { $_ => 1 } (@to, @from); 
            $attributes->{$key} = [ keys %tmp ];
        }
        
        # Now merge the values. This assumes Google knows more than we do. Which may be wrong.
        $persona->{$name} = $attributes->{$key};
    }
    return $persona;
}

sub _json {
    my $self = shift;
    return $self->{_json} ||= JSON::Any->new;
}

sub _elsewhere_param {
    my $self = shift;
    return $self->homepage || $self->user;
}

1;

