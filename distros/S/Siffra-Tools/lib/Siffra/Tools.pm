package Siffra::Tools;

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

my %driverConnections = (
    pgsql => {
        module => 'DBD::Pg',
        dsn    => 'DBI:Pg(AutoCommit=>1,RaiseError=>1,PrintError=>1):dbname=%s;host=%s;port=%s',
    },
    mysql => {
        module => 'DBD::mysql',
    },
    sqlite => {
        module => 'DBD::SQLite',
    },
);

BEGIN
{
    binmode( STDOUT, ":encoding(UTF-8)" );
    binmode( STDERR, ":encoding(UTF-8)" );

    require Siffra::Base;
    use Exporter ();
    use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
    $VERSION = '0.14';
    @ISA     = qw(Siffra::Base Exporter);

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

    return $self;
} ## end sub new

sub _initialize()
{
    $log->debug( "_initialize", { package => __PACKAGE__ } );
    my ( $self, %parameters ) = @_;
    $self->SUPER::_initialize( %parameters );

    eval { require JSON::XS; };
    $self->{ json } = JSON::XS->new->utf8;
} ## end sub _initialize

sub _finalize()
{
    $log->debug( "_finalize", { package => __PACKAGE__ } );
    my ( $self, %parameters ) = @_;
    $self->SUPER::_finalize( %parameters );
}

sub END
{
    $log->debug( "END", { package => __PACKAGE__ } );
    eval { $log->{ adapter }->{ dispatcher }->{ outputs }->{ Email }->flush; };
}

sub DESTROY
{
    my ( $self, %parameters ) = @_;
    $log->debug( 'DESTROY', { package => __PACKAGE__, GLOBAL_PHASE => ${^GLOBAL_PHASE}, blessed => FALSE } );
    return if ${^GLOBAL_PHASE} eq 'DESTRUCT';

    if ( blessed( $self ) && $self->isa( __PACKAGE__ ) )
    {
        $log->debug( "DESTROY", { package => __PACKAGE__, GLOBAL_PHASE => ${^GLOBAL_PHASE}, blessed => TRUE } );
    }
    else
    {
        # TODO
    }
} ## end sub DESTROY

=head2 C<connectDB()>
=cut

sub connectDB()
{
    my ( $self, %parameters ) = @_;
    $log->debug( "connectDB", { package => __PACKAGE__ } );

    my ( $database, $host, $password, $port, $username, $connection );

    if ( %parameters )
    {
        $connection = $parameters{ connection };
        $database   = $parameters{ database };
        $host       = $parameters{ host };
        $password   = $parameters{ password };
        $port       = $parameters{ port };
        $username   = $parameters{ username };
    } ## end if ( %parameters )
    elsif ( defined $self->{ configurations }->{ database } )
    {
        $connection = $self->{ configurations }->{ database }->{ connection };
        $database   = $self->{ configurations }->{ database }->{ database };
        $host       = $self->{ configurations }->{ database }->{ host };
        $password   = $self->{ configurations }->{ database }->{ password };
        $port       = $self->{ configurations }->{ database }->{ port };
        $username   = $self->{ configurations }->{ database }->{ username };
    } ## end elsif ( defined $self->{ ...})
    else
    {
        $log->error( "Tentando conectar mas sem configuração de DB..." );
        return FALSE;
    }

    my $driverConnection = $driverConnections{ lc $connection };
    if ( $driverConnection )
    {
        eval {
            require DBI;
            require "$driverConnection->{ module }";
        };

        my $dsn = sprintf( $driverConnection->{ dsn }, $database, $host, $port );
        my ( $scheme, $driver, $attr_string, $attr_hash, $driver_dsn ) = DBI->parse_dsn( $dsn ) or die "Can't parse DBI DSN '$dsn'";
        my $data_source = "$scheme:$driver:$driver_dsn";
        $self->{ database }->{ connection } = eval { DBI->connect( $data_source, $username, $password, $attr_hash ); };

        if ( $@ )
        {
            $log->error( "Erro ao conectar ao banco [ $data_source ] [ $username\@$host:$port ]." );
            $log->error( @_ );
            return FALSE;
        } ## end if ( $@ )
    } ## end if ( $driverConnection...)
    else
    {
        $log->error( "Connection [ $connection ] não existe configuração..." );
        return FALSE;
    }

    return $self->{ database }->{ connection };
} ## end sub connectDB

=head2 C<begin_work()>
=cut

sub begin_work()
{
    my ( $self, %parameters ) = @_;
    if ( !defined $self->{ database }->{ connection } )
    {
        $log->error( "Tentando começar uma transação sem uma conexão com DB..." );
        return FALSE;
    }
    my $rc = $self->{ database }->{ connection }->begin_work or die $self->{ database }->{ connection }->errstr;
    return $rc;
} ## end sub begin_work

=head2 C<commit()>
=cut

sub commit()
{
    my ( $self, %parameters ) = @_;
    if ( !defined $self->{ database }->{ connection } )
    {
        $log->error( "Tentando commitar uma transação sem uma conexão com DB..." );
        return FALSE;
    }
    my $rc = $self->{ database }->{ connection }->commit or die $self->{ database }->{ connection }->errstr;
    return $rc;
} ## end sub commit

=head2 C<rollback()>
=cut

sub rollback()
{
    my ( $self, %parameters ) = @_;
    if ( !defined $self->{ database }->{ connection } )
    {
        $log->error( "Tentando reverter uma transação sem uma conexão com DB..." );
        return FALSE;
    }
    my $rc = $self->{ database }->{ connection }->rollback or die $self->{ database }->{ connection }->errstr;
    return $rc;
} ## end sub rollback

=head2 C<prepareQuery()>
=cut

sub prepareQuery
{
    my ( $self, %parameters ) = @_;
    my $sql = $parameters{ sql };

    my $sth = $self->{ database }->{ connection }->prepare( $sql ) or die $self->{ database }->{ connection }->errstr;
    return $sth;
} ## end sub prepareQuery

=head2 C<doQuery()>
=cut

sub doQuery
{
    my ( $self, %parameters ) = @_;
    my $sql = $parameters{ sql };

    my $sth = $self->{ database }->{ connection }->do( $sql ) or die $self->{ database }->{ connection }->errstr;
    return $sth;
} ## end sub doQuery

=head2 C<executeQuery()>
=cut

sub executeQuery()
{
    my ( $self, %parameters ) = @_;
    my $sql = $parameters{ sql };

    $self->connectDB() unless ( defined( $self->{ database }->{ connection } ) );

    my $sth = $self->prepareQuery( sql => $sql );
    my $res = $sth->execute() or die $self->{ database }->{ connection }->errstr;

    my @rows;
    my $line;
    push( @rows, $line ) while ( $line = $sth->fetchrow_hashref );

    return @rows;
} ## end sub executeQuery

=head2 C<teste()>
=cut

sub teste()
{
    my ( $self, %parameters ) = @_;

    $self->{ configurations }->{ teste } = 'LALA';
    return $self;
} ## end sub teste

=head2 C<getFileMD5()>
-------------------------------------------------------------------------------
 Retorna o MD5 do arquivo
 Parametro 1 - Caminho e nome do arquivo a ser calculado
 Retorna o MD5 do arquivo informado
-------------------------------------------------------------------------------
=cut

sub getFileMD5()
{
    my ( $self, %parameters ) = @_;
    my $file = $parameters{ file };

    return FALSE unless ( -e $file );

    my $return;

    eval { require Digest::MD5; };
    if ( $@ )
    {
        $log->error( 'Package Digest::MD5 não encontrado...' );
        return FALSE;
    }

    if ( open( my $fh, $file ) )
    {
        binmode( $fh );
        $return = Digest::MD5->new->addfile( $fh )->hexdigest;
        close( $fh );
    } ## end if ( open( my $fh, $file...))
    else
    {
        $log->error( "Não foi possível abrir o arquivo [ $file ]..." );
    }

    return $return;
} ## end sub getFileMD5

=head2 C<parseBlockText()>
=cut

sub parseBlockText()
{
    my $me     = ( caller( 0 ) )[ 3 ];
    my $parent = ( caller( 1 ) )[ 3 ];
    $log->debug( "parseBlockText", { package => __PACKAGE__, file => __FILE__, me => $me, parent => $parent } );

    my ( $self, %parameters ) = @_;
    my $file        = $parameters{ file };
    my $layout      = $parameters{ layout };
    my $length_type = $parameters{ length_type };
    my $retorno     = { rows => undef, error => 0, message => undef, };

    if ( !$file || !-e $file )
    {
        $log->error( "O arquivo [ $file ] não existe..." );
        $retorno->{ message } = 'Arquivo não existe';
        $retorno->{ error }   = TRUE;
        return $retorno;
    } ## end if ( !$file || !-e $file...)

    $log->info( "Começando a parsear o arquivo [ $file ]..." );
    open FH, "<:encoding(UTF-8)", $file or die "Erro ao abrir o arquivo [ $file ]...";
    while ( my $linha = <FH> )
    {
        $linha =~ s/\n|\r//g;

        my $tipo_de_registro = substr( $linha, 0, $length_type );
        my $posicao          = 0;
        my $auxiliar         = ();

        if ( !$layout->{ $tipo_de_registro } )
        {
            my $tipos = join ",", sort keys %{ $layout };
            my $msg   = "Não existe o tipo de registro [ $tipo_de_registro ] no layout cadastrado [ $tipos ] na linha [ $. ]...";
            $log->error( $msg );
            $log->error( "Linha [ $. ] = [$linha]..." );
            $retorno->{ rows }    = undef;
            $retorno->{ message } = $msg;
            $retorno->{ error }   = 1;
            return $retorno;
        } ## end if ( !$layout->{ $tipo_de_registro...})

        my $tamanho_da_linha_no_layout  = $layout->{ $tipo_de_registro }->{ total_length };
        my $tamanho_da_linha_no_arquivo = length( $linha );

        if ( $tamanho_da_linha_no_arquivo != $tamanho_da_linha_no_layout )
        {
            my $msg = "Tamanho da linha [ $. ] do tipo $tipo_de_registro no arquivo $file ($tamanho_da_linha_no_arquivo) esta diferente do layout ($tamanho_da_linha_no_layout)";
            $log->error( $msg );
            $retorno->{ rows }    = undef;
            $retorno->{ message } = $msg;
            $retorno->{ error }   = 1;
            return $retorno;
        } ## end if ( $tamanho_da_linha_no_arquivo...)

        foreach my $field ( @{ $layout->{ $tipo_de_registro }->{ fields } } )
        {
            $auxiliar->{ $field->{ field } } = $self->trim( substr( $linha, $posicao, $field->{ length } ) );
            $posicao += $field->{ length };

            my $out = $field->{ out };

            if ( $field->{ match } )
            {
                if ( $auxiliar->{ $field->{ field } } !~ /$field->{match}/ )
                {
                    my $msg = "O campo [ $field->{ field } ] com o valor [ $auxiliar->{ $field->{ field } } ] não corresponde a regra de validação [ $field->{match} ] no registro [ $. ]...";
                    $log->error( $msg );
                    $retorno->{ rows }    = undef;
                    $retorno->{ message } = $msg;
                    $retorno->{ error }   = 1;
                    return $retorno;
                } ## end if ( $auxiliar->{ $field...})

                if ( $out )
                {
                    $out =~ s/\?\?\?/$auxiliar->{ $field->{field} }/g;
                    $auxiliar->{ $field->{ field } } = eval( $out );
                }
            } ## end if ( $field->{ match }...)
            elsif ( $out && $out !~ /\$/ )
            {
                $out =~ s/\?\?\?/$auxiliar->{ $field->{field} }/g;
                $auxiliar->{ $field->{ field } } = eval( $out );
            }
        } ## end foreach my $field ( @{ $layout...})

        push( @{ $retorno->{ rows }->{ $tipo_de_registro } }, $auxiliar );
    } ## end while ( my $linha = <FH> ...)
    return $retorno;
} ## end sub parseBlockText

=head2 C<parseCSV()>
=cut

sub parseCSV()
{
    my ( $self, %parameters ) = @_;
    my $file     = $parameters{ file };
    my $sep_char = $parameters{ sep_char } // ',';
    my $encoding = $parameters{ encoding } // 'iso-8859-1';
    my $retorno  = { rows => undef, error => 0, message => undef, };

    $log->info( "Começando a parsear o arquivo [ $file ]..." );

    # Read/parse CSV
    eval { require Text::CSV_XS; };

    if ( $@ )
    {
        $log->error( $@ );
        return $retorno;
    }

    my $csv = eval {

        Text::CSV_XS->new(
            {
                binary         => 1,
                auto_diag      => 0,
                diag_verbose   => 0,
                blank_is_undef => 1,
                empty_is_undef => 1,
                sep_char       => $sep_char,
            }
        );

    };

    if ( $@ )
    {
        $log->error( $@ );
        $retorno->{ error }   = 1;
        $retorno->{ message } = $@;
    } ## end if ( $@ )
    else
    {
        $csv->callbacks(
            after_parse => sub {

                # Limpar os espaços em branco no começo e no final de cada campo.
                map { defined $_ ? ( ( $_ =~ /^\s+$/ ) ? ( $_ = undef ) : ( s/^\s+|\s+$//g ) ) : undef } @{ $_[ 1 ] };
            },

            #error => sub {
            #    my ( $err, $msg, $pos, $recno, $fldno ) = @_;
            #    Text::CSV_XS->SetDiag(0);
            #    return;
            #}
        );
        my @rows;
        open my $fh, "<:encoding($encoding)", $file or die "$file->{path}: $!";

        if ( $encoding =~ /utf-8/i )
        {
            my @header = $csv->header( $fh, { detect_bom => 1, munge_column_names => "uc" } );
            $retorno->{ header } = \@header;
        }
        else
        {
            my @header = $csv->header( $fh, { munge_column_names => "uc" } );
            $retorno->{ header } = \@header;
        }

        while ( my $row = $csv->getline( $fh ) )
        {
            push @rows, $row;
        }
        close $fh;

        my ( $cde, $str, $pos, $rec, $fld ) = $csv->error_diag();

        if ( $cde > 0 && $cde != 2012 )
        {
            $rec--;
            undef @rows;
            $retorno->{ error }   = $cde;
            $retorno->{ message } = "$str @ rec $rec, pos $pos, field $fld";
        } ## end if ( $cde > 0 && $cde ...)
        else
        {
            @{ $retorno->{ rows } } = @rows;
        }
    } ## end else [ if ( $@ ) ]

    return $retorno;
} ## end sub parseCSV

=head2 C<trim()>
=cut

sub trim()
{
    my ( $self, $string ) = @_;

    eval { $string =~ s/^\s+|\s+$//g; };

    if ( $@ )
    {
        $log->error( "Erro ao fazer o trim na string $string" );
    }

    return $string;
} ## end sub trim

=head2 C<getTimeStampHash()>
=cut

#-------------------------------------------------------------------------------
# Retorna o timestamp atual do sistema em forma de HASH
#-------------------------------------------------------------------------------
sub getTimeStampHash
{
    my ( $self, %parameters ) = @_;
    my ( $sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst ) = localtime( time );

    {
        year  => $year + 1900,
        month => sprintf( '%02d', ( $mon + 1 ) ),
        day   => sprintf( '%02d', $mday ),
        hour  => sprintf( '%02d', $hour ),
        min   => sprintf( '%02d', $min ),
        sec   => sprintf( '%02d', $sec ),
        wday  => $wday,
        yday  => $yday,
        isdst => $isdst
    };
} ## end sub getTimeStampHash

=head2 C<getTimeStamp()>
=cut

#-------------------------------------------------------------------------------
# Retorna o timestamp atual do sistema
#-------------------------------------------------------------------------------
sub getTimeStamp
{
    my ( $sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst ) = localtime( time );
    return sprintf( "%4d%02d%02d%02d%02d%02d", $year + 1900, $mon + 1, $mday, $hour, $min, $sec );
}

#################### main pod documentation begin ###################
## Below is the stub of documentation for your module.
## You better edit it!

=encoding UTF-8


=head1 NAME

Siffra::Tools - Module abstract (<= 44 characters) goes here

=head1 SYNOPSIS

  use Siffra::Tools;
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

