#!/usr/bin/perl

# example-application for Netx::WebRadio

package Netx::WebRadio::Station::Shoutcast::FileWriter;
use Netx::WebRadio::Station::Shoutcast;
@Netx::WebRadio::Station::Shoutcast::FileWriter::ISA = ('Netx::WebRadio::Station::Shoutcast');
use strict;
use warnings;
use Carp;

sub init {
	my $self = shift;
	$self->SUPER::init(@_);
}

sub process_chunk {
	my $self = shift;
	my $chunk = shift || croak "no chunk\n".(caller())[2];
	my $fh = $self->{ _fh } || croak "no filehandle\n";
	print $fh $chunk;
}

sub process_new_title {
	my ($self,$title) = @_;
	my $oldTitle = $self->{ _actualTitle } || '';
	return if $oldTitle eq $title;
	croak "no title" unless $title;
	
	my $path = $self->{ _savepath } || '';
	
	my $filename = '';
	if ($self->{ _fh }) {
		$self->close_old_file;
		$filename = $title.'.mp3';
	} else {
		$filename = "!! incomplete !! ".$title.'.mp3';	
	}
	$filename =~ s/\\/-/g;	
	my $fh;
	open ($fh, ">$path$filename") or croak "could not create file $path$filename: $!\n";
	$self->{ _fh } = $fh;
	
	$self->{ _actualTitle } = $title;
	$self->{ _actualFilename } = $filename;
	print $self->stationname()."\n\t\tnew Title:".$title,"\n";
}

sub close_old_file {
	my $self = shift;
	my $title = $self->{_actualTitle};
	my $filename = $self->{ _actualFilename };
	my ($artist, $song) = $title =~ /(.*?) - (.*)/;
	close $self->{ _fh } if $self->{ _fh };
	$self->setMP3Tag( $filename, $artist, $song );
	return;
}

sub disconnected {
	my $self = shift;
	$self->close_old_file();
}

sub setMP3Tag {
	my $self = shift;
	my ($filename, $artist, $song) = @_;
	return unless $filename;
	use MP3::Tag;
	my $mp3 = MP3::Tag->new( $filename );
	unless ( exists $mp3->{ ID3v1 } ) {
		$mp3->new_tag( 'ID3v1' );
	}
	my $id3v1 = $mp3->{ ID3v1 };
	$id3v1->all( $song, $artist, '',2003,'',0,'' );
	$id3v1->write_tag();
	
}
