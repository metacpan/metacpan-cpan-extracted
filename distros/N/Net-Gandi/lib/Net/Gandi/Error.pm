#
# This file is part of Net-Gandi
#
# This software is copyright (c) 2012 by Natal Ngétal.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
package Net::Gandi::Error;
{
  $Net::Gandi::Error::VERSION = '1.122180';
}

# ABSTRACT: Internal class to manage error.

use strict;
use warnings;

use Params::Check qw( check );
use Carp;

use Const::Fast;
use Data::Dumper;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(_validated_params);

const my %TEMPLATE_VALIDATED => (
    vm_create => {
        datacenter_id => {
            required => 1,
            defined  => 1
            #allow    => qr/^\d+$/,
        },
        ip_version => {
            required => 1,
            defined  => 1
        },
        sys_disk_id => {
            required => 1,
            defined  => 1
        },
        memory => {
            required => 1,
            defined  => 1
        },
        hostname => {
            required => 1,
            defined  => 1
        }
    },
    vm_create_from => {
        datacenter_id => {
            required => 1,
            defined  => 1
            #allow    => qr/^\d+$/,
        },
        ip_version => {
            required => 1,
            defined  => 1
        },
        memory => {
            required => 1,
            defined  => 1
        },
        hostname => {
            required => 1,
            defined  => 1
        }
    },
    disk_create => {
        datacenter_id => {
            required => 1,
            defined  => 1
        },
        name => {
            required => 1,
            defined  => 1
        },
        size => {
            required => 1,
            defined  => 1
        },
    },
    disk_create_from => {
        name => {
            required => 1,
            defined  => 1
        },
    },
    iface_create => {
        datacenter_id => {
            required => 1,
            defined  => 1
        },
        ip_version => {
            required => 1,
            defined  => 1
        },
    },
    iface_update => {
        bandwith => {
            required => 1,
            defined  => 1
        },
    },
    ip_create => {
        datacenter_id => {
            required => 1,
            defined  => 1
            #allow    => qr/^\d+$/,
        },
        ip_version => {
            required => 1,
            defined  => 1
        }
    },
    ip_update => {
        reverse => {
            required => 1,
            defined  => 1
        }
    },
);

sub _validated_params {
    my ( $type, $args ) = @_;

    check($TEMPLATE_VALIDATED{$type}, $args, 1) or croak 'Invalid hash';
}

1;

__END__
=pod

=head1 NAME

Net::Gandi::Error - Internal class to manage error.

=head1 VERSION

version 1.122180

=head1 AUTHOR

Natal Ngétal

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Natal Ngétal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

