#$Id: gzip.pm 517 2009-10-23 15:52:21Z maj $

package PerlIO::via::gzip;
use strict;
use warnings;
use PerlIO;
use IO::Compress::Gzip qw(:constants);
use IO::Uncompress::Gunzip;
use Carp;
our $VERSION = '0.03';
our $COMPRESSION_LEVEL = Z_DEFAULT_COMPRESSION;
our $COMPRESSION_STRATEGY = Z_DEFAULT_STRATEGY;
our $BLOCK_SIZE = 4096;
our $INSTANCE = 128;

sub PUSHED { 
    no strict qw(refs);
    my ($class, $mode) = @_;
    my $stat;
    my $self = { 
        instance => $INSTANCE++
    };
    $mode =~ s/\+//;
    $self->{mode} = $mode;
    bless $self, $_[0];
}


# open hook
sub FILENO {
    my ($self, $fh) = @_;
    if ( !defined $self->{inited} ) {
	my $via = grep (/via/, PerlIO::get_layers($fh));
	my $compress = ($self->{mode} =~ /w|a/ and !$via) ||
	($self->{mode} =~ /r/ and $via);
	$self->{fileno} = fileno($fh); # nec. to kick fileno hooks
	$self->{inited} = 1;
	if ($compress) {
	    $self->{gzip} = IO::Compress::Gzip->new(
		$fh,
		AutoClose => 1,
		Level => $COMPRESSION_LEVEL,
		Strategy => $COMPRESSION_STRATEGY,
		);
	    croak "via(gzip) [OPEN]: Couldn't create compression stream" unless ($self->{gzip});
	    $self->{gzip}->autoflush(1);
	}
	else {
	    $self->{gunzip} = IO::Uncompress::Gunzip->new(
		$fh,
		BlockSize => $BLOCK_SIZE
		);

	    croak "via(gzip) [OPEN]: Couldn't create decompression stream" unless ($self->{gunzip});
	}

    }
    $self->{fileno};
}

sub FILL {
    my ($self, $fh) = @_;
    return $self->Readline($fh);
}

sub Readline {
    my $self = shift;
    if ($self->{gzip}) {
	return $self->{gzip}->getline;
    }
    elsif ($self->{gunzip}) {
	return $self->{gunzip}->getline;
    }
    else {
	croak "via(gzip) [FILL]: handle not initialized";
    }
}

sub WRITE {
    my ($self, $buf, $fh) = @_;
    return $self->Write($fh, $buf);
}

sub Write {
    my ($self, $fh, $buf) = @_;
    my $ret;
    if ($self->{gunzip}) {
	return $self->{gunzip}->write($buf);
    }
    elsif ($self->{gzip}) {
	return $self->{gzip}->print($buf);
    }
    else {
	croak "via(gzip) [WRITE]: handle not initialized";
    }
}

sub FLUSH {
     my ($self, $fh) = @_;
     return -1 unless $self->{inited} == 1; # not open yet
     $fh && $fh->flush;
     if ($self->{gzip}) {
        $self->{gzip}->flush;
	# to get a valid gzip file, the Gzip handle must 
	# be closed before the source handle. 
	# if FLUSH is called on via handle close, 
	# the source handle is closed before we 
	# can get to it in via::gzip::CLOSE.
	# So we are closing the Gzip handle here.
	$self->{gzip}->close;
	1;
     }
     return 0;
 }

sub CLOSE {
    my ($self, $fh) = @_;
    return -1 unless $self->{inited}; # not open yet
    if ($self->{gzip}) {
	# the $self->{gzip} handle was already flushed and 
	# closed by FLUSH
	return $fh ? $fh->close : 0;
    }
    else {
	$self->{gunzip}->close;
	return $fh->close if $fh;
    }
}

1;
__END__

=pod 

=head1 NAME

PerlIO::via::gzip - PerlIO layer for gzip (de)compression

=head1 SYNOPSIS

 # compress
 open( $cfh, ">:via(gzip)", 'stdout.gz' );
 print $cfh @stuff;

 # decompress
 open( $fh, "<:via(gzip)", "stuff.gz" );
 while (<$fh>) {
    ...
 }

=head1 DESCRIPTION

This module provides a PerlIO layer for transparent gzip de/compression,
using L<IO::Compress::Gzip> and L<IO::Uncompress::Gunzip>. 

=head1 Changing compression parameters

On write, compression level and strategy default to the defaults specified in 
L<IO::Compress::Gzip>. To hack these, set

 $PerlIO::via::gzip::COMPRESSION_LEVEL

and

 $PerlIO::via::gzip::COMPRESSION_STRATEGY

to the desired constants, as imported from L<IO::Compress::Gzip>.

=head1 NOTE

When a C<PerlIO::via::gzip> write handle is flushed, the underlying
IO::Compress::Gzip handle is flushed and closed. This appears to be
necessary for getting a valid gzip file when a C<PerlIO::via::gzip>
write handle is closed. See comment in the FLUSH source.

=head1 SEE ALSO

L<PerlIO|perlio>, L<PerlIO::via>, L<IO::Compress::Gzip>, L<IO::Uncompress::Gunzip>

=head1 AUTHOR - Mark A. Jensen

 Email maj -at- cpan -dot- org
 http://fortinbras.us

=cut


