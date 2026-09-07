package Punk::Command::Challenge;

use 5.010;
use strict;
use warnings;
use Punk::Command ();
use Punk::Challenge::Token ();
use Punk::Challenge::Solver ();

our $VERSION = '0.01';

sub _cmd_key {
    print Punk::Challenge::Token->key, "\n";
    return 0;
}

sub _cmd_solve {
    my ($opt, $puzzle) = @_;
    die { usage_error => 'punk challenge solve <puzzle>' }
        unless defined $puzzle && length $puzzle;
    my ($bits) = $puzzle =~ /\Av1\.\d+\.(\d{1,2})\.[0-9a-z-]+\.[A-Za-z0-9_-]{22}\z/
        or die "not a puzzle: $puzzle\n";
    die "$bits bits is above the 22 this plugin ever issues; not attempting it\n"
        if $bits > 22;
    # Expected work before anything is spent: 2^bits hashes on average.
    my $hashes = 2 ** $bits;
    my $note = $bits >= 20 ? ' - this will take a while' : '';
    print STDERR "solving at $bits bits: about $hashes hashes on average$note\n";
    my $solution = Punk::Challenge::Solver::solve($puzzle);
    print "$solution\n";
    return 0;
}

Punk::Command->register(challenge => {
    abstract => 'proof-of-work challenges: a secret, or a solution',
    display  => 'challenge <command>',
    usage    => '<command> [options]',
    desc     => "The two things an operator does by hand with Punk::Plugin::Challenge:\n"
              . "mint the secret its configuration needs, and solve one puzzle to\n"
              . 'clear a deployment from curl.',
    commands => {
        key => {
            abstract => 'print a fresh secret for the configuration',
            desc     => "Thirty-two random bytes as base64url. Configure it as the\n"
                      . "plugin's `secret`; it is never generated for you at runtime,\n"
                      . 'because a pool of workers would each mint their own.',
            code     => \&_cmd_key,
        },
        solve => {
            abstract => 'solve one puzzle and print the solution',
            usage    => '<puzzle>',
            desc     => "The puzzle is what an X-Challenge header carries. The solution\n"
                      . "is presented back as X-Challenge-Response, or posted to the\n"
                      . 'verify route. The expected work is stated before it starts.',
            code     => \&_cmd_solve,
        },
    },
    examples => [
        'punk challenge key',
        'punk challenge solve v1.1725600000.16.k3x-2f.Zm9vYmFy...',
    ],
}, __PACKAGE__) if Punk::Command->can('register');

1;

__END__

=head1 NAME

Punk::Command::Challenge - the punk challenge subcommand

=head1 SYNOPSIS

    $ punk challenge key
    fQ2k...43 characters...

    $ curl -si https://example.com/api/x | grep X-Challenge
    X-Challenge: v1.1725600000.16.k3x-2f.Zm9vYmFy...
    $ punk challenge solve v1.1725600000.16.k3x-2f.Zm9vYmFy...
    solving at 16 bits: about 65536 hashes on average
    v1.1725600000.16.k3x-2f.Zm9vYmFy....48213
    $ curl -si -H 'X-Challenge-Response: v1....48213' https://example.com/api/x

=head1 DESCRIPTION

Registers C<punk challenge> when loaded, which C<punk> does on first use, so
it costs nothing on the common path.

=head2 key

Prints thirty-two random bytes as base64url, for the plugin's C<secret>.
Croaks rather than printing anything when no entropy source is available.

=head2 solve

Solves one puzzle and prints the solution. Says how many hashes it expects
before it starts, because twenty bits is a moment and twenty-two is a
while, and refuses anything above the twenty-two the plugin ever issues.

=head1 SEE ALSO

L<Punk::Plugin::Challenge>, L<Punk::Challenge::Token>, L<Punk::Command>.

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
