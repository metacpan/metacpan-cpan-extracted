package Plack::Middleware::I18N;

use strict;
use warnings;

use parent 'Plack::Middleware';

use Carp qw(croak);
use List::Util qw(first);
use I18N::AcceptLanguage;

use Plack::Util::Accessor qw(i18n use_path use_session use_header custom_cb);

sub prepare_app {
    my $self = shift;

    croak 'i18n required' unless $self->{i18n};

    $self->{use_path}    = 1 unless defined $self->{use_path};
    $self->{use_session} = 1 unless defined $self->{use_session};
    $self->{use_header}  = 1 unless defined $self->{use_header};

    return $self;
}

sub call {
    my $self = shift;
    my ($env) = @_;

    $self->_detect_language($env);

    return $self->app->($env);
}

sub _detect_language {
    my $self = shift;
    my ($env) = @_;

    my $lang;
    $lang = $self->_detect_from_path($env) if $self->use_path;
    $lang ||= $self->_detect_from_session($env) if $self->use_session;
    $lang ||= $self->_detect_from_header($env)  if $self->use_header;
    $lang = $self->_detect_from_custom_cb($env, $lang) if $self->custom_cb;

    $lang ||= $self->i18n->default_language;

    $env->{'plack.i18n'}          = $self->i18n;
    $env->{'plack.i18n.language'} = $lang;
    $env->{'plack.i18n.handle'}   = $self->i18n->handle($lang);

    if ($self->{use_session}) {
        $env->{'psgix.session'}->{'plack.i18n.language'} = $lang;
    }
}

sub _detect_from_session {
    my $self = shift;
    my ($env) = @_;

    return unless my $session = $env->{'psgix.session'};

    return unless my $lang = $session->{'plack.i18n.language'};

    return unless $self->_is_allowed($lang);

    return $lang;
}

sub _detect_from_path {
    my $self = shift;
    my ($env) = @_;

    my $path = $env->{PATH_INFO};

    my $languages_re = join '|', $self->i18n->languages;
    if ($path =~ s{^/($languages_re)(?=/|$)}{}) {
        $env->{PATH_INFO} = $path;
        return $1 if $self->_is_allowed($1);
    }

    return;
}

sub _detect_from_header {
    my $self = shift;
    my ($env) = @_;

    return unless my $accept_header = $env->{HTTP_ACCEPT_LANGUAGE};

    return
      unless my $lang =
      $self->_build_acceptor->accepts($accept_header, [$self->i18n->languages]);

    return unless $self->_is_allowed($lang);

    return $lang;
}

sub _detect_from_custom_cb {
    my $self = shift;
    my ($env, $detected_lang) = @_;

    my $lang = $self->custom_cb->($env, $detected_lang);

    return unless $lang;

    return unless $self->_is_allowed($lang);

    return $lang;
}

sub _build_acceptor {
    my $self = shift;

    return I18N::AcceptLanguage->new();
}

sub _is_allowed {
    my $self = shift;
    my ($lang) = @_;

    return !!first { $lang eq $_ } $self->i18n->default_language,
      $self->i18n->languages;
}

1;
__END__
=pod

=encoding utf-8

=head1 NAME

Plack::Middleware::I18N - language detection

=head1 SYNOPSIS

    use Plack::Builder;

    builder {
        enable 'I18N', i18n => $i18n;

        ...
    };

=head1 DESCRIPTION

Plack::Middleware::I18N detects client's languages and set C<$env> variables.

=head2 Language detection

All detected languages are validated against available languages.

=head3 From path

When C<PATH_INFO> contains something like C</en/path/to>, then C<en> is detected
as a language and C<PATH_INFO> is B<changed> to C</path/to>.

=head3 From session

When C<psgix.session> contains C<plack.i18n.language> then it is used as
a language. Session option is set after every detection.

=head3 From C<HTTP_ACCEPT_LANGUAGE>

Detects language from C<HTTP_ACCEPT_LANGUAGE> header using L<I18N::AcceptLanguage>.

=head3 From custom callback

Sometimes a more sophisticated language detection is needed. Thus a custom
callback can be provided. For example:

    enable 'I18N', custom_cb => sub {
        my ($env, $lang) = @_;

        return 'de';
    };

=head2 C<$env> parameters

Plack::Middleware::I18N registers the following C<$env> parameters:

=over

=item C<plack.i18n>

Holds Plack::I18N instance.

=item C<plack.i18n.language>

Current detected language. A shortcut for C<$env->{'plack.i18n'}->language>.

=item C<plack.i18n.handle>

A shortcut for C<$env->{'plack.i18n'}->handle($env->{'plack.i18n.language'})>.

=back

=head1 ISA

L<Plack::Middleware>

=head1 METHODS

=head2 C<prepare_app>

=head2 C<call($env)>

=head1 INHERITED METHODS

=head2 C<wrap($app, @args)>

=head1 OPTIONS

=over

=item i18n

L<Plack::I18N> instance.

=item use_path

Whether detect language from URL.

=item use_session

Whether detect language from session.

=item use_header

Whether detect language from C<HTTP_ACCEPT_LANGUAGE>.

=item custom_cb

Whether detect language from a custom callback.

=back

=head1 AUTHOR

Viacheslav Tykhanovskyi, E<lt>viacheslav.t@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2015, Viacheslav Tykhanovskyi

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

This program is distributed in the hope that it will be useful, but without any
warranty; without even the implied warranty of merchantability or fitness for
a particular purpose.

=cut
