package Mojolicious::Plugin::CSRFDefender;

use strict;
use warnings;
use Carp;

our $VERSION = '0.0.8';

use base qw(Mojolicious::Plugin Class::Accessor::Fast);
__PACKAGE__->mk_accessors(qw(
    parameter_name
    session_key
    token_length
    error_status
    error_content
    error_template
    onetime
));

use String::Random;
use Path::Class;

sub register {
    my ($self, $app, $conf) = @_;

    # Plugin config
    $conf ||= {};

    # setting
    $self->parameter_name($conf->{parameter_name} || 'csrftoken');
    $self->session_key($conf->{session_key} || 'csrftoken');
    $self->token_length($conf->{token_length} || 32);
    $self->error_status($conf->{error_status} || 403);
    $self->error_content($conf->{error_content} || 'Forbidden');
    $self->onetime($conf->{onetime} || 0);
    if ($conf->{error_template}) {
        my $file = $app->home->rel_file($conf->{error_template});
        $self->error_template($file);
    }

    # input check
    $app->hook(before_dispatch => sub {
        my ($c) = @_;
        unless ($self->_validate_csrf($c)) {
            my $content;
            if ($self->error_template) {
                my $file = file($self->error_template);
                $content = $file->slurp;
            }
            else {
                $content = $self->{error_content},
            }
            $c->render(
                status => $self->{error_status},
                text   => $content,
            );
        };
    });

    # output filter
    $app->hook(after_dispatch => sub {
        my ($c) = @_;
        my $token = $self->_get_csrf_token($c);
        my $p_name = $self->parameter_name;
        my $body = $c->res->body;
        $body =~ s{(<form\s*[^>]*method=["']POST["'][^>]*>)}{$1\n<input type="hidden" name="$p_name" value="$token" />}isg;
        $c->res->body($body);
    });

    return $self;
}

sub _validate_csrf {
    my ($self, $c) = @_;

    my $p_name = $self->parameter_name;
    my $s_name = $self->session_key;
    my $request_token = $c->req->param($p_name);
    my $session_token = $c->session($s_name);

    if ($c->req->method eq 'POST') {
        return 0 unless $request_token;
        return 0 unless $session_token;
        return 0 unless $request_token eq $session_token;
    }

    # onetime
    if ($c->req->method eq 'POST' && $self->onetime) {
        $c->session($self->{session_key} => '');
    }

    return 1;
}

sub _get_csrf_token {
    my ($self, $c) = @_;

    my $key    = $self->session_key;
    my $token  = $c->session($key);
    my $length = $self->token_length;
    return $token if $token;

    $token = String::Random::random_regex("[a-zA-Z0-9_]{$length}");
    $c->session($key => $token);
    return $token;
}

1;

__END__

=head1 NAME

Mojolicious::Plugin::CSRFDefender - Defend CSRF automatically in Mojolicious Application


=head1 VERSION

This document describes Mojolicious::Plugin::CSRFDefender.


=head1 SYNOPSIS

    # Mojolicious
    $self->plugin('Mojolicious::Plugin::CSRFDefender');

    # Mojolicious::Lite
    plugin 'Mojolicious::Plugin::CSRFDefender';

=head1 DESCRIPTION

This plugin defends CSRF automatically in Mojolicious Application.
Following is the strategy.

=head2 output filter

When the application response body contains form tags with method="post",
this inserts hidden input tag that contains token string into forms in the response body.
For example, the application response body is

    <html>
      <body>
        <form method="post" action="/get">
          <input name="text" />
          <input type="submit" value="send" />
        </form>
      </body>
    </html>

this becomes

    <html>
      <body>
        <form method="post" action="/get">
        <input type="hidden" name="csrf_token" value="zxjkzX9RnCYwlloVtOVGCfbwjrwWZgWr" />
          <input name="text" />
          <input type="submit" value="send" />
        </form>
      </body>
    </html>

=head2 input check

For every POST requests, this module checks input parameters contain the collect token parameter. If not found, throws 403 Forbidden.

=head1 OPTIONS

    plugin 'Mojolicious::Plugin::CSRFDefender' => {
        parameter_name => 'param-csrftoken',
        session_key    => 'session-csrftoken',
        token_length   => 40,
        error_status   => 400,
        error_template => 'public/400.html',
    };

=over 4

=item parameter_name(default:"csrftoken")

Name of the input tag for the token.

=item session_key(default:"csrftoken")

Name of the session key for the token.

=item token_length(default:32)

Length of the token string.

=item error_status(default:403)

Status code when CSRF is detected.

=item error_content(default:"Forbidden")

Content body when CSRF is detected.

=item error_template

Return content of the specified file as content body when CSRF is detected.  Specify the file path from the application home directory.

=item onetime(default:0)

If specified with 1,  this plugin uses onetime token, that is, whenever client sent collect token and this middleware detect that, token string is regenerated.

=back

=head1 METHODS

L<Mojolicious::Plugin::CSRFDefender> inherits all methods from
L<Mojolicious::Plugin> and implements the following new ones.

=head2 C<register>

    $plugin->register;

Register plugin in L<Mojolicious> application.

=head1 SEE ALSO

=over 4

=item * L<Mojolicious>

=back

=head1 REPOSITORY

https://github.com/shibayu36/p5-Mojolicious-Plugin-CSRFDefender

=head1 AUTHOR

  C<< <shibayu36 {at} gmail.com> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2011, Yuki Shibazaki C<< <shibayu36 {at} gmail.com> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.
