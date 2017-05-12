package POEx::URI;

use strict;
use warnings;

use URI::Escape qw(uri_unescape);
use URI::_server;
use Carp;

use vars qw( @ISA $VERSION );
@ISA = qw(URI::_server);
$VERSION = '0.0301';

use overload '@{}' => \&as_array, 
    fallback => 1;

##############################################
sub _init
{
    my( $class, $str, $scheme ) = @_;

    if( $str =~ m,^poe://[^/]+/[^/]+$, ) {
        $str .= '/';
    }
    $str = "$scheme:$str" unless $str =~ /^\Q$scheme:/;

    return $class->SUPER::_init($str, $scheme);
}

##############################################
sub default_port { 603 }

##############################################
sub kernel
{
    my $self = shift;
    my $old = $self->authority;
    if( @_ ) {
        my $tmp = $old;
        $tmp = "" unless defined $old;
        my $ui = ($tmp =~ /(.*@)/) ? $1 : "";
        my $new = shift;
        $new = "" unless defined $new;
        if (length $new) {
            $new =~ s/[@]/%40/g;   # protect @
        }
        if( $ui or length $new ) {
            $self->authority( "$ui$new" );
        }
        else {
            $self->authority( undef );
        }
    }
    return undef unless defined $old;
    $old =~ s/.*@//;
    return uri_unescape($old);
}


##############################################
sub path
{
    my $self = shift;
    my $old = $self->SUPER::path;
    if( @_ ) {
        my $new = shift;
        if( $new =~ m,(.+)/(.+), ) {
            
            my $session = $1;
            my $event = $2;
            $session =~ s,^/+,,;
            $session =~ s,/,%2F,g;
            $new = join '/', $session, $event;
        }
        $self->SUPER::path( $new );
    }
    return $old;
}

##############################################
sub path_segments
{
    my $self = shift;

    my @seg = $self->SUPER::path_segments;
    if( @_ ) {
        my @new = @_;
        shift @new if $new[0] eq '';
        if( 2 <= @new ) {
            my $event = pop @new;
            @new = ( join( '/', @new ), $event );
        }
        $self->SUPER::path_segments( @new );
    }
    return @seg;
}

##############################################
sub session
{
    my $self = shift;
    my @seg = $self->path_segments;
    shift @seg if defined $seg[0] and $seg[0] eq '';
    my $event;    
    if( 1==@seg ) {     # only an event?
        $event = $seg[0];
        @seg = ();        
    }   
    if( @seg >= 2 ) {   # session + event
        $event = pop @seg;
    }
    my $old = join '/', @seg[0..$#seg];

    if( @_ ) { 
        my $new = shift;
        $new = '' unless defined $new;
        $self->path_segments( $new, (defined $event ? $event : '' ) );
    }   

    return $old;
}

##############################################
sub event
{
    my $self = shift;
    my $old = ( $self->path_segments )[-1];
    $old = '' unless defined $old;
    if( @_ ) {
        my @seg = $self->path_segments;
        my $new = shift;
        if( @seg >= 2 ) {           # session/event
            $seg[-1] = $new||'';
        }
        elsif( @seg ) {             # session
            push @seg, $new||'';
        }
        else {                      # nothing
            if( $self->kernel and defined $new ) {
                carp "It makes no sense to set an event without a session";
            }
            @seg = ('', $new||'');
        }
        
        $self->path_segments( @seg );
    }
    return $old;
}

##############################################
sub _user
{
    my $self = shift;
    my $old = $self->userinfo;
    $old =~ s/:.*$//;
    return $old;
}
sub user
{
    my $self = shift;
    my $old = $self->userinfo;
    $old =~ s/:.*$//;

    if( @_ ) {
        my $pw = $self->_password;
        my $new = shift;
        my $ui = $new;
        if( defined $new ) {
            $new =~ s/:/%3A/g;
            $ui = $new;
            $ui .= ":$pw" if( defined $pw );
        }
        elsif( defined $pw ) {
            $ui = ":$pw";
        }
        $self->userinfo( $ui );
    }

    $old =~ s/%3A/:/g if $old;
    return $old;
}

##############################################
sub _password
{
    my $self = shift;
    my $old = $self->userinfo;
    undef( $old ) unless $old =~ s/^.*?://;
    return $old;
}
sub password
{
    my $self = shift;
    my $old = $self->userinfo;
    undef( $old ) unless $old =~ s/^.*?://;

    if( @_ ) {
        my $user = $self->_user;
        $user = '' unless defined $user;
        my $new = shift;
        if( defined $new ) {
            $new =~ s/:/%3A/g;
            $self->userinfo( "$user:$new" );
        }
        else {
            $self->userinfo( $user );
        }
    }
    $old =~ s/%3A/:/g if $old;
    return $old;
}

##############################################
sub _is_inet
{
    my $kernel = shift;
    return unless $kernel;
    return 1 if $kernel =~ /:\d*$/;
    return 1 if $kernel =~ /^\[[:0-9a-f]+\]$/i;     # [IPv6]
    return 1 if $kernel =~ /^\d+\.\d+\.\d+\.\d+/;   # IPv4 dotted quad
    return 1 if $kernel =~ /^[-\w.]+$/ and $kernel =~ /[.]/;
}

sub canonical
{
    my( $self ) = @_;
    my $other = $self->URI::_generic::canonical();


    my $kernel = $self->kernel;
    if( _is_inet( $kernel ) ) {
        $other = $other->clone if $other == $self;
        $other->kernel( lc $kernel );
    }
    my $port = $other->_port;
    if( defined($port) && ($port eq "" || $port == $self->default_port) ) {
        $other = $other->clone if $other == $self;
        $other->port(undef);
    }

    if( $other =~ m(poe:/[^/]) ) {
        $other = $other->clone if $other == $self;
        $$other =~ s(poe:/)(poe:);        
    }

    my @seg = $other->path_segments;
    if( 2 < @seg ) {
        $other = $other->clone if $other == $self;
        $other->path_segments( @seg );   # enforce 2 segments
    }

    return $other;
}

##############################################
sub fragment
{
    return if 1==@_;
    croak "->fragment() currently not supported";
}

##############################################
sub as_array
{
    my $self = shift;
    my $kid;
    $kid = $POE::Kernel::poe_kernel->ID
        if $POE::Kernel::poe_kernel and $POE::Kernel::poe_kernel->can('ID');
    my $kernel = $self->kernel;
    my $alias = $self->session;
    if( $kernel and ( not $kid or $kernel ne $kid ) ) {
        $alias = join '/', $self->scheme.':/', $kernel, $alias;
    }

    my @ret = ( $alias, $self->event, $self->argument );

    return \@ret unless wantarray;
    return @ret;
}

##############################################
sub argument
{
    my $self = shift;
    my $old = $self->_argument;
    if( @_ ) {
        if( 1==@_ ) {
            my $new = shift;
            unless( ref $new ) {
                $self->query( $new );
            }
            elsif( 'ARRAY' eq ref $new ) {
                $self->query_keywords( $new );
            }
            else {
                $self->query_form( $new );
            }
        }
        else {
            $self->query_form( @_ );
        }
    }
    return unless defined $old;
    return $old;
}

sub _argument
{
    my $self = shift;
    my $args;

    my $q = $self->query;
    return unless defined $q;

    if( $q =~ /=/ ) {
        return { map { s/\+/ /g; uri_unescape($_) }
                 map { /=/ ? split(/=/, $_, 2) : ($_ => '')} 
                 split(/&/, $q)
               };
    }
    return [ map { uri_unescape($_) } split(/\+/, $q, -1) ];
} 

##############################################
sub abs
{
    my $self = shift;
    my $base = shift || croak "Missing base argument";

    $base = URI->new($base) unless ref $base;
    $base = $base->canonical;
    my $abs = $self->clone;

    $abs->scheme( $base->scheme ) unless $abs->scheme;
    foreach my $part ( qw( event session authority ) ) {
        my $f = $abs->$part;
        next if defined $f and length $f;
        $f = $base->$part;
        next unless length $f;
        $abs->$part( $base->$part );
    }
    return $abs;    
}

##############################################
sub rel
{
    my $self = shift;
    my $base = shift || croak "Missing base argument";

    my $rel = $self->clone;
    $base = URI->new($base) unless ref $base;

    my $scheme = $rel->scheme;
    my $auth   = $rel->canonical->authority;
    my $session = $rel->session;
    my $event  = $rel->event;

    if (!defined($scheme) && !defined($auth)) {
        # it is already relative
        return $rel;
    }

    my $bscheme = $base->scheme;
    my $bauth   = $base->canonical->authority;
    my $bsession = $base->session;
    my $bevent  = $base->event;

    for ($bscheme, $bauth, $auth) {
        $_ = '' unless defined
    }

    unless ($scheme eq $bscheme && $auth eq $bauth) {
        # different location, can't make it relative
        return $rel;
    }

    # Make it relative by eliminating scheme and authority
    $rel->scheme(undef);
    $rel->authority(undef);

    for ($session, $event, $bsession, $bevent) {
        $_ = '' unless defined
    }

    if( $bsession eq $session ) {
        $rel->session(undef);
    }    
    if( $bevent eq $event ) {
        $rel->event(undef);
    }    

    return $rel;
}

1;

__END__

=head1 NAME

POEx::URI - URI extension for POE event specfiers

=head1 SYNOPSIS

    use URI;

    my $uri = URI->new( "$session/$event" );

    $poe_kernel->post( $uri->session, $uri->event, @args );
    $poe_kernel->post( @$uri, @args );

    $uri->host( $host );
    $uri->port( 33100 );
    $poe_kernel->post( IKC => $uri, @args );


=head1 DESCRIPTION

This module implements the URIs that reference POE session/event tuples.
Objects of this class represent non-standard "Uniform Resource Identifier
references" of the I<poe:> scheme.

The canonical forms of POE URIs are:

    poe:event
    poe:session/
    poe:session/event
    poe://kernel/session/
    poe://kernel/session/event

Events may also have parameters :

    poe:event?foo=bar
    poe:event?b+20+BINGO

See L</argument> below.

URI fragements (the bits after C<#>) make no sense.


=head2 Use

This module attempts to have no pre-conception on how the URIs would be
used.  Core POE has way of turning URIs into event invocations.  However,
you may use L</as_array> to invoke the event referenced by a URI.

    $poe_kernel->post( @$uri );

The presence of a kernel name in the URI presuposes some form of
inter-kernel communication.  L<POE::Component::IKC> doesn't currently
support URIs, beyond the fact that a subscribed remote session will have a
local thunk session with the alias of the form I<poe://kernel/session>.  So
using L</as_array> will be able to access it.


=head1 METHODS

=head2 event

    my $name = $uri->event
    $old = $uri->event( $name );

Sets and returns the event part of the $uri.  If the C<$name> contains a
forward-slash (/), it is escaped (%2F).

To clear the event name, use C<''> or C<undef>, which are equivalent.

=head2 session

    my $name = $uri->session
    $old = $uri->session( $name );

Sets and returns the session part of the $uri.  If the C<$name> contains a
forward-slash (/), it is escaped (%2F).

To clear the event name, use C<''> or C<undef>, which are equivalent

=head2 kernel

    my $kernel = $uri->kernel;
    $old = $uri->kernel( $name );

Sets and returns the kernel part of the $uri.  
A kernel may be a dotted quad IPv4 address (I<127.0.0.1>), an IPv6 address
(I<[::1]>) or a hostname (I<localhost.localdomain>) followed by a port number.
A kernel may also be kernel ID or alias.

The kernel only make sense when using IKC.

To clear the kernel name, use C<''> or C<undef>, which are equivalent.

=head2 host

    $host = $uri->host;
    $old = $uri->host( $host );

Sets and returns the host part of the $uri's kernel.  If the kernel wasn't 
host:port, then it is converted to that.

=head2 port

    $port = $uri->port;
    $old = $uri->port( $port );

Sets and retuns the port part of the $uri's kernel.  If the kernel wasn't a
host name, then it becomes one.

=head2 default_port

The default POE port is 603 which is POE upside-down and backwards.  Almost.


=head2 argument

    $arg = $uri->argument
    $old = $uri->argument( $new_arg );
    $old = $uri->argument( %new_arg );
    $old = $uri->argument( \@new_arg );

Sets and returns the argument for this $uri.  And argument may be a string,
a hash (L<URI/query_form>) or an arrayref (L<URI/query_keywords>).

See L</as_array> to see how the argument is passed to the event handler.

=head2 user

    $user = $uri->user;
    $old = $uri->user( $user );

Sets and returns the username part of the $uri's L<URI/userinfo>.  If the
user name contains C<:>, it is escaped.

A user only makes sense in IKC.

=head2 password

    $pw = $uri->password;
    $old = $uri->password( $passwd );

Sets and returns the password part of the $uri's L<URI/userinfo>.  If the
password contains C<:>, it is escaped.

The user name and password are seperated by C<:>.  This is might be a security
issue.  Beware.

While this method is called I<password>, it works just as well with pass
phrases.

A password only makes sense in IKC.

=head2 as_array

    $poe_kernel->post( @$uri, @args );
    $poe_kernel->post( $uri->as_array, @args );

Returns a URI object to a session/event tuple, suitable for posting or
calling. POEx::URI objects are also converted to arrays
automatically by overloading.  

If a kernel name is present, and it is not the local kernel ID, then it is
prepended to the session name.  This is compatible with IKC after
subscribing to the remote session.

If an argument is present, it is returned as the last item.  

=head2 canonical

    my $full = $uri->canonical;

Returns a normalized version of the URI.  For POE URIs, the hostname is 
folded to lower case.


=head2 path

    $path = $uri->path;
    $old = $uri->path( $new_path );

Sets and returns the session/event tupple of a $uri.  If the new path
contains more then one slash, the last segment of the path is the event, and
the others are the session and those slash are escaped.

=head2 path_segments

    ( $session, $event ) = $uri->path_segments;
    @old = $uri->path_segments( @new );

Sets and returns the path.  In a scalar context, it returns the same value
as $uri->path.  In a list context, it returns the unescaped path segments
that make up the path.  See L<URI/path_segments> for more details.

=head1 SEE ALSO

L<POE>, L<URI>, L<http://www.faqs.org/rfcs/rfc3986.html>.

=head1 AUTHOR

Philip Gwyn, E<lt>gwyn -at- cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Some of this code is based on C<URI> and related subclasses was developed by
Gisle Aas et al.


Copyright (C) 2009 by Philip Gwyn

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut
