package Shipwright::Script::Delete;

use strict;
use warnings;

use base qw/App::CLI::Command Shipwright::Base Shipwright::Script/;
__PACKAGE__->mk_accessors(qw/unreferenced check_only/);

use Shipwright;
use Shipwright::Util;

sub options {
    (
        'unreferenced' => 'unreferenced',
        'C|check-only' => 'check_only',
    );
}

sub run {
    my $self = shift;
    my @sources = @_;

    unless ( @sources || $self->unreferenced ) {
        confess_or_die "need name arg or --unreferenced\n";
    }

    if ( @sources && $self->unreferenced ) {
        confess_or_die "please choose only one thing: a dist name or --unreferenced";
    }

    my $shipwright = Shipwright->new( repository => $self->repository, );
    my @names;

    if (@sources) {
        for my $name (@sources) {
            my $map = $shipwright->backend->map;
            if ( $map && $map->{$name} ) {

                # it's a cpan module
                $name = $map->{$name};
            }
            push @names, $name;
        }
    }
    else {

        # unreferenced dists except the last one
        my $refs  = $shipwright->backend->refs;
        my $order = $shipwright->backend->order;
        if ($refs) {
            for my $name ( keys %$refs ) {
                next if $name eq $order->[-1];
                push @names, $name unless $refs->{$name};
            }
        }
    }

    if ( $self->check_only ) {
        $self->log->fatal( "dists to be deleted are: @names" );
    }
    else {
        for my $name (@names) {
            $shipwright->backend->trim( name => $name );
        }
        $self->log->fatal( "successfully deleted @names" );
    }

}

1;

__END__

=head1 NAME

Shipwright::Script::Delete - Delete source(s)

=head1 SYNOPSIS

 shipwright delete cpan-Jifty cpan-Catalyst

=head1 OPTIONS

 --unreferenced                 : to delete all unreferenced dists except the last one
 --check-only                   : show the lists, not really delete

=head1 GLOBAL OPTIONS

 -r [--repository] REPOSITORY   : specify the repository uri of our shipyard
 -l [--log-level] LOGLEVEL      : specify the log level
                                  (info, debug, warn, error, or fatal)
 --log-file FILENAME            : specify the log file

=head1 AUTHORS

sunnavy  C<< <sunnavy@bestpractical.com> >>

=head1 LICENCE AND COPYRIGHT

Shipwright is Copyright 2007-2015 Best Practical Solutions, LLC.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

