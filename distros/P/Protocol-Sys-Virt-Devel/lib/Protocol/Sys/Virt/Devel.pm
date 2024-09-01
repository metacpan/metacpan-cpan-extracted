
use v5.20;
use warnings;
use experimental 'signatures';

package Protocol::Sys::Virt::Devel v0.0.3;

use parent 'Exporter';
our @EXPORT_OK = qw( extract_all );

use File::Spec;
use List::Util qw(pairfirst);
use XDR::Parse;


my @modules = (
    {
        name        => 'transport',
        definitions => 'src/rpc/virnetprotocol.x',
    },
    {
        name        => 'keepalive',
        definitions => 'src/rpc/virkeepaliveprotocol.x',
    },
    {
        name        => 'remote',
        definitions => 'src/remote/remote_protocol.x',
    },
    );

my %headers = (
    'include/libvirt/libvirt-common.h.in' => {
        module => [
            qr// => 'Client',
        ],
    },
    'include/libvirt/libvirt-host.h' => {
        module => [
            qr// => 'Client',
        ],
    },
    'include/libvirt/libvirt-domain.h' => {
        module => [
            qr/^VIR_DOMAIN_(DEFINE_|EVENT_ID_)/ => 'Client',
            qr/^VIR_(DOMAIN_|KEYCODE_|PERF_|VCPU_|MEMORY_|MIGRATE_|DUMP_)/ => 'Domain',
            qr/^VIR_CONNECT_/ => 'Client',
        ],
    },
    'include/libvirt/libvirt-domain-checkpoint.h' => {
        module => [
            qr/^VIR_DOMAIN_CHECKPOINT_CREATE/ => 'Domain',
            qr/^VIR_DOMAIN_CHECKPOINT_/ => 'DomainCheckpoint',
        ],
    },
    'include/libvirt/libvirt-domain-snapshot.h' => {
        module => [
            qr/^VIR_DOMAIN_SNAPSHOT_CREATE_/ => 'Domain',
            qr/^VIR_DOMAIN_SNAPSHOT_/ => 'DomainSnapshot',
        ],
    },
    'include/libvirt/libvirt-interface.h' => {
        module => [
            qr/^VIR_INTERFACE_DEFINE_/ => 'Client',
            qr/^VIR_INTERFACE_/ => 'Interface',
            qr/^VIR_CONNECT_/ => 'Client',
        ],
    },
    'include/libvirt/libvirt-network.h' => {
        module => [
            qr/^VIR_NETWORK_(DEFINE_|CREATE_|EVENT_ID_)/ => 'Client',
            qr/^VIR_NETWORK_PORT_CREATE_/ => 'Network',
            qr/^VIR_NETWORK_PORT_/ => 'NetworkPort',
            qr/^VIR_(NETWORK_|IP_)/ => 'Network',
            qr/^VIR_CONNECT_/ => 'Client',
        ],
    },
    'include/libvirt/libvirt-nodedev.h' => {
        module => [
            qr/^VIR_NODE_DEVICE_(DEFINE_|CREATE_|EVENT_ID_)/ => 'Client',
            qr/^VIR_NODE_DEVICE_/ => 'NodeDevice',
            qr/^VIR_CONNECT_/ => 'Client',
        ],
    },
    'include/libvirt/libvirt-nwfilter.h' => {
        module => [
            qr/^VIR_NWFILTER_DEFINE_/ => 'Client',
            qr/^VIR_NWFILTER_BINDING_CREATE_/ => 'Client',
            qr/^VIR_NWFILTER_BINDING_/ => 'NwFilterBinding', # no occurrances in libvirt 10.3.0
            qr/^VIR_NWFILTER_/ => 'NwFilter',                # no occurrances in libvirt 10.3.0
        ],
    },
    'src/libvirt_internal.h' => {
        module => [
            qr/^VIR_DRV_FEATURE_/ => 'Remote',
        ],
    },
    'include/libvirt/libvirt-secret.h' => {
        module => [
            qr/^VIR_SECRET_(DEFINE_|CREATE_|EVENT_ID_)/ => 'Client',
            qr/^VIR_SECRET_USAGE_/ => 'Client',
            qr/^VIR_SECRET_/ => 'Secret',
            qr/^VIR_CONNECT_/ => 'Client',
        ],
    },
    'include/libvirt/libvirt-storage.h' => {
        module => [
            qr/^VIR_STORAGE_POOL_(CREATE_|DEFINE_|EVENT_ID_)/ => 'Client',
            qr/^VIR_STORAGE_VOL_CREATE_/ => 'Client',
            qr/^VIR_STORAGE_POOL_/ => 'StoragePool',
            qr/^VIR_STORAGE_VOL_/ => 'StorageVol',
            qr/^VIR_STORAGE_XML/ => 'StoragePool',
            qr/^VIR_CONNECT_/ => 'Client',
        ],
    },
    'include/libvirt/libvirt-stream.h' => {
        module => [
            qr/^VIR_STREAM_/ => 'Stream',
        ],
    },
    );

my $parser = XDR::Parse->new;

sub _ast($filename) {
    open my $fh, '<:encoding(UTF-8)', $filename
        or die "Error opening '$filename': $!";

    return $parser->parse( $fh );
}



my %prefix_strip_h = (
    Client => qr/^VIR_(CONNECT_|NODE_(?!DEVICE_))?/,
    Domain => qr/^VIR_(DOMAIN_)?/,
    DomainCheckpoint => qr/^VIR_(DOMAIN_CHECKPOINT_)?/,
    DomainSnapshot => qr/^VIR_(DOMAIN_SNAPSHOT_)?/,
    Interface => qr/^VIR_(INTERFACE_)?/,
    Network => qr/^VIR_(NETWORK_)?/,
    NetworkPort => qr/^VIR_(NETWORK_PORT_)?/,
    NwFilter => qr/^VIR_(NWFILTER_)?/,
    NwFilterBinding => qr/^VIR_(NWFILTER_BINDING_)?/,
    NodeDevice  => qr/^VIR_(NODE_DEVICE_)?/,
    Remote      => qr/^VIR_/,
    Secret      => qr/^VIR_(SECRET_)?/,
    StoragePool => qr/^VIR_(STORAGE_(POOL_)?)?/,
    StorageVol  => qr/^VIR_(STORAGE_(VOL_)?)?/,
    Stream      => qr/^VIR_STREAM_/,
    );

sub _strip_number_suffix {
    my $v = ($_[0] =~ s/([0-9]+)(?:u|l|ul|ll|ull)(\s|$)/$1$2/igr);
    $v;
}

sub _trim {
    my $v = ($_[0] =~ s/^\s*//r);
    $v =~ s/\s*$//;
    $v;
}

sub _header_extractor($libvirt, $header) {
    my @syms;

    open my $fh, '<:encoding(UTF-8)', File::Spec->catfile($libvirt, $header)
        or die "Error opening '$header': $!";

    my $in_enum = 0;
    while (my $line = <$fh>) {
        if (not $in_enum
            and $line =~ m/^\s*typedef\s+enum\s*{/) {
            $in_enum = 1;
            next;
        }
        $line =~ s{/\*([^*]|\*[^/])*\*/}{}g
            if $in_enum;
        if ($in_enum
            and $line =~ m/^\s*}/) {
            $in_enum = 0;
            next;
        }
        if ($in_enum
            and $line =~ m{\s*(VIR_[A-Z0-9_]+)\s*=\s*((?:[^,/\n]|/(?!\*))+)}) {
            my ($orig, $val) = ($1, $2);
            $val = _strip_number_suffix(_trim($val));
            my (undef, $module) = pairfirst {;
                $orig =~ m/$a/
            } @{ $headers{$header}->{module} };
            die "No module for constant $orig in $header"
                unless $module;
            my $sym = ($orig =~ s/$prefix_strip_h{$module}//r);
            push @syms, {
                sym => $sym,
                value => $val,
                orig => $orig,
                mod => $module
            };
        }
        if ($line =~ m{#\s*define (VIR_[A-Z0-9_]+)\s+((?:[^\n/]|/(?!\*))+)}) {
            my ($orig, $val) = ($1, $2);
            $val = _strip_number_suffix(_trim($val));
            next if $orig =~ m/^(VIR_DEPRECATED|VIR_EXPORT_VAR)$/; # for C programs, but not for us...
            next if $val =~ m/^@.*@$/; # defined by autoconf macro... can't include
            my (undef, $module) = pairfirst {;
                $orig =~ m/$a/
            } @{ $headers{$header}->{module} };
            die "No module for constant $orig in $header"
                unless $module;
            my $sym = ($orig =~ s/$prefix_strip_h{$module}//r);
            push @syms, { sym => $sym, value => $val, orig => $orig, mod => $module };
        }
    }

    return @syms;
}


sub extract_all($libvirt) {
    my @h_syms;
    for my $header (sort keys %headers) {
        push @h_syms,
            _header_extractor( $libvirt, $header );
    }
    my %h_sym_values;
    for my $h_sym (@h_syms) {
        $h_sym_values{$h_sym->{orig}} = $h_sym->{value};
    }
    for my $key (keys %h_sym_values) {
        if (exists $h_sym_values{$h_sym_values{$key}}) {
            $h_sym_values{$key} = $h_sym_values{$h_sym_values{$key}};
        }
    }
    for my $val (values %h_sym_values) {
        die "Unresolved value: $val"
            if $val =~ m/^[A-Z_]+$/;
    }
    for my $h_sym (@h_syms) {
        $h_sym->{resolved} = $h_sym_values{$h_sym->{orig}};
    }

    return {
        ast => {
            map {
                $_->{name} =>
                    _ast(File::Spec->catfile($libvirt, $_->{definitions}))
            } @modules
        },
        header_syms => \@h_syms,
    };
}

1;


__END__

=head1 NAME

Protocol::Sys::Virt::Devel - Helper module for Protocol::Sys::Virt and dependants

=head1 VERSION

0.0.3

=head1 SYNOPSIS

  use Protocol::Sys::Virt::Devel qw(extract_all);

  my $api_data = extract_all( './libvirt' );

=head1 DESCRIPTION

Given a cloned C<libvirt> repository, this library extracts the constants
and structure definitions required to build functionalities against its
(XDR-based) wire protocol.

=head1 SUBROUTINES

=head2 extract_all($libvirt)

Extracts API data from the directory passed in C<$libvirt>.

Returns a hashref with the following keys:

=over 8

=item * ast

The value is a hashref with the values being the ASTs as generated by
L<XDR::Parse> for various parts of the wire protocol.  The following
keys

=over 8

=item * transport

Taken from C< src/rpc/virnetprotocol.x >, defines the lowest level
of the protocol.

=item * keepalive

Taken from C< src/rpc/virkeepaliveprotocol.x >, defines the I<keep alive>
"program" in the protocol. Very old clients may not support this program.

=item * remote

Taken from C< src/remote/remote_protocol.x >, defines the I<remote>
"program" in the protocol.

=back

=item * header_syms

An arrayref holding data of symbols (constant definitions) extracted from
the public C<libvirt> headers (and an internal header hiding some of the
protocol constants).

Each array element is a hashref with the following keys:

=over 8

=item * mod

The name of the I<module> which should hold the symbol as named by
the C<sym> key.  This module name may be used to construct a Perl
module name.

=item * orig

The original name of the symbol (as it occurs in the header file).

=item * sym

The symbol stripped from any prefixes; the name that is to be used
in conjunction with the I<module>.

=item * value

An expression defining the value of the symbol. Strings are quoted;
numeric values may be expressed as C< (1 << 2) >.

=back

=back

=head1 INCOMPATIBILITIES

This module has been written in I< Modern Perl >, using function signatures,
which makes the module compatible with Perl 5.36 and up.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests through
the GitHub repository at
L<https://github.com/ehuelsmann/perl-protocol-sys-virt-devel/issues>

=head1 AUTHOR

=over 8

=item * Erik Huelsmann C<< <ehuels@gmail.com> >>

=back

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2024, Erik Huelsmann C<< <ehuels@gmail.com> >>.
All rights reserved.

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY FOR
THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN OTHERWISE
STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES PROVIDE THE
SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED,
INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
FITNESS FOR A PARTICULAR PURPOSE. THE ENTIRE RISK AS TO THE QUALITY AND
PERFORMANCE OF THE SOFTWARE IS WITH YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE,
YOU ASSUME THE COST OF ALL NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING WILL ANY
COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR REDISTRIBUTE THE
SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE LIABLE TO YOU FOR DAMAGES,
INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING
OUT OF THE USE OR INABILITY TO USE THE SOFTWARE (INCLUDING BUT NOT LIMITED TO
LOSS OF DATA OR DATA BEING RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR
THIRD PARTIES OR A FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE),
EVEN IF SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH
DAMAGES.
