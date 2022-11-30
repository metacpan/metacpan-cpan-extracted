package Pg::SQL::PrettyPrinter;

# UTF8 boilerplace, per http://stackoverflow.com/questions/6162484/why-does-modern-perl-avoid-utf-8-by-default/
use v5.26;
use strict;
use warnings;
use warnings qw( FATAL utf8 );
use utf8;
use open qw( :std :utf8 );
use Unicode::Normalize qw( NFC );
use Unicode::Collate;
use Encode qw( decode );

if ( grep /\P{ASCII}/ => @ARGV ) {
    @ARGV = map { decode( 'UTF-8', $_ ) } @ARGV;
}

# If there is __DATA__,then uncomment next line:
# binmode( DATA, ':encoding(UTF-8)' );
# UTF8 boilerplace, per http://stackoverflow.com/questions/6162484/why-does-modern-perl-avoid-utf-8-by-default/

# Useful common code
use autodie;
use Carp         qw( carp croak confess cluck );
use English      qw( -no_match_vars );
use Data::Dumper qw( Dumper );

# give a full stack dump on any untrapped exceptions
local $SIG{ __DIE__ } = sub {
    confess "Uncaught exception: @_" unless $^S;
};

# now promote run-time warnings into stackdumped exceptions
#   *unless* we're in an try block, in which
#   case just generate a clucking stackdump instead
local $SIG{ __WARN__ } = sub {
    if   ( $^S ) { cluck "Trapped warning: @_" }
    else         { confess "Deadly warning: @_" }
};

# Useful common code

use HTTP::Tiny;
use JSON::MaybeXS;
use Pg::SQL::PrettyPrinter::Node;

our $VERSION = 0.7;

sub new {
    my ( $class, %args ) = @_;
    my $self = bless {}, $class;

    croak( 'SQL query was not provided!' ) unless $args{ 'sql' };
    $self->{ 'sql' } = $args{ 'sql' };

    if ( exists $args{ 'service' } ) {
        croak( 'You should provide only one of service/struct!' ) if $args{ 'struct' };
        croak( 'Invalid syntax for service!' ) unless $args{ 'service' } =~ m{
            \A
            http://
            \d{1,3} (?: \. \d{1,3} ){3}     # IP address for parse microservice
            :
            [1-9]\d+                                  # Port number for parse microservice
            /
            \z
        }x;
        $self->{ 'service' } = $args{ 'service' };
    }
    elsif ( exists $args{ 'struct' } ) {
        $self->validate_struct( $args{ 'struct' } );
        $self->{ 'struct' } = $args{ 'struct' };
    }
    else {
        croak( 'You have to provide either service or struct!' );
    }
    return $self;
}

sub validate_struct {
    my ( $self, $struct ) = @_;
    croak( 'Invalid parse struct!' )      unless 'HASH' eq ref $struct;
    croak( 'Invalid parse struct (#2)!' ) unless $struct->{ 'version' };
    croak( 'Invalid parse struct (#3)!' ) unless $struct->{ 'stmts' };
    croak( 'Invalid parse struct (#4)!' ) unless 'ARRAY' eq ref $struct->{ 'stmts' };
    croak( 'Invalid parse struct (#5)!' ) unless 0 < scalar @{ $struct->{ 'stmts' } };
    return;
}

sub parse {
    my $self = shift;
    $self->fetch_struct();
    $self->{ 'statements' } = [ map { Pg::SQL::PrettyPrinter::Node->make_from( $_->{ 'stmt' } ) } @{ $self->{ 'struct' }->{ 'stmts' } } ];
    return;
}

sub remove_irrelevant {
    my $self = shift;
    my $q    = $self->{ 'sql' };
    $q =~ s{
        \A            # Beginning of sql
        \s*           # Eventual spacing, including new lines
        [a-z0-9_]*    # optional dbname
        [=-]?         # optional prompt type
        [>#\$]         # prompt final character, depending on user level, or common(ish) '$'
        \s*           # optional spaces
    }{}x;
    $self->{ 'sql' } = $q;
}

sub fetch_struct {
    my $self = shift;
    return if $self->{ 'struct' };
    $self->remove_irrelevant();
    my $http = HTTP::Tiny->new( 'timeout' => 0.5 );                                     # There really isn't a reason why it should take longer than 0.3s
    my $res  = $http->post_form( $self->{ 'service' }, { 'q' => $self->{ 'sql' } } );
    unless ( $res->{ 'success' } ) {
        croak( 'Timeout while parsing' ) if $res->{ 'content' } =~ m{\ATimed out while waiting for socket};
        croak( "Couldn't parse the queries! : " . Dumper( $res ) );
    }
    my $struct = decode_json( $res->{ 'content' } );
    croak( "Parse error: " . $struct->{ 'error' } ) if exists $struct->{ 'error' };
    $self->validate_struct( $struct );
    $self->{ 'struct' } = $struct;
    return;
}

1;
