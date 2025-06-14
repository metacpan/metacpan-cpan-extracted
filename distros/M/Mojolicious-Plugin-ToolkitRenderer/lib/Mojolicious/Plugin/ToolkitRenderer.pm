package Mojolicious::Plugin::ToolkitRenderer;
# ABSTRACT: Template Toolkit Renderer Mojolicious Plugin

use 5.016;
use strict;
use warnings;

use Mojo::Base 'Mojolicious::Plugin';
use Mojo::Exception;

BEGIN {
    local $SIG{__WARN__} = sub {};
    require Template;
    Template->import;
}

our $VERSION = '1.14'; # VERSION

sub register {
    my ( $self, $app, $settings ) = @_;

    $settings->{config}{RELATIVE}     //= 1;
    $settings->{config}{EVAL_PERL}    //= 0;
    $settings->{config}{INCLUDE_PATH} //= $app->renderer->paths;

    my $template = Template->new( $settings->{config} );

    $settings->{context}->( $template->context ) if ( $settings->{context} );

    $app->renderer->add_handler( tt => sub {
        my ( $renderer, $controller, $output, $options ) = @_;
        my $inline = $settings->{settings}{inline_template} || 'inline';

        $template->process(
            ( ( $options->{$inline} ) ? \$options->{$inline} : $renderer->template_name($options) ),
            {
                content => $controller->content,
                %{ $controller->stash },
                ( $settings->{settings}{controller} || 'c' ) => $controller,
            },
            $output,
        ) || do {
            if ( ref( $settings->{settings}{error_handler} ) eq 'CODE' ) {
                $settings->{settings}{error_handler}->( $controller, $renderer, $app, $template );
            }
            else {
                unless (
                    $template->error and (
                        $template->error eq 'file error - exception.html.tt: not found' or
                        $template->error eq 'file error - exception.' . $app->mode . '.html.tt: not found'
                    )
                ) {
                    $$output = $template->error;
                    $controller->res->headers->content_type('text/plain');

                    $controller->log->error( $template->error );
                    $controller->rendered(
                        ( $template->error and $template->error =~ /not found/ ) ? 404 : 500
                    );
                }
            }
        };

        return $$output;
    } );

    $app->helper(
        render_tt => sub {
            shift->render( handler => 'tt', @_ );
        }
    );

    return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mojolicious::Plugin::ToolkitRenderer - Template Toolkit Renderer Mojolicious Plugin

=head1 VERSION

version 1.14

=for markdown [![test](https://github.com/gryphonshafer/Mojo-Plugin-Toolkit/workflows/test/badge.svg)](https://github.com/gryphonshafer/Mojo-Plugin-Toolkit/actions?query=workflow%3Atest)
[![codecov](https://codecov.io/gh/gryphonshafer/Mojo-Plugin-Toolkit/graph/badge.svg)](https://codecov.io/gh/gryphonshafer/Mojo-Plugin-Toolkit)

=for test_synopsis my($self);

=head1 SYNOPSIS

    # Simple Mojolicious
    $self->plugin('ToolkitRenderer');
    $self->renderer->default_handler('tt');

    # Customized Mojolicious
    $self->plugin(
        'ToolkitRenderer',
        {
            settings => {
                inline_template => 'inline',
                controller      => 'c',
            },
            config => {
                RELATIVE     => 1,
                EVAL_PERL    => 0,
                FILTERS      => { ucfirst => sub { return ucfirst shift } },
                ENCODING     => 'utf8',
                INCLUDE_PATH => $self->renderer->paths,
            },
            context => sub {
                shift->define_vmethod( 'scalar', 'upper', sub { return uc shift } );
            },
        },
    );
    $self->renderer->default_handler('tt');

    # Mojolicious::Lite
    plugin( ToolkitRenderer => {
        settings => {
            inline_template => 'inline',
            controller      => 'c',
        },
        config => {
            RELATIVE  => 1,
            EVAL_PERL => 0,
            FILTERS   => { ucfirst => sub { return ucfirst shift } },
            ENCODING  => 'utf8',
        },
        context => sub {
            shift->define_vmethod( 'scalar', 'upper', sub { return uc shift } );
        },
    } );

=head1 DESCRIPTION

This module is a Mojolicious plugin for easy use of L<Template> Toolkit. It
adds a "tt" handler and provides a "render_tt" helper method. It allows for
inline TT and all the usual L<Template> complexities.

=head1 SETUP

When setting up the plugin, you need to provide a hashref of settings that
are in 3 sections.

    {
        config   => {},
        settings => {},
        context  => {},
    }

=head2 config

These are the configuration settings that get passed directly to L<Template>
within it's C<new()> method. (See L<Template> documentation for details.)

=head2 settings

These are settings specific to this plugin, all of which are optional.

    {
        inline_template => 'inline',
        controller      => 'c',
        error_handler   => sub {},
    }

The "inline_template" setting lets you define what keyword you can use to
define an inline template. It defaults to "inline".

    $self->render_tt(
        inline => 'The answer to life, the [% universe | upper %], and [% everything.upper %] is [% answer %].',
        answer => 42, everything => 'everything', universe => 'universe',
    );

The "controller" settings lets your defined what keyword you can use within your
TT templates that will be a reference to the Mojolicious controller.

The "error_handler" setting lets you provide an optional subroutine reference
that will get called if there is any TT errors.

    error_handler => sub {
        my ( $controller, $renderer, $app, $template ) = @_;

        unless (
            $template->error and (
                $template->error eq 'file error - exception.html.tt: not found' or
                $template->error eq 'file error - exception.' . $app->mode . '.html.tt: not found'
            )
        ) {
            $$output = $template->error;
            $controller->res->headers->content_type('text/plain');

            $controller->log->error( $template->error );
            $controller->rendered(
                ( $template->error and $template->error =~ /not found/ ) ? 404 : 500
            );
        }
    }

=head2 context

This optional setting gives you access to setting vmethods and other things that
require TT's context.

    context => sub {
        my ($context) = @_;
        $context->define_vmethod( 'scalar', 'upper', sub { return uc shift } );
    },

=head1 SEE ALSO

L<Mojolicious>, L<Mojolicious::Plugin>, L<Template>.

You can also look for additional information at:

=over 4

=item *

L<GitHub|https://github.com/gryphonshafer/Mojo-Plugin-Toolkit>

=item *

L<MetaCPAN|https://metacpan.org/pod/Mojolicious::Plugin::ToolkitRenderer>

=item *

L<GitHub Actions|https://github.com/gryphonshafer/Mojo-Plugin-Toolkit/actions>

=item *

L<Codecov|https://codecov.io/gh/gryphonshafer/Mojo-Plugin-Toolkit>

=item *

L<CPANTS|http://cpants.cpanauthors.org/dist/Mojo-Plugin-Toolkit>

=item *

L<CPAN Testers|http://www.cpantesters.org/distro/M/Mojo-Plugin-Toolkit.html>

=back

=head1 AUTHOR

Gryphon Shafer <gryphon@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013-2050 by Gryphon Shafer.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
