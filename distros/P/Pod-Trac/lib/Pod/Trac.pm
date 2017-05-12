package Pod::Trac;

use warnings;
use strict;
use Carp;

use File::Util;
use URI::Escape;
use HTTP::Request::Common qw(POST);
use LWP::UserAgent;
use HTTP::Cookies;
use Pod::Simple::Wiki;

use base qw( Class::Accessor::Fast );
__PACKAGE__->mk_accessors( qw(form_token pod_url pod_rev) );

our $VERSION = '0.0.1';

=head1 NAME

Pod::Trac - Convert a POD to trac's wiki syntax and add it to the trac


=head1 VERSION

This document describes Pod::Trac version 0.0.1


=head1 SYNOPSIS

    use Pod::Trac;

    my $trac = Pod::Trac->new({url => "http", login => "mylogin", passwd => "mypass"});
    $trac->from_file({file => "myfile.pm"});
    # or
    $trac->from_path({path => "/my/path/", file_filter => "pm"});
    
see pod2trac.pl in the example directory

=head1 DESCRIPTION

    Extract POD from your sources, convert them to the trac's wiki syntax, and create or update the
    page with the new document
    
=cut

=head2 METHODS

=head3 init

create a LWP Object.
Log in the trac wiki, and store the cookie.
get the trac_form_token

=head3 generate

Convert the POD to the wiki syntax.

=head3 write_to_trac

send the POD to the trac
    
    set $self->pod_rev to the revision of the current page
    set $self->pod_url to the url of the page created/updated
    push in $self->{created_path} the $self->pod_rev and $self->pod_url
    
=head3 from_file

Get a filename and convert the pod in this file

=head3 from_path

Look in a directory, for all the pods and send them to the trac.

=cut

sub init {
    my ( $self ) = @_;
    $self->{ ua } = LWP::UserAgent->new;
    $self->{ ua }->cookie_jar( {} );

    my $req = HTTP::Request->new( GET => $self->{ trac_url } . "/login" );
    $req->authorization_basic( $self->{ login }, $self->{ passwd } );

    my $response = $self->{ ua }->request( $req );

    # are we logged in ?
    if ( !$response->is_success ) {
        croak( "Can't login on this trac, check your login" );
    }
    my $cookie = $response->request->headers->{ cookie };
    $cookie =~ /trac_form_token=(.*);/;
    $self->form_token( $1 );
}

sub generate {
    my ( $self, $file ) = @_;

    my ( $parser, $wiki );

    # convert the pod to wiki syntax
    $parser = Pod::Simple::Wiki->new( 'moinmoin' );
    $parser->output_string( \$wiki );
    $parser->parse_file( $file );

    return if length $wiki < 1;

    # send data to trac
    $self->write_to_trac( $wiki, $file );
}

sub write_to_trac {
    my ( $self, $poddata, $podname ) = @_;

    $poddata = uri_escape( $poddata );
    $podname =~ s/(\.\.\/)//g;

    $self->pod_url( $self->{ trac_url } . "/wiki/" . $podname );

    $self->pod_rev( 0 );
    my $req = HTTP::Request->new( GET => $self->pod_url );
    my $response = $self->{ ua }->request( $req );

    if ( $response->is_success ) {
        if ( $response->content
             =~ /<input type="hidden" name="version" value="(\d+?)" \/>/ )
        {
            $self->pod_rev( $1 );
        }
    }

    $req = HTTP::Request->new( POST => $self->pod_url );
    $req->content_type( 'application/x-www-form-urlencoded' );
    $req->content(   "__FORM_TOKEN="
                   . $self->form_token
                   . "&action=edit&version="
                   . $self->pod_rev
                   . "&text="
                   . $poddata
                   . "&save=Submit+changes" );
    $response = $self->{ ua }->request( $req );
    push @{ $self->{ created_path } },
        { pod_url => $self->pod_url, pod_rev => $self->pod_rev };
}

sub from_file {
    my ( $self, $params ) = @_;

    croak( "Please give me a file" ) unless defined $$params{ 'file' };
    $self->init();
    $self->generate( $$params{ file } );

}

sub from_path {
    my ( $self, $params ) = @_;

    croak( "Please give me a path" ) unless defined $$params{ 'path' };
    $self->init();
    my $f     = File::Util->new();
    my @files = $f->list_dir( $$params{ 'path' },
                              qw/--files-only --recurse --no-fsdots/ );

    foreach my $file ( @files ) {
        if ( defined $$params{ 'filter' } ) {
            if (grep { $file =~ /\.$_$/} @{$$params{filter}}){
                $self->generate( $file );
            }
        }
    }
}

1;
__END__

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-pod-trac@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 AUTHOR

franck cuny  C<< <franck.cuny@gmail.com> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2007, franck cuny C<< <franck.cuny@gmail.com> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.
