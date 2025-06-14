package Mojolicious::Plugin::CSRF;
# ABSTRACT: Cross Site Request Forgery (CSRF) "prevention" Mojolicious plugin

use 5.016;
use strict;
use warnings;
use Mojo::Base 'Mojolicious::Plugin';
use Mojo::DOM;
use Mojo::Util;

our $VERSION = '1.05'; # VERSION

sub register {
    my ( $self, $app, $conf ) = @_;

    my $csrf = Mojolicious::Plugin::CSRF::Base->new( ( ref $conf eq 'HASH' ) ? %$conf : () );
    $app->helper( csrf => sub { $csrf->c( $_[0] ) } );

    $conf->{hooks} //= [
        before_routes => sub {
            my ($c) = @_;
            $c->csrf->setup;
            $c->csrf->check;
        },
        after_render => sub {
            my ( $c, $output, $format ) = @_;

            if ( $format eq 'html' and $$output ) {
                my $dom   = Mojo::DOM->new( Mojo::Util::decode( 'UTF-8', $$output ) );
                my $forms = $dom->find('form[method="post"]');

                if ( $forms->size ) {
                    $forms->each( sub {
                        $_->append_content(
                            '<input type="hidden" ' .
                                'name="'  . $c->csrf->token_name . '" ' .
                                'value="' . $c->csrf->token . '">'
                        );
                    } );
                    $$output = Mojo::Util::encode( 'UTF-8', $dom->to_string );
                }
            }
        },
    ];

    $app->hook( shift @{ $conf->{hooks} }, shift @{ $conf->{hooks} } )
        while ( ref $conf->{hooks} eq 'ARRAY' and @{ $conf->{hooks} } and not @{ $conf->{hooks} } % 2 );

    return;
}

package Mojolicious::Plugin::CSRF::Base;

use Mojo::Base -base;
use Crypt::URandom;

has c              => undef;
has generate_token => sub { sub { unpack( 'H*', Crypt::URandom::urandom(16) ) } };
has token_name     => 'csrf_token';
has header         => 'X-CSRF-Token';
has methods        => sub { [ qw( POST PUT DELETE PATCH ) ] };
has include        => undef;
has exclude        => undef;

has on_success => sub { sub {
    my ($c) = @_;
    $c->log->info('CSRF check success');
    return 1;
} };

has on_failure => sub { sub {
    my ($c) = @_;
    $c->reply->exception( 'Access Forbidden: CSRF check failure', { status => 403 } );
    return 0;
} };

sub setup {
    my ($self) = @_;
    $self->c->res->headers->add( $self->header => $self->token );
    return $self;
}

sub check {
    my ($self) = @_;

    my $path = $self->c->req->url->path->to_string;
    return if ( $self->c->app->static->file($path) );

    my $method  = $self->c->req->method;
    my @methods = @{ ( $self->methods and ref $self->methods eq 'ARRAY' ) ? $self->methods : [] };
    @methods    = 'any' unless @methods;
    return unless ( grep { uc $_ eq $method or lc $_ eq 'any' } @methods );

    if ( $self->include and ref $self->include eq 'ARRAY' ) {
        my $include = 0;
        for ( @{ $self->include } ) {
            if ( $path =~ $_ ) {
                $include = 1;
                last;
            }
        }
        return unless $include;
    }

    if ( $self->exclude and ref $self->exclude eq 'ARRAY' ) {
        for ( @{ $self->exclude } ) {
            return if ( $path =~ $_ );
        }
    }

    my $session = $self->c->session( $self->token_name );
    my $param   = $self->c->param( $self->token_name );
    my $header  = $self->c->req->headers->header( $self->header );
    my $on      = 'on_' . ( (
        not $session or
        not (
            $param  and $param  eq $session or
            $header and $header eq $session
        )
    ) ? 'failure' : 'success' );

    return $self->$on->( $self->c );
}

sub token {
    my ($self) = @_;
    return
        $self->c->session( $self->token_name ) ||
        $self->c->session( $self->token_name => $self->generate_token->() )->session( $self->token_name );
}

sub url_for {
    my ( $self, @params ) = @_;
    return $self->c->url_for(@params)->query( { $self->token_name => $self->token } );
}

sub delete_token {
    my ($self) = @_;
    delete $self->c->session->{ $self->token_name };
    return $self;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mojolicious::Plugin::CSRF - Cross Site Request Forgery (CSRF) "prevention" Mojolicious plugin

=head1 VERSION

version 1.05

=for markdown [![test](https://github.com/gryphonshafer/Mojo-Plugin-CSRF/workflows/test/badge.svg)](https://github.com/gryphonshafer/Mojo-Plugin-CSRF/actions?query=workflow%3Atest)
[![codecov](https://codecov.io/gh/gryphonshafer/Mojo-Plugin-CSRF/graph/badge.svg)](https://codecov.io/gh/gryphonshafer/Mojo-Plugin-CSRF)

=for test_synopsis my($app);

=head1 SYNOPSIS

    # Simple Mojolicious
    $app->plugin('CSRF');

    my $token = $app->csrf->token;                 # returns the current token
    my $url   = $app->csrf->url_for('/some/path'); # returns a Mojo::URL object

    $app->csrf->delete_token;

    $app->csrf->setup;
    my $result = $app->csrf->check;

    # Customized Mojolicious
    use Crypt::URandom;
    use Mojo::DOM;
    use Mojo::Util;
    $app->plugin( CSRF => {
        generate_token => sub { unpack( 'H*', Crypt::URandom::urandom(16) ) },
        token_name     => 'csrf_token',
        header         => 'X-CSRF-Token',
        methods        => [ qw( POST PUT DELETE PATCH ) ],
        include        => [ '^/' ],
        exclude        => [ '^/api/[^/]+/user/log(?:in|out)/test$' ],

        on_success => sub {
            my ($c) = @_;
            $c->log->info('CSRF check success');
            return 1;
        },

        on_failure => sub {
            my ($c) = @_;
            $c->reply->exception(
                'Access Forbidden: CSRF check failure',
                { status => 403 },
            );
            return 0;
        },

        hooks => [
            before_routes => sub {
                my ($c) = @_;
                $c->csrf->setup;
                $c->csrf->check;
            },

            after_render => sub {
                my ( $c, $output, $format ) = @_;

                if ( $format eq 'html' and $$output ) {
                    my $dom = Mojo::DOM->new(
                        Mojo::Util::decode( 'UTF-8', $$output )
                    );
                    my $forms = $dom->find('form[method="post"]');

                    if ( $forms->size ) {
                        $forms->each( sub {
                            $_->append_content(
                                '<input type="hidden" ' .
                                    'name="'  . $c->csrf->token_name . '" ' .
                                    'value="' . $c->csrf->token . '">'
                            );
                        } );
                        $$output = Mojo::Util::encode( 'UTF-8', $dom->to_string );
                    }
                }
            },
        ],
    } );

    # Mojolicious::Lite
    plugin('CSRF');

=head1 DESCRIPTION

This module is a L<Mojolicious> plugin for Cross Site Request Forgery (CSRF)
"prevention" (theoretically; if used correctly; caveat emptor).

By default, when used, the plugin will cause requests methods that traditionally
contain data-changing actions (i.e. POST, PUT, etc.) to check a generated session
token against a token from a form value, URL parameter, or HTTP header. On
failure, a L<Mojo::Exception> is thrown.

=head1 METHODS

The plugin provides a C<csrf> helper from which some methods can be called.

=head2 token

This method will return the current token. If there is no current token, this
method will first call the C<generate_token> method, store the new token in the
L<Mojolicious> session, and then return the new token.

    my $token = $app->csrf->token;

=head2 url_for

This is a wrapper around C<url_for> from L<Mojolicious::Plugin::DefaultHelpers>,
returning a L<Mojo::URL> object with the current token merged as a parameter.

    # returns a Mojo::URL object
    my $url  = $app->csrf->url_for('/some/path');
    my $url2 = $app->csrf->url_for('/some/other/path')->query({ answer => 42 });

=head2 delete_token

This method deletes the current token from the L<Mojolicious> session.

    $app->csrf->delete_token;

=head2 setup

This method should be called prior to rendering a page that precedes a request
where C<check> is called. (All this does is set the HTTP header.)

    $app->csrf->setup;

=head2 check

This method checks the current token (saved in the L<Mojolicious> session)
against a token value from a form value, URL parameter, or HTTP header.

    my $result = $app->csrf->check;

The method will call C<on_success> or C<on_failure> after a check.

=head1 SETTINGS

Almost everything can be customized from the C<plugin> call by providing a
hashref of stuff.

=head2 generate_token

This is a code reference that when called is expected to generate a new token
and return it (though not save it). This subroutine is called by C<token> when
it needs to generate a token.

=head2 token_name

This is the form/URL parameter name containing the comparison token. By default,
it's "csrf_token".

=head2 header

This is the HTTP header name containing the comparison token. By default,
it's "X-CSRF-Token".

=head2 methods

These are the methods where a comparison check will be performed. You can specify
the set of methods in an arrayref of strings. By default, it's:

    [ qw( POST PUT DELETE PATCH ) ]

If you set "any", then all methods are checked:

    ['any']

=head2 include

This is an arrayref of strings of regular expressions representing URL paths to
include checks on. If not defined, then all paths are checked.

=head2 exclude

This is an arrayref of strings of regular expressions representing URL paths to
exclude checks on.

=head2 on_success

This is the code reference called when a check is successful. It'll be passed
the application object.

    on_success => sub {
        my ($c) = @_;
        $c->log->info('CSRF check success');
        return 1;
    },

=head2 on_failure

This is the code reference called when a check fails. It'll be passed the
application object.

    on_failure => sub {
        my ($c) = @_;
        $c->reply->exception(
            'Access Forbidden: CSRF check failure',
            { status => 403 },
        );
        return 0;
    },

=head2 hooks

This is an arrayref of hook names and code references the plugin will install
during it's registration. You could easily (and probably more cleanly) just do
this yourself as you prefer; but by default, this plugin will set
a C<before_routes> hook and a C<after_render> hook as follows:

    hooks => [
        before_routes => sub {
            my ($c) = @_;
            $c->csrf->setup;
            $c->csrf->check;
        },

        after_render => sub {
            my ( $c, $output, $format ) = @_;

            if ( $format eq 'html' and $$output ) {
                my $dom = Mojo::DOM->new(
                    Mojo::Util::decode( 'UTF-8', $$output )
                );
                my $forms = $dom->find('form[method="post"]');

                if ( $forms->size ) {
                    $forms->each( sub {
                        $_->append_content(
                            '<input type="hidden" ' .
                                'name="'  . $c->csrf->token_name . '" ' .
                                'value="' . $c->csrf->token . '">'
                        );
                    } );
                    $$output = Mojo::Util::encode( 'UTF-8', $dom->to_string );
                }
            }
        },
    ],

=head1 SEE ALSO

L<Mojolicious>, L<Mojolicious::Plugin>, L<Mojolicious::Plugin::CSRFProtect>,
L<Mojolicious::Plugin::DeCSRF>, L<Mojolicious::Plugin::CSRFDefender>.

You can also look for additional information at:

=over 4

=item *

L<GitHub|https://github.com/gryphonshafer/Mojo-Plugin-CSRF>

=item *

L<MetaCPAN|https://metacpan.org/pod/Mojolicious::Plugin::CSRF>

=item *

L<GitHub Actions|https://github.com/gryphonshafer/Mojo-Plugin-CSRF/actions>

=item *

L<Codecov|https://codecov.io/gh/gryphonshafer/Mojo-Plugin-CSRF>

=item *

L<CPANTS|http://cpants.cpanauthors.org/dist/Mojo-Plugin-CSRF>

=item *

L<CPAN Testers|http://www.cpantesters.org/distro/M/Mojo-Plugin-CSRF.html>

=back

=head1 AUTHOR

Gryphon Shafer <gryphon@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2025-2050 by Gryphon Shafer.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
