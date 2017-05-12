package Mojolicious::Plugin::JSUrlFor;
use Mojo::Base 'Mojolicious::Plugin';

our $VERSION = '0.17';

use Mojo::ByteStream qw/b/;
use Data::Dumper;
use v5.10;

sub register {
    my ( $self, $app, $config ) = @_;

    if ( $config->{route} ) {
        $app->routes->get( $config->{route} => sub {
            my $c = shift;
            $c->render(
                inline => $c->app->_js_url_for_code_only(),
                format => 'js'
            );
        } )->name('js_url_for');
    }

    $app->helper(
        js_url_for => sub {
            my $c      = shift;
            state $b_js; # bytestream for $js

            if ( $b_js && $app->mode eq 'production' ) {
                return $b_js;
            }

            my $js = $app->_js_url_for_code_only;

            $b_js = b('<script type="text/javascript">'.$js.'</script>');
            return $b_js;
        }
    );

    $app->helper(
        _js_url_for_code_only => sub {
            my $c      = shift;
            my $endpoint_routes = $self->_collect_endpoint_routes( $app->routes );

            my %names2paths;
            foreach my $route (@$endpoint_routes) {
                next unless $route->name;

                my $path = $self->_get_path_for_route($route);
                $path =~ s{^/*}{/}g; # TODO remove this quickfix

                $names2paths{$route->name} = $path;
            }

            my $json_routes = $c->render_to_string( json => \%names2paths );
            utf8::decode( $json_routes );

            my $js = <<"JS";
var mojolicious_routes = $json_routes;
function url_for(route_name, captures) {
    var pattern = mojolicious_routes[route_name];
    if(!pattern) return route_name;

    // Fill placeholders with values
    if (!captures) captures = {};
    for (var placeholder in captures) { // TODO order placeholders from longest to shortest
        var re = new RegExp('[:*]' + placeholder, 'g');
        pattern = pattern.replace(re, captures[placeholder]);
    }

    // Clean not replaces placeholders
    pattern = pattern.replace(/[:*][^/.]+/g, '');

    return pattern;
}
JS
            return $js;
        } );
}


sub _collect_endpoint_routes {
    my ( $self, $route ) = @_;
    my @endpoint_routes;

    foreach my $child_route ( @{ $route->children } ) {
        if ( $child_route->is_endpoint ) {
            push @endpoint_routes, $child_route;
        } else {
            push @endpoint_routes, @{ $self->_collect_endpoint_routes($child_route) };
        }
    }
    return \@endpoint_routes
}

sub _get_path_for_route {
    my ( $self, $parent ) = @_;

    my $path = $parent->pattern->unparsed // '';

    while ( $parent = $parent->parent ) {
        $path = ($parent->pattern->unparsed//'') . $path;
    }

    return $path;
}

1;
__END__

=head1 NAME

Mojolicious::Plugin::JSUrlFor - Mojolicious "url_for" helper for javascript

=head1 SYNOPSIS

  # Mojolicious
  $self->plugin('JSUrlFor');

  # Mojolicious::Lite
  plugin 'JSUrlFor';

  # In your application
  my $r = $self->routes;
  $r->get('/messages/:message_id')->to('messages#show')->name('messages_show');

  # In your layout template
  <head>
  <%= js_url_for%>
  </head>

  # In your javascript
  $.getJSON( url_for( 'messages_show', {message_id: 123} ), params, function() { ... } )


  # Instead of helper you can use generator for generating static file
  ./your_app.pl generate js_url_for public/static/url_for.js

  # And then in your layout template
  <head>
    <script type="text/javascript" src='/static/url_for.js'> </script>
  </head>

  # Or let it generate on the fly
  # Can be useful if you have only RESTful API without templates and you want to provide routes names for UI
  $self->plugin('JSUrlFor', {route => '/javascript/url.js'});
  <head>
    <script type="text/javascript" src='/javascripts/url.js'> </script>
  </head>

=head1 DESCRIPTION

I like Mojolicious routes. And one feature that I like most is that you can name your routes.
So, you can change your routes without rewriting a single line of dependent code. Of course this works if you
use route names in all of your code. You can use route name everywhere except... javascript.
But with L<Mojolicious::Plugin::JSUrlFor> you can use route names really everywhere.
This plugin support mounted (see L<Mojolicious::Plugin::Mount> ) apps too.

L<Mojolicious::Plugin::JSUrlFor> contains only one helper that adds C<url_for> function to your client side javascript.

=head1 HELPERS

=head2 C<js_url_for>

In templates C<< <%= js_url_for %> >>

This helper will add C<url_for> function to your client side javascript.

In I<production> mode this helper will cache generated code for javascript I<url_for> function

=head1 CONFIG OPTIONS

=head2 C<route>

Simulate static javascript file. It can be useful if you have RESTful API and want to provide js file with routes.

=head1 GENERATORS

=head2 C<js_url_for>

  ./your_app.pl generate js_url_for $relative_file_name

This command will create I<$relative_file_name> file with the same content as C<js_url_for> helper creates.
Then you should include this file into your layout template with I<script> tag.

=head1 METHODS

L<Mojolicious::Plugin::JSUrlFor> inherits all methods from
L<Mojolicious::Plugin> and implements the following new ones.

=head2 C<register>

  $plugin->register;

Register plugin in L<Mojolicious> application.

=head1 AUTHOR

Viktor Turskyi <koorchik@cpan.org>

=head1 BUGS

Please report any bugs or feature requests to Github L<https://github.com/koorchik/Mojolicious-Plugin-JSUrlFor/>

Also you can report bugs to CPAN RT

=head1 SEE ALSO

L<Mojolicious>, L<Mojolicious::Guides>, L<http://mojolicio.us>.

=cut
