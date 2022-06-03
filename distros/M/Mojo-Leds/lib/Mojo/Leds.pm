package Mojo::Leds;
$Mojo::Leds::VERSION = '1.13';
use Mojo::Base 'Mojolicious';
use Mojo::Log;
use Mojo::File 'path';

sub startup() {
    my $s = shift;

    # plugins
    $s->plugin( Config => { default => {docs_root => 'www' }} );
    $s->plugin( Config => { file => 'cfg/app.cfg' } )
        if (-e $s->home->rel_file('cfg/app.cfg'));

    # log
    unless ( $s->app->mode eq 'development' ) {
        if ( $s->config->{log}->{path} ) {
            my $log = Mojo::Log->new(
                path  => $s->config->{log}->{path},
                level => $s->config->{log}->{level} || 'warn',
            );
            $s->app->log($log);
        }
    }

    # support for plugins config in Mojolicious < 9.0
    if ( $Mojolicious::VERSION < 9 && ( my $plugins = $s->config->{plugins} ) ) {
        die qq{Configuration value "plugins" is not an array reference}
          unless ref $plugins eq 'ARRAY';
        for my $plugin (@$plugins) {
            die qq{Configuration value "plugins" contains an entry }
              . qq{that is not a hash reference}
              unless ref $plugin eq 'HASH';
            $s->plugin( ( keys %$plugin )[0], ( values %$plugin )[0] );
        }
    }

    # global configurations
    my $cfg = $s->config;
    $s->secrets( $cfg->{secret} );
    $s->sessions->default_expiration( $cfg->{session}->{default_expiration} );
    $s->sessions->cookie_name( $cfg->{session}->{name} );

    # la root dei file statici
    my $docs_root = $s->config->{docs_root};
    push @{ $s->app->static->paths }, $s->home->rel_file("$docs_root/public");

    # ridefinisco la root dei template
    $s->app->renderer->paths->[0] = $s->home->rel_file($docs_root)->to_string;

    #  add bundled templates
    my $templates_bundled = path(__FILE__)->sibling('Leds')->child('resources');
    push @{$s->app->renderer->paths}, $templates_bundled->child('templates');
    push @{$s->app->static->paths}, $templates_bundled->child('public');
}

1;

=pod

=head1 NAME

Mojo::Leds - Leds aka Light Environment (emi) for Development System based on Mojolicious

=for html <p>
    <a href="https://github.com/emilianobruni/mojo-leds/actions/workflows/test.yml">
        <img alt="github workflow tests" src="https://github.com/emilianobruni/mojo-leds/actions/workflows/test.yml/badge.svg">
    </a>
    <img alt="Top language: " src="https://img.shields.io/github/languages/top/emilianobruni/mojo-leds">
    <img alt="github last commit" src="https://img.shields.io/github/last-commit/emilianobruni/mojo-leds">
</p>

=head1 VERSION

version 1.13

=head1 SYNOPSIS

=head1 DESCRIPTION

Mojo::Leds is a L<Mojolicious> app to use a filesystem similiar to classical web site

=encoding UTF-8

=head1 DIFFERENCES WITH MOJOLICIOUS

Mojolicious applications use a filesystem structure closer to a CPAN distribution
which is not (IMHO) intuitive.

This is a classical Mojolicios applications

    myapp                      # Application directory
    |- script                  # Script directory
    |  +- my_app               # Application script
    |- lib                     # Library directory
    |  |- MyApp.pm             # Application class
    |  +- MyApp                # Application namespace
    |     +- Controller        # Controller namespace
    |        +- Example.pm     # Controller class
    |- public                  # Static file directory (served automatically)
    |  |- index.html           # Static HTML file
    |  +- css                  # Static CSS file
    |     +- example           # Static CSS for "Example" controller
    |       +- welcome.css     # Static CSS for "welcome" action
    |  |- js                   # Static JS file
    |     +- example           # Static js for "Example" controller
    |        +- welcome.js     # Static js for "welcome" action
    +- templates               # Template directory
       |- layouts              # Template directory for layouts
       |  +- default.html.ep   # Layout template
       +- example              # Template directory for "Example" controller
          +- welcome.html.ep   # Template for "welcome" action

And, as you can see, the "page" welcome has its controller in
C<lib/MyApp/Controller/Example.pm>, the html code in C<templates/example/welcome.html.ep>,
the CSS code in C<public/css/example/welcome.css> and its JS code in
C<public/js/example/welcome.js>.

In Mojo::Leds this structure is quite different

    myapp                      # Application directory
    |- cfg                     # Config directory
       +- app.cfg              # App config file
    |- script                  # Script directory
    |  +- my_app               # Application script
    |- lib                     # Library directory
    |  +- MyApp.pm             # Application class
    |- www                     # DocumentRoot :-)
        |- public              # Static files directory (served automatically)
        |  |- index.html       # Static Home page HTML
        |  |- css              # Static CSS file
        |     + app.css        # Global Static CSS file
        |  +- js               # Static JS file
        |     + app.js         # Global Static JS file
        |- layouts
        |  +- default.html.ep  # Layout template
        +- welcome             # Welcome page: directory
           |- index.pm         # Welcome page: controller
           |- index.html.ep    # Welcome page: template
           |- index.css        # Welcome page: CSS file
           +- index.js         # Welcome page: JS file

and here, controller, html code, css and js are all inside C<www/example/> directory.

=head1 BUGS/CONTRIBUTING

Please report any bugs through the web interface at L<https://github.com/EmilianoBruni/Mojo-Leds/issues>

If you want to contribute changes or otherwise involve yourself in development, feel free to fork the Git repository from
L<https://github.com/EmilianoBruni/Mojo-Leds/>.

=head1 SUPPORT

You can find this documentation with the perldoc command too.

    perldoc Mojo::Leds

=head1 AUTHOR

Emiliano Bruni <info@ebruni.it>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by Emiliano Bruni.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__

# ABSTRACT: Leds aka Light Environment (emi) for Development System based on Mojolicious

