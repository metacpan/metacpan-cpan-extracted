package RT::Client;

use 5.006;
our $VERSION = '0.01';
our @ISA = 'XML::Atom::Client';

=head1 NAME

RT::Client - A client of RT from Best Practical Solutions

=head1 VERSION

This document describes version 0.01 of RT::Client,
released August 26, 2004.

=head1 SYNOPSIS

    use RT::Client;

    my $rt = RT::Client->new('http://root@password:localhost');

    # ...see t/1-procedure.t for details...

=head1 DESCRIPTION

This module is a subclass of B<XML::Atom::Client>.  It implements a
client API for RT's Atom interface.  Please refer to L<RT::Atom> for
the server-side specification.

For the time being, the unit tests in the F<t/> directory from the
CPAN distribution remains the only documentation for this module.

As the version number indicates, this is a very early proof-of-concept
release for peer review; all interfaces are subject to change, and
should not be relied upon in production code.

=cut

use strict;
use warnings;

use Spiffy '-Base';

use URI;
use Carp;
use HTTP::Request::Common;
use XML::Atom::Client;

BEGIN { %LWP::Authen::Wsse:: = (); }

use LWP::Authen::Wsse;
use LWP::UserAgent::RTClient;

use RT::Client::Base ();
use RT::Client::Object ();
use RT::Client::Property ();
use RT::Client::Container ();
use RT::Client::ResultSet ();

field path      => '/Atom/0.3/';
field server    => 'localhost';
field encoding  => 'UTF-8';
field debug     => 0;
field 'ua';
field 'current_user';
field 'status';
field 'errstr';
field 'handle_error';

=head1 CONSTRUCTORS AND ATTRIBUTES

=head2 new

=cut

sub new {
    my %args = (@_ % 2) ? (URI => @_) : @_;

    if (my $uri = delete $args{URI}) {
        $uri = URI->new($uri);
        @args{'Username', 'Password'} = split(/:/, $uri->userinfo||'', 2);
        $args{Server} = $uri->scheme . '://' .$uri->host_port;
        $args{Path} = ($uri->path =~ m{^/*$}) ? undef : $uri->path;
    }

    my $rv = $self->SUPER::new(%args);

    foreach my $attr (qw( username password server path )) {
        $rv->$attr($args{"\u$attr"}) if defined $args{"\u$attr"};
    }

    $rv->ua( LWP::UserAgent::RTClient->new($rv) );
    $rv->ua->{keep_alive} = 1;
    $rv->ua->{requests_redirectable} = [ qw( GET HEAD OPTIONS ) ];
    
    return $rv;
}

sub munge_request {
    my $req = shift;
    $req->header(
        'Accept' => join(
            ', ',
            'application/atom+xml', 'application/x.atom+xml',
            'application/xml', 'text/xml', '*/*',
        )
    );
    $req->header(
        'Content-Type' => join(
            '; ',
            ($req->content_type || 'text/plain'),
            'charset='.$self->encoding
        )
    );
    $req->header( 'Accept-Charset' => $self->encoding );
    $req->header( 'X-RT-CurrentUser' => $self->current_user );
    return $req;
}

const _describe_map => {
    feed    => 'RT::Client::Container',
    entry   => 'RT::Client::Object',
};

sub _spawn {
    my $res = shift;
    my $ref = $res->content_ref;
    chomp $$ref;

    $$ref =~ /<(\w+)/ or return $$ref;

    if ($1 eq 'html') {
        $self->errstr($$ref);
        $self->status(500);
        $self->_handle_error;
        return undef;
    }

    my $class = $self->_describe_map->{$1} or die "Sorry, type $1 not handled yet";
    return $class->new(Client => $self, Stream => $ref, URI => $res->base);
}

=head1 OBJECT-ORIENTED INTERFACE

This interface is still under construction.

=head1 PROCEDURE-ORIENTED INTERFACE

The B<RT::Client> object implements seven operations, each taking a
mandatory B<URI> parameter; see F<t/1-procedural.t> for details.

=head2 describe

=cut

sub describe {
    my $res = $self->_request(@_, method => 'OPTIONS') or return undef;
    return $self->_spawn($res);
}

=head2 search

Not yet implemented.

=cut

stub 'search';

=head2 get

=cut

sub get {
    my $res = $self->_request(@_, method => 'GET') or return undef;
    return $self->_spawn($res);
}

=head2 set

=cut

sub set {
    splice(@_, 1, 0, 'content') if (@_ == 2 and $_[0] ne 'URI');
    my $res = $self->_request(@_, method => 'PUT') or return undef;
    return $self->_spawn($res);
}

=head2 add

=cut

sub add {
    my ($uri, %args) = $self->_parse_args(@_);
    my $container = $self->describe($uri) or return undef;
    return $container->add(%args);
}

=head2 update

=cut

sub update {
    my ($uri, %args) = $self->_parse_args(@_);
    my $object = $self->describe($uri) or return undef;
    return $object->update(%args);
}

=head2 remove

=cut

sub remove {
    my $res = $self->_request(@_, method => 'DELETE') or return undef;
    return $self->_spawn($res);
}

sub _parse_args {
    my %args = (@_ % 2) ? (URI => @_) : @_;
    my $uri = delete $args{URI} or die "Must pass a URI";
    $uri = URI->new_abs( $uri, join('/', $self->server . $self->path) );
    return($uri, %args);
}

sub _request {
    my ($uri, %args) = $self->_parse_args(@_);

    my $method = delete $args{method};
    my $req;

    if ($method eq 'POST') {
        foreach my $key (sort keys %args) {
            if (ref $args{$key} and UNIVERSAL::can($args{$key}, 'as_string')) {
                $args{$key} = $args{$key}->as_string;
            }
        }
        foreach my $key (sort keys %args) {
            next unless UNIVERSAL::isa($args{$key}, 'HASH');
            my $val = delete $args{$key};
            while (my ($k, $v) = each %$val) {
                my $new_key = "$key-$k";
                foreach my $new_val (UNIVERSAL::isa($v, 'ARRAY') ? @$v : $v) {
                    if (exists $args{$new_key}) {
                        if (UNIVERSAL::isa($args{$new_key}, 'ARRAY')) {
                            push @{$args{$new_key}}, $new_val;
                            next;
                        }
                        $args{$new_key} = [ $args{$new_key}, $new_val ];
                        next;
                    }
                    $args{$new_key} = [ $new_val ];
                }
            }
        }
        $req = HTTP::Request::Common::POST(
	    $uri,
	    \%args,
#	    Content_Type => 'form-data',
#	    Content => [ %args ],
	);
    }
    else {
        $req = HTTP::Request::Common::_simple_req($method => $uri);
        $req->content(delete $args{content}) if exists $args{content};
    }

    print STDERR "===> " . $req->as_string if $self->debug;

    my $res = $self->make_request($req);
    $self->status($res->code);

    print STDERR "<=== " . $res->as_string if $self->debug;

    if ($res->is_error) {
	my $ref = $res->content_ref; chomp $$ref;
        $self->errstr($$ref);
        $self->_handle_error;
        return;
    }
    else {
        $self->errstr(undef);
    }

    return $res;
}

sub _handle_error {
    my $code = $self->handle_error or return;
    $code = \&Carp::croak if $code eq 'die';
    $code = \&Carp::carp if $code eq 'warn';
    $code->($self->status, $self->errstr);
}

1;

=head1 SEE ALSO

L<RT::Atom>, L<XML::Atom::Client>

=head1 AUTHORS

Autrijus Tang E<lt>autrijus@autrijus.orgE<gt>

=head1 COPYRIGHT

Copyright 2004 by Best Practical Solutions, LLC.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>

=cut
