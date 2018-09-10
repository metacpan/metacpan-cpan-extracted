package Pcore::Core::Dump::Dumper;

use Pcore -class, -ansi;
use Pcore::Util::Scalar qw[refaddr isweak reftype blessed looks_like_number tainted];
use Pcore::Util::Text qw[escape_scalar remove_ansi add_num_sep];
use re qw[];
use Sort::Naturally qw[nsort];
use PerlIO::Layers qw[];

has color  => ( is => 'ro', isa => Bool, default => 0 );    # colorize dump
has tags   => ( is => 'ro', isa => Bool, default => 0 );    # do not add tags
has indent => ( is => 'ro', isa => Int,  default => 4 );    # indent spaces

has _indent => ( is => 'ro', isa => Str, init_arg => undef );
has _seen => ( is => 'ro', isa => HashRef, default => sub { {} }, init_arg => undef );

our $COLOR = {
    number  => $BOLD . $CYAN,                               # numbers
    string  => $BOLD . $YELLOW,                             # strings
    class   => $BOLD . $GREEN,                              # class names
    regex   => $YELLOW,                                     # regular expressions
    code    => $GREEN,                                      # code references
    glob    => $BOLD . $CYAN,                               # globs (usually file handles)
    vstring => $BOLD . $YELLOW,                             # version strings (v5.16.0, etc)
    format  => $BOLD . $CYAN,

    array => $WHITE,                                        # array index numbers
    hash  => $BOLD . $MAGENTA,                              # hash keys

    refs    => $BOLD . $WHITE,
    unknown => $BLACK . $ON_YELLOW,                         # potential new Perl datatypes
    undef   => $BOLD . $RED,                                # the 'undef' value
    escaped => $BOLD . $RED,                                # escaped characters (\t, \n, etc)
    seen    => $WHITE . $ON_RED,                            # references to seen values
};

our $DUMPERS = {
    'DateTime' => sub {
        my $self   = shift;
        my $dumper = shift;
        my %args   = (
            path => undef,
            @_,
        );

        my $res;
        my $tags;

        $res .= q[] . $self;                            # stringify
        $res .= ' [' . $self->time_zone->name . ']';    # timezone

        return $res, $tags;
    },
    'File::Temp' => sub {
        my $self   = shift;
        my $dumper = shift;
        my %args   = (
            path => undef,
            @_,
        );

        my $res;
        my $tags;

        $res .= $dumper->_dump_blessed( $self, path => $args{path} );
        $res .= qq[,\npath: "] . $self->filename . q["];

        return $res, $tags;
    },
};

sub run ( $self, @ ) {
    $self->{_indent} = q[ ] x ( $self->{indent} // 4 );

    if ( !$self->{color} ) {
        return remove_ansi $self->_dump( $_[1], path => '$VAR' );
    }
    else {
        return $self->_dump( $_[1], path => '$VAR' );
    }
}

# INTERNAL METHODS
sub _dump ( $self, @ ) {
    my %args = (
        path    => '',
        unbless => 0,
        splice @_, 2,
    );

    local $ENV{ANSI_COLORS_DISABLED} = 1 if !$self->{color};

    my ( $var_type, $blessed ) = $self->_var_type( $_[1], unbless => $args{unbless} );

    # detect var addr
    my $var_addr = "${var_type}_";

    if ( ref $_[1] ) {
        $var_addr .= refaddr $_[1];
    }
    else {
        $var_addr .= refaddr \$_[1];
    }

    my ( $res, $tags );

    if ( $var_addr && exists $self->{_seen}->{$var_addr} ) {
        $res = $COLOR->{seen} . $self->{_seen}->{$var_addr} . $RESET;
    }
    else {
        $self->{_seen}->{$var_addr} = $args{path};

        my $dump_method = $blessed ? 'BLESSED' : $var_type;

        $dump_method = 'UNKNOWN' if !$self->can($dump_method);

        ( $res, $tags ) = $self->$dump_method( $_[1], path => $args{path}, var_type => $var_type );
    }

    # weak
    push $tags->@*, 'weak' if isweak( $_[1] );
    #
    # $res .= ',';

    # add tags
    # $res .= q[ # ] . join q[, ], $tags->@* if $tags;

    return bless { text => \$res, tags => $self->{tags} && $tags }, 'Pcore::Core::Dump::Dumper::_Item';
}

sub _var_type {
    my $self = shift;
    my %args = (
        unbless => 0,
        splice( @_, 1 ),
    );

    my $ref_type = reftype $_[0];

    if ( my $blessed = blessed $_[0] ) {    # blessed
        if ( $args{unbless} ) {
            return $ref_type;
        }
        elsif ( $ref_type eq 'REGEXP' && $blessed eq 'Regexp' ) {
            return $ref_type;
        }
        elsif ( $ref_type eq 'IO' ) {
            return $blessed, 1;
        }
        else {
            return $blessed, 1;
        }
    }
    else {
        if ( defined $ref_type ) {
            if ( $ref_type eq 'SCALAR' || $ref_type eq 'VSTRING' || $ref_type eq 'GLOB' ) {
                return 'REF';
            }
            else {
                return $ref_type;
            }
        }
        else {
            return CORE::ref \$_[0];
        }
    }
}

sub _indent_text {
    my $self = shift;

    $_[0] =~ s/\n/\n$self->{_indent}/smg;

    return;
}

sub _dump_blessed {
    my $self = shift;
    my $obj  = shift;
    my %args = (
        path => undef,
        @_,
    );

    return 'blessed: ' . $self->_dump( $obj, path => $args{path}, unbless => 1 );
}

sub _tied_to {
    my $self = shift;
    my $tied = shift;

    if ($tied) {
        $_[0] //= [];

        push $_[0]->@*, 'tied to ' . ref $tied;
    }

    return;
}

# DUMPERS
sub UNKNOWN {
    my $self = shift;
    my %args = (
        var_type => q[],
        @_,
    );

    return $COLOR->{unknown} . 'unknown: ' . $args{var_type} . $RESET;
}

sub BLESSED {
    my $self = shift;
    my $obj  = shift;
    my %args = (
        path => undef,
        @_,
    );

    my $ref = ref $obj;

    my $res = $COLOR->{class} . $ref . ' {' . $RESET . "\n";

    my ( $tags, $dumped );

    # @ISA
    if ( my @superclasses = @{ $ref . '::ISA' } ) {
        $res .= $self->{_indent} . '@ISA: ' . join q[, ], map { $COLOR->{class} . $_ . $RESET } @superclasses;

        $res .= ",\n";
    }

    # reafddr
    $res .= $self->{_indent} . 'refaddr: ' . refaddr($obj) . ",\n";

    # class dump method
    if ( my $to_dump = $obj->can('TO_DUMP') ) {
        my ( $dump, $dump_tags ) = $to_dump->( $obj, $self, path => $args{path} );

        if ($dump) {
            $dumped = 1;

            $self->_indent_text($dump);

            $res .= $self->{_indent} . $dump;
        }

        push $tags->@*, $dump_tags->@* if $dump_tags;
    }

    # predefined dumper sub for class
    if ( !$dumped && $DUMPERS->{$ref} ) {
        my ( $dump, $dump_tags ) = $DUMPERS->{$ref}->( $obj, $self, path => $args{path} );

        if ($dump) {
            $dumped = 1;

            $self->_indent_text($dump);

            $res .= $self->{_indent} . $dump;
        }

        push $tags->@*, $dump_tags->@* if $dump_tags;
    }

    if ( !$dumped ) {

        # blessed
        my $blessed = $self->_dump_blessed( $obj, path => $args{path} );

        $self->_indent_text($blessed);

        $res .= $self->{_indent} . $blessed;
    }

    $res .= "\n" . $COLOR->{class} . '}' . $RESET;

    return $res, $tags;
}

sub REF {
    my $self = shift;
    my $ref  = shift;
    my %args = (
        path => undef,
        @_,
    );

    my $item = $self->_dump( $ref->$*, path => $args{path} . '->$*' );

    $item->{prefix} = $COLOR->{refs} . '\\ ' . $RESET;

    return "$item";
}

sub SCALAR {
    my $self = shift;

    my ( $res, $tags );

    if ( !defined $_[0] ) {    # undefined value
        $res = $COLOR->{undef} . 'undef' . $RESET;
    }
    elsif ( looks_like_number( $_[0] ) ) {
        $res = $COLOR->{number} . add_num_sep( $_[0] ) . $RESET;
    }
    else {
        my $item         = $_[0];                  # scalar become untied
        my $bytes_length = bytes::length($item);
        my $length       = length $item;
        escape_scalar( $item, esc_color => $COLOR->{escaped}, reset_color => $COLOR->{string} );

        if ( utf8::is_utf8 $item ) {               # characters
            push $tags->@*, 'UTF8';

            if ( $bytes_length == $length ) {
                push $tags->@*, 'single-byte, downgradable';    # ASCII-7bit (bytes in perl terminology), UTF8 flag can be dropped
            }
            else {
                push $tags->@*, 'multi-byte';
            }

            push $tags->@*, 'chars: ' . $length;
        }
        else {                                                  # octets
            if ( $item =~ /[[:^ascii:]]/sm ) {                  # if has non-ASCII-7bit bytes - treats buffer as binary
                push $tags->@*, 'latin1';
            }
            else {                                              # if contains only ASCII-7bit bytes - treats buffer as string
                push $tags->@*, 'ASCII';
            }
        }

        push $tags->@*, 'bytes: ' . $bytes_length;

        push $tags->@*, 'tied to ' . ref tied $_[0] if tainted $_[0];

        $res = 'qq[' . $COLOR->{string} . $item . $RESET . ']';
    }

    $self->_tied_to( tied $_[0], $tags );

    return $res, $tags;
}

sub ARRAY {
    my $self      = shift;
    my $array_ref = shift;
    my %args      = (
        path => undef,
        @_,
    );

    my ( $res, $tags );

    if ( !$array_ref->@* ) {
        $res = $COLOR->{refs} . '[]' . $RESET;
    }
    else {
        $res = $COLOR->{refs} . '[' . $RESET . $LF;

        my $max_index_length = length( $#{$array_ref} ) + 2;

        for my $i ( 0 .. $array_ref->$#* ) {
            my $index = sprintf( '%-*s', $max_index_length, "[$i]" ) . q[ ];

            $res .= $self->{_indent} . $COLOR->{array} . $index . $RESET;

            my $el = $self->_dump( $array_ref->[$i], path => $args{path} . "->[$i]" );

            # not last array element
            if ( $i != $array_ref->$#* ) {
                $el->{sep} = ',';
            }

            $self->_indent_text($el);

            $res .= "$el\n";
        }

        $res .= $COLOR->{refs} . ']' . $RESET;
    }

    $self->_tied_to( tied $array_ref->@*, $tags );

    return $res, $tags;
}

sub HASH {
    my $self     = shift;
    my $hash_ref = shift;
    my %args     = (
        path => undef,
        @_,
    );

    my ( $res, $tags );

    if ( !keys $hash_ref->%* ) {
        $res = $COLOR->{refs} . '{}' . $RESET;
    }
    else {
        $res = $COLOR->{refs} . '{' . $RESET . $LF;

        my $keys;
        my $max_length = 0;

        # index hash keys
        for ( nsort keys $hash_ref->%* ) {
            my $indexed_key = {
                raw_key     => $_,
                escaped_key => \escape_scalar( $_, esc_color => $COLOR->{escaped}, reset_color => $COLOR->{hash} ),
            };

            # hash key requires to be quoted
            if ( $_ eq q[] || /[^[:alnum:]_]/sm ) {
                $indexed_key->{escaped_key} = \( 'q[' . $indexed_key->{escaped_key}->$* . ']' );
            }

            $indexed_key->{escaped_key_nc} = $indexed_key->{escaped_key}->$*;

            remove_ansi $indexed_key->{escaped_key_nc};

            $indexed_key->{escaped_key_nc_len} = length $indexed_key->{escaped_key_nc};

            push $keys->@*, $indexed_key;

            $max_length = $indexed_key->{escaped_key_nc_len} if $indexed_key->{escaped_key_nc_len} > $max_length;
        }

        my $indent = $max_length + 8;

        for my $i ( 0 .. $keys->$#* ) {
            $res .= $self->{_indent} . $COLOR->{hash} . $keys->[$i]->{escaped_key}->$* . $RESET;

            $res .= sprintf '%*s', ( $max_length - $keys->[$i]->{escaped_key_nc_len} + 4 ), ' => ';

            my $el = $self->_dump( $hash_ref->{ $keys->[$i]->{raw_key} }, path => $args{path} . '->{"' . $keys->[$i]->{escaped_key_nc} . '"}' );

            # not last hash key
            if ( $i != $keys->$#* ) {
                $el->{sep} = ',';
            }

            $self->_indent_text($el);

            $res .= "$el\n";
        }

        $res .= $COLOR->{refs} . '}' . $RESET;
    }

    $self->_tied_to( tied $hash_ref->%*, $tags );

    return $res, $tags;
}

sub VSTRING {
    my $self = shift;

    return $COLOR->{vstring} . version->declare( $_[0] )->normal . $RESET;
}

sub GLOB {
    my $self = shift;

    my ( $res, $tags, $i );
    my $flags  = [];
    my $layers = q[];

    for ( PerlIO::Layers::get_layers( $_[0] ) ) {
        unless ($i) {
            $i = 1;

            $flags = $_->[2];
        }
        $layers .= ":$_->[0]";

        $layers .= "($_->[1])" if defined $_->[1];    # add layer encoding

        $layers .= ':utf8' if 'UTF8' ~~ $_->[2];      # add :utf8 layer, if defined
    }

    my $fileno = eval { fileno $_[0] };

    push $tags->@*, nsort $flags->@*;

    push $tags->@*, $layers if $layers;

    push $tags->@*, "fileno: $fileno" if defined $fileno;

    $self->_tied_to( tied $_[0], $tags );

    {
        no overloading;

        $res = $COLOR->{glob} . "$_[0]";
    }

    $res .= $RESET;

    return $res, $tags;
}

# TODO - more informative dumper for IO refs
sub IO {
    my $self = shift;

    return $self->GLOB(@_);
}

sub CODE {
    my $self = shift;

    return $COLOR->{code} . 'sub { ... }' . $RESET;
}

sub REGEXP {
    my $self = shift;

    my ( $pat, $flags ) = re::regexp_pattern( $_[0] );

    $flags //= q[];

    return $COLOR->{regex} . qq[qr/$pat/$flags] . $RESET;
}

sub FORMAT {
    my $self = shift;

    return $COLOR->{format} . 'FORMAT' . $RESET;
}

sub LVALUE {
    my $self = shift;

    my ( $res, $tags ) = $self->SCALAR( $_[0]->$* );

    unshift $tags->@*, 'LVALUE';

    return $res, $tags;
}

package Pcore::Core::Dump::Dumper::_Item {
    use overload    #
      q[""] => sub {
        if ( $_[0]->{tags} ) {
            return ( $_[0]->{prefix} // q[] ) . $_[0]->{text}->$* . ( $_[0]->{sep} // q[] ) . ' # ' . join q[, ], $_[0]->{tags}->@*;
        }
        else {
            return ( $_[0]->{prefix} // q[] ) . $_[0]->{text}->$* . ( $_[0]->{sep} // q[] );
        }
      };
}

1;
## -----SOURCE FILTER LOG BEGIN-----
##
## PerlCritic profile "pcore-script" policy violations:
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
## | Sev. | Lines                | Policy                                                                                                         |
## |======+======================+================================================================================================================|
## |    2 | 86                   | ValuesAndExpressions::ProhibitEmptyQuotes - Quotes used with a string containing no non-whitespace characters  |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    1 | 76, 79, 228, 289     | ValuesAndExpressions::RequireInterpolationOfMetachars - String *may* require interpolation                     |
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
##
## -----SOURCE FILTER LOG END-----
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::Core::Dump::Dumper

=head1 SYNOPSIS

=head1 DESCRIPTION

=cut
