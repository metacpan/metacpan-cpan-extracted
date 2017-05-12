package Plient::Handler::LWP;
use strict;
use warnings;

require Plient::Handler unless $Plient::bundle_mode;
our @ISA = 'Plient::Handler';
my ( $LWP, %all_protocol, %protocol, %method );

%all_protocol = map { $_ => undef }
  qw/http https ftp news gopher file mailto cpan data ldap nntp/;
sub all_protocol { return \%all_protocol }
sub protocol { return \%protocol }
sub method { return \%method }

my $inited;
sub init {
    return if $inited;
    $inited = 1;
    eval { require LWP::UserAgent } or return;
    
    undef $protocol{http};

    if ( eval { require Crypt::SSLeay } ) {
        undef $protocol{https};
    }

    $method{http_get} = sub {
        my ( $uri, $args ) = @_;

        # XXX TODO tweak the new arguments
        my $ua  = LWP::UserAgent->new;
        $ua->env_proxy;
        add_headers( $ua, $uri, $args );
        my $res = $ua->get($uri);
        if ( $res->is_success ) {
            return $res->decoded_content;
        }
        else {
            warn "failed to get $uri with lwp: " . $res->status_line;
            return;
        }
    };

    $method{http_post} = sub {
        my ( $uri, $args ) = @_;

        # XXX TODO tweak the new arguments
        my $ua  = LWP::UserAgent->new;
        $ua->env_proxy;
        add_headers( $ua, $uri, $args );

        my $content = [];
        my $is_form_data;
        if (   $args->{body}
            && $args->{content_type}
            && $args->{content_type} =~ /form-data/ )
        {
            $is_form_data = 1;
            if ( $args->{body_array} ) {
                my $body = $args->{body_array};

                for ( my $i = 0 ; $i < $#$body ; $i += 2 ) {
                    my $key = $body->[$i];
                    my $value =
                      defined $body->[ $i + 1 ] ? $body->[ $i + 1 ] : '';
                    if ( ref $value eq 'HASH' && $value->{file} ) {

                        # file upload
                        push @$content, $key, [ $value->{file} ];
                    }
                    else {
                        push @$content, $key, $value;
                    }
                }
            }
        }
        else {
            $content = $args->{body_array};
        }

        my $res = $ua->post(
            $uri,
            (
                $is_form_data
                ? ( Content_Type => 'form−data' )
                : ()
            ),
            $args->{body} ? ( Content => $content ) : (),
        );

        if ( $res->is_success ) {
            return $res->decoded_content;
        }
        else {
            warn "failed to get $uri with lwp: " . $res->status_line;
            return;
        }
    };

#   XXX there is no official way to get the *origin* header output :/
#       $res->headers->as_string isn't exactly the same head output
#       e.g. it adds Client-... headers, and lacking the first line:
#           HTTP/1.0 200 OK
#       
#       
#    $method{http_head} = sub {
#        my ( $uri, $args ) = @_;
#
#        my $ua  = LWP::UserAgent->new;
#        my $res = $ua->head($uri);
#        if ( $res->is_success ) {
#            return $res->headers->as_string;
#        }
#        else {
#            warn "failed to get head of $uri with lwp: " . $res->status_line;
#            return;
#        }
#    };

    if ( exists $protocol{https} ) {
        # have you seen https is available while http is not?
        $method{https_get} = $method{http_get};
        $method{https_post} = $method{http_post};
    }
    return 1;
}

sub add_headers {
    my ( $ua, $uri, $args ) = @_;
    my $headers = $args->{headers} || {};
    for my $k ( keys %$headers ) {
        $ua->default_header( $k, $headers->{$k} );
    }

    if ( $args->{user} && defined $args->{password} ) {
        my $method = lc $args->{auth_method} || 'basic';
        if ( $method eq 'basic' ) {
            require MIME::Base64;
            $ua->default_header(
                "Authorization",
                'Basic '
                  . MIME::Base64::encode_base64(
                    "$args->{user}:$args->{password}", ''
                  )
              )
        }
        else {
            die "aborting: unsupported auth method: $method";
        }
    }
}

__PACKAGE__->_add_to_plient if $Plient::bundle_mode;

1;

__END__

=head1 NAME

Plient::Handler::LWP - 


=head1 SYNOPSIS

    use Plient::Handler::LWP;

=head1 DESCRIPTION


=head1 INTERFACE

=head1 AUTHOR

sunnavy  C<< <sunnavy@bestpractical.com> >>


=head1 LICENCE AND COPYRIGHT

Copyright 2010-2011 Best Practical Solutions.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

