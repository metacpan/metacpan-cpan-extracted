package Sys::Info::Driver::BSD;
use strict;
use warnings;
use vars qw( $VERSION @ISA @EXPORT );
use BSD::Sysctl qw( sysctl sysctl_exists );
use base qw( Exporter   Sys::Info::Base );
use Carp qw( croak );

$VERSION = '0.7801';
@EXPORT  = qw( fsysctl nsysctl dmesg );

sub fsysctl {
    my $key = shift || croak 'Key is missing';
    my $val = sysctl_exists($key) ? sysctl($key)
                                  : croak "Can not happen: $key is not defined";
    return $val;
}

sub nsysctl {
    my $key = shift || croak 'Key is missing';
    return if ! sysctl_exists($key);
    return sysctl($key);
}

sub dmesg {
    my $self = __PACKAGE__;
    my $buf  = qx(dmesg 2>&1); ## no critic (InputOutput::ProhibitBacktickOperators)
    return +() if ! $buf;

    my $skip =  1;
    my $i    = -1; ## no critic (ValuesAndExpressions::ProhibitMagicNumbers)
    my @buf;

    foreach my $line ( split m{\n}xms, $buf ) {
        chomp $line;
        $skip = 0 if $line =~ m{ \A CPU: \s }xms;
        next if $skip;
        if ( $line =~ m{ \A \s+ (.+?) \z }xms ) {
            my($key, $value) = split m{=}xms, $line, 2;
            next if ! $value;
            $buf[$i]->{_sub}{ $self->trim($key) } = $self->trim($value);
            next;
        }
        my($key, $value) = split m{:\s}xms, $line, 2;
        next if ! $value;
        next if $value eq 'filesystem full';
        $i++;
        push @buf, { $self->trim($key) => $self->trim($value) };
    }

    my %rv;
    my @pci;
    foreach my $e ( @buf ) {
        my $is_pci = grep { m{\A pci }xms } keys %{ $e };
        if ( $is_pci ) {
            push @pci, $e;
            next;
        }
        my $sub = delete $e->{_sub};
        my($key) = keys %{ $e };
        $rv{ $key } = {
            value => $e->{ $key },
            ( $sub ? %{ $sub } : () ),
        }
    }

    $rv{pci} = { map { %{ $_ } } @pci };

    if ( $rv{CPU} && ref $rv{CPU} eq 'HASH' ) {
        my %cpu = %{ $rv{CPU} };
        my @flags = $self->_extract_dmesg_flags( \%cpu, qw/ Features Features2 / );

        $cpu{value} =~ s[\s{2,}][ ]xmsg if $cpu{value};
        $cpu{flags} = [ sort @flags ] if @flags;

        if ( $cpu{Origin} && $cpu{Origin} =~ m{ \A "(.+?)" \s+ (.+?) \z }xms ) {
            $cpu{Origin} = {
                vendor => $1,
                ( map { split m{\s=\s}xms, $_ } split m/\s{2,}/xms, $2 )
            };
        }
        if ( exists $cpu{value} ) {
            $cpu{name} = delete $cpu{value};
        }

        if ( $cpu{'AMD Features'} ) {
            my @amd = $self->_extract_dmesg_flags(
                            \%cpu, 'AMD Features', 'AMD Features2'
                        );
            $cpu{AMD_flags} = [ @amd ];
        }

        $rv{CPU} = { %cpu };
    }

    return %rv;
}

sub _extract_dmesg_flags {
    my($self, $ref, @keys) = @_;
    my @raw = map { delete $ref->{ $_ } } @keys;
    my @flags;
    foreach my $flag ( @raw ) {
        next if ! $flag;
        if ( $flag =~ m{ \A (0x.+?)<(.+?)> \z }xms ) {
            push @flags, split m{,}xms, $2;
        }
    }
    return @flags;
}

1;

__END__

=head1 NAME

Sys::Info::Driver::BSD - BSD driver for Sys::Info

=head1 SYNOPSIS

    use Sys::Info::Driver::BSD;

=head1 DESCRIPTION

This document describes version C<0.7801> of C<Sys::Info::Driver::BSD>
released on C<12 September 2011>.

This is the main module in the C<BSD> driver collection.

=head1 METHODS

None.

=head1 FUNCTIONS

=head2 dmesg

Interface to the C<dmesg> system call.

=head2 fsysctl

f(atal)sysctl(). Implemented via L<BSD::Sysctl>.

=head2 nsysctl

n(ormal)sysctl. Implemented via L<BSD::Sysctl>.

=head1 AUTHOR

Burak Gursoy <burak@cpan.org>.

=head1 COPYRIGHT

Copyright 2009 - 2011 Burak Gursoy. All rights reserved.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify 
it under the same terms as Perl itself, either Perl version 5.8.8 or, 
at your option, any later version of Perl 5 you may have available.

=cut
