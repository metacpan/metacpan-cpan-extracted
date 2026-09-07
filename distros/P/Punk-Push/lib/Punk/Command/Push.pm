package Punk::Command::Push;

use 5.010;
use strict;
use warnings;

our $VERSION = '0.02';

use Punk::Command ();
use VAPID ();

Punk::Command->register(push => {
    abstract => 'Web Push: VAPID keys and delivery',
    display  => 'push <verb>',
    commands => {
        keys => {
            abstract => 'a fresh VAPID keypair',
            usage    => '',
            desc     => "Print a VAPID keypair as two environment lines.\n\n"
                      . "A keypair is configuration and belongs outside the "
                      . "application: generate\nit once, put it in the "
                      . "environment, and keep it. Every subscription a\n"
                      . "browser makes is bound to the public key it was made "
                      . "with, so replacing\nthe pair makes every existing "
                      . "subscription undeliverable - and a browser\nwill not "
                      . "re-grant permission without being asked again.",
            code => sub {
                my ($opt, @a) = @_;
                die { usage_error => 'keys takes no arguments' } if @a;
                my ($pub, $priv) = VAPID::generate_vapid_keys();
                print "VAPID_PUBLIC=$pub\n";
                print "VAPID_PRIVATE=$priv\n";
                return 0;
            },
        },
    },
});

1;

__END__

=head1 NAME

Punk::Command::Push - the `punk push` subcommand

=head1 SYNOPSIS

    punk push keys

=head1 DESCRIPTION

Registers itself with L<Punk::Command> at load, which is how a plugin
distribution adds a subcommand with no scanning and no cost on the common
path.

=head2 keys

Prints a fresh VAPID keypair as two environment lines:

    VAPID_PUBLIC=BF...
    VAPID_PRIVATE=k3...

A keypair is configuration and belongs outside the application. Generate it
once, put it in the environment, and keep it: every subscription a browser
makes is bound to the public key it was made with, so replacing the pair makes
every existing subscription undeliverable, and a browser will not re-grant
permission without being asked again.

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
