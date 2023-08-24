[![Actions Status](https://github.com/nyrdz/Namespace-Subroutines/actions/workflows/test.yml/badge.svg)](https://github.com/nyrdz/Namespace-Subroutines/actions)
# NAME

Namespace::Subroutines - Finds subroutines in namespace (attributes included).

# SYNOPSIS

    use Namespace::Subroutines;

    Namespace::Subroutines::find(
        'My::App::Controller',
        sub ( $mod, $subname, $subref, $attrs ) {
            # $mod     = [qw( My App Controller Home )]
            # $subname = 'foo'
            # $subref  = sub {...}
            # $attrs   = [qw( GET )]
        }
    );

    package My::App::Controller::Home;
    sub foo :GET {}

# DESCRIPTION

Namespace::Subroutines is a module that explores your @INC in order
to seek out every module placed within the given namespace. Then,
invokes your callback once for every subroutine found in each module.

## Considerations

There is one thing to be aware of.
This module uses a very simple strategy to decide which subroutines to pick:
From all the subroutines present in the module's symbol table,
Namespace::Subroutines will keep only those that are explicitly defined.
Basically, this module will check each line in the module's source code file
and if it starts with a subroutine definition, that subroutine is picked.
(regex: $line =~ /^sub\\s+(\\w+)\[\\:\\(\\s\]/)

## Use case: Autogenerate Mojolicious application routes

    my $r = $self->routes;
    Namespace::Subroutines::find(
        'My::App::Controller',
        sub ( $mod, $subname, $subref, $attrs ) {
            my $controller = join( '::', $mod->@* );
            my $path       = '/' . lc join( '/', $mod->@*, $subname );
            foreach my $verb ( $attrs->@* ) {
                $verb = lc $verb;
                $r->$verb($path)
                  ->to( controller => $controller, action => $subname );
            }
        }
    );

    package My::App::Controller::Home;

    sub welcome :GET ($self) { # <-- GET is defined in My::App domain
        $self->render( msg => 'Hello, world!' );
    }

# LICENSE

Copyright (C) José Manuel Rodríguez D..

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

José Manuel Rodríguez D. <nyrdz@cpan.org>
