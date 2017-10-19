package Mojolicious::Plugin::Check;
use Mojo::Base 'Mojolicious::Plugin';

our $VERSION        = '0.03';

sub register {
    my ($self, $app, $conf) = @_;

    $conf                   ||= {};
    $conf->{stash_checkers} //= 'plugin-check-checkers';
    $conf->{stash_actions}  //= 'plugin-check-actions';

    $app->helper(add_checker => sub {
        my ($c, $name, $sub) = @_;

        my $checkers = $c->app->routes->{$conf->{stash_checkers}} //= {};
        $checkers->{$name} = $sub;

        $c->app->routes->add_condition($name => sub {
            my ($route, $c, $captures, $pattern) = @_;

            my $actions = $c->stash->{$conf->{stash_actions}} //= [];
            push @$actions, [$name, $route, $c, {%$captures}, $pattern];

            return 1;
        });

        return $self;
    });

    $app->hook(around_action => sub {
        my ($next, $c, $action, $last) = @_;

        my $checkers    = $c->app->routes->{$conf->{stash_checkers}}    //= {};
        my $actions      = $c->stash->{$conf->{stash_actions}}          //= [];

        for my $args ( @$actions ) {
            my ($name, @opts) = @$args;

            my $checker = $checkers->{ $name };
            next unless $checker;

            my @result = $checker->( @opts );

            if( @result ) {
                if( defined $result[0] ) {
                    if( $result[0] ) {
                        next;
                    } else {
                        return $c->reply->not_found;
                    }
                } else {
                    return;
                }
            } else {
                return $c->reply->not_found;
            }
        }

        return $next->();
    });

    return;
}

1;

__END__

=encoding utf-8

=head1 NAME

Mojolicious::Plugin::Check - Mojolicious plugin for controller level conditions.

=head1 DESCRIPTION

This module provide delayed to I<around_action> hook execution for conditions
to use with database, models and over controller level checks.
You do not have to use I<add_condition> directly for this because: conditions
check route/headers not business logic, you can`t save something in stash, etc.

=head1 SYNOPSIS

    # Add plugin in startup
    $self->plugin('Check');

    # Good example:
    $r->add_condition(integer   => sub {...});
    $app->add_checker(user        => sub {...});
    $r->get('/user/:id')->over(
        integer => 'id',    # good, simple integer check
        user    => 'id',    # good, delay check
    )->to('foo#bar');

    # Bad example:
    $r->add_condition(integer   => sub {...});
    $r->add_condition(user      => sub {...});
    $r->get('/user/:id')->over(
        integer => 'id',    # good, simple integer check
        user    => 'id',    # bad, too early for DB, Model, Controller etc.
    )->to('foo#bar');

=head1 METHODS

=head2 add_checker

Same as add_condition, but delay execution to I<around_action> hook level.

    # Simple "true" checker example
    $app->add_checker('true' => sub {
        my ($route, $c, $captures, $pattern) = @_;
        return $captures->{$pattern} ? 1 : 0;
    });

    # You can use database and save objects in stash to use in controllers
    $app->add_checker('user_exists' => sub {
        my ($route, $c, $captures, $pattern) = @_;
        my $id = $captures->{$pattern};
        my $db = $c->pg->db;
        $c->stash->{user} = $db->query('...', $id);
        return $c->stash->{user} ? 1 : 0;
    });

    # The user is guaranteed to have or render not_found page.
    $r->get('/user/:id')->over(user_exists => 'id')->to(cb => sub{
        my ($c) = @_;
        my $user = $c->stash('user');
        ...
    });

Return values for sub:

=over

=item true

Check pass.

=item false or empty

Check fail. Render "Page not found" automatically.

=item undef

Check fail. You should render something manually.

    # Example "true" for forbidden status:
    $self->add_checker('true' => sub {
        my ($route, $c, $captures, $pattern) = @_;
        unless( $captures->{$pattern} ){
            $c->render(text => 'Forbidden', status => 403);
            return undef;
        }
        return 1;
    });

=back

=cut

=head1 AUTHORS

Dmitry E. Oboukhov <unera@debian.org>,
Roman V. Nikolaev <rshadow@rambler.ru>

=head1 COPYRIGHT

Copyright (C) 2017 Dmitry E. Oboukhov <unera@debian.org>
Copyright (C) 2017 Roman V. Nikolaev <rshadow@rambler.ru>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
