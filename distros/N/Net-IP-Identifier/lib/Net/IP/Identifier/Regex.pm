#!/usr/bin/perl
#===============================================================================
#      PODNAME:  Net::IP::Identifier::Regex
#     ABSTRACT:  Some regular expressions used by Net::IP::Identifier
#                   Tries to use use Regexp::Common qw /net/, but if not
#                   available, creates the regexes by hand.
#
#       AUTHOR:  Reid Augustin
#        EMAIL:  reid@LucidPort.com
#      CREATED:  11/20/2014 10:06:21 AM
#===============================================================================

use 5.008;
use strict;
use warnings;

package Net::IP::Identifier::Regex;
use Try::Tiny;

our $VERSION = '0.111'; # VERSION

sub new {
    my ($class, %opts) = @_;

    my $self = {};
    bless $self, (ref $class || $class);

    return $self;
}

# IPv4/6 single IP
sub IP  {
    my ($self) = @_;

    my $IPv4 = $self->IPv4;
    my $IPv6 = $self->IPv6;
    return qr{(?:$IPv4|$IPv6)};
}

# IPv4/6 any netblock format, but not single IPs
sub netblock  {
    my ($self) = @_;

    my $range = $self->range;  # IPv4/6 range
    my $cidr  = $self->cidr;   # IPv4/6 cidr
    my $plus  = $self->plus;   # IPv4/6 plus notation range
    return qr{(?:$range|$plus|$cidr)};
}

sub range  {
    my ($self) = @_;

    my $IPv4_range = $self->IPv4_range;
    my $IPv6_range = $self->IPv6_range;
    return qr{(?:$IPv4_range|$IPv6_range)};
}

sub cidr  {
    my ($self) = @_;

    my $IPv4_cidr = $self->IPv4_cidr;
    my $IPv6_cidr = $self->IPv6_cidr;
    return qr{(?:$IPv4_cidr|$IPv6_cidr)};
}

sub plus  {
    my ($self) = @_;

    my $IPv4_plus = $self->IPv4_plus;
    my $IPv6_plus = $self->IPv6_plus;
    return qr{(?:$IPv4_plus|$IPv6_plus)};
}

sub IPv4_cidr  {
    my ($self) = @_;

    my $IPv4 = $self->IPv4;
    return qr{$IPv4\s*/\s*\d\d?};
}
sub IPv4_range {
    my ($self) = @_;

    my $IPv4 = $self->IPv4;
    return qr{$IPv4\s*-\s*$IPv4};
}
sub IPv4_plus   {
    my ($self) = @_;

    my $IPv4 = $self->IPv4;
    return qr{$IPv4\s*\+\s*\d+};
}
sub IPv4_any   {
    my ($self) = @_;

    my $IPv4 = $self->IPv4;
    return qr{$IPv4(?:\s*/\s*\d\d?|\s*-\s*$IPv4|\s*\+\s*\d+)?};
}

sub IPv6_cidr  {
    my ($self) = @_;

    my $IPv6 = $self->IPv6;
    return qr{$IPv6\s*/\s*\d+};
}
sub IPv6_range {
    my ($self) = @_;

    my $IPv6 = $self->IPv6;
    return qr{$IPv6\s*-\s*$IPv6};
}
sub IPv6_plus   {
    my ($self) = @_;

    my $IPv6 = $self->IPv6;
    return qr{$IPv6\s*\+\s*\d+};
}
sub IPv6_any   {
    my ($self) = @_;

    my $IPv6       = $self->IPv6;
    return qr{$IPv6(?:\s*/\s*\d+|\s*-\s*$IPv6|\s*\+\s*\d+)?};
}

sub IP_any {
    my ($self) = @_;

    my $IPv4_any = $self->IPv4_any;
    my $IPv6_any = $self->IPv6_any;
    return qr{$IPv4_any|$IPv6_any};
}

sub IPv4 {
    my ($self, $new) = @_;

    if (@_ > 1) {
        $self->{IPv4} = $new;
    }
    if (not $self->{IPv4}) {
        try {
            require Regexp::Common;
            Regexp::Common->import(qw /net/);
            $self->IPv4($Regexp::Common::RE{net}{IPv4});
            $self->IPv6($Regexp::Common::RE{net}{IPv6});
        }
        catch {
            # I need this to work with an older version of perl, so I have
            # copied some regexes from Regexp::Common::net:
            $self->IPv4( qr/\b(?:(?:25[0-5]|2[0-4][0-9]|[0-1]?[0-9]{1,2})[.](?:25[0-5]|2[0-4][0-9]|[0-1]?[0-9]{1,2})[.](?:25[0-5]|2[0-4][0-9]|[0-1]?[0-9]{1,2})[.](?:25[0-5]|2[0-4][0-9]|[0-1]?[0-9]{1,2}))\b/ );
            $self->IPv6( qr/\s*-\s*(?:(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4})|(?::(?:)(?:):(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}))|(?::(?:)(?:)(?:):(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}))|(?::(?:)(?:)(?:)(?:):(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}))|(?::(?:)(?:)(?:)(?:)(?:):(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}))|(?::(?:)(?:)(?:)(?:)(?:)(?:):(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}))|(?::(?:)(?:)(?:)(?:)(?:)(?:)(?:):(?:[0-9a-fA-F]{1,4}))|(?::(?:)(?:)(?:)(?:)(?:)(?:)(?:)(?:):)|(?:(?:[0-9a-fA-F]{1,4}):(?:)(?:):(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}))|(?:(?:[0-9a-fA-F]{1,4}):(?:)(?:)(?:):(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}))|(?:(?:[0-9a-fA-F]{1,4}):(?:)(?:)(?:)(?:):(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}))|(?:(?:[0-9a-fA-F]{1,4}):(?:)(?:)(?:)(?:)(?:):(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}))|(?:(?:[0-9a-fA-F]{1,4}):(?:)(?:)(?:)(?:)(?:)(?:):(?:[0-9a-fA-F]{1,4}))|(?:(?:[0-9a-fA-F]{1,4}):(?:)(?:)(?:)(?:)(?:)(?:)(?:):)|(?:(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}):(?:)(?:):(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}))|(?:(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}):(?:)(?:)(?:):(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}))|(?:(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}):(?:)(?:)(?:)(?:):(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}))|(?:(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}):(?:)(?:)(?:)(?:)(?:):(?:[0-9a-fA-F]{1,4}))|(?:(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}):(?:)(?:)(?:)(?:)(?:)(?:):)|(?:(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}):(?:)(?:):(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}))|(?:(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}):(?:)(?:)(?:):(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}))|(?:(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}):(?:)(?:)(?:)(?:):(?:[0-9a-fA-F]{1,4}))|(?:(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}):(?:)(?:)(?:)(?:)(?:):)|(?:(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}):(?:)(?:):(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}))|(?:(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}):(?:)(?:)(?:):(?:[0-9a-fA-F]{1,4}))|(?:(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}):(?:)(?:)(?:)(?:):)|(?:(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}):(?:)(?:):(?:[0-9a-fA-F]{1,4}))|(?:(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}):(?:)(?:)(?:):)|(?:(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}):(?:)(?:):))/ );
            # vim users: expect syntax coloring to be messed up from here on
        };
    }
    $self->{IPv4};
}

sub IPv6 {
    my ($self, $new) = @_;

    if (@_ > 1) {
        $self->{IPv6} = $new;
    }
    if (not $self->{IPv6}) {
        try {
            require Regexp::Common;
            Regexp::Common->import(qw /net/);
            $self->IPv4($Regexp::Common::RE{net}{IPv4});
            $self->IPv6($Regexp::Common::RE{net}{IPv6});
        }
        catch {
            # I need this to work with an older version of perl, so I have
            # copied some regexes from Regexp::Common::net:
            $self->IPv4( qr/\b(?:(?:25[0-5]|2[0-4][0-9]|[0-1]?[0-9]{1,2})[.](?:25[0-5]|2[0-4][0-9]|[0-1]?[0-9]{1,2})[.](?:25[0-5]|2[0-4][0-9]|[0-1]?[0-9]{1,2})[.](?:25[0-5]|2[0-4][0-9]|[0-1]?[0-9]{1,2}))\b/ );
            $self->IPv6( qr/\s*-\s*(?:(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4})|(?::(?:)(?:):(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}))|(?::(?:)(?:)(?:):(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}))|(?::(?:)(?:)(?:)(?:):(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}))|(?::(?:)(?:)(?:)(?:)(?:):(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}))|(?::(?:)(?:)(?:)(?:)(?:)(?:):(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}))|(?::(?:)(?:)(?:)(?:)(?:)(?:)(?:):(?:[0-9a-fA-F]{1,4}))|(?::(?:)(?:)(?:)(?:)(?:)(?:)(?:)(?:):)|(?:(?:[0-9a-fA-F]{1,4}):(?:)(?:):(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}))|(?:(?:[0-9a-fA-F]{1,4}):(?:)(?:)(?:):(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}))|(?:(?:[0-9a-fA-F]{1,4}):(?:)(?:)(?:)(?:):(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}))|(?:(?:[0-9a-fA-F]{1,4}):(?:)(?:)(?:)(?:)(?:):(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}))|(?:(?:[0-9a-fA-F]{1,4}):(?:)(?:)(?:)(?:)(?:)(?:):(?:[0-9a-fA-F]{1,4}))|(?:(?:[0-9a-fA-F]{1,4}):(?:)(?:)(?:)(?:)(?:)(?:)(?:):)|(?:(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}):(?:)(?:):(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}))|(?:(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}):(?:)(?:)(?:):(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}))|(?:(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}):(?:)(?:)(?:)(?:):(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}))|(?:(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}):(?:)(?:)(?:)(?:)(?:):(?:[0-9a-fA-F]{1,4}))|(?:(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}):(?:)(?:)(?:)(?:)(?:)(?:):)|(?:(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}):(?:)(?:):(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}))|(?:(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}):(?:)(?:)(?:):(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}))|(?:(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}):(?:)(?:)(?:)(?:):(?:[0-9a-fA-F]{1,4}))|(?:(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}):(?:)(?:)(?:)(?:)(?:):)|(?:(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}):(?:)(?:):(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}))|(?:(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}):(?:)(?:)(?:):(?:[0-9a-fA-F]{1,4}))|(?:(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}):(?:)(?:)(?:)(?:):)|(?:(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}):(?:)(?:):(?:[0-9a-fA-F]{1,4}))|(?:(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}):(?:)(?:)(?:):)|(?:(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}):(?:[0-9a-fA-F]{1,4}):(?:)(?:):))/ );
            # vim users: expect syntax coloring to be messed up from here on
        };
    }
    $self->{IPv6};
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::IP::Identifier::Regex - Some regular expressions used by Net::IP::Identifier

=head1 VERSION

version 0.111

=head1 SYNOPSIS

 use Net::IP::Identifier::Regex;

 my $re = Net::IP::Identifier::Regex->new;

=head1 DESCRIPTION

Net::IP::Identifier::Regex tries to 'require Regexp::Common ('net')' and
extract regular expressions for matching IPv4 and IPv6 addresses.  If that
fails (older versions of perl may not support it), the regular expressions
are built by hand, 'borrowed' from a recent a version of Regexp::Common::net.

=head2 Methods

=over 2

=item new

Creates a new Net::IP::Identifier::Regex object.  No options are recognized.

=item IPv4( [ $new ] )

Set/get the regular expression for matching IPv4 addresses.

=item IPv6( [ $new ] )

Set/get the regular expression for matching IPv6 addresses.

=item IP

Get IPv4/6 single IP regex.

=item range

Get IPv4/6 range regex (xx - xx).

=item cidr

Get IPv4/6 CIDR regex (xx/W).

=item plus

Get IPv4/6 range regex (xx + N).

=item netblock

Get IPv4/6 any netblock regex, but not single IPs.

=item IP_any

Get any IPv4/6 format regex (single IP, CIDR, range, or plus).

=item IPv4_cidr

Get IPv4 CIDR regex (xx/W).

=item IPv4_range

Get IPv4 range regex (xx - xx).

=item IPv4_plus

Get IPv4 range regex (xx + N).

=item IPv4_any

Get any IPv4 format regex (single IP, CIDR, range, or plus).

=item IPv6_cidr

Get IPv6 CIDR regex (xx/W).

=item IPv6_range

Get IPv6 range regex (xx - xx).

=item IPv6_plus

Get IPv6 range regex (xx + N).

=item IPv6_any

Get any IPv6 format regex (single IP, CIDR, range, or plus).

=back

=head1 SEE ALSO

=over

=item Net::IP::Identifier

=back

=head1 AUTHOR

Reid Augustin <reid@hellosix.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Reid Augustin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
