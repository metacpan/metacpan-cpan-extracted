package Pg::SQL::PrettyPrinter::Node::FuncCall;

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

use parent qw( Pg::SQL::PrettyPrinter::Node );

# Taken from PostgreSQL sources, from src/include/nodes/parsenodes.h
our $FRAMEOPTION_NONDEFAULT                = 0x00001;    # any specified?
our $FRAMEOPTION_RANGE                     = 0x00002;    # RANGE behavior
our $FRAMEOPTION_ROWS                      = 0x00004;    # ROWS behavior
our $FRAMEOPTION_GROUPS                    = 0x00008;    # GROUPS behavior
our $FRAMEOPTION_BETWEEN                   = 0x00010;    # BETWEEN given?
our $FRAMEOPTION_START_UNBOUNDED_PRECEDING = 0x00020;    # start is U. P.
our $FRAMEOPTION_END_UNBOUNDED_PRECEDING   = 0x00040;    # (disallowed)
our $FRAMEOPTION_START_UNBOUNDED_FOLLOWING = 0x00080;    # (disallowed)
our $FRAMEOPTION_END_UNBOUNDED_FOLLOWING   = 0x00100;    # end is U. F.
our $FRAMEOPTION_START_CURRENT_ROW         = 0x00200;    # start is C. R.
our $FRAMEOPTION_END_CURRENT_ROW           = 0x00400;    # end is C. R.
our $FRAMEOPTION_START_OFFSET_PRECEDING    = 0x00800;    # start is O. P.
our $FRAMEOPTION_END_OFFSET_PRECEDING      = 0x01000;    # end is O. P.
our $FRAMEOPTION_START_OFFSET_FOLLOWING    = 0x02000;    # start is O. F.
our $FRAMEOPTION_END_OFFSET_FOLLOWING      = 0x04000;    # end is O. F.
our $FRAMEOPTION_EXCLUDE_CURRENT_ROW       = 0x08000;    # omit C.R.
our $FRAMEOPTION_EXCLUDE_GROUP             = 0x10000;    # omit C.R. & peers
our $FRAMEOPTION_EXCLUDE_TIES              = 0x20000;    # omit C.R.'s peers

sub new {
    my $class = shift;
    my $self  = $class->SUPER::new( @_ );
    bless $self, $class;

    $self->objectify(
        'funcname',
        'args',
        'agg_filter',
        'agg_order',
        map { [ 'over', $_ ] } qw( orderClause partitionClause startOffset endOffset )
    );

    if ( $self->{ 'func_variadic' } ) {
        my $last_type = ref $self->{ 'args' }->[ -1 ];
        $last_type =~ s/^Pg::SQL::PrettyPrinter::Node:://;
        croak( "Function is variadic, but last arg is not an array/subquery: ${last_type}" ) unless $last_type =~ m{\A(?:A_ArrayExpr|SubLink)\z};
    }

    return $self;
}

sub func_name {
    my $self = shift;
    unless ( exists $self->{ '_funcname' } ) {
        $self->{ '_funcname' } = join '.', map { $_->as_ident } @{ $self->{ 'funcname' } };
    }
    return $self->{ '_funcname' };
}

sub over_clause_as_text {
    my $self = shift;
    return unless exists $self->{ 'over' };

    # shortcut
    my $O = $self->{ 'over' };

    # Build the clause from parts, as it's simpler that way.
    my @parts = ();

    if ( exists $O->{ 'partitionClause' } ) {
        push @parts, 'PARTITION BY ' . join( ', ', map { $_->as_text } @{ $O->{ 'partitionClause' } } );
    }
    if ( exists $O->{ 'orderClause' } ) {
        push @parts, 'ORDER BY ' . join( ', ', map { $_->as_text } @{ $O->{ 'orderClause' } } );
    }

    # If there is no frame clause it will be empty array, so nothing will get pushed.
    push @parts, $self->frame_clause();

    # Shortcut for over without clauses
    return ' OVER ()' if 0 == scalar @parts;

    return sprintf( ' OVER ( %s )', join( ' ', @parts ) );
}

sub over_clause_pretty {
    my $self = shift;
    return unless exists $self->{ 'over' };

    # shortcut
    my $O = $self->{ 'over' };

    # Build the clause from parts, as it's simpler that way.
    my @parts = ();

    if ( exists $O->{ 'partitionClause' } ) {
        push @parts, 'PARTITION BY ' . join( ', ', map { $_->pretty_print } @{ $O->{ 'partitionClause' } } );
    }
    if ( exists $O->{ 'orderClause' } ) {
        push @parts, 'ORDER BY ' . join( ', ', map { $_->pretty_print } @{ $O->{ 'orderClause' } } );
    }

    # If there is no frame clause it will be empty array, so nothing will get pushed.
    push @parts, $self->frame_clause();

    # Shortcut for over without clauses
    return ' OVER ()' if 0 == scalar @parts;

    # Shortcut for over with just 1 clause
    return sprintf( ' OVER ( %s )', $parts[ 0 ] ) if 1 == scalar @parts;

    my @lines = ();
    push @lines, ' OVER (';
    push @lines, map { $self->increase_indent( $_ ) } @parts;
    push @lines, ')';
    return join( "\n", @lines );
}

sub frame_clause {
    my $self = shift;

    # shortcuts
    my $O  = $self->{ 'over' };
    my $FO = $O->{ 'frameOptions' };

    # Make sure it's called for FuncCalls with some frameOptions.
    return unless defined $FO;

    # Make sure the frameOptions are not default.
    return unless $FO & $FRAMEOPTION_NONDEFAULT;

    my @elements = ();

    # Frame based off what? range? rows? groups?
    if ( $FO & $FRAMEOPTION_RANGE ) {
        push @elements, 'RANGE';
    }
    elsif ( $FO & $FRAMEOPTION_ROWS ) {
        push @elements, 'ROWS';
    }
    elsif ( $FO & $FRAMEOPTION_GROUPS ) {
        push @elements, 'GROUPS';
    }
    else {
        croak( "Bad (#1) frameOptions: $FO" );
    }

    # Calculate start clause, as it's used in both between and just-start frames
    my $start_clause;
    if ( $FO & $FRAMEOPTION_START_UNBOUNDED_PRECEDING ) {
        $start_clause = 'UNBOUNDED PRECEDING';
    }
    elsif ( $FO & $FRAMEOPTION_START_CURRENT_ROW ) {
        $start_clause = 'CURRENT ROW';
    }
    elsif ( $FO & $FRAMEOPTION_START_OFFSET_PRECEDING ) {
        $start_clause = $self->{ 'over' }->{ 'startOffset' }->as_text . ' PRECEDING';
    }
    elsif ( $FO & $FRAMEOPTION_START_OFFSET_FOLLOWING ) {
        $start_clause = $self->{ 'over' }->{ 'startOffset' }->as_text . ' FOLLOWING';
    }
    else {
        croak( "Bad (#2) frameOptions: $FO" );
    }

    if ( $FO & $FRAMEOPTION_BETWEEN ) {

        # It's frame with BETWEEN operation. It needs end_clause and proper format ...
        my $end_clause = '';
        if ( $FO & $FRAMEOPTION_END_UNBOUNDED_FOLLOWING ) {
            $end_clause = 'UNBOUNDED FOLLOWING';
        }
        elsif ( $FO & $FRAMEOPTION_END_CURRENT_ROW ) {
            $end_clause = 'CURRENT ROW';
        }
        elsif ( $FO & $FRAMEOPTION_END_OFFSET_PRECEDING ) {
            $end_clause = $self->{ 'over' }->{ 'endOffset' }->as_text . ' PRECEDING';
        }
        elsif ( $FO & $FRAMEOPTION_END_OFFSET_FOLLOWING ) {
            $end_clause = $self->{ 'over' }->{ 'endOffset' }->as_text . ' FOLLOWING';
        }
        else {
            croak( "Bad (#3) frameOptions: $FO" );
        }

        # Put the elements of between clause together.
        push @elements, 'BETWEEN';
        push @elements, $start_clause;
        push @elements, 'AND';
        push @elements, $end_clause;
    }
    else {
        # If it's not BETWEEN frame, just put start clause to output
        push @elements, $start_clause;
    }

    # Handle excludes in the frame.
    if ( $FO & $FRAMEOPTION_EXCLUDE_CURRENT_ROW ) {
        push @elements, 'EXCLUDE CURRENT ROW';
    }
    elsif ( $FO & $FRAMEOPTION_EXCLUDE_GROUP ) {
        push @elements, 'EXCLUDE GROUP';
    }
    elsif ( $FO & $FRAMEOPTION_EXCLUDE_TIES ) {
        push @elements, 'EXCLUDE TIES';
    }

    return join( ' ', @elements );
}

sub as_text {
    my $self = shift;

    my $suffix = $self->over_clause_as_text // '';
    if ( exists $self->{ 'agg_filter' } ) {
        $suffix .= ' FILTER ( WHERE ' . $self->{ 'agg_filter' }->as_text . ' )';
    }
    my $agg_order = $self->get_agg_order();

    if ( $self->{ 'agg_star' } ) {
        my $internal = $agg_order ? " * ${agg_order} " : '*';
        return sprintf( '%s(%s)%s', $self->func_name, $internal, $suffix );
    }
    unless ( exists $self->{ 'args' } ) {
        return $self->func_name . '()' . $suffix unless $agg_order;
        return $self->func_name . "( ${agg_order} )" . $suffix;
    }

    my @args_as_text = map { $_->as_text } @{ $self->{ 'args' } };
    if ( $self->{ 'func_variadic' } ) {
        $args_as_text[ -1 ] = 'VARIADIC ' . $args_as_text[ -1 ];
    }
    my $args_str = join( ', ', @args_as_text );
    $args_str .= ' ' . $agg_order if $agg_order;
    return $self->func_name . '( ' . $args_str . ' )' . $suffix;
}

sub get_agg_order {
    my $self = shift;
    return '' unless exists $self->{ 'agg_order' };
    return sprintf( 'ORDER BY %s', join( ', ', map { $_->as_text } @{ $self->{ 'agg_order' } } ) );
}

sub pretty_print {
    my $self = shift;

    my $suffix = $self->over_clause_pretty // '';
    if ( exists $self->{ 'agg_filter' } ) {
        $suffix .= ' FILTER ( WHERE ' . $self->{ 'agg_filter' }->as_text . ' )';
    }
    my $agg_order = $self->get_agg_order();

    if ( $self->{ 'agg_star' } ) {
        my $internal = $agg_order ? " * ${agg_order} " : '*';
        return sprintf( '%s(%s)%s', $self->func_name, $internal, $suffix );
    }
    unless ( exists $self->{ 'args' } ) {
        return $self->func_name . '()' . $suffix unless $agg_order;
        return $self->func_name . "( ${agg_order} )" . $suffix;
    }

    my @args_as_text = map { $_->as_text } @{ $self->{ 'args' } };
    if ( $self->{ 'func_variadic' } ) {
        $args_as_text[ -1 ] = 'VARIADIC ' . $args_as_text[ -1 ];
    }
    my $args_str = join( ', ', @args_as_text );
    $args_str .= ' ' . $agg_order if $agg_order;
    if (   ( 1 == scalar @{ $self->{ 'args' } } )
        && ( 40 > length( $args_str ) ) )
    {
        return $self->func_name . '( ' . $args_str . ' )' . $suffix;
    }
    my @lines = ();
    push @lines, $self->func_name . '(';
    my @args_pp = map { $_->pretty_print } @{ $self->{ 'args' } };
    if ( $self->{ 'func_variadic' } ) {
        $args_pp[ -1 ] = 'VARIADIC ' . $args_pp[ -1 ];
    }
    push @lines, map { $self->increase_indent( $_ ) . ',' } @args_pp;
    $lines[ -1 ] =~ s/,\z//;
    push @lines, $self->increase_indent( $agg_order ) if $agg_order;
    push @lines, ')' . $suffix;
    return join( "\n", @lines );
}

1;
