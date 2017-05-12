package Pcore::Core::Dump::Dumper;

use Pcore -class;
use Pcore::Util::Scalar qw[refaddr isweak reftype blessed looks_like_number tainted];
use Pcore::Util::Text qw[escape_scalar remove_ansi add_num_sep];
use re qw[];
use Sort::Naturally qw[nsort];
use Term::ANSIColor qw[colored];
use PerlIO::Layers qw[];

has color => ( is => 'ro', isa => Bool, default => 1 );    # colorize dump
has dump_method => ( is => 'ro', isa => Maybe [Str], default => 'TO_DUMP' );    # dump method for objects, use "undef" to skip call
has indent => ( is => 'ro', isa => Int, default => 4 );                         # indent spaces

has _indent => ( is => 'lazy', isa => Str, default => sub { my $self = shift; return q[ ] x $self->indent; }, init_arg => undef );
has _seen => ( is => 'lazy', isa => HashRef, default => sub { {} }, init_arg => undef );

our $COLOR = {
    number  => 'bold cyan',                                                     # numbers
    string  => 'bold yellow',                                                   # strings
    class   => 'bold green',                                                    # class names
    regex   => 'yellow',                                                        # regular expressions
    code    => 'green',                                                         # code references
    glob    => 'bold cyan',                                                     # globs (usually file handles)
    vstring => 'bold yellow',                                                   # version strings (v5.16.0, etc)
    format  => 'bold cyan',

    array => 'white',                                                           # array index numbers
    hash  => 'bold magenta',                                                    # hash keys

    refs    => 'bold white',
    unknown => 'black on_yellow',                                               # potential new Perl datatypes
    undef   => 'bold red',                                                      # the 'undef' value
    escaped => 'bold red',                                                      # escaped characters (\t, \n, etc)
    seen    => 'white on_red',                                                  # references to seen values
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

sub run ( $self, @args ) {
    return $self->_dump(@args);
}

# INTERNAL METHODS
sub _dump ( $self, @ ) {
    my %args = (
        path    => q[$VAR],
        unbless => 0,
        splice @_, 2,
    );

    local $ENV{ANSI_COLORS_DISABLED} = 1 unless $self->color;

    my ( $var_type, $blessed ) = $self->_var_type( $_[1], unbless => $args{unbless} );

    # detect var addr
    my $var_addr = qq[${var_type}_];
    if ( ref $_[1] ) {
        $var_addr .= refaddr( $_[1] );
    }
    else {
        $var_addr .= refaddr( \$_[1] );
    }

    my $res;
    my $tags;
    if ( $var_addr && exists $self->_seen->{$var_addr} ) {
        $res = colored( $self->_seen->{$var_addr}, $COLOR->{seen} );
    }
    else {
        $self->_seen->{$var_addr} = $args{path};
        my $dump_method = $blessed ? 'BLESSED' : $var_type;
        $dump_method = 'UNKNOWN' if !$self->can($dump_method);

        ( $res, $tags ) = $self->$dump_method( $_[1], path => $args{path}, var_type => $var_type );
    }

    # weak
    push @{$tags}, q[weak] if isweak( $_[1] );

    # add tags
    $self->_add_tags( $tags, $res );

    return $res;
}

sub _var_type {
    my $self = shift;
    my %args = (
        unbless => 0,
        splice( @_, 1 ),
    );

    my $ref_type = reftype( $_[0] );

    if ( my $blessed = blessed( $_[0] ) ) {    # blessed
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
            if ( $ref_type ~~ [qw[SCALAR VSTRING GLOB]] ) {
                return 'REF';
            }
            else {
                return $ref_type;
            }
        }
        else {
            return CORE::ref( \$_[0] );
        }
    }
}

sub _indent_text {
    my $self = shift;

    my $indent = $self->_indent;
    $_[0] =~ s/\n/\n$indent/smg;

    return;
}

sub _add_tags {
    my $self = shift;
    my $tags = shift;

    $_[0] .= q[ # ] . join q[, ], $tags->@* if $tags && @{$tags};

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
        push @{ $_[0] }, 'tied to ' . ref $tied;
    }

    return;
}

# REF DUMPERS
sub UNKNOWN {
    my $self = shift;
    my %args = (
        var_type => q[],
        @_,
    );

    return colored( 'unknown: ' . $args{var_type}, $COLOR->{unknown} );
}

sub BLESSED {
    my $self = shift;
    my $obj  = shift;
    my %args = (
        path => undef,
        @_,
    );

    my $ref = ref $obj;

    my $res = colored( $ref . ' {', $COLOR->{class} ) . qq[\n];

    my $tags;

    my $dumped;

    # @ISA
    {
        no strict qw[refs];

        if ( my @superclasses = @{ $ref . '::ISA' } ) {
            $res .= $self->_indent . '@ISA: ' . join q[, ], map { colored( $_, $COLOR->{class} ) } @superclasses;

            $res .= qq[,\n];
        }
    }

    # reafddr
    $res .= $self->_indent . 'refaddr: ' . refaddr($obj) . qq[,\n];

    # class dump method
    if ( my $dump_method = $self->dump_method && $obj->can( $self->dump_method ) ) {
        my ( $dump, $dump_tags ) = $obj->$dump_method( $self, path => $args{path} );

        if ($dump) {
            $dumped = 1;

            $self->_indent_text($dump);

            $res .= $self->_indent . $dump;
        }

        push $tags->@*, $dump_tags->@* if $dump_tags;
    }

    # predefined dumper sub for class
    if ( !$dumped && $DUMPERS->{$ref} ) {
        my ( $dump, $dump_tags ) = $DUMPERS->{$ref}->( $obj, $self, path => $args{path} );

        if ($dump) {
            $dumped = 1;

            $self->_indent_text($dump);

            $res .= $self->_indent . $dump;
        }

        push $tags->@*, $dump_tags->@* if $dump_tags;
    }

    if ( !$dumped ) {

        # blessed
        my $blessed = $self->_dump_blessed( $obj, path => $args{path} );

        $self->_indent_text($blessed);

        $res .= $self->_indent . $blessed;
    }

    $res .= qq[\n] . colored( '}', $COLOR->{class} );

    return $res, $tags;
}

sub REF {
    my $self = shift;
    my $ref  = shift;
    my %args = (
        path => undef,
        @_,
    );

    return colored( q[\\ ], $COLOR->{refs} ) . $self->_dump( ${$ref}, path => $args{path} . q[->$*] );
}

sub SCALAR {
    my $self = shift;

    my $res;
    my $tags;

    if ( !defined $_[0] ) {    # undefined value
        $res = colored( 'undef', $COLOR->{undef} );
    }
    elsif ( looks_like_number( $_[0] ) ) {
        $res = colored( add_num_sep( $_[0] ), $COLOR->{number} );
    }
    else {
        my $item         = $_[0];                  # scalar become untied
        my $bytes_length = bytes::length($item);
        my $length       = length $item;
        escape_scalar( $item, esc_color => $COLOR->{escaped}, reset_color => $COLOR->{string} );

        if ( utf8::is_utf8($item) ) {              # characters
            push @{$tags}, q[UTF8];

            if ( $bytes_length == $length ) {
                push @{$tags}, q[single-byte, downgradable];    # ASCII-7bit (bytes in perl terminology), UTF8 flag can be dropped
            }
            else {
                push @{$tags}, q[multi-byte];
            }

            push @{$tags}, q[len = ] . $length;
        }
        else {                                                  # octets
            if ( $item =~ /[[:^ascii:]]/sm ) {                  # if has non-ASCII-7bit bytes - treats buffer as binary
                push @{$tags}, q[latin1];
            }
            else {                                              # if contains only ASCII-7bit bytes - treats buffer as string
                push @{$tags}, q[ASCII];
            }
        }

        push @{$tags}, q[bytes::len = ] . $bytes_length;
        push @{$tags}, q[tied to ] . ref tied $_[0] if tainted( $_[0] );

        $res = q["] . colored( $item, $COLOR->{string} ) . q["];
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

    my $res;
    my $tags;
    if ( !@{$array_ref} ) {
        $res = colored( q[[]], $COLOR->{refs} );
    }
    else {
        $res = colored( q{[}, $COLOR->{refs} ) . $LF;
        my $max_index_length = length( $#{$array_ref} ) + 2;

        for my $i ( 0 .. $#{$array_ref} ) {
            my $index = sprintf( q[%-*s], $max_index_length, qq[[$i]] ) . q[ ];
            $res .= $self->_indent . colored( $index, $COLOR->{array} );

            my $el = $self->_dump( $array_ref->[$i], path => $args{path} . "->[$i]" );
            $self->_indent_text($el);

            $res .= $el;
            $res .= qq[,\n] if $i != $#{$array_ref};    # not last array element
        }

        $res .= $LF . colored( q{]}, $COLOR->{refs} );
    }

    $self->_tied_to( tied @{$array_ref}, $tags );

    return $res, $tags;
}

sub HASH {
    my $self     = shift;
    my $hash_ref = shift;
    my %args     = (
        path => undef,
        @_,
    );

    my $res;
    my $tags;
    if ( !keys %{$hash_ref} ) {
        $res = colored( q[{}], $COLOR->{refs} );
    }
    else {
        $res = colored( '{', $COLOR->{refs} ) . $LF;
        my $keys;
        my $max_length = 0;
        for ( nsort keys $hash_ref->%* ) {
            my $indexed_key = {
                raw_key     => $_,
                escaped_key => \escape_scalar( $_, esc_color => $COLOR->{escaped}, reset_color => $COLOR->{hash} ),
            };

            $indexed_key->{escaped_key_nc} = $indexed_key->{escaped_key}->$*;

            remove_ansi $indexed_key->{escaped_key_nc};

            $indexed_key->{escaped_key_nc_len} = length $indexed_key->{escaped_key_nc};

            push @{$keys}, $indexed_key;

            $max_length = $indexed_key->{escaped_key_nc_len} if $indexed_key->{escaped_key_nc_len} > $max_length;
        }

        my $indent = $max_length + 8;

        for my $i ( 0 .. $#{$keys} ) {
            $res .= $self->_indent . q["] . colored( $keys->[$i]->{escaped_key}->$*, $COLOR->{hash} ) . q["];
            $res .= sprintf q[%*s], ( $max_length - $keys->[$i]->{escaped_key_nc_len} + 4 ), q[ => ];

            my $el = $self->_dump( $hash_ref->{ $keys->[$i]->{raw_key} }, path => $args{path} . '->{"' . $keys->[$i]->{escaped_key_nc} . '"}' );
            $self->_indent_text($el);

            $res .= $el;
            $res .= qq[,\n] if $i != $#{$keys};    # not last hash key
        }

        $res .= $LF . colored( '}', $COLOR->{refs} );
    }

    $self->_tied_to( tied %{$hash_ref}, $tags );

    return $res, $tags;
}

sub VSTRING {
    my $self = shift;

    return colored( version->declare( $_[0] )->normal, $COLOR->{vstring} );
}

sub GLOB {
    my $self = shift;

    my $res;
    my $tags;
    my $i;
    my $flags  = [];
    my $layers = q[];

    for ( PerlIO::Layers::get_layers( $_[0] ) ) {
        unless ($i) {
            $i = 1;

            $flags = $_->[2];
        }
        $layers .= qq[:$_->[0]];

        $layers .= qq[($_->[1])] if defined $_->[1];    # add layer encoding

        $layers .= q[:utf8] if q[UTF8] ~~ $_->[2];      # add :utf8 layer, if defined
    }

    my $fileno = eval { fileno $_[0] };

    push @{$tags}, nsort @{$flags};

    push @{$tags}, $layers if $layers;

    push @{$tags}, qq[fileno = $fileno] if defined $fileno;

    $self->_tied_to( tied $_[0], $tags );

    {
        no overloading;

        $res = colored( "$_[0]", $COLOR->{glob} );
    }

    return $res, $tags;
}

# TODO - more informative dumper for IO refs
sub IO {
    my $self = shift;

    return $self->GLOB(@_);
}

sub CODE {
    my $self = shift;

    return colored( q[sub { ... }], $COLOR->{code} );
}

sub REGEXP {
    my $self = shift;

    my ( $pat, $flags ) = re::regexp_pattern( $_[0] );
    $flags //= q[];

    return colored( qq[qr/$pat/$flags], $COLOR->{regex} );
}

sub FORMAT {
    my $self = shift;

    return colored( 'FORMAT', $COLOR->{format} );
}

sub LVALUE {
    my $self = shift;

    my ( $res, $tags ) = $self->SCALAR( ${ $_[0] } );
    unshift @{$tags}, 'LVALUE';

    return $res, $tags;
}

1;
## -----SOURCE FILTER LOG BEGIN-----
##
## PerlCritic profile "pcore-script" policy violations:
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
## | Sev. | Lines                | Policy                                                                                                         |
## |======+======================+================================================================================================================|
## |    1 | 80, 231, 293         | ValuesAndExpressions::RequireInterpolationOfMetachars - String *may* require interpolation                     |
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
