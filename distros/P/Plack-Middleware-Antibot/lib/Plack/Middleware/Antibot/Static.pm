package Plack::Middleware::Antibot::Static;

use strict;
use warnings;

use parent 'Plack::Middleware::Antibot::FilterBase';

use Plack::Session;

sub new {
    my $self = shift->SUPER::new(@_);
    my (%params) = @_;

    $self->{path}         = $params{path}         || '/antibot.gif';
    $self->{session_name} = $params{session_name} || 'antibot_static';
    $self->{timeout}      = $params{timeout}      || 60 * 15;
    $self->{score}        = $params{score}        || 0.9;

    return $self;
}

sub execute {
    my $self = shift;
    my ($env) = @_;

    if ($env->{REQUEST_METHOD} eq 'GET') {
        my $path_info = $env->{PATH_INFO};

        if ($path_info eq $self->{path}) {
            my $session = Plack::Session->new($env);
            $session->set($self->{session_name} => time);

            return [200, [], ['']];
        }

        $env->{'plack.antibot.static.path'} = $self->{path};
        $env->{'plack.antibot.static.html'} = qq{<img src="$self->{path}" }
          . qq{width="1" height="1" style="display:none" />};
    }
    elsif ($env->{REQUEST_METHOD} eq 'POST') {
        my $session = Plack::Session->new($env);

        my $static_fetched = $session->get($self->{session_name});
        unless ($static_fetched && time - $static_fetched < $self->{timeout}) {
            $env->{'plack.antibot.static.detected'}++;
        }
    }

    return;
}

1;
__END__
=pod

=encoding utf-8

=head1 NAME

Plack::Middleware::Antibot::Static - Check if static file was fetched

=head1 SYNOPSIS

    enable 'Antibot', filters =>
      [['Static', path => '/antibot.css']];

=head1 DESCRIPTION

Plack::Middleware::Antibot::Static checks if a static-like file was fetched.

=head2 C<$env>

=over

=item C<plack.antibot.static.path>

Path to the static file.

=item C<plack.antibot.static.html>

Something like:

    <img src="/antibot.gif" width="1" height="1" style="display:none" />

=back

=head2 Options

=head3 B<score>

Filter's score when bot detected. C<0.9> by default.

=head3 B<session_name>

Session name. C<antibot_static> by default.

=head3 B<timeout>

Expiration timeout in seconds. C<15 * 60> by default (15 minutes).

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
