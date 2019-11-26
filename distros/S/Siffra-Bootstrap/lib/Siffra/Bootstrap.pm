package Siffra::Bootstrap;

use 5.014;
use strict;
use warnings;
use utf8;
use Data::Dumper;
use DDP;
use Log::Any qw($log);
use Scalar::Util qw(blessed);
$Carp::Verbose = 1;

use Config::Any;
use IO::Prompter;

$| = 1;    #autoflush

use constant {
    FALSE => 0,
    TRUE  => 1,
    DEBUG => $ENV{ DEBUG } // 0,
};

BEGIN
{
    binmode( STDOUT, ":encoding(UTF-8)" );
    binmode( STDERR, ":encoding(UTF-8)" );

    require Siffra::Tools;
    use Exporter ();
    use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
    $VERSION = '0.08';
    @ISA     = qw(Siffra::Tools Exporter);

    #Give a hoot don't pollute, do not export more than needed by default
    @EXPORT      = qw();
    @EXPORT_OK   = qw();
    %EXPORT_TAGS = ();
} ## end BEGIN

#################### subroutine header begin ####################

=head2 sample_function

 Usage     : How to use this function/method
 Purpose   : What it does
 Returns   : What it returns
 Argument  : What it wants to know
 Throws    : Exceptions and other anomolies
 Comment   : This is a sample subroutine header.
           : It is polite to include more pod and fewer comments.

See Also   :

=cut

#################### subroutine header end ####################

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
    $log->debug( "new", { progname => $0, pid => $$, perl_version => $], package => __PACKAGE__ } );
    my ( $class, %parameters ) = @_;
    my $self = $class->SUPER::new( %parameters );

    $self->{ beachmarck } = {
        created  => $^T,
        started  => undef,
        finished => undef
    };

    $self->{ configurations } = \%parameters;

    $self->_initialize( %parameters );
    return $self;
} ## end sub new

sub _initialize()
{
    $log->debug( "_initialize", { package => __PACKAGE__ } );
    my ( $self, %parameters ) = @_;
    $self->SUPER::_initialize( %parameters );
}

sub _finalize()
{
    $log->debug( "_finalize", { package => __PACKAGE__ } );
    my ( $self, %parameters ) = @_;
    $self->SUPER::_finalize( %parameters );
}

=head2 C<loadApplication()>

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

sub loadApplication()
{
    my ( $self, %parameters ) = @_;
    $log->debug( "loadApplication", { package => __PACKAGE__ } );
    my $configurationFile = $self->{ configurations }->{ configurationFile };

    if ( !-e $configurationFile )
    {
        ( $configurationFile = $0 ) =~ s/\.pl/\-config\.json/;
        $log->error( "Não existe o arquivo de configuração...", { package => __PACKAGE__ } );

        if ( prompt 'Não existe o arquivo de configuração, deseja criar agora ?', -yn1, -default => 'y' )
        {
            my $config;

            $config->{ $configurationFile }->{ applicationName }   = prompt( 'Application Name     :', -v, -echostyle => 'bold white' );
            $config->{ $configurationFile }->{ applicationModule } = prompt( 'Application Module   :', -v, -echostyle => 'bold white' );
            $config->{ $configurationFile }->{ environment }       = prompt( 'Environment [desenv] :', -v, -echostyle => 'bold white', -default => 'desenv' );

            # Mail Config
            $config->{ $configurationFile }->{ mail } = {
                server => prompt( 'E-mail server [mail] :', -v, -echostyle => 'bold white', -default => 'mail' ),
                port   => prompt( 'E-mail port [25]     :', -v, -echostyle => 'bold white', -default => '25' ),
                debug  => prompt( 'E-mail debug [0]     :', -v, -echostyle => 'bold white', -default => '0' ),
                from   => prompt( 'E-mail from          :', -v, -echostyle => 'bold white' ),
            };

            my $json_text = $self->{ json }->pretty( 1 )->canonical( 1 )->encode( $config->{ $configurationFile } );

            open FH, ">", $configurationFile;
            print FH $json_text;
            close FH;
        } ## end if ( prompt 'Não existe o arquivo de configuração, deseja criar agora ?'...)
        else
        {
            return FALSE;
        }
    } ## end if ( !-e $configurationFile...)

    my @configFiles = ( $configurationFile );
    my $configAny   = Config::Any->load_files( { files => \@configFiles, flatten_to_hash => 1, use_ext => 1 } );

    foreach my $configFile ( keys %$configAny )
    {
        $self->{ configurations }->{ $_ } = $configAny->{ $configFile }->{ $_ } foreach ( keys %{ $configAny->{ $configFile } } );
    }

    $log->info( "Configurações lidas com sucesso na aplicação [ $self->{ configurations }->{ application }->{ name } ]..." );

    $log->error( 'Falta passar nome do package' ) if ( $self->{ configurations }->{ application }->{ package } !~ /^\D/ );

    eval "use $self->{ configurations }->{ application }->{ fileName };";    ## Usando o módulo.

    if ( $@ )
    {
        $log->error( "Problemas ao usar o arquivo [ $self->{ configurations }->{ application }->{ fileName } ]..." );
        return FALSE;
    }
    else
    {
        $self->{ application }->{ instance } = eval { $self->{ configurations }->{ application }->{ package }->new( bootstrap => $self ); };
        if ( !$self->{ application }->{ instance } )
        {
            $log->error( "Erro ao iniciar o módulo [ $self->{ configurations }->{ application }->{ package } ]..." );
            return FALSE;
        }
    } ## end else [ if ( $@ ) ]

    my $emailDispatcher = $log->{ adapter }->{ dispatcher }->{ outputs }->{ Email };

    if ( $emailDispatcher )
    {
        my $mailConf = $self->{ configurations }->{ mail };

        if ( $mailConf )
        {
            eval { require DateTime; };
            $emailDispatcher->{ to }      = [ $mailConf->{ to } ];
            $emailDispatcher->{ from }    = $mailConf->{ from };
            $emailDispatcher->{ host }    = $mailConf->{ host };
            $emailDispatcher->{ port }    = $mailConf->{ port };
            $emailDispatcher->{ subject } = "[ " . DateTime->now()->datetime( ' ' ) . " ] " . $self->{ configurations }->{ application }->{ name };
        } ## end if ( $mailConf )

    } ## end if ( $emailDispatcher ...)

    return TRUE;
} ## end sub loadApplication

=head2 C<run()>
=cut

sub run
{
    my ( $self, %parameters ) = @_;
    my $retorno = {};

    if ( ref $self->{ application }->{ instance } eq $self->{ configurations }->{ application }->{ package } )
    {
        $self->{ beachmarck }->{ started }  = time();
        $retorno                            = eval { $self->{ application }->{ instance }->start(); };
        $self->{ beachmarck }->{ finished } = time();
        $log->error( "Problemas durante execucao de start: $@" ) if ( $@ );
    } ## end if ( ref $self->{ application...})
    else
    {
        $log->error( "Impossivel de executar $self->{ configurations }->{ application }->{ package }::start\nSub nao existe" );
    }

    return $retorno;
} ## end sub run

=head2 C<getExecutionTime()>
=cut

sub getExecutionTime()
{
    my ( $self, %parameters ) = @_;
    return ( ( $self->{ beachmarck }->{ finished } // 0 ) - ( $self->{ beachmarck }->{ started } // 0 ) );
}

=head2 C<getExecutionInfo()>
=cut

sub getExecutionInfo()
{
    my ( $self, %parameters ) = @_;

    $log->info( "Quantidade de erro(s): 0" );
    $log->info( "Tempo de execucao: " . $self->getExecutionTime() . " segundo(s)" );
    $log->info( "Fim da aplicacao." );
} ## end sub getExecutionInfo

sub END
{
    $log->debug( "END", { package => __PACKAGE__ } );
    my ( $self, %parameters ) = @_;
    eval { $log->{ adapter }->{ dispatcher }->{ outputs }->{ Email }->flush; };
}

sub DESTROY
{
    my ( $self, %parameters ) = @_;
    if ( ${^GLOBAL_PHASE} eq 'DESTRUCT' )
    {
        $self->getExecutionInfo() if ( blessed( $self ) && $self->isa( __PACKAGE__ ) );
        return;
    }

    if ( blessed( $self ) && $self->isa( __PACKAGE__ ) )
    {
        $log->debug( "DESTROY", { package => __PACKAGE__, GLOBAL_PHASE => ${^GLOBAL_PHASE}, blessed => TRUE } );
    }
    else
    {
        $log->debug( 'DESTROY', { package => __PACKAGE__, GLOBAL_PHASE => ${^GLOBAL_PHASE}, blessed => FALSE } );
    }

    Siffra::Bootstrap->SUPER::DESTROY;
} ## end sub DESTROY

#################### main pod documentation begin ###################
## Below is the stub of documentation for your module.
## You better edit it!

=encoding UTF-8


=head1 NAME

Siffra::Bootstrap - Module abstract (<= 44 characters) goes here

=head1 SYNOPSIS

  use Siffra::Bootstrap;
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

__DATA__