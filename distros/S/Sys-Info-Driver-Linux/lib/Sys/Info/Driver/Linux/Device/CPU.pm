package Sys::Info::Driver::Linux::Device::CPU;
$Sys::Info::Driver::Linux::Device::CPU::VERSION = '0.7905';
use strict;
use warnings;
use base qw(Sys::Info::Base);

use Sys::Info::Driver::Linux;
use Unix::Processors;
use POSIX ();
use Carp qw( croak );

sub identify {
    my $self = shift;

    if ( ! $self->{META_DATA} ) {
        my $mach = $self->uname->{machine};
        my $arch = $mach =~ m{ i [0-9] 86 }xmsi ? 'x86'
                 : $mach =~ m{ ia64       }xmsi ? 'IA64'
                 : $mach =~ m{ x86_64     }xmsi ? 'AMD-64'
                 :                                 $mach
                 ;

        my @raw = split m{\n\n}xms,
                        $self->trim( $self->slurp( proc->{cpuinfo} ) );
        $self->{META_DATA} = [];
        foreach my $e ( @raw ) {
            push @{ $self->{META_DATA} },
                  { $self->_parse_cpuinfo($e), architecture => $arch };
        }
    }

    return $self->_serve_from_cache(wantarray);
}

sub bitness {
    my $self = shift;
    my @cpu  = $self->identify;
    my $flags = $cpu[0]->{flags};
    if ( $flags ) {
        my $lm = grep { $_ eq 'lm' } @{$flags};
        return '64' if $lm;
    }
    return $cpu[0]->{architecture} =~ m{64}xms ? '64' : '32';
}

sub load {
    my $self  = shift;
    my $level = shift;
    my @loads = split /\s+/xms, $self->slurp( proc->{loadavg} );
    return $loads[$level];
}

sub _parse_cpuinfo {
    my $self = shift;
    my $raw  = shift || croak 'Parser called without data';
    my($k, $v);
    my %cpu;
    foreach my $line (split /\n/xms, $raw) {
        ($k, $v) = split /\s+:\s+/xms, $line;
        $cpu{$k} = $v;
    }

    my @flags = $cpu{flags} ? (split /\s+/xms, $cpu{flags}) : ();
    my %flags = map { $_ => 1 } @flags;
    my $up    = Unix::Processors->new;
    my $name  = $cpu{'model name'};
    $name     =~ s[ \s{2,} ][ ]xms if $name;

    return(
        processor_id                 => $cpu{processor},
        data_width                   => $flags{lm} ? '64' : '32', # guess
        address_width                => $flags{lm} ? '64' : '32', # guess
        bus_speed                    => undef,
        speed                        => $cpu{'cpu MHz'},
        name                         => $name || q{},
        family                       => $cpu{'cpu family'},
        manufacturer                 => $cpu{vendor_id},
        model                        => $cpu{model},
        stepping                     => $cpu{stepping},
        number_of_cores              => $cpu{'cpu cores'} || $up->max_physical,
        number_of_logical_processors => $up->max_online,
        L2_cache                     => {max_cache_size => $cpu{'cache size'}},
        flags                        => @flags ? [ @flags ] : undef,
    );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Sys::Info::Driver::Linux::Device::CPU

=head1 VERSION

version 0.7905

=head1 SYNOPSIS

-

=head1 DESCRIPTION

Identifies the CPU with L<Unix::Processors>, L<POSIX> and C<< /proc >>.

=head1 NAME

Sys::Info::Driver::Linux::Device::CPU - Linux CPU Device Driver

=head1 METHODS

=head2 identify

See identify in L<Sys::Info::Device::CPU>.

=head2 load

See load in L<Sys::Info::Device::CPU>.

=head2 bitness

See bitness in L<Sys::Info::Device::CPU>.

=head1 SEE ALSO

L<Sys::Info>,
L<Sys::Info::Device::CPU>,
L<Unix::Processors>, L<POSIX>,
proc filesystem.

=head1 AUTHOR

Burak Gursoy <burak@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2006 by Burak Gursoy.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
