package Net::SRCDS::Queries::Parser;

use warnings;
use strict;
use version; our $VERSION = qv('0.0.5');
use Encode qw(from_to);

sub parse_packet {
    my( $self, $buf, $server, $sender ) = @_;
    my $t = unpack 'x4a', $buf;
    if ( $t eq 'A' ) {
        my $result = $self->parse_challenge($buf);
        $self->send_a2s_rules( $sender, $result->{cnum} );
        $self->send_a2s_player( $sender, $result->{cnum} );
    }
    elsif ( $t eq 'I' ) {
        my $result = $self->parse_a2s_info($buf);
        $self->{results}->{$server}->{info} = $result;
    }
    elsif ( $t eq 'D' ) {
        my $result = $self->parse_a2s_player($buf);
        $self->{results}->{$server}->{player} = $result;
        return 1;
    }
    elsif ( $t eq 'E' ) {
        my $result = $self->parse_a2s_rules($buf);
        $self->{results}->{$server}->{rules} = $result;
        return 1;
    }
    return 0;
}

sub parse_a2s_info {
    my( $self, $buf ) = @_;
    my( $type, $version, $str ) = unpack 'x4aca*', $buf;
    my( $sname, $map, $dir, $desc, $remains ) = split /\0/, $str, 5;
    my(
        $app_id, $players, $max,    $bots, $dedicated,
        $os,     $pw,      $secure, $remains2
    ) = unpack 'vcccaacca*', $remains;
    my( $gversion, $remains3 ) = split /\0/, $remains2, 2;

    my $result = {
        type      => $type,
        version   => $version,
        sname     => $sname,
        map       => $map,
        dir       => $dir,
        desc      => $desc,
        app_id    => $app_id,
        players   => $players,
        max       => $max,
        bots      => $bots,
        dedicated => $dedicated,
        os        => $os,
        password  => $pw,
        secure    => $secure,
        gversion  => $gversion,
    };
    my( $edf, $opt ) = unpack 'ca*', $remains3;
    if ( $edf & 0x80 ) {
        my $port;
        ( $port, $opt ) = unpack 'va*', $opt;
        $result->{port} = $port;
    }
    if ( $edf & 0x40 ) {
        # print "opt is spectator port\n";
        $result->{spectator} = '';
    }
    if ( $edf & 0x20 ) {
        chop $opt;
        $result->{game_tag} = $opt;
    }
    return $result;
}

sub parse_a2s_player {
    my( $self, $buf ) = @_;
    my $encoding = $self->{encoding};
    my( $type, $num_players, $followings ) = unpack 'x4aca*', $buf;
    my $player_info;
    while ($followings) {
        my( $index, $r1 ) = unpack 'ca*', $followings;
        my( $name, $r2 ) = ( split /\0/, $r1, 2 );
        from_to( $name, 'utf8', $encoding ) if $encoding;
        my( $kills, $connected, $r3 ) = unpack 'lfa*', $r2;
        # XXX : reverse float for some environment
        if ( $self->{float_order} ) {
            my $hex = unpack 'H*', pack 'f', $connected;
            my @b;
            $hex =~ s/(.{2})/push(@b, $1)/seg;
            $hex = join '', reverse @b;
            $connected = unpack 'f', pack 'H*', $hex;
        }
        push @{$player_info},
            {
            name      => $name,
            kills     => $kills,
            connected => $connected,
            };
        $followings = $r3;
    }

    my $result = {
        type        => $type,
        num_players => $num_players,
        player_info => $player_info,
    };
    return $result;
}

sub parse_a2s_rules {
    my( $self, $buf ) = @_;
    my $encoding = $self->{encoding};
    my( $type, $num_rules, $r1 ) = unpack 'x4aca*', $buf;
    my( undef, $followings ) = ( split /\0/, $r1, 2 );
    my $rules_info;
    while ($followings) {
        my( $name, $value, $r2 ) = ( split /\0/, $followings, 3 );
        push @{$rules_info},
            {
            name  => $name,
            value => $value,
            };
        $followings = $r2;
    }

    my $result = {
        type       => $type,
        num_rules  => $num_rules,
        rules_info => $rules_info,
    };
    return $result;
}

sub parse_challenge {
    my( $self, $buf ) = @_;
    my( $type, $cnum ) = unpack 'x4aa4', $buf;
    return {
        type => $type,
        cnum => $cnum,
    };
}

use constant base_number => 76561197960265728;
sub id2community_id {
    my( $self, $id ) = @_;
    my( $n1, $n2, $n3 ) = ( $id =~ /STEAM_(\d):(\d):(\d+)/i );
    return unless defined $n1;
    my $community_id = base_number + $n2 + ( $n3 * 2 );
    return $community_id;
}

1;
__END__

=head1 NAME

Net::SRCDS::Queries::Parser - Stream parser for Net::SRCDS::Querires


=head1 VERSION

This document describes Net::SRCDS::Queries::Parser version 0.0.4


=head1 SYNOPSIS

    my $result = $self->parse_packet( $buf, $server, $sender );

=head1 DESCRIPTION

This is base class of Net::SRCDS::Queries.
defined parser methods for SRCDS packets.

=head2 Methods

=over

=item parse_packet

    my $result = $self->parse_packet( $buf, $server, $sender );

parse SRCDS packet and store result in $self->{result}.
return true when A2S_PLAYER, A2S_RULES pakcet received.

=item parse_challenge

    my $result = $self->parse_challenge($buf);

parse GETCHALLENGE packet and return result as hash ref.

=item parse_a2s_info

    my $result = $self->parse_a2s_info($buf);

parse A2S_INFO packet and return result as hash ref.

=item parse_a2s_player

    my $result = $self->parse_a2s_player($buf);

parse A2S_PLAYER packet and return result as hash ref.

=item parse_a2s_rules

    my $result = $self->parse_a2s_rules($buf);

parse A2S_RULES packet and return result as hash ref.

=item id2community_id

    my $community_id = $self->id2community_id($steam_id);

convers STEAM_ID to to Steam Community ID.
See L<http://forums.alliedmods.net/showthread.php?t=60899> for details.

=back

=head1 INCOMPATIBILITIES

None reported.


=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-net-srcds-queries@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 AUTHOR

Masanori Hara  C<< <massa.hara at gmail.com> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2010, Masanori Hara C<< <massa.hara at gmail.com> >>.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
