package Punk::Push;

use 5.010;
use strict;
use warnings;

our $VERSION = '0.02';

1;

__END__

=head1 NAME

Punk::Push - Web Push notifications for Punk

=head1 SYNOPSIS

    package MyApp;
    use Punk;
    use Punk::Plugin::Push;

    host 'https://example.com';

    plugin 'Push' => {
        subject     => 'mailto:ops@example.com',
        public_key  => { '$env' => 'VAPID_PUBLIC'  },
        private_key => { '$env' => 'VAPID_PRIVATE' },
    };

    post '/reports' => sub {
        my ($c) = @_;
        $c->push_send($c->auth_id, {
            title => 'Your report is ready',
            body  => 'Three pages, as usual.',
            url   => '/reports/2026-09',
        });
        return $c->json({ ok => 1 });
    };

=head1 SEE ALSO

L<Punk::Plugin::Push> for the plugin, its options and its helpers.

L<VAPID> for the RFC 8291 encryption and the RFC 8292 identification
underneath.

L<Punk>.

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
