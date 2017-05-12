package POE::XUL::Request;
# $Id: Request.pm 1566 2010-11-03 03:13:32Z fil $
# Copyright Philip Gwyn 2007-2010.  All rights reserved.

use strict;
use warnings;

use Carp;
use HTTP::Status;
use POE::XUL::Logging;
use Unicode::String qw( latin1 utf8 );

use constant DEBUG => 0;

use base 'POE::Component::Server::HTTP::Request';

our $VERSION = '0.0601';

##############################################################
# Rebless an HTTP::Request to us, so we can add the param argument
sub new 
{
    my( $package, $req ) = @_;

	my $self = bless $req, $package;

    my $rv = $self->parse_args;
    return $rv if $rv;
	return $self;
}

##############################################################
# Get the arguments out of a request
sub parse_args
{
    my( $self ) = @_;
    my $P;
    return if $self->{P};

    local $ENV{QUERY_STRING};
    my $method = $self->method;
    if( $method eq 'GET' ) {
        # TODO: is query UTF-8?
        DEBUG and 
            xdebug "GET: ", $self->uri->query;
        $P = $self->decode_urlencoded( $self->uri->query );
    }
    elsif( $method eq 'POST' ) {
        $P = $self->parse_post_args;
        return $P unless ref $P;
    }
    else {
        return RC_METHOD_NOT_ALLOWED;
    }

    ####
    $self->{P} = $P;
    return;
}

sub pre_log
{
    my( $self ) = @_;
    my $P = $self->{P};
    xwarn "Request=", join( ' ', map { "$_:@{$P->{$_}}" } sort keys %$P), "\n";
    return;
}

##############################################################
# Get a request parameter.  Uses the P hash created in parse_args()
sub param
{
    my( $self, $key, $value ) = @_;
    if( 3==@_ ) {
        if( ref $value ) {
            $self->{P}{$key} = $value;
        }
        else {
            $self->{P}{$key} = [ $value ];
        }
    }
    my $V = $self->{P}->{$key};
    return $V->[0] unless wantarray();
    return @$V;
}

sub params
{
    my( $self ) = @_;
    return keys %{$self->{P}};
}

##############################################################
sub parse_post_args
{
    my( $self ) = @_;

    # NOTE : this might/will fail if we use a different
    # content-type.  In which case, we have to move to Apache::Request
    # Also, maybe we should look at $request->dencoded_content;

    my $C = $self->content;

    if( 1 ) {
        my $bad = 0;
        # This code was to handle over-long requests.  But it
        # turned out the bug was in fact in POE::Filter::HTTPD
        my $l = $self->header('Content-Length');
        if( $l != length( $C ) ) {          # MSIE5.01 does this
            xlog "WRONG LENGTH";
            $C = substr( $C, 0, $l );
            $bad++;
        }
        $bad++ if $C =~ s/%0D%0A/%0A/g;       # I hate you milkman MSIE!
        $bad++ if $C =~ s/%0D/%0A/g;
        $bad++ if $C =~ s/\r\n/\n/g;
        if( $bad ) {
            xlog "Broken User-Agent = ", $self->header('User-Agent');
            $self->content( $C );
            $self->header( 'Content-Length' => length( $C ) );
        }
    }

    my $ct = $self->header( 'Content-Type' );
    my $charset = '';
    if( $ct =~ s/; charset=(.+)// ) {
        $charset = $1;
    }
    DEBUG and xdebug "POST ct=$ct -- charset=$charset";
    if( $ct eq 'application/x-www-form-urlencoded' ) {
        return $self->decode_urlencoded( $C, $charset );
    }
    elsif( $ct eq 'application/json' or $ct eq 'text/json' ) {
        # TODO : request might be an array of requests!
        return $self->decode_json ( $C );
    }
    xwarn "Unable to parse $ct";
    return RC_UNSUPPORTED_MEDIA_TYPE;
}

##############################################################
sub decode_json
{
    my( $self, $C ) = @_;
    my $args = eval { 
            if( $JSON::XS::VERSION > 2 ) {
                return JSON::XS::decode_json( $C ) 
            }
            else {
                return JSON::XS::from_json( $C ) 
            }
        };
    if( $@ ) {
        xwarn "JSON error: $@";
        return RC_BAD_REQUEST;
    }
    unless( 'HASH' eq ref $args ) {
        return RC_UNSUPPORTED_MEDIA_TYPE;
    }
    my $P = {};
    while( my( $k, $v ) = each %$args ) {
        if( ref $v ) {
            $P->{$k} = $v;
        }
        else {
            $P->{$k} = [ $v ];
        }
    }
    return $P;
}

##############################################################
sub decode_urlencoded
{
    my( $self, $C, $charset ) = @_;

    return $C unless defined $C;
    my $form;

    foreach my $bit ( split /&/, $C ) {
        my( $key, $value ) = split "=", $bit, 2;

        $key   = $self->decode_urlencoded_value( $key, $charset );
        $value = $self->decode_urlencoded_value( $value, $charset );
        unless( exists $form->{$key} ) {
            $form->{$key} = [ $value ];
        } else {
            push @{ $form->{$key} }, $value;
        }
    }

    return $form;
}

##############################################################
sub decode_urlencoded_value
{
    my( $self, $value, $charset ) = @_;
    return '' unless defined $value and $value ne '';
    $value =~ tr/+/ /;
    $value =~ s/%([a-fA-F0-9][a-fA-F0-9])/pack("C", hex($1))/egs;

    return $value unless $charset;

    my $U;
    if( $charset eq 'UTF-8' ) {
        $U = utf8( $value );
    }
    
    if( defined $U ) {
        return $U->latin1;
    }
    xwarn "Failed to decode $charset string";
    return $value;
}

1;
