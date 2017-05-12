package Net::FTP::Throttle;
use strict;
use warnings;
use Algorithm::TokenBucket;
use Carp;
use Fcntl qw(O_WRONLY O_RDONLY O_APPEND O_CREAT O_TRUNC);
use Net::FTP;
use Time::HiRes qw(sleep);
use base qw(Net::FTP);
our $VERSION = "0.32";

# a lot of this code was stolen from Net::FTP

BEGIN {

    # make a constant so code is fast'ish
    my $is_os390 = $^O eq 'os390';
    *trEBCDIC = sub () {$is_os390}
}

sub new {
    my $package = shift;
    my $self    = $package->SUPER::new(@_);

    return unless $self;

    my ( $peer, %arg );
    if ( @_ % 2 ) {
        $peer = shift;
        %arg  = @_;
    } else {
        %arg  = @_;
        $peer = delete $arg{Host};
    }

    my $mbps = $arg{MegabitsPerSecond} || croak "No MegabitsPerSecond passed";
    my $bps = $mbps * 1024 * 1024 / 8;

    my $bucket = new Algorithm::TokenBucket $bps, 10240;
    ${*$self}{'tokenbucket'} = $bucket;
    return $self;
}

sub get {
    my ( $ftp, $remote, $local, $where ) = @_;
    my $bucket = ${*$ftp}{'tokenbucket'};

    my ( $loc, $len, $buf, $resp, $data );
    local *FD;

    my $localfd = ref($local) || ref( \$local ) eq "GLOB";

    ( $local = $remote ) =~ s#^.*/##
        unless ( defined $local );

    croak("Bad remote filename '$remote'\n")
        if $remote =~ /[\r\n]/s;

    ${*$ftp}{'net_ftp_rest'} = $where if defined $where;
    my $rest = ${*$ftp}{'net_ftp_rest'};

    delete ${*$ftp}{'net_ftp_port'};
    delete ${*$ftp}{'net_ftp_pasv'};

    $data = $ftp->retr($remote)
        or return undef;

    if ($localfd) {
        $loc = $local;
    } else {
        $loc = \*FD;

        unless (
            sysopen(
                $loc, $local,
                O_CREAT | O_WRONLY | ( $rest ? O_APPEND: O_TRUNC )
            )
            )
        {
            carp "Cannot open Local file $local: $!\n";
            $data->abort;
            return undef;
        }
    }

    if ( $ftp->type eq 'I' && !binmode($loc) ) {
        carp "Cannot binmode Local file $local: $!\n";
        $data->abort;
        close($loc) unless $localfd;
        return undef;
    }

    $buf = '';
    my ( $count, $hashh, $hashb, $ref ) = (0);

    ( $hashh, $hashb ) = @$ref
        if ( $ref = ${*$ftp}{'net_ftp_hash'} );

    my $blksize = ${*$ftp}{'net_ftp_blksize'};
    local $\;    # Just in case

    while (1) {
        last unless $len = $data->read( $buf, $blksize );

        sleep 0.01 until $bucket->conform($len);
        $bucket->count($len);

        if ( trEBCDIC && $ftp->type ne 'I' ) {
            $buf = $ftp->toebcdic($buf);
            $len = length($buf);
        }

        if ($hashh) {
            $count += $len;
            print $hashh "#" x ( int( $count / $hashb ) );
            $count %= $hashb;
        }
        unless ( print $loc $buf ) {
            carp "Cannot write to Local file $local: $!\n";
            $data->abort;
            close($loc)
                unless $localfd;
            return undef;
        }
    }

    print $hashh "\n" if $hashh;

    unless ($localfd) {
        unless ( close($loc) ) {
            carp "Cannot close file $local (perhaps disk space) $!\n";
            return undef;
        }
    }

    unless ( $data->close() )    # implied $ftp->response
    {
        carp "Unable to close datastream";
        return undef;
    }

    return $local;
}

sub _store_cmd {
    my ( $ftp, $cmd, $local, $remote ) = @_;
    my ( $loc, $sock, $len, $buf );
    local *FD;
    my $bucket = ${*$ftp}{'tokenbucket'};

    my $localfd = ref($local) || ref( \$local ) eq "GLOB";

    unless ( defined $remote ) {
        croak 'Must specify remote filename with stream input'
            if $localfd;

        require File::Basename;
        $remote = File::Basename::basename($local);
    }
    if ( defined ${*$ftp}{'net_ftp_allo'} ) {
        delete ${*$ftp}{'net_ftp_allo'};
    } else {

        # if the user hasn't already invoked the alloc method since the last
        # _store_cmd call, figure out if the local file is a regular file(not
        # a pipe, or device) and if so get the file size from stat, and send
        # an ALLO command before sending the STOR, STOU, or APPE command.
        my $size
            = do { local $^W; -f $local && -s _ }; # no ALLO if sending data from a pipe
        $ftp->_ALLO($size) if $size;
    }
    croak("Bad remote filename '$remote'\n")
        if $remote =~ /[\r\n]/s;

    if ($localfd) {
        $loc = $local;
    } else {
        $loc = \*FD;

        unless ( sysopen( $loc, $local, O_RDONLY ) ) {
            carp "Cannot open Local file $local: $!\n";
            return undef;
        }
    }

    if ( $ftp->type eq 'I' && !binmode($loc) ) {
        carp "Cannot binmode Local file $local: $!\n";
        return undef;
    }

    delete ${*$ftp}{'net_ftp_port'};
    delete ${*$ftp}{'net_ftp_pasv'};

    $sock = $ftp->_data_cmd( $cmd, $remote )
        or return undef;

    $remote = ( $ftp->message =~ /FILE:\s*(.*)/ )[0]
        if 'STOU' eq uc $cmd;

    my $blksize = ${*$ftp}{'net_ftp_blksize'};

    my ( $count, $hashh, $hashb, $ref ) = (0);

    ( $hashh, $hashb ) = @$ref
        if ( $ref = ${*$ftp}{'net_ftp_hash'} );

    while (1) {
        last unless $len = read( $loc, $buf = "", $blksize );

        sleep 0.01 until $bucket->conform($len);
        $bucket->count($len);

        if ( trEBCDIC && $ftp->type ne 'I' ) {
            $buf = $ftp->toascii($buf);
            $len = length($buf);
        }

        if ($hashh) {
            $count += $len;
            print $hashh "#" x ( int( $count / $hashb ) );
            $count %= $hashb;
        }

        my $wlen;
        unless ( defined( $wlen = $sock->write( $buf, $len ) )
            && $wlen == $len )
        {
            $sock->abort;
            close($loc)
                unless $localfd;
            print $hashh "\n" if $hashh;
            return undef;
        }
    }

    print $hashh "\n" if $hashh;

    close($loc)
        unless $localfd;

    $sock->close()
        or return undef;

    if ( 'STOU' eq uc $cmd
        and $ftp->message =~ m/unique\s+file\s*name\s*:\s*(.*)\)|"(.*)"/ )
    {
        require File::Basename;
        $remote = File::Basename::basename($+);
    }

    return $remote;
}

1;

__END__

=head1 NAME

Net::FTP::Throttle - Throttle FTP connections

=head1 SYNOPSIS

  my $ftp = Net::FTP::Throttle->new("some.host.name", MegabitsPerSecond => 2)
    or die "Cannot connect: $@";

  $ftp->login("username", 'password')
    or die "Cannot login ", $ftp->message;

  $ftp->cwd("/pub")
    or die "Cannot change working directory ", $ftp->message;

  $ftp->get("this.file")
    or die "get failed ", $ftp->message;

  $ftp->put("that.file")
    or die "put failed ", $ftp->message;

=head1 DESCRIPTION

L<Net::FTP> is a module implementing a simple FTP client in Perl as
described in RFC959. L<Net::FTP::Throttle> is a module which
subclasses L<Net::FTP> to add a throttling option, which allows you to
set the maximum bandwidth used.

As shown in the synopsis, this is passed into the contructor as a
value in megabits per second.

Currently only get and put requests are throttled.

=head1 AUTHOR

Leon Brocard <acme@astray.com>

=head1 COPYRIGHT

Copyright (C) 2005 Foxtons Ltd.

This module is free software; you can redistribute it or modify it
under the same terms as Perl itself.
