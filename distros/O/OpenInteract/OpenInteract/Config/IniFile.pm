package OpenInteract::Config::IniFile;

# $Id: IniFile.pm,v 1.50 2002/09/16 20:20:28 lachoy Exp $

use strict;
use base qw( OpenInteract::Config );
use OpenInteract::Config qw( _w DEBUG );
use OpenInteract::Config::Ini;

$OpenInteract::Config::IniFile::VERSION = sprintf("%d.%02d", q$Revision: 1.50 $ =~ /(\d+)\.(\d+)/);

use constant META_KEY => '_INI';

sub valid_keys {
    my ( $self ) = @_;
    return $self->sections;
    #return grep ! /^_/, keys %{ $self };
}


sub read_config {
    my ( $class, $filename ) = @_;
    $class->is_file_valid( $filename );
    return OpenInteract::Config::Ini->new({ filename => $filename });
}


# Cheeseball, but it works

sub write_config {
    my ( $self ) = @_;
    my $backup = $self;
    bless( $backup, 'OpenInteract::Config::Ini' );
    $backup->write_file;
}


1;
