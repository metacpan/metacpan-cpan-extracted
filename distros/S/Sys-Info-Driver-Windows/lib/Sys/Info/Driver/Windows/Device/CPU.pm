package Sys::Info::Driver::Windows::Device::CPU;
use strict;
use warnings;
#use vars     qw( $Registry );
use base qw(
    Sys::Info::Driver::Unknown::Device::CPU::Env
    Sys::Info::Driver::Windows::Device::CPU::WMI
);
use Sys::Info::Constants       qw( :windows_reg    );
use Sys::Info::Driver::Windows::Constants;
use Sys::Info::Driver::Windows qw( :info :reg :WMI CPUFeatures );
use Carp                       qw( croak           );
use Win32::OLE                 qw( in              );

our $VERSION = '0.78';
my $REG;
$REG = registry()->{ +WIN_REG_CPU_KEY } if registry()->{ +WIN_REG_HW_KEY };

sub load {
    my $self = shift;
    my @cpu  = $self->identify;
    return $cpu[0]->{load};
}

sub bitness {
    my $self = shift;
    ## no critic (ValuesAndExpressions::ProhibitMagicNumbers)
    # XXX: put this into ->arch()
    if ( my($cpu) = $self->_from_wmi ) {
        my $arch = $cpu->{architecture};
        if ( $arch ) {
            return +( $arch eq 'x64' || $arch =~ m{Itanium}xms ) ? 64 : 32;
        }
    }
    my %i    = GetSystemInfo();
    my $bits = $i{wProcessorBitness};
    if ( $bits < 0 ) {
        warn "Failed to detect processor bitness. Guessing as 32bit\n";
        return 32;
    }
    return $bits;
}

# XXX: interface is unclear. return data based on context !!!
# Take a parameter named cpu_num and return properties based on that
# ... else: add a method named properties() !!!
sub identify {
    my $self = shift;
    if ( ! $self->{META_DATA} ) {
        my @cache = $self->_from_wmi
                    or $self->_from_registry
                    or $self->SUPER::identify(@_)
                    or croak('Failed to identify CPU');
        $self->_set_flags( \@cache );
        $self->{META_DATA} = [ @cache ];
    }
    return $self->_serve_from_cache(wantarray);
}

# ------------------------[ P R I V A T E ]------------------------ #

sub _set_flags {
    my($self, $cpu) = @_;

    my %feat = CPUFeatures();
    my $c    = 'Sys::Info::Driver::Windows::Constants';

    my $get_symbols = sub {
        # fetch the related constants
        my $regex = shift || die "Regex missing\n";
        no strict qw( refs );
        return grep { $_ =~ $regex } keys %{ $c . q{::} };
    };

    my $cf = $feat{CpuFeatures};
    my $f  = $feat{Flags};
    my $k  = $feat{KFBits};
    my $ff = $feat{FeatureFlags};
    my @flags;

    foreach my $flag ( $get_symbols->( qr{ \A CF_ }xms ) ){
        push @flags, $flag if $f & $c->$flag();
    }

    foreach my $flag ( $get_symbols->( qr{ \A KF_ }xms ) ){
        push @flags, $flag if $k & $c->$flag();
    }

    foreach my $flag ( $get_symbols->( qr{ \A FT_ }xms ) ){
        push @flags, $flag if $ff & $c->$flag();
    }

    foreach my $e ( @flags ) {
        $e =~ s{ \A (?: CF|KF|FT )_ }{}xms;
    }

    my %fbuf = map { lc $_ => 1 } @flags;
    @flags = sort keys %fbuf;

    $cpu->[$_]{flags} = [ @flags ] for 0..$#{$cpu};
    return;
}

# $REG->{'0/FeatureSet'}
# $REG->{'0/Update Status'}
sub _from_registry {
    my $self = shift;
    return +() if not $self->_registry_is_ok;
    my(@cpu);

    foreach my $k (keys %{ $REG }) {
        my $name = $REG->{ $k . '/ProcessorNameString' };
        $name =~ s{\s+}{ }xmsg;
        $name =~ s{\A \s+}{}xms;
        my $id = $REG->{ $k . '/Identifier' };

        push @cpu, {
            name          => $name,
            speed         => hex( $REG->{ $k . '/~MHz' } ),
            architecture  => ($id =~ m{ \A (.+?) \s? Family }xmsi),
            data_width    => undef,
            bus_speed     => undef,
            address_width => undef,
        };
    }

    return @cpu;
}

sub _registry_is_ok {
    my $self = shift;
    return if not $REG;
    return if not $REG->{'0/'};
    return if not $REG->{'0/ProcessorNameString'};
    return 1;
}

# may be called from ::Env
sub __env_pi { # XXX: remove this thing
    my $self = shift;
    return if not $REG;
    return $REG->{'0/Identifier'}.', '.$REG->{'0/VendorIdentifier'};
}

1;

__END__

=pod

=head1 NAME

Sys::Info::Driver::Windows::Device::CPU - Windows CPU Device Driver

=head1 SYNOPSIS

-

=head1 DESCRIPTION

This document describes version C<0.78> of C<Sys::Info::Driver::Windows::Device::CPU>
released on C<17 April 2011>.

Uses C<WMI>, C<Registry> and C<ENV> to identify the CPU.

=head1 METHODS

=head2 identify

See identify in L<Sys::Info::Device::CPU>.

=head2 load

See load in L<Sys::Info::Device::CPU>.

=head2 bitness

See bitness in L<Sys::Info::Device::CPU>.

=head1 SEE ALSO

L<Sys::Info>,
L<Sys::Info::Device::CPU>.

=head1 AUTHOR

Burak Gursoy <burak@cpan.org>.

=head1 COPYRIGHT

Copyright 2006 - 2011 Burak Gursoy. All rights reserved.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify 
it under the same terms as Perl itself, either Perl version 5.12.2 or, 
at your option, any later version of Perl 5 you may have available.

=cut
