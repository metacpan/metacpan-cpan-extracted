# P2P::pDonkey::Met.pm
#
# Copyright (c) 2003-2004 Alexey klimkin <klimkin at cpan.org>. 
# All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
package P2P::pDonkey::Met;

use 5.006;
use strict;
use warnings;

require Exporter;

our $VERSION = '0.05';

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use P2P::pDonkey ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
    MT_KNOWNMET MT_PARTMET MT_SERVERMET
    
    unpackServerDesc packServerDesc printServerDesc makeServerDesc
    unpackServerDescList packServerDescList printServerDescList
    unpackServerDescListU packServerDescListU printServerDescListU
    unpackServerMet packServerMet printServerMet
    readServerMet writeServerMet

    unpackPartMet packPartMet printPartMet
	readPartMet writePartMet

    unpackKnownMet packKnownMet printKnownMet
	readKnownMet writeKnownMet

    unpackPrefMet packPrefMet printPrefMet
	readPrefMet writePrefMet

    readFile writeFile
) ],
                  'server' => [ qw(
    unpackServerDesc packServerDesc printServerDesc makeServerDesc
    unpackServerDescList packServerDescList printServerDescList
    unpackServerDescListU packServerDescListU printServerDescListU
    unpackServerMet packServerMet printServerMet
    readServerMet writeServerMet
) ],
                  'part'   => [ qw(
    unpackPartMet packPartMet printPartMet
	readPartMet writePartMet
) ],
                  'known'  => [ qw(
    unpackKnownMet packKnownMet printKnownMet
	readKnownMet writeKnownMet
) ],
                  'pref'   => [ qw(
    unpackPrefMet packPrefMet printPrefMet
	readPrefMet writePrefMet
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

use Carp;
use Data::Hexdumper;
use P2P::pDonkey::Meta ':all';
use P2P::pDonkey::Util qw( ip2addr );

my $debug = 0;

# Preloaded methods go here.

use constant MT_SERVERMET   => 0x0e;
use constant MT_PARTMET     => 0xe1;
use constant MT_KNOWNMET    => 0x0e;


sub readFile {
    my ($fname, $tag) = @_;
    my ($handle, $buf);
    my $rs = $/;
    undef $/;
    open($handle, "<$fname") 
        or warn "Can't open '$fname': $!\n" 
        and $/ = $rs 
        and return;
    binmode($handle);
    if ($tag) {
        if (read($handle, $buf, 1) != 1 || unpack('C',$buf) != $tag) {
            warn "File '$fname' without tag!\n";
            close($handle);
            $/ = $rs;
            return;
        }
        $buf .= <$handle>;
    } else {
        $buf = <$handle>;
    }
    close($handle);
    $/ = $rs;
    return \$buf;
};

sub writeFile($$) {
    my ($fname, $buf) = @_;
    my $handle;
    open($handle, ">$fname") or warn "Can't open `$fname': $!\n" and return;
    binmode($handle);
    print $handle $$buf;
    close($handle);
    return 1;
};

# -----------------------------------------------------------------------------
# server.met

sub unpackServerDesc {
    my ($ip, $port, $meta);
    ($ip, $port) = &unpackAddr or return;
    $meta = &unpackMetaListU or return;
    # Hash is for compatibility with Info structure
    return {Hash => '01234567012345670123456701234567', IP => $ip, Port => $port, Meta => $meta};
}
sub packServerDesc {
    my ($d) = @_;
    return packAddr($d) . packMetaListU($d->{Meta});
}
sub printServerDesc {
    my ($d) = @_;
    printAddr($d);
    print "\n";
    printMetaListU($d->{Meta});
}
sub makeServerDesc {
    my ($ip, $port, $name, $desc, $nusers, $nfiles, $preference) = @_;
    defined($ip) && defined($port) or confess "Specify ip and port of server!";
    $name or $name = '';
    $desc or $desc = '';
    $preference or $preference = 0;
    my %meta;
    tie %meta, "Tie::IxHash";
    $meta{Name}         = makeMeta(TT_NAME, $name);
    $meta{Description}  = makeMeta(TT_DESCRIPTION, $desc);
    $meta{IP}           = makeMeta(TT_IP, $ip);
    $meta{Port}         = makeMeta(TT_PORT, $port);
    $meta{users}        = makeMeta(TT_UNDEFINED, $nusers, "users", VT_INTEGER) if defined $nusers;
    $meta{files}        = makeMeta(TT_UNDEFINED, $nfiles, "files", VT_INTEGER) if defined $nfiles;
    $meta{Preference}   = makeMeta(TT_PREFERENCE, $preference);
    return {Hash => '01234567012345670123456701234567', IP => $ip, Port => $port, Meta => \%meta};
}

sub unpackServerDescList {
    my ($n, @l, $d);
    defined($n = &unpackD) or return;
    @l = ();
    while ($n--) {
        $d = &unpackServerDesc or return;
        push @l, $d;
    }
    return \@l;
}
sub packServerDescList {
    my ($l) = @_;
    my ($res);
    $res = packD(scalar @$l);
    foreach my $d (@$l) {
        $res .= packServerDesc($d);
    }
    return $res;
}
sub printServerDescList {
    foreach my $d (@{$_[0]}) {
        printServerDesc($d);
    }
}

sub unpackServerDescListU {
    my ($n, %l, $d);
    tie %l, "Tie::IxHash";
    defined($n = &unpackD) or return;
    %l = ();
    while ($n--) {
        $d = &unpackServerDesc or return;
        $l{idAddr($d)} = $d;
    }
    return \%l;
}
sub packServerDescListU {
    my ($res, $d);
    my $n = 0;
    $res = '';
    while ((undef, $d) = each %{$_[0]}) {
        $res .= packServerDesc($d);
        $n++;
    }
    return packD($n) . $res;
}
sub printServerDescListU {
    my $d;
    while ((undef, $d) = each %{$_[0]}) {
        printServerDesc($d);
    }
}

sub unpackServerMet {
    &unpackB == MT_SERVERMET or return;
    return &unpackServerDescListU;
}
sub packServerMet {
    return packB(MT_SERVERMET) . &packServerDescListU;
}
sub printServerMet {
    &printServerDescListU;
}

# parse server.met file && create hash
sub readServerMet {
    my ($fname) = @_;
    my ($off, $buf, $res);
    $buf = readFile($fname, MT_SERVERMET) or return;
    $off = 0;
    $res = unpackServerMet($$buf, $off);
    if ($res && $off != length $$buf) {
        warn "Unhandled bytes at the end:\n", hexdump(data=>$$buf, start_position=>$off);
    }
    return $res;
}

sub writeServerMet {
    my ($fname, $servers) = @_;
    my $buf = packServerMet($servers);
    return writeFile($fname, \$buf);
}

# -----------------------------------------------------------------------------
# .part.met

sub unpackPartMet {
    my $v = &unpackB;
    $v == MT_PARTMET or return;
    return &unpackFileInfo;
}
sub packPartMet {
    return packB(MT_PARTMET) . &packFileInfo;
}
sub printPartMet {
    &printInfo;
}

sub readPartMet {
    my ($fname) = @_;
    my ($off, $buf, $res);
    $buf = readFile($fname, MT_PARTMET) or return;
    $off = 0;
    $res = unpackPartMet($$buf, $off);
    $res->{Path} = $fname;
    if ($res && $off != length $$buf) {
        warn "Unhandled bytes at the end:\n", hexdump(data=>$$buf, start_position=>$off);
    }
    return $res;
}

sub writePartMet {
    my ($fname, $p) = @_;
    my $buf = packPartMet($p);
    return writeFile($fname, \$buf);
}


# -----------------------------------------------------------------------------
# known.met
sub unpackKnownMet {
    &unpackB == MT_KNOWNMET or return;
    return &unpackFileInfoList;
}
sub packKnownMet {
    return packB(MT_KNOWNMET) . &packFileInfoList;
}
sub printKnownMet {
    &printInfoList;
}
sub readKnownMet {
    my ($fname) = @_;
    my ($off, $buf, $res);
    $buf = readFile($fname, MT_KNOWNMET) or return;
    $off = 0;
    $res = unpackKnownMet($$buf, $off);
    if ($res && $off != length $$buf) {
        warn "Unhandled bytes at the end:\n", hexdump(data=>$$buf, start_position=>$off);
    }
    return $res;
}
sub writeKnownMet {
    my ($fname, $p) = @_;
    my $buf = packKnownMet($p);
    return writeFile($fname, \$buf);
}

# -----------------------------------------------------------------------------
# pref.met

sub unpackPrefMet {
    my ($ip, $port, $hash, $meta, $pref, $name, $m);
    ($ip, $port) = &unpackAddr or return;
    $hash = &unpackHash or return;
    $meta = &unpackMetaListU or return;
    $pref = &unpackMetaListU or return;
    return {IP => $ip, Port => $port, Hash => $hash, Meta => $meta, Pref => $pref};
}
sub packPrefMet {
    my ($p) = @_;
    return packAddr($p) . packHash($p->{Hash})
        . packMetaListU($p->{Meta}) . packMetaListU($p->{Pref});
}
sub printPrefMet {
    my ($d) = @_;
    print "Address: ";
    printAddr($d);
    print "\n";
    print "Hash: $d->{Hash}\n";
    print "Meta:\n";
    printMetaListU($d->{Meta});
    print "Preferencies:\n";
    printMetaListU($d->{Pref});
}

sub readPrefMet {
    my ($fname) = @_;
    my ($off, $buf, $res);
    $buf = readFile($fname) or return;
    $off = 0;
    $res = unpackPrefMet($$buf, $off);
    if ($res && $off != length $$buf) {
        warn "Unhandled bytes at the end:\n", hexdump(data=>$$buf, start_position=>$off);
    }
    return $res;
}
sub writePrefMet {
    my ($fname, $p) = @_;
    my $buf = packPrefMet($p);
    return writeFile($fname, \$buf);
}

1;
__END__

=head1 NAME

P2P::pDonkey::Met - Perl extension for handling *.met files of
eDonkey peer2peer protocol.

=head1 SYNOPSIS

    use P2P::pDonkey::Met ':server';
    my $servers;
    my $p = readServerMet($ARGV[0]);
    if ($p) {
        printServerMet($p);
    } else {
        print "$ARGV[0] is not in server.met format\n";
    }

    ...

    use P2P::pDonkey::Met ':part';
    foreach my $f (@ARGV) {
        my $p = readPartMet($f);
        if ($p) {
            printPartMet($p);
        } else {
            print "$f is not in part.met format\n";
        }
    }

    ...

    use P2P::pDonkey::Met ':known';
    my $p = readKnownMet($ARGV[0]);
    if ($p) {
        printKnownMet($p);
    } else {
        print "$ARGV[0] is not in known.met format\n";
    }

    ...

    use P2P::pDonkey::Met ':pref';
    my $p = readPrefMet($ARGV[0]);
    if ($p) {
        printPrefMet($p);
    } else {
        print "$ARGV[0] is not in pref.met format\n";
    }

=head1 DESCRIPTION

The module provides functions for reading, printing and writing *.met
files of eDonkey peer2peer protocol.

C<P2P::pDonkey::Met> provides the subroutines for four types of met files:
F<server.met>, F<...part.met>, F<known.met>, F<pref.met>.

=head2 server.met

Functions are tagged with ':server'.

=over 4

=item unpackServerDesc($buffer, $offset)

    Returns reference to unpacked server description structure.

=item packServerDesc($p)

    Returns packed string for description $$p.

=item printServerDesc($p)

    Prints server description to STDOUT.

=item makeServerDesc($ip, $port, $name, $desc, $nusers, $nfiles, $preference)

    Returns reference to new server description structure. 

=item unpackServerDescList($buffer, $offset)

    Returns reference to list of server descriptions.

=item packServerDescList($l)

    Returns packed string for list of descriptions @$l.

=item printServerDescList($l)

    Prints items of list @$l to STDOUT.

=item unpackServerDescListU($buffer, $offset)

    Returns reference to hash of server descriptions. Keys are idAddr($ip, $port).

=item packServerDescListU($h)

    Returns packed string for hash of descriptions %$h.

=item printServerDescListU($h)

    Prints values of hash %$h to STDOUT.

=item unpackServerMet($buffer, $offset)

    Returns reference to hash of server descriptions.

=item packServerMet($h)

    Returns packed string in server.met file format.

=item printServerMet($buffer, $offset)

    Alias to printServerDescListU($buffer, $offset).

=item readServerMet($filename)

    Reads file and unpacks data with unpackServerMet() function.

=item writeServerMet($filename, $h)

    Packs %$h with packServerMet() function and writes to file.

=back

=head2 ...part.met

Functions are tagged with ':part'.

=over 4

=item unpackPartMet($buffer, $offset)

    Returns reference to file information structure.
    
=item packPartMet($p)
    
    Returns packed string in part.met format.

=item printPartMet($p)

    Prints file information to STDOUT.
    
=item readPartMet($filename)

    Reads file and unpacks data with unpackPartMet() function.

=item writePartMet($filename, $p)

    Packs $$p with packPartMet() function and writes to file.

=back

=head2 known.met

Functions are tagged with ':known'.

=over 4

=item unpackKnownMet($buffer, $offset)

    Returns reference to list of file information structures.
    
=item packKnownMet($l)
    
    Returns packed string in known.met format.

=item printKnownMet($l)

    Prints elements of list @$l to STDOUT.
    
=item readKnownMet($filename)

    Reads file and unpacks data with unpackKnownMet() function.

=item writeKnownMet($filename, $l)

    Packs @$p with packKnownMet() function and writes to file.

=back

=head2 pref.met

Functions are tagged with ':pref'.

=over 4

=item unpackPrefMet($buffer, $offset)

    Returns reference to hash:

        IP => $ip 
        Port => $port 
        Hash => $hash 
        Meta => $meta 
        Pref => $pref
    
=item packPrefMet($p)
    
    Returns packed string in pref.met format.

=item printPrefMet($p)

    Print file information to STDOUT.
    
=item readPrefMet($filename)

    Reads file and unpacks data with unpackPrefMet() function.

=item writePrefMet($filename, $p)

    Packs $$p with packPrefMet() function and writes to file.

=back

=head2 EXPORT

None by default.


=head1 AUTHOR

Alexey Klimkin, E<lt>klimkin@mail.ruE<gt>

=head1 SEE ALSO

L<perl>, L<P2P::pDonkey::Meta>.

eDonkey home:

=over 4

    <http://www.edonkey2000.com/>

=back

Basic protocol information:

=over 4

    <http://hitech.dk/donkeyprotocol.html>

    <http://www.schrevel.com/edonkey/>

=back

Client stuff:

=over 4

    <http://www.emule-project.net/>

    <http://www.nongnu.org/mldonkey/>

=back

Server stuff:

=over 4

    <http://www.thedonkeynetwork.com/>

=back

=cut
