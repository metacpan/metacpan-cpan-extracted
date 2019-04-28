package Siffra::Transfers;

use 5.014;
use strict;
use warnings;
use Carp;
use utf8;
use Data::Dumper;
use DDP;
use Log::Any qw($log);
use Scalar::Util qw(blessed);
$Carp::Verbose = 1;

$| = 1;    #autoflush

use constant {
    FALSE => 0,
    TRUE  => 1,
    DEBUG => $ENV{ DEBUG } // 0,
};

use Term::ProgressBar;

#-------------------------------------------------------------------------------
# Tipos de protocolos suportados
#-------------------------------------------------------------------------------
my $supportedProtocols = {
    'FTP'   => TRUE,
    'SFTP'  => TRUE,
    'LOCAL' => TRUE
};

#-------------------------------------------------------------------------------
# Tipos de MIMI-Types suportados
#-------------------------------------------------------------------------------
my $supported_mimi_types = {
    'application/x-tar-gz'         => FALSE,          # .tar.gz
    'application/x-bzip'           => FALSE,          # .bz2
    'application/zip'              => 'unZipFile',    # .zip
    'application/x-rar-compressed' => FALSE,          # .rar
    'application/x-tar'            => FALSE,          # .tar
    'application/pdf'              => FALSE,          # .pdf
                                                      # este não existe MIME Type, mas usem este:
    'deltax/tar-bz2'               => FALSE,          # tar.bz2
};

BEGIN
{
    binmode( STDOUT, ":encoding(UTF-8)" );
    binmode( STDERR, ":encoding(UTF-8)" );

    require Siffra::Base;
    use Exporter ();
    use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
    $VERSION = '0.03';
    @ISA     = qw(Siffra::Base Exporter);

    #Give a hoot don't pollute, do not export more than needed by default
    @EXPORT      = qw();
    @EXPORT_OK   = qw();
    %EXPORT_TAGS = ();
} ## end BEGIN

=head2 C<new()>

  Usage     : $self->block_new_method() within text_pm_file()
  Purpose   : Build 'new()' method as part of a pm file
  Returns   : String holding sub new.
  Argument  : $module: pointer to the module being built
              (as there can be more than one module built by EU::MM);
              for the primary module it is a pointer to $self
  Throws    : n/a
  Comment   : This method is a likely candidate for alteration in a subclass,
              e.g., pass a single hash-ref to new() instead of a list of
              parameters.

=cut

sub new
{
    my ( $class, %parameters ) = @_;
    $log->debug( "new", { progname => $0, pid => $$, perl_version => $], package => __PACKAGE__ } );

    my $self = $class->SUPER::new( %parameters );

    $self->{ config } = {
        protocol       => undef,
        host           => undef,
        user           => undef,
        password       => undef,
        port           => undef,
        passive        => undef,
        identity_file  => undef,
        debug          => undef,
        localDirectory => undef,
        directories    => {},
    };

    $self->{ connection } = undef;
    $self->{ json }       = undef;

    $self->_initialize( %parameters );

    return $self;
} ## end sub new

sub _initialize()
{
    my ( $self, %parameters ) = @_;
    $self->SUPER::_initialize( %parameters );
    $log->debug( "_initialize", { package => __PACKAGE__ } );
}

sub END
{
    $log->debug( "END", { package => __PACKAGE__ } );
    eval { $log->{ adapter }->{ dispatcher }->{ outputs }->{ Email }->flush; };
}

#################################################### Sets

my $setProtocol = sub {
    my ( $self, $value ) = @_;
    return FALSE unless ( $supportedProtocols->{ uc( $value ) } );
    return $self->{ config }->{ protocol } = uc( $value );
};
my $setHost = sub {
    my ( $self, $value ) = @_;
    return $self->{ config }->{ host } = $value;
};
my $setUser = sub {
    my ( $self, $value ) = @_;
    return $self->{ config }->{ user } = $value;
};
my $setPassword = sub {
    my ( $self, $value ) = @_;
    return $self->{ config }->{ password } = $value;
};
my $setPort = sub {
    my ( $self, $value ) = @_;
    return $self->{ config }->{ port } = $value;
};
my $setDebug = sub {
    my ( $self, $value ) = @_;
    return $self->{ config }->{ debug } = $value;
};
my $setPassive = sub {
    my ( $self, $value ) = @_;
    return $self->{ config }->{ passive } = $value;
};
my $setIdentityFile = sub {
    my ( $self, $value ) = @_;
    return $self->{ config }->{ identity_file } = $value;
};
my $setLocalDirectory = sub {
    my ( $self, $value ) = @_;
    return $self->{ config }->{ localDirectory } = ( $value // './download/' );
};
my $setDirectories = sub {
    my ( $self, $value ) = @_;

    while ( my ( $remoteDirectory, $configuration ) = each( %{ $value } ) )
    {
        $configuration->{ remoteDirectory } = $remoteDirectory;
        return FALSE unless $self->addDirectory( $configuration );
    }
    return TRUE;
};

#################################################### Sets

=head2 C<addDirectory()>
=cut

#-------------------------------------------------------------------------------
# Adiciona uma configuracao para upload
#-------------------------------------------------------------------------------
sub addDirectory
{
    my ( $self, $configuration ) = @_;
    $self->{ config }->{ directories }->{ $configuration->{ remoteDirectory } } = $configuration;
    return TRUE;
}

=head2 C<cleanDirectories()>
=cut

#-------------------------------------------------------------------------------
# Limpa os directories
#-------------------------------------------------------------------------------
sub cleanDirectories
{
    my ( $self ) = @_;
    return $self->{ config }->{ directories } = {};
}

=head2 C<setConfig()>
=cut

sub setConfig()
{
    my ( $self, %parameters ) = @_;

    $self->$setProtocol( $parameters{ protocol } );
    $self->$setHost( $parameters{ host } );
    $self->$setUser( $parameters{ user } );
    $self->$setPassword( $parameters{ password } );
    $self->$setPort( $parameters{ port } );
    $self->$setDebug( $parameters{ debug } );
    $self->$setPassive( $parameters{ passive } );
    $self->$setIdentityFile( $parameters{ identity_file } );
    $self->$setLocalDirectory( $parameters{ localDirectory } );
    $self->$setDirectories( $parameters{ directories } );

    return $self->testConfig( %parameters );
} ## end sub setConfig

=head2 C<testConfig()>
=cut

sub testConfig()
{
    my ( $self, %parameters ) = @_;

    return TRUE;
}

=head2 C<connect()>
=cut

sub connect()
{
    my ( $self, %parameters ) = @_;

    return FALSE unless $self->testConfig();

    my $retorno = FALSE;

    if ( uc $self->{ config }->{ protocol } eq 'FTP' )
    {
        $retorno = $self->connectFTP( %parameters );
    }
    elsif ( uc $self->{ config }->{ protocol } eq 'SFTP' )
    {
        $retorno = $self->connectSFTP( %parameters );
    }
    elsif ( uc $self->{ config }->{ protocol } eq 'LOCAL' )
    {
        $retorno = $self->connectLocal( %parameters );
    }

    return $retorno;
} ## end sub connect

=head2 C<connectFTP()>
=cut

sub connectFTP()
{
    my ( $self, %parameters ) = @_;

    eval { require Net::FTP; };

    if ( $@ )
    {
        $log->error( "Erro ao usar o módulo [ Net::FTP ]..." . $@ );
        return FALSE;
    }

    my %args = (
        Host    => $self->{ config }->{ host },
        Port    => $self->{ config }->{ port } // 21,
        Debug   => $self->{ config }->{ debug },
        Passive => $self->{ config }->{ passive } // 1,
    );

    $self->{ connection } = Net::FTP->new( %args );

    if ( $@ )
    {
        $log->error( "Erro ao conectar no FTP [ $args{Host}\:$args{Port} ] ... [ $@ ]" );
        return FALSE;
    }

    if ( $self->{ connection } )
    {
        my $user     = $self->{ config }->{ user };
        my $password = $self->{ config }->{ password };
        if ( !$self->{ connection }->login( $user, $password ) )
        {
            $log->error( $self->{ connection }->message );
            return FALSE;
        }
        else
        {
            $log->info( "Logged on [ ${user}\@$args{Host} ]..." );
            return TRUE;
        }

    } ## end if ( $self->{ connection...})
    else
    {
        $log->error( "Não foi possível criar o objeto FTP..." );
        return FALSE;
    }
} ## end sub connectFTP

=head2 C<connectSFTP()>
=cut

sub connectSFTP()
{
    my ( $self, %parameters ) = @_;

    eval { require Net::SFTP::Foreign; };

    if ( $@ )
    {
        $log->error( "Erro ao usar o módulo [ Net::SFTP::Foreign ]..." . $@ );
        return FALSE;
    }

    my %args = (
        host     => $self->{ config }->{ host },
        user     => $self->{ config }->{ user },
        password => $self->{ config }->{ password },
        port     => $self->{ config }->{ port } // 22,
        autodie  => 0,
        more     => [
            -o => 'StrictHostKeyChecking no',
            -o => 'HostKeyAlgorithms +ssh-dss',
        ],
    );

    push @{ $args{ key_path } }, $self->{ config }->{ identity_file } if $self->{ config }->{ identity_file };
    push @{ $args{ more } }, '-v' if ( $self->{ config }->{ debug } );

    $self->{ connection } = eval { Net::SFTP::Foreign->new( %args ); };

    if ( $@ )
    {
        $log->error( $@ );
        return FALSE;
    }
    elsif ( $self->{ connection }->error )
    {
        $log->error( $self->{ connection }->error );
        return FALSE;
    }

    return TRUE;
} ## end sub connectSFTP

=head2 C<connectLocal()>
=cut

sub connectLocal()
{
    my ( $self, %parameters ) = @_;

    return TRUE;
}

=head2 C<getActiveDirectory()>
=cut

#-------------------------------------------------------------------------------
# Pega o diretorio atual
#-------------------------------------------------------------------------------
sub getActiveDirectory()
{
    my ( $self ) = @_;

    $self->{ config }->{ activeDirectory } = $self->{ config }->{ activeDirectory } ? $self->{ config }->{ activeDirectory } : '/';

    return $self->{ config }->{ activeDirectory };
} ## end sub getActiveDirectory

=head2 C<setActiveDirectory()>
=cut

#-------------------------------------------------------------------------------
# Pega o diretorio atual
#-------------------------------------------------------------------------------
sub setActiveDirectory()
{
    my ( $self, $directory ) = @_;

    return $self->{ config }->{ activeDirectory } = $directory;
}

=head2 C<getFiles()>
=cut

sub getFiles
{
    my ( $self, %parameters ) = @_;

    return FALSE unless ( $self->testConfig() );

    my $getFilesFunctions = {
        'FTP'   => 'getFilesFTP',
        'SFTP'  => 'getFilesSFTP',
        'LOCAL' => 'getFilesLOCAL'
    };

    my $protocol = uc $self->{ config }->{ protocol };
    my $subName;

    if ( !$getFilesFunctions->{ $protocol } )
    {
        $log->error( "SUB getFiles para o protocolo [ $protocol ] não existe." );
        return FALSE;
    }
    else
    {
        $subName = $getFilesFunctions->{ $protocol };
    }

    my $retorno = {};

    while ( my ( $directory, $directoryConfiguration ) = each( %{ $self->{ config }->{ directories } } ) )
    {
        $self->setActiveDirectory( $directory );

        $retorno->{ $directory } = $self->$subName( %parameters );

        if ( ( ref $retorno->{ $directory } eq 'HASH' ) && ( $retorno->{ $directory }->{ error } == 0 ) && ( $directoryConfiguration->{ 'unpack' } ) )
        {
            foreach my $file ( @{ $retorno->{ $directory }->{ files } } )
            {
                if ( ref $file eq 'HASH' && $file->{ error } == 0 )
                {
                    $file->{ 'unpack' } = $self->unPackFile( conf => $directoryConfiguration, file => $file );
                }

            } ## end foreach my $file ( @{ $retorno...})

        } ## end if ( ( ref $retorno->{...}))

    } ## end while ( my ( $directory, ...))

    return $retorno;
} ## end sub getFiles

=head2 C<getFilesFTP()>
=cut

sub getFilesFTP()
{
    my ( $self, %parameters ) = @_;

    return TRUE;
}

=head2 C<getFilesSFTP()>
=cut

sub getFilesSFTP()
{
    my ( $self, %parameters ) = @_;

    my $retorno = {
        error              => 0,
        message            => 'ok',
        downloadedFiles    => [],
        notDownloadedFiles => []
    };

    my $remoteDirectory = $self->getActiveDirectory();
    my $configuration   = $self->{ config }->{ directories }->{ $remoteDirectory };
    my $localDirectory  = $self->{ config }->{ localDirectory };                      #'./download/';

    $log->info( "Entrando em [ getFilesSFTP ] para o diretório [ $remoteDirectory ]..." );

    my $ls = $self->{ connection }->ls(
        $remoteDirectory,
        wanted => sub {
            my $entry = $_[ 1 ];
            return ( $entry->{ a }->{ size } > 0 and ( $entry->{ filename } =~ qr/$configuration->{ fileNameRule }/i ) and ref $configuration->{ downloadedFiles } eq 'HASH' and !$configuration->{ downloadedFiles }->{ $entry->{ filename } } );
        }
    );

    my $callback = sub {
        my ( $sftp, $data, $offset, $size, $progress ) = @_;
        $offset = $size if ( $offset >= $size );
        $progress->update( $offset );
    };

    foreach my $remoteFile ( @{ $ls } )
    {
        my $progress = Term::ProgressBar->new(
            {
                name   => $remoteFile->{ filename } . " ( $remoteFile->{ a }->{ size } ) ",
                count  => $remoteFile->{ a }->{ size },
                ETA    => 'linear',
                remove => 1,
            }
        );
        $progress->minor( 0 );

        my %options = ( callback => sub { &$callback( @_, $progress ); }, mkpath => 1 );
        $self->{ connection }->get( $remoteDirectory . $remoteFile->{ filename }, $localDirectory . $remoteFile->{ filename }, %options );

        my $downloadedFile = {
            error    => FALSE,
            message  => undef,
            filename => $remoteFile->{ filename },
            size     => $remoteFile->{ a }->{ size },
            md5sum   => undef,
            filePath => $localDirectory . $remoteFile->{ filename },
        };

        if ( $self->{ connection }->error )
        {
            $log->error( $self->{ connection }->error );
            $downloadedFile->{ error }   = TRUE;
            $downloadedFile->{ message } = $self->{ connection }->error;
        } ## end if ( $self->{ connection...})
        else
        {
            $downloadedFile->{ md5sum } = $self->getFileMD5( file => $localDirectory . $remoteFile->{ filename } );
            $downloadedFile->{ message } = 'Ok';
            $log->info( "Download do arquivo [ $downloadedFile->{ filename } ] feito com sucesso..." );
        } ## end else [ if ( $self->{ connection...})]

        push( @{ $retorno->{ downloadedFiles } }, $downloadedFile );
    } ## end foreach my $remoteFile ( @{...})

    return $retorno;
} ## end sub getFilesSFTP

=head2 C<getFilesLOCAL()>
=cut

sub getFilesLOCAL()
{
    my ( $self, %parameters ) = @_;
    return TRUE;
}

=head2 C<getFileMD5()>
=cut

#-------------------------------------------------------------------------------
# Retorna o MD5 do arquivo
# Parametro 1 - Caminho e nome do arquivo a ser calculado
# Retorna o MD5 do arquivo informado
#-------------------------------------------------------------------------------
sub getFileMD5()
{
    my ( $self, %parameters ) = @_;
    my $file = $parameters{ file };
    my $retorno;

    return FALSE unless ( -e $file );

    require Digest::MD5;

    open( my $fh, '<', $file ) or croak( "Can't open '$file': $!" );
    binmode( $fh );
    $retorno = Digest::MD5->new->addfile( $fh )->hexdigest;
    close( $fh );

    return $retorno;
} ## end sub getFileMD5

#-------------------------------------------------------------------------------
# Descompacta arquivos
#-------------------------------------------------------------------------------

=head2 C<unPackFile()>
=cut

sub unPackFile()
{
    my ( $self, %parameters ) = @_;
    my $mmt = $parameters{ conf }{ 'MIMI-Type' };

    my $files = [];
    if ( !$supported_mimi_types->{ $mmt } == FALSE )
    {
        my $unPackParam = {
            fileName => $parameters{ file }{ file_path },
            out_path => $parameters{ conf }{ unpackDirectory }
        };

        my $subname = $supported_mimi_types->{ $mmt };
        $files = $self->$subname( $unPackParam );

    } ## end if ( !$supported_mimi_types...)
    else
    {
        return { message => "MIMI-Type $mmt não suportado", error => 1 };
    }

    return { error => 0, files => $files };
} ## end sub unPackFile

#-------------------------------------------------------------------------------
# Descompacta arquivos ZIP
#-------------------------------------------------------------------------------

=head2 C<unZipFile()>
=cut

sub unZipFile()
{

    my ( $self, $param ) = @_;

    my $cmd   = "unzip -o -b \"$param->{fileName}\" -d \"$param->{out_path}\"";
    my @files = `$cmd`;

    my $unpack = [];

    foreach ( @files )
    {
        next unless ( $_ =~ /inflating:\s(.+)$/ );
        my $fileName = $1;
        $fileName =~ s/(^\s*)|(\s*$)//g;
        push( @{ $unpack }, $fileName );

    } ## end foreach ( @files )

    return $unpack;
} ## end sub unZipFile

sub DESTROY
{
    my ( $self, %parameters ) = @_;
    $log->debug( 'DESTROY', { package => __PACKAGE__, GLOBAL_PHASE => ${^GLOBAL_PHASE}, blessed => FALSE } );
    return if ${^GLOBAL_PHASE} eq 'DESTRUCT';

    if ( blessed( $self ) && $self->isa( __PACKAGE__ ) )
    {
        $self->SUPER::DESTROY( %parameters );
        $log->debug( "DESTROY", { package => __PACKAGE__, GLOBAL_PHASE => ${^GLOBAL_PHASE}, blessed => TRUE } );
    }
    else
    {
        # TODO
    }
} ## end sub DESTROY

#################### main pod documentation begin ###################
## Below is the stub of documentation for your module.
## You better edit it!

=encoding UTF-8


=head1 NAME

Siffra::Transfers - File transfers module

=head1 SYNOPSIS

  use Siffra::Transfers;
  blah blah blah


=head1 DESCRIPTION

Stub documentation for this module was created by ExtUtils::ModuleMaker.
It looks like the author of the extension was negligent enough
to leave the stub unedited.

Blah blah blah.


=head1 USAGE



=head1 BUGS



=head1 SUPPORT



=head1 AUTHOR

    Luiz Benevenuto
    CPAN ID: LUIZBENE
    Siffra TI
    luiz@siffra.com.br
    https://siffra.com.br

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.


=head1 SEE ALSO

perl(1).

=cut

#################### main pod documentation end ###################

1;

# The preceding line will help the module return a true value

