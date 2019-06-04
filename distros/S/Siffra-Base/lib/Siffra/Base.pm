package Siffra::Base;

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

BEGIN
{
    use Exporter ();
    use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
    $VERSION = '0.08';
    @ISA     = qw(Exporter);

    #Give a hoot don't pollute, do not export more than needed by default
    @EXPORT      = qw();
    @EXPORT_OK   = qw();
    %EXPORT_TAGS = ();
} ## end BEGIN

BEGIN
{
    binmode( STDOUT, ":encoding(UTF-8)" );
    binmode( STDERR, ":encoding(UTF-8)" );

    $SIG{ __DIE__ } = sub {
        $log->debug( 'Entrando em __DIE__', { package => __PACKAGE__ } );
        if ( $^S )
        {
            $log->debug( 'Entrando em __DIE__ eval {}', { package => __PACKAGE__ } );

            # We're in an eval {} and don't want log
            # this message but catch it later
            return;
        } ## end if ( $^S )

        ( my $message = $_[ 0 ] ) =~ s/\n|\r//g;
        $log->fatal( $message, { package => __PACKAGE__ } );

        die Dumper @_;    # Now terminate really
    };

    $SIG{ __WARN__ } = sub {
        state $count = 0;
        ( my $message = $_[ 0 ] ) =~ s/\n|\r//g;
        if ( $log )
        {
            $log->warn( $message, { package => __PACKAGE__, count => $count++, global_phase => ${^GLOBAL_PHASE} } );
        }
    };
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
    $log->debug( "new", { progname => $0, pid => $$, perl_version => $], package => __PACKAGE__ } );
    my ( $class, %parameters ) = @_;

    my $self = {};

    $self = bless( $self, ref( $class ) || $class );

    return $self;
} ## end sub new

sub _initialize()
{
    $log->debug( "_initialize", { package => __PACKAGE__ } );
    my ( $self, %parameters ) = @_;
}

sub _finalize()
{
    $log->debug( "_finalize", { package => __PACKAGE__ } );
    my ( $self, %parameters ) = @_;
}

sub END
{
    $log->debug( "END", { package => __PACKAGE__ } );
    eval { $log->{ adapter }->{ dispatcher }->{ outputs }->{ Email }->flush; };
}

sub DESTROY
{
    my ( $self, %parameters ) = @_;

    if ( ${^GLOBAL_PHASE} eq 'DESTRUCT' )
    {
        eval { $log->{ adapter }->{ dispatcher }->{ outputs }->{ Email }->flush; };
        return;
    }

    if ( blessed( $self ) && $self->isa( __PACKAGE__ ) )
    {
        $log->debug( "DESTROY", { package => __PACKAGE__, GLOBAL_PHASE => ${^GLOBAL_PHASE}, blessed => TRUE } );
    }
    else
    {
        # TODO
    }
} ## end sub DESTROY

=head2 C<AUTOLOAD>
=cut

sub AUTOLOAD
{
    my ( $self, @parameters ) = @_;
    our $AUTOLOAD;
    return if ( $AUTOLOAD =~ /DESTROY/ );

    # Remove qualifier from original method name...
    my $called = $AUTOLOAD =~ s/.*:://r;

    # Is there an attribute of that name?
    die "No such attribute ****[ $called ]****" unless exists $self->{ $called };

    # If so, return it...
    return $self->{ $called };
} ## end sub AUTOLOAD

#################### main pod documentation begin ###################
## Below is the stub of documentation for your module.
## You better edit it!

=encoding UTF-8


=head1 NAME

Siffra::Base - Siffra Base Module

=head1 SYNOPSIS

  use Siffra::Base;
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

