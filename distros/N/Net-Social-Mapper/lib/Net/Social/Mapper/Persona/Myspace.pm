package Net::Social::Mapper::Persona::Myspace;

use strict;
use base qw(Net::Social::Mapper::Persona::Generic);
use URI;
use Data::Dumper;


=head1 NAME

Net::Social::Mapper::Person::Myspace - the persona for a Myspace account

=head2 SYNOPSIS

See C<Net::Social::Mapper>

=cut

sub _init {
    my $self = shift;

    # Guess at a bunch of stuff
    $self = $self->SUPER::_init;
    
    my $id           = ($self->{user} =~ m!^\d+$!) ? $self->{user} : $self->_fetch_id;    
    $self->{id}      = $id;    
    $self->{profile} = $self->{homepage} = "http://myspace.com/".$self->{user};
    $self->{feeds}   = defined $id? [ "http://blogs.myspace.com/Modules/BlogV2/Pages/RssFeed.aspx?friendID=".$self->{id} ] : [];
    return $self;
}

sub _fetch_id {
    my $self = shift;
    return $self->_fetch_id_from_google || $self->_fetch_id_from_page || undef;
}

sub _fetch_id_from_google {
    my $self   = shift;
    my $page   = $self->{homepage}; $page =~ s!/+$!!;
    my %params = ( q => $page );
    my $url    = URI->new("http://socialgraph.apis.google.com/lookup");
    $url->query_form(%params);
    my $data   = $self->mapper->get("$url") || return;
    
    my $res    = eval { $self->_json->decode($data) };
    my $node   = $res->{nodes}->{$page}     || {};
    my $rss    = $node->{attributes}->{rss} || return;
    my ($id)   = ($rss =~ m!friendID=(\d+)!i);
    return $id;
}

sub _fetch_id_from_page {
    my $self   = shift;
    my $page   = $self->{homepage}; 
    my $data   = $self->mapper->get("$page") || return; 
    my ($id)   = ($data =~ m!"DisplayFriendId":(\d+)!);
    return $id;
}


1;

