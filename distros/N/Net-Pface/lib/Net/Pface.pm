package Net::Pface;

use strict;
use warnings;
use JSON::XS;
use utf8;
use HTTP::Request;
use LWP::UserAgent;
use Encode;

our $VERSION = '1.02';

my %def = (
              server     => 'https://s.pface.ru/',
              timeout    => 10,
              agent      => 'Net-Pface-' . $VERSION,
              type       => 'application/json',
              cache_time => 300
);

sub new {
    my $class = shift;
    my $self  = {@_};
    
    bless $self, $class;

    # check param
    warn "Don't defined 'id'"  unless defined $self->{'id'};
    warn "Don't defined 'key'" unless defined $self->{'key'};
    unless ( defined $self->{'server'} )     {$self->{'server'}     = $def{'server'};}
    unless ( defined $self->{'timeout'} )    {$self->{'timeout'}    = $def{'timeout'}}
    unless ( defined $self->{'agent'} )      {$self->{'agent'}      = $def{'agent'}}
    unless ( defined $self->{'type'} )       {$self->{'type'}       = $def{'type'}}
    unless ( defined $self->{'cache_time'} ) {$self->{'cache_time'} = $def{'cache_time'}}
    
    # init browser
    $self->{'browser'} = LWP::UserAgent->new( agent => $self->{'agent'}, ssl_opts => { verify_hostname => 0 } );
    $self->{'browser'}->timeout( $self->{'timeout'} );
    
    # init json::xs
    $self->{'json_xs'} = JSON::XS->new();
    
    #init cache data
    $self->{'cache_data'} = {};
    
    return $self;
}

# get data from users.get.json
sub get {
    my ( $self, $user_id, @fields ) = @_;
    my $result = {};
    
    # check params
    unless ( defined $user_id ) {$$result{'error'} = "Don't defined user id";}
    unless (@fields)             {$$result{'error'} = "Don't defined fileds list"};
    return $result
        if exists $$result{'error'};
    
    # check cache
    my $memkey = $user_id . '_' . join "_", @fields;
    my $cache  = $self->_check_cache($memkey);
    return $cache
        if $cache;
    
    # prepare request
    my $json = {
                   s      => $self->{'id'},
                   p      => $self->{'key'},
                   id     => $user_id,
                   fields => join ",", @fields
    };
    
    # request to server
    my $request = HTTP::Request->new( 'POST', $self->{'server'} . 'users.get.json/' );
    $request->header( 'Content-Type' => $self->{'type'} );
    $request->content( encode( "utf8", $self->{'json_xs'}->encode($json) ) );
    my $response = $self->{'browser'}->request($request);
    
    # parse answer by server
    $self->_parse( $result, $response );
    
    # set to cache
    $$result{'is_cache'} = 0;
    $self->{'cache_data'}{$memkey}{'time'} = time() + $self->{'cache_time'};
    $self->{'cache_data'}{$memkey}{'data'} = $result;
    
    return $result;
}

# auth from users.auth.json
sub auth {
    my ( $self, $s1, $s2, $ip ) = @_;
    my $result = {};
    
    # check params
    unless ( defined $ip ) {$$result{'error'} = "Don't defined ip address";}
    unless ( defined $s2 ) {$$result{'error'} = "Don't defined second sess";}
    unless ( defined $s1 ) {$$result{'error'} = "Don't defined first sess";}
    return $result
        if exists $$result{'error'};
    
    # check cache
    my $memkey = $s1 . '_' . $s2 . '_' . $ip;
    my $cache  = $self->_check_cache($memkey);
    return $cache
        if $cache;
    
    # prepare request
    my $json = {
                   s  => $self->{'id'},
                   p  => $self->{'key'},
                   s1 => $s1,
                   s2 => $s2,
                   ip => $ip
    };
    
    # request to server
    my $request = HTTP::Request->new( 'POST', $self->{'server'} . 'users.auth.json/' );
    $request->header( 'Content-Type' => $self->{'type'} );
    $request->content( encode( "utf8", $self->{'json_xs'}->encode($json) ) );
    my $response = $self->{'browser'}->request($request);

    # parse answer by server
    $self->_parse( $result, $response );
    
    # set to cache
    $$result{'is_cache'} = 0;
    $self->{'cache_data'}{$memkey}{'time'} = time() + $self->{'cache_time'};
    $self->{'cache_data'}{$memkey}{'data'} = $result;
    
    return $result;
}

# parsing answer by server
sub _parse {
    my $self = shift;
    
    # check pface answer
    unless ($_[1]->is_success) {${$_[0]}{'error'} = $_[1]->status_line;}
    return
        if exists ${$_[0]}{'error'};

    # parse json from server
    my $content = decode( "utf8", $_[1]->decoded_content );
    unless ( eval { $_[0] = $self->{'json_xs'}->decode($content) } ) {
        ${$_[0]}{'error'} = "don't parse json";
    }
    
    # save source answer
    ${$_[0]}{'answer'} = $content;
    return;    
}

# get data from cache
sub _check_cache {
    my ( $self, $memkey ) = @_;
    
    if ( defined $self->{'cache_data'}{$memkey} ) {
        if ( $self->{'cache_data'}{$memkey}{'time'} > time() ) {
            # get data from cache
            my $result = $self->{'cache_data'}{$memkey}{'data'};
            unless ($$result{'is_cache'}) {
                $$result{'is_cache'} = 1;
            }
            return $result;
        }
    }
    
    return;
}

1;
__END__
=head1 NAME

Net::Pface - Perl extension for pface.ru simple API

=head1 SYNOPSIS

    use Modern::Perl;
    use Net::Pface;
    my $obj_pface = Net::Pface->new( id  => $site_id, key => $site_key );
      
    # user authentication
    my $hash = $obj_pface->auth( $sess1, $sess2, $user_ip );
    if ( exists $$hash{'result'} ) {
        my $lnk = $$hash{'result'};
        say $$lnk{'id'}; # if id > 0 then user else guest
        say $$lnk{'dname'};
        say $$lnk{'level'};
        say $$lnk{'lang'};
    }
    else {
        say $$hash{'error'};
    }
    
    # get user data
    $hash = $obj_pface->get( $user_id, 'id', 'phone', 'mail' );
    if ( exists $$hash{'result'} ) {
        my $lnk = $$hash{'result'};
        say $$lnk{'id'};
        say $$lnk{'phone'};
        say $$lnk{'mail'};
    }
    else {
        say $$hash{'error'};
    }

=head1 DESCRIPTION

This module is simple API for pface.ru.

Connect to server use your pface site_id and site_key:

  my $obj_pface = Net::Pface->new( id => $site_id, key => $site_key );
  
  keys:
  id         - your site id in pface.ru
  key        - your site secret key in pface.ru
  server     - URL pface.ru server for API, default https://s.pface.ru/
  timeout    - timeout connect, default 10
  agent      - browser name, default 'Net-Pface-' + VERSION_MODULE
  type       - connect type to server, default application/json
  cache_time - cache lifetime, default 300; use 0 that off
  
Then you can use two methods: for user authentication or for get user data:

  - user authentication
    $hash = $obj_pface->auth( $sess1, $sess2, $user_ip );
  
  - get user data
    $hash = $obj_pface->get( $user_id, @fields );

You get $hash{'result'}, if you have success answer.

You get $hash{'error'}, if you have error.

You get true in $hash{'is_cache'}, if answer get from cache.

$hash{'answer'} is pure answer from API server.

=head2 EXPORT

None.

=head1 SEE ALSO

pface.ru API: http://d.pface.ru/request_basic.html

=head1 AUTHOR

Konstantin Titov, E<lt>xmolex@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2018 by Konstantin Titov

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
