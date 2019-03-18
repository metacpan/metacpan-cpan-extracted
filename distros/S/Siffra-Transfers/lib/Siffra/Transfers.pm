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

use Term::ProgressBar;

#use Progress::Any '$progress';
#use Progress::Any::Output 'TermProgressBarColor';

$| = 1;    #autoflush

use constant {
    FALSE => 0,
    TRUE  => 1
};

#-------------------------------------------------------------------------------
# Tipos de protocolos suportados
#-------------------------------------------------------------------------------
my $supportedProtocols = {
    'FTP'   => TRUE,
    'SFTP'  => TRUE,
    'LOCAL' => TRUE
};

BEGIN
{
    require Siffra::Base;
    use Exporter ();
    use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
    $VERSION = '0.01';
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

    my $self = $class->SUPER::new( %parameters );

    $self->{ config } = {
        protocol      => undef,
        host          => undef,
        user          => undef,
        password      => undef,
        port          => undef,
        passive       => undef,
        identity_file => undef,
        debug         => undef,
        directories   => {},
    };

    $self->{ connection } = undef;
    $self->{ json }       = undef;

    $log->info( "new", { progname => $0, pid => $$, perl_version => $], package => __PACKAGE__ } );

    $self->_initialize( %parameters );

    return $self;
} ## end sub new

sub _initialize()
{
    my ( $self, %parameters ) = @_;
    $self->SUPER::_initialize( %parameters );
    $log->info( "_initialize", { package => __PACKAGE__ } );
}

sub END
{
    $log->info( "END", { package => __PACKAGE__ } );
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
my $setDirectories = sub {
    my ( $self, $value ) = @_;

    while ( my ( $remoteDirectory, $configuration ) = each( %{ $value } ) )
    {
        p $configuration;
    }
    return TRUE;
};

#################################################### Sets

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
    $self->$setDirectories( $parameters{ directories } );

    return $self->testConfig();
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
        $retorno = TRUE;
    }

} ## end sub connect

=head2 C<connectFTP()>
=cut

sub connectFTP()
{
    my ( $self, %parameters ) = @_;
}

=head2 C<connectSFTP()>
=cut

sub connectSFTP()
{
    my ( $self, %parameters ) = @_;
    my $remotePath = '/valid/upload/';
    my $localpath  = './download/';

    my %args = (
        user => 'valid',
        more => [ -o => 'StrictHostKeyChecking no' ],
    );

    push @{ $args{ more } }, '-v' if ( $self->{ config }->{ debug } );

    $self->{ connection } = eval {
        require Net::SFTP::Foreign;
        Net::SFTP::Foreign->new( $self->{ config }->{ host }, %args );
    };

    if ( $self->{ connection }->error )
    {
        $log->error( $self->{ connection }->error );
    }
    else
    {
        my $ls = $self->{ connection }->ls(
            $remotePath,
            wanted => sub {
                my $entry = $_[ 1 ];
                return ( $entry->{ a }->{ size } > 0 and $entry->{ filename } =~ /\.TXT$/i );
            }
        );

        my $callback = sub {
            my ( $sftp, $data, $offset, $size, $progress ) = @_;
            $offset = $size if ( $offset >= $size );
            $progress->update( $offset );
        };

        my $contador;
        foreach my $file ( @{ $ls } )
        {
            $contador++;

            my $progress = Term::ProgressBar->new(
                {
                    name   => $file->{ filename } . " ( $file->{ a }->{ size } ) ",
                    count  => $file->{ a }->{ size },
                    ETA    => 'linear',
                    remove => 1,
                }
            );
            $progress->minor( 0 );

            my %options = (
                callback => sub { &$callback( @_, $progress ); },
                mkpath   => 1
            );
            $self->{ connection }->get( $remotePath . $file->{ filename }, $localpath . $file->{ filename }, %options );

            if ( $self->{ connection }->error )
            {
                $log->error( $self->{ connection }->error );
            }
            else
            {
                $log->info( "Download do arquivo [ $file->{ filename } ] feito com sucesso..." );
            }

            last if $contador % 3 == 0;
        } ## end foreach my $file ( @{ $ls }...)

    } ## end else [ if ( $self->{ connection...})]

} ## end sub connectSFTP

=head2 C<connectLocal()>
=cut

sub connectLocal()
{
    my ( $self, %parameters ) = @_;
}

sub DESTROY
{
    my ( $self, %parameters ) = @_;
    $log->info( 'DESTROY', { package => __PACKAGE__, GLOBAL_PHASE => ${^GLOBAL_PHASE} } );
    return if ${^GLOBAL_PHASE} eq 'DESTRUCT';

    if ( blessed( $self ) && $self->isa( __PACKAGE__ ) )
    {
        $self->SUPER::DESTROY( %parameters );
        $log->alert( "DESTROY", { package => __PACKAGE__, GLOBAL_PHASE => ${^GLOBAL_PHASE}, blessed => 1 } );
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

