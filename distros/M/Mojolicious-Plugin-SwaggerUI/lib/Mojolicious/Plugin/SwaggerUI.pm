package Mojolicious::Plugin::SwaggerUI;

use Mojo::Base 'Mojolicious::Plugin';
use Mojo::File qw(path);

use File::ShareDir qw(dist_dir);

our $VERSION = '0.0.2';

sub register {
    my ($self, $app, $config) = @_;

    my $prefix = $config->{route} // $app->routes()->any('/swagger-ui');

    # --- Configuring the Mojolicious path resolvers
    my $resources = path(dist_dir('Mojolicious-Plugin-SwaggerUI'))
        ->child('resources');

    push(@{$app->static()->paths()}, $resources->child('public')->to_string());
    push(@{$app->renderer()->paths()}, $resources->child('templates')->to_string());

    # --- Adding the route
    my $url = $config->{url} // '/v1';
    $prefix->get(q(/) => { url => $url })
        ->name('swagger_ui');

    return;
}

1;

=encoding utf8

=head1 NAME

    Mojolicious::Plugin::SwaggerUI - Swagger UI plugin for Mojolicious

=head1 SYNOPSIS

    # Mojolicious Lite
    plugin 'SwaggerUI' => {
        route => app->routes()->any('/swagger'),
        url => '/swagger.json',
    };

=head1 DESCRIPTION

The plugin allows you to run the Swagger UI component inside your Mojolicious application.

=begin html

<p>
    <img alt="Screenshot" 
        src="https://gitlab.com/marghidanu/mojolicious-plugin-swaggerui/raw/master/share/images/Screenshot.png?inline=true">
</p>

=end html

=head1 OPTIONS

=head2 route

    plugin 'SwaggerUI' => { 
        route => app()->routes()->any('/swagger') 
    };

Route for the swagger-ui component. It defaults to a any route on C</swagger-ui>

=head2 url

    plugin 'SwaggerUI' => {
        url => '/swagger.json'
    };

Url for the JSON Swagger specification. It defaults to C</v1>.

B<NOTE:>
L<Mojolicious::Plugin::OpenAPI> can expose the JSON Swagger spec under the base path route. 
You can just point the path in her and it will automatically work.

=head1 AUTHOR

Tudor Marghidanu L<tudor@marghidanu.com>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2019, Tudor Marghidanu.

This program is free software, you can redistribute it and/or modify it under the terms of the Artistic License version 2.0.

=cut

__END__