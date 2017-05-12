package Nephia::Plugin::PlackSession;
use 5.008005;
use strict;
use warnings;
use parent 'Nephia::Plugin';
use Plack::Session;

our $VERSION = "0.81";

sub exports {
    qw/ session /;
}

sub session {
    my ($self, $context) = @_;

    return sub {
        my $session = $context->get('sessions');
        if (defined $session) {
            return $session;
        } else {
            my $req = $context->get('req');
            $session = Plack::Session->new($req->env);
            $context->set(sessions => $session);
            return $session;
        }
    };
}

1;

__END__

=encoding utf-8

=head1 NAME

Nephia::Plugin::PlackSession - Session plugin for Nephia

=head1 SYNOPSIS

    # app.psgi
    builder {
        enable 'Plack::Middleware::Session';
        MyApp->run();
    }
    
    # MyApp.pm
    package MyApp;
    use strict;
    use warnings;
    use Nephia plugins => [qw/
        'PlackSession'
    /];

    app {
        session->get($key);
        session->set($key, $value);
        session->remove($key);
        session->keys;
        session->expire;
    };

=head1 DESCRIPTION

Nephia::Plugin::PlackSession is plugin that provides session management using Plack::Session

=head1 SEE ALSO

L<Nephia>

L<Plack::Session>

L<Amon2::Plugin::Web::PlackSession>

=head1 LICENSE

Copyright (C) papix.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

papix E<lt>mail@papix.netE<gt>

=cut
