# ABSTRACT: a fast and reliable mailq-like utility for postfix

package Postfix::Mailq;

use strict;
use warnings;

sub DEFAULT_SPOOL_DIR () { '/var/spool/postfix' }


sub get_fast_count {
    my ($opt) = @_;

    $opt ||= {};

    my $get_hold = $opt->{get_hold} ? 1 : 0;
    my $spool_dir = defined $opt->{spool_dir} && $opt->{spool_dir} ne ''
        ? $opt->{spool_dir}
        : DEFAULT_SPOOL_DIR;

    my %count = (
        total    => 0,
        active   => 0,
        incoming => 0,
        deferred => 0,
    );

    my @dirs = ('active', 'incoming', map { "deferred/$_" } 0..9, 'A'..'F');
    push @dirs, 'hold' if $get_hold;

    for my $dir (@dirs) {

        opendir(my $dh, "$spool_dir/$dir") || next;

        my $n = 0;
        while (my $item = readdir($dh)) {
            ++$n unless $item =~ m{^\.};
        }

        $count{total} += $n;

        if ($dir =~ m{^deferred}) {
            $count{deferred} += $n;
        } else {
            $count{$dir} += $n;
        }

    }

    return \%count;
}


1;


__END__
=pod

=head1 NAME

Postfix::Mailq - a fast and reliable mailq-like utility for postfix

=head1 VERSION

version 0.01

=head1 SYNOPSIS

    my $mq = Postfix::Mailq::get_fast_count();

    # $mq = {
    #     active => 0,
    #     total  => 0,
    #     incoming => 0,
    #     deferred => 0,
    #     # and optionally, hold
    # }

    if (! $mq) {
        die "Something's very wrong?";
    }

    for (sort keys %{$mq}) {
        printf "%s: %-6d\n", $_, $mq->{$_};
    }

=head1 DESCRIPTION

This module implements a B<fast> partial replacement
for the C<mailq> utility that comes with Postfix, where
emphasis in on B<fast> and B<reliable>, not on B<complete>.

It is a C<Postfix-specific> module.

=head1 MOTIVATION

Why would you want to use a replacement for C<mailq>?

Because the standard C<mailq> can get very slow and
unreliable if your system is under heavy I/O load.

If you use Nagios to monitor your mail queue, the nagios
checks will fail if the system in under load, even if
your mail queue is not stressed at all.

That sucks and must be fixed.

=head1 FUNCTIONS

=head2 C<get_fast_count()>

Gets you a B<fast> count of the messages in the spool dirs.
Checks in C<active>, C<incoming>, C<deferred/*> by default.

If you want it to check in the C<hold> directory too, then
you should supply an additional C<get_hold> option, as in:

    my $mq = Postfix::Mailq::get_fast_count({ get_hold => 1 });

If your C<postfix> spool directory is not in the default
(specified by the C<DEFAULT_SPOOL_DIR> constant, usually
C</var/spool/postfix>, then you can specify your own with:

    my $mq = Postfix::Mailq::get_fast_count({
        spool_dir => '/var/local/postfix/spool'
    });

The result is a hash reference with all counts by folder,
as in:

    my $mq = Postfix::Mailq::get_fast_count();

    # $mq = {
    #     active => 0,
    #     total  => 0,
    #     incoming => 0,
    #     deferred => 0,
    #     # and optionally, hold
    # }

    if (! $mq) {
        die "Something's very wrong?";
    }

    for (sort keys %{$mq}) {
        printf "%s: %-6d\n", $_, $mq->{$_};
    }

=head1 THANKS

Thanks to Bron Gondwana and the Opera Mail team for this code.
I just cleaned it up and packaged it for CPAN.

=head1 AUTHOR

Cosimo Streppone <cosimo@opera.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2011 by Opera Software ASA.

This is free software, licensed under:

  The (three-clause) BSD License

=cut

