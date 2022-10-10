package Pg::SQL::PrettyPrinter::Node;

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
use Carp qw( carp croak confess cluck );
use English qw( -no_match_vars );
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

use Module::Runtime qw( use_module );
use Clone qw( clone );

sub new {
    my ( $class, $the_rest ) = @_;
    my $self = clone( $the_rest );
    bless $self, $class;
    return $self;
}

sub make_from {
    my ( $self, $data ) = @_;

    return unless defined $data;

    if ( 'ARRAY' eq ref $data ) {
        return [ map { $self->make_from( $_ ) } @{ $data } ];
    }

    croak( 'Invalid data for making Pg::SQL::PrettyPrinter::Node: ' . Dumper( $data ) ) unless 'HASH' eq ref $data;

    my @all_keys = keys %{ $data };
    return if 0 == scalar @all_keys;
    croak( 'Invalid data for making Pg::SQL::PrettyPrinter::Node (#2): ' . join( ', ', @all_keys ) ) unless 1 == scalar @all_keys;
    my $class_suffix = $all_keys[ 0 ];
    croak( "Invalid data for making Pg::SQL::PrettyPrinter::Node (#3): $class_suffix" ) unless $class_suffix =~ /^[A-Z][a-zA-Z0-9_-]+$/;

    my $class = 'Pg::SQL::PrettyPrinter::Node::' . $class_suffix;
    my $object;
    eval { $object = use_module( $class )->new( $data->{ $class_suffix } ); };
    if ( $EVAL_ERROR ) {
        my $msg  = $EVAL_ERROR;
        my $keys = join( '; ', sort keys %{ $data } );
        croak( "Can't make object out of [${keys}]:\n" . Dumper( $data ) . "\n" . $msg );
    }
    return $object;
}

sub objectify {
    my $self = shift;
    my @keys = @_;

    # Only arrays and hashes (well, references to them) can be objectified.
    my %types_ok = map { $_ => 1 } qw{ ARRAY HASH };

    for my $key ( @keys ) {
        my ( $container, $real_key ) = $self->get_container_key( $key );
        next unless defined $container;
        next unless exists $container->{ $real_key };

        my $val  = $container->{ $real_key };
        my $type = ref $val;
        next unless $types_ok{ $type };

        $container->{ $real_key } = $self->make_from( $val );
    }

    return;
}

sub get_container_key {
    my $self = shift;
    my $path = shift;

    my $type = ref $path;
    return $self, $path if '' eq $type;
    croak( "Can't get container/key for non-array: $type" ) unless 'ARRAY' eq $type;
    croak( "Can't get container/key for empty array" ) if 0 == scalar @{ $path };
    return $self, $path->[ 0 ] if 1 == scalar @{ $path };

    my $container = $self;
    for ( my $i = 0 ; $i < $#{ $path } ; $i++ ) {
        my $key = $path->[ $i ];
        return unless exists $container->{ $key };
        $container = $container->{ $key };
    }

    return $container, $path->[ -1 ];
}

sub pretty_print {
    my $self = shift;
    return $self->as_text( @_ );
}

sub quote_literal {
    my $self = shift;
    my $val  = shift;
    $val =~ s/'/''/g;
    return "'" . $val . "'";
}

sub quote_ident {
    my $self = shift;
    my $val  = shift;
    return $val if $val =~ m{\A[a-z0-9_]+\z};
    $val =~ s/"/""/g;
    return '"' . $val . '"';
}

sub increase_indent {
    my $self  = shift;
    my $input = shift;
    return $self->increase_indent_n( 1, $input );
}

sub increase_indent_n {
    my $self   = shift;
    my $levels = shift;
    my $input  = shift;
    croak( "Bad number of levels ($levels) to increase indent!" ) unless $levels =~ m{\A[1-9]\d*\z};
    my $prefix = '    ' x $levels;
    my @lines  = split /\n/, $input;
    return join( "\n", map { $prefix . $_ } @lines );
}

1;
