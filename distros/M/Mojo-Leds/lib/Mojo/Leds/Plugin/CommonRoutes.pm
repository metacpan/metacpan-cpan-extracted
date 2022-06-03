package Mojo::Leds::Plugin::CommonRoutes;
$Mojo::Leds::Plugin::CommonRoutes::VERSION = '1.13';
# ABSTRACT: Add routes to get app informations (library version, routes,...)

use Mojo::Base 'Mojolicious::Plugin';
use Mojo::File qw/curfile/;
use Net::Domain qw(hostname);
use re qw(regexp_pattern);
use Mojo::Util qw(encode getopt tablify);

sub register {
    my ( $s, $app ) = @_;
    $app->log->debug( "Loading " . __PACKAGE__ );

    my $class = ref $app;
    $class = eval { $app->renderer->classes->[0] } // 'main'
      if $class eq 'Mojolicious::Lite';
    my $version = $class->VERSION // 'dev';

    my $r = $app->routes;

    $r->get('/version')->to(
        cb => sub {
            shift->render(
                json => {
                    class   => $class,
                    version => $version
                }
            );
        }
    );

    my ( $app_name, $hostname ) = do {
        my $name = ref $app;
        $name = curfile if $name eq 'Mojolicious::Lite';
        ( $name, hostname() );
    };

    $r->get('/status')->to(
        cb => sub {
            my $s = shift;
            $s->render(
                json => {
                    app_name => $app_name,
                    server   => {
                        version  => $version,
                        hostname => $hostname,
                        url      => $s->url_for('/')->to_abs->to_string,
                    }
                }
            );
        }
    );

    my $get_routes = sub() {
        my $verbose = shift || '';
        my $rows    = [];
        _walk( $_, 0, $rows, $verbose ) for @{ $app->routes->children };
        return $rows;
    };

    my $root_with_format =
      $r->get( '/' => [ format => [ 'json', 'html', 'txt' ] ] );

    $root_with_format->get( '/routes/:verbose' => { verbose => '' } )->to(
        format => undef,
        cb     => sub {
            my $s = shift;
            $s->respond_to(
                any => { json => $get_routes->( $s->stash('verbose') ) },
                txt =>
                  { text => tablify( $get_routes->( $s->stash('verbose') ) ) }
            );
        }
    );
}

sub _walk {
    my ( $route, $depth, $rows, $verbose ) = @_;

    # Pattern
    my $prefix = '';
    if ( my $i = $depth * 2 ) { $prefix .= ' ' x $i . '+' }
    push @$rows, my $row = [ $prefix . ( $route->pattern->unparsed || '/' ) ];

    # Flags
    my @flags;
    push @flags, @{ $route->requires // [] } ? 'C' : '.';
    push @flags, ( my $partial = $route->partial ) ? 'P' : '.';
    push @flags, $route->inline       ? 'U' : '.';
    push @flags, $route->is_websocket ? 'W' : '.';
    push @$row,  join( '', @flags ) if $verbose;

    # Methods
    my $methods = $route->methods;
    push @$row, !$methods ? '*' : uc join ',', @$methods;

    # Name
    my $name = $route->name;
    push @$row, $route->has_custom_name ? qq{"$name"} : $name;

    # Regex (verbose)
    my $pattern = $route->pattern;
    $pattern->match( '/', $route->is_endpoint && !$partial );
    push @$row, ( regexp_pattern $pattern->regex )[0] if $verbose;

    $depth++;
    _walk( $_, $depth, $rows, $verbose ) for @{ $route->children };
    $depth--;
}

1;

__END__

=pod

=head1 NAME

Mojo::Leds::Plugin::CommonRoutes - Add routes to get app informations (library version, routes,...)

=head1 VERSION

version 1.13

=head1 AUTHOR

Emiliano Bruni <info@ebruni.it>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by Emiliano Bruni.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
