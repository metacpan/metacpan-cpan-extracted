package Plack::Middleware::Antibot::TextCaptcha;

use strict;
use warnings;

use parent 'Plack::Middleware::Antibot::FilterBase';

use Plack::Session;
use Plack::Request;

sub new {
    my $self = shift->SUPER::new(@_);
    my (%params) = @_;

    $self->{session_name} = $params{session_name} || 'antibot_textcaptcha';
    $self->{field_name}   = $params{field_name}   || 'antibot_textcaptcha';
    $self->{variants} = $params{variants} || [{text => '2 + 2', answer => 4}];
    $self->{score}    = $params{score}    || 0.9;

    return $self;
}

sub execute {
    my $self = shift;
    my ($env) = @_;

    my $variants = $self->{variants};

    my $captcha = $variants->[int(rand(@$variants))];
    $env->{'plack.antibot.textcaptcha.text'}       = $captcha->{text};
    $env->{'plack.antibot.textcaptcha.field_name'} = $self->{field_name};

    if ($env->{REQUEST_METHOD} eq 'GET') {
        my $session = Plack::Session->new($env);
        $session->set($self->{session_name}, $captcha->{answer});
    }
    elsif ($env->{REQUEST_METHOD} eq 'POST') {
        my $session = Plack::Session->new($env);

        my $expected = $session->get($self->{session_name});
        my $got      = Plack::Request->new($env)->param($self->{field_name});

        unless ($expected && $got && $got eq $expected) {
            $env->{'plack.antibot.textcaptcha.detected'}++;
        }

        $session->set($self->{session_name}, $captcha->{answer});
    }

    return;
}

1;
__END__
=pod

=encoding utf-8

=head1 NAME

Plack::Middleware::Antibot::TextCaptcha - Check if correct captcha was submitted

=head1 SYNOPSIS

    enable 'Antibot', filters =>
      [['TextCaptcha', variants => [{text => '2 + 2', answer => 4}]]];

=head1 DESCRIPTION

Plack::Middleware::Antibot::TextCaptcha checks if a correct captcha was
submitted. Most of the time a simple text with a simple solution is enough to
prevent bots from successful form submitions.

=head2 C<$env>

This filter sets C<plack.antibot.textcaptcha.text> as captcha text. This should be
shown to the user as a field label or description.

C<plack.antibot.textcaptcha.field_name> is set to the needed field name.

=head2 Options

=head3 B<score>

Filter's score when bot detected. C<0.8> by default.

=head3 B<session_name>

Session name. C<antibot_textcaptcha> by default.

=head3 B<field_name>

Field name. C<antibot_textcaptcha> by default.

=head3 B<variants>

Captcha variants. C<[{text => '2 + 2', answer => 4}]> by default.

=head1 ISA

L<Plack::Middleware::Antibot::FilterBase>

=head1 METHODS

=head2 C<new>

=head2 C<execute($env)>

=head1 INHERITED METHODS

=head2 C<score>

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
