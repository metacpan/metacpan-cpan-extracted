package Mojo::Leds;

use Mojo::Base 'Mojolicious';
use Mojo::Log;

sub startup() {
    my $s = shift;

    # plugins
    $s->plugin( Config => { file => 'cfg/app.cfg' } );

    # lo leggo due volte per valorizzare dentro al cfg app->config->...
    $s->plugin( Config => { file => 'cfg/app.cfg' } );

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
}

1;

=pod

=head1 NAME

Mojo::Leds - Leds aka Light Environment (emi) for Development System based on Mojolicious

=for html <p><img alt="GitHub last commit" src="https://img.shields.io/github/last-commit/EmilianoBruni/Mojo-Leds?style=plastic"> <a href="https://travis-ci.com/EmilianoBruni/Mojo-Leds"><img alt="Travis tests" src="https://img.shields.io/travis/com/EmilianoBruni/Mojo-Leds?label=Travis%20tests&style=plastic"></a></p>

=head1 VERSION

version 1.02

=head1 SYNOPSIS

=head1 DESCRIPTION

=encoding UTF-8

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

This software is copyright (c) 2021 by Emiliano Bruni.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__

# ABSTRACT: Leds aka Light Environment (emi) for Development System based on Mojolicious

