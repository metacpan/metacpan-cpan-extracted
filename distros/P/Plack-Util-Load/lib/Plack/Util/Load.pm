package Plack::Util::Load;
use strict;
use warnings;

our $VERSION = '0.1';

use parent 'Exporter';
our @EXPORT = qw(load_app);

use Plack::Util;
use Plack::Request;
use Plack::Response;
use HTTP::Tiny;
use URI;

use Carp;
our @CARP_NOT = ('Plack::Util');

our $VERBOSE = 0;

sub load_app {
    my ($app, %options) = @_;

    if ( !defined $options{verbose} ) {
        $options{verbose} = $VERBOSE;
    }

    if ( ref $app ) {
        if (ref $app eq 'CODE') {
            return $app;
        } elsif ( eval { $app->can('to_app') } ) {
            return $app->to_app;
        } else {
            croak "failed to load app from object or reference " . ref $app;
        }
    } elsif ( !defined $app or $app eq '' ) {
        $app = 'app.psgi';
    }

    if ( $app =~ /^:?(\d+)$/ and $1 > 0 ) {
        return load_url("http://localhost:$1/", %options);
    } elsif ( $app eq 'localhost' ) {
        return load_url("http://localhost/", %options);
    } elsif ( $app =~ /^https?:\/\// ) {
        return load_url($app, %options);
    } elsif ( -f $app ) {
        return Plack::Util::load_psgi($app);
    } elsif ( $app =~ /^[a-zA-Z0-9\_\:]+$/ ) {
        return load_package($app, %options);
    }

    croak "failed to load app $app";
}

sub load_package {
    my ($module, %options) = @_;

    # check defined module
    no strict 'refs';
    if ( %{ $module.'::' } ) { 
        my $app = eval { $module->new->to_app };
        if ( ref $app ) {
            print "# load_app defined package $module\n" if $options{verbose};
            return $app;
        }
        croak "failed to load app $module from package";
    }


    # load and instanciate new module
    Plack::Util::load_class( $module );
    my $app = $module->new->to_app; 
    print "# load_app new package $module\n" if $options{verbose};

    return $app;
}

sub load_url {
    my ($url, %options) = @_ % 2 ? @_ : (undef, @_);

    $url = URI->new($url);
    my ($scheme, $host, $port) = ($url->scheme, $url->host, $url->port);
    
    my $verbose = $options{verbose};

    return sub {
        my $req = Plack::Request->new($_[0]);
        my @headers;
        $req->headers->scan(sub { push @headers, @_ });
        my $options = { headers => {} };
        $options->{headers} = Hash::MultiValue->new(@headers)->mixed if @headers;
        delete $options->{headers}->{Host}; # not allowed by HTTP::Tiny
        $options->{content} = $req->content if length($req->content);
        my $uri = $req->uri;
        $uri->scheme($scheme);
        $uri->host($host);
        $uri->port($port);

        if ($verbose) {
            printf "# %s %s\n", $req->method, $uri;
        }

        my $res = HTTP::Tiny->new->request( $req->method, $uri, $options );

        if ($res->{status} == 599 and $verbose) {
            print STDERR "# ".$res->{content};
        }

        return Plack::Response->new( $res->{status}, $res->{headers}, $res->{content} )->finalize;
    };
}

1;
__END__

=head1 NAME

Plack::Util::Load - load PSGI application from class, file, or URL

=begin markdown

# STATUS

[![Build Status](https://travis-ci.org/nichtich/Plack-Util-Load.png)](https://travis-ci.org/nichtich/Plack-Util-Load)
[![Coverage Status](https://coveralls.io/repos/nichtich/Plack-Util-Load/badge.png)](https://coveralls.io/r/nichtich/Plack-Util-Load)
[![Kwalitee Score](http://cpants.cpanauthors.org/dist/Plack-Util-Load.png)](http://cpants.cpanauthors.org/dist/Plack-Util-Load)

=end markdown

=head1 SYNOPSIS

    use Plack::Util::Load;

    $app = load_app('app.psgi');
    $app = load_app;

    $app = load_app(5000); 
    $app = load_app(':5000');
    $app = load_app('localhost:5000');
    $app = load_app('http://localhost:5000/');

    $app = load_app("http://example.org/");

    $app = load_app('MyApp::PSGI');

=head1 DESCRIPTION

This module exports the function C<load_app> to load a L<PSGI> application from
file, class name, URL, or port number on localhost. The function will return a
code reference or die. A typical use case is the application of unit tests.

=head1 OPTIONS

The additional options C<verbose> can be passed to log HTTP requests and
errors:

    $app = load_app( 'http://example.org/', verbose => 1 ); 

The default value for this option can be set with
C<$Plack::Util::Load::VERBOSE>.

=head1 SEE ALSO

L<Plack::Util>, L<Plack::App::Proxy>

=head1 COPYRIGHT AND LICENSE

Copyright Jakob Voss, 2015-

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
