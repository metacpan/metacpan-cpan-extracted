package Punk::ClamAV;

use 5.010;
use strict;
use warnings;

our $VERSION = '0.01';

1;

__END__

=head1 NAME

Punk::ClamAV - virus scanning for Punk uploads

=head1 SYNOPSIS

    package MyApp;
    use Punk;

    plugin 'ClamAV' => { socket => '/run/clamav/clamd.ctl' };

    post '/avatar' => sub {
        my ($c) = @_;
        my $up = $c->upload('file') or return $c->text('no file', 400);
        return $c->text('no thanks', 422) unless $c->upload_ok($up);
        $up->save("/var/lib/app/avatars/" . $c->auth_id);   # not $up->filename
        $c->json({ ok => 1 });
    };

=head1 SEE ALSO

L<Punk::Plugin::ClamAV> for the plugin and its options.

L<ClamAV::Clamd> for the client underneath, including the non-blocking
interface and the C ABI.

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under the Artistic License 2.0.

=cut
