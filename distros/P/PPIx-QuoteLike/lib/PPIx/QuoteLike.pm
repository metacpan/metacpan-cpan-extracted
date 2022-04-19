package PPIx::QuoteLike;

use 5.006;

use strict;
use warnings;

use Carp;
use Encode ();
use List::Util ();
use PPIx::QuoteLike::Constant qw{
    ARRAY_REF
    LOCATION_LINE
    LOCATION_CHARACTER
    LOCATION_COLUMN
    LOCATION_LOGICAL_LINE
    LOCATION_LOGICAL_FILE
    MINIMUM_PERL
    VARIABLE_RE
    @CARP_NOT
};
use PPIx::QuoteLike::Token::Control;
use PPIx::QuoteLike::Token::Delimiter;
use PPIx::QuoteLike::Token::Interpolation;
use PPIx::QuoteLike::Token::String;
use PPIx::QuoteLike::Token::Structure;
use PPIx::QuoteLike::Token::Unknown;
use PPIx::QuoteLike::Token::Whitespace;
use PPIx::QuoteLike::Utils qw{
    column_number
    line_number
    logical_filename
    logical_line_number
    statement
    visual_column_number
    __instance
    __match_enclosed
    __matching_delimiter
};
use Scalar::Util ();

our $VERSION = '0.022';

use constant CLASS_CONTROL       => 'PPIx::QuoteLike::Token::Control';
use constant CLASS_DELIMITER     => 'PPIx::QuoteLike::Token::Delimiter';
use constant CLASS_INTERPOLATION => 'PPIx::QuoteLike::Token::Interpolation';
use constant CLASS_STRING        => 'PPIx::QuoteLike::Token::String';
use constant CLASS_STRUCTURE     => 'PPIx::QuoteLike::Token::Structure';
use constant CLASS_UNKNOWN       => 'PPIx::QuoteLike::Token::Unknown';
use constant CLASS_WHITESPACE    => 'PPIx::QuoteLike::Token::Whitespace';

use constant CODE_REF	=> ref sub {};

use constant ILLEGAL_FIRST	=>
    'Tokenizer found illegal first characters';
use constant MISMATCHED_DELIM	=>
    'Tokenizer found mismatched delimiters';
use constant NO_INDENTATION	=>
    'No indentation string found';

{
    my $match_sq = __match_enclosed( qw< ' > );
    my $match_dq = __match_enclosed( qw< " > );
    my $match_bt = __match_enclosed( qw< ` > );

    sub new {	## no critic (RequireArgUnpacking)
	my ( $class, $source, %arg ) = @_;

	my @children;

	if ( $arg{location} ) {
	    ARRAY_REF eq ref $arg{location}
		or croak q<Argument 'location' must be an array reference>;
	    foreach my $inx ( 0 .. 3 ) {
		$arg{location}[$inx] =~ m/ [^0-9] /smx
		    and croak "Argument 'location' element $inx must be an unsigned integer";
	    }
	}

	if ( ! defined $arg{index_locations} ) {
	    $arg{index_locations} = !! $arg{location} ||
		__instance( $source, 'PPI::Element' );
	}

	my $self = {
	    index_locations	=> $arg{index_locations},
	    children	=> \@children,
	    encoding	=> $arg{encoding},
	    failures	=> 0,
	    location	=> $arg{location},
	    source	=> $source,
	};

	bless $self, ref $class || $class;

	defined( my $string = $self->_stringify_source( $source ) )
	    or return;

	my ( $type, $gap, $gap2, $content, $end_delim, $indented, $start_delim );

	$arg{trace}
	    and warn "Initial match of $string\n";

	# q<>, qq<>, qx<>
	if ( $string =~ m/ \A \s* ( q [qx]? ) ( \s* ) ( . ) /smxgc ) {
	    ( $type, $gap, $start_delim ) = ( $1, $2, $3 );
	    not $gap
		and $start_delim =~ m< \A \w \z >smx
		and return $self->_link_elems( $self->_make_token(
		    CLASS_UNKNOWN, $string, error => ILLEGAL_FIRST ) );
	    $arg{trace}
		and warn "Initial match '$type$start_delim'\n";
	    $self->{interpolates} = 'qq' eq $type ||
		'qx' eq $type && q<'> ne $start_delim;
	    $content = substr $string, ( pos $string || 0 );
	    $end_delim = __matching_delimiter( $start_delim );
	    if ( $end_delim eq substr $content, -1 ) {
		chop $content;
	    } else {
		$end_delim = '';
	    }

	# here doc
	# Note that the regexp used here is slightly wrong in that white
	# space between the '<<' and the termination string is not
	# allowed if the termination string is not quoted in some way.
	} elsif ( $string =~ m/ \A \s* ( << ) ( \s* ) ( ~? ) ( \s* )
	    ( [\\]? \w+ | $match_sq | $match_dq | $match_bt ) \n /smxgc ) {
	    ( $type, $gap, $indented, $gap2, $start_delim ) = (
		$1, $2, $3, $4, $5 );
	    $arg{trace}
		and warn "Initial match '$type$start_delim$gap$indented'\n";
	    $self->{interpolates} = $start_delim !~ m/ \A [\\'] /smx;
	    $content = substr $string, ( pos $string || 0 );
	    $end_delim = _unquote( $start_delim );
	    # NOTE that the indentation is specifically space or tab
	    # only.
	    if ( $content =~ s/ ^ ( [ \t]* ) \Q$end_delim\E \n? \z //smx ) {
		# NOTE PPI::Token::HereDoc does not preserve the
		# indentation of an indented here document, so the
		# indentation will appear to be '' if we came from PPI.
		if ( $indented ) {
		    # Version per perldelta.pod for that release.
		    $self->{perl_version_introduced} = '5.025007';
		    $self->{indentation} = "$1";
		    $self->{_indentation_re} = qr/
			^ \Q$self->{indentation}\E /smx;
		}
	    } else {
		$end_delim = '';
	    }
	    $self->{start} = [
		$self->_make_token( CLASS_DELIMITER, $start_delim ),
		$self->_make_token( CLASS_WHITESPACE, "\n" ),
	    ];

	    # Don't instantiate yet -- we'll do them at the end.
	    $self->{finish} = [
		[ CLASS_DELIMITER, $end_delim ],
		[ CLASS_WHITESPACE, "\n" ],
	    ];

	# ``, '', "", <>
	} elsif ( $string =~ m/ \A \s* ( [`'"<] ) /smxgc ) {
	    ( $type, $gap, $start_delim ) = ( '', '', $1 );
	    $arg{trace}
		and warn "Initial match '$type$start_delim'\n";
	    $self->{interpolates} = q<'> ne $start_delim;
	    $content = substr $string, ( pos $string || 0 );
	    $end_delim = __matching_delimiter( $start_delim );
	    if ( $end_delim eq substr $content, -1 ) {
		chop $content;
	    } else {
		$end_delim = '';
	    }

	# Something we do not recognize
	} else {
	    $arg{trace}
		and warn "No initial match\n";
	    return $self->_link_elems( $self->_make_token(
		    CLASS_UNKNOWN, $string, error => ILLEGAL_FIRST ) );
	}

	$self->{interpolates} = $self->{interpolates} ? 1 : 0;

	defined or $_ = '' for $indented, $gap2;
	$self->{type} = [
	    $self->_make_token( CLASS_STRUCTURE, $type ),
	    length $gap ?
		$self->_make_token( CLASS_WHITESPACE, $gap ) :
		(),
	    length $indented ?
	        $self->_make_token( CLASS_STRUCTURE, $indented ) :
		(),
	    length $gap2 ?
		$self->_make_token( CLASS_WHITESPACE, $gap2 ) :
		(),
	];
	$self->{start} ||= [
	    $self->_make_token( CLASS_DELIMITER, $start_delim ),
	];

	$arg{trace}
	    and warn "Without delimiters: '$content'\n";

	# We accumulate data and manufacure tokens at the end to reduce
	# the overhead involved in merging strings.
	if ( $self->{interpolates} ) {
	    push @children, [ '' => '' ];	# Prime the pump
	    while ( 1 ) {

		if ( $content =~ m/ \G ( \\ [ULulQEF] ) /smxgc ) {
		    push @children, [ CLASS_CONTROL, "$1" ];
		} elsif (
		    $content =~ m/ \G ( \\ N [{] ( [^}]+ ) [}] ) /smxgc
		) {
		    # Handle \N{...} separately because it can not
		    # contain an interpolation even inside of an
		    # otherwise-interpolating string. That is to say,
		    # "\N{$foo}" is simply invalid, and does not even
		    # try to interpolate $foo.  {
		    # TODO use $re = __match_enclosed( '{' ); # }
		    my ( $seq, $name ) = ( $1, $2 );
		    # TODO The Regexp is certainly too permissive. For
		    # the moment all I am doing is disallowing
		    # interpolation.
		    push @children, $name =~ m/ [\$\@] /smx ?
			[ CLASS_UNKNOWN, $seq,
			    error => "Unknown charname '$name'" ] :
			[ CLASS_STRING, $seq ];
		# NOTE in the following that I do not read perldata as
		# saying there can be space between the sigil and the
		# variable name, but Perl itself seems to accept it as
		# of 5.30.1.
		} elsif ( $content =~ m/ \G ( [\$\@] \#? \$* ) /smxgc ) {
		    push @children, $self->_interpolation( "$1", $content );
		} elsif ( $content =~ m/ \G ( \\ . | [^\\\$\@]+ ) /smxgc ) {
		    push @children, $self->_remove_here_doc_indentation(
			"$1",
			sibling	=> \@children,
		    );
		} else {
		    last;
		}
	    }

	    @children = _merge_strings( @children );
	    shift @children;	# remove the priming

	    # Make the tokens, at long last.
	    foreach ( @children ) {
		$_ = $self->_make_token( @{ $_ } );
	    }

	} else {

	    length $content
		and push @children, map { $self->_make_token( @{ $_ } ) }
		    _merge_strings(
			$self->_remove_here_doc_indentation( $content )
			);

	}

	# Add the indentation before the end marker, if needed
	$self->{indentation}
	    and push @children, $self->_make_token(
	    CLASS_WHITESPACE, $self->{indentation} );

	if ( $self->{finish} ) {
	    # If we already have something here it is data, not objects.
	    foreach ( @{ $self->{finish} } ) {
		$_ = $self->_make_token( @{ $_ } );
	    }
	} else {
	    $self->{finish} = [
		$self->_make_token( CLASS_DELIMITER, $end_delim ),
	    ];
	}

	ref $_[1]
	    and pos( $_[1] ) = pos $string;

	return $self->_link_elems();
    }
}

sub child {
    my ( $self, $number ) = @_;
    return $self->{children}[$number];
}

sub children {
    my ( $self ) = @_;
    return @{ $self->{children} };
}

sub content {
    my ( $self ) = @_;
    return join '', map { $_->content() } grep { $_ } $self->elements();
}

sub delimiters {
    my ( $self ) = @_;
    return join '', grep { defined }
	map { $self->_get_value_scalar( $_ ) }
	qw{ start finish };
}

#	$self->_deprecation_notice( $type, $name );
#
#	This method centralizes deprecation. Type is 'attribute' or
#	'method'. Deprecation is driven of the %deprecate hash. Values
#	are:
#	    false - no warning
#	    1 - warn on first use
#	    2 - warn on each use
#	    3 - die on each use.
#
#	$self->_deprecation_in_progress( $type, $name )
#
#	This method returns true if the deprecation is in progress. In
#	fact it returns the deprecation level.

=begin comment

# Abandoned in place, against future need.

{

    my %deprecate = (
	attribute => {
	    postderef	=> 3,
	},
    );

    sub _deprecation_notice {
	my ( undef, $type, $name, $repl ) = @_;		# Invocant unused
	$deprecate{$type} or return;
	$deprecate{$type}{$name} or return;
	my $msg = sprintf 'The %s %s is %s', $name, $type,
	    $deprecate{$type}{$name} > 2 ? 'removed' : 'deprecated';
	defined $repl
	    and $msg .= "; use $repl instead";
	$deprecate{$type}{$name} >= 3
	    and croak $msg;
	warnings::enabled( 'deprecated' )
	    and carp $msg;
	$deprecate{$type}{$name} == 1
	    and $deprecate{$type}{$name} = 0;
	return;
    }

}

=end comment

=cut

sub _get_value_scalar {
    my ( $self, $method ) = @_;
    defined( my $val = $self->$method() )
	or return;
    return ref $val ? $val->content() : $val;
}

sub elements {
    my ( $self ) = @_;
    return @{ $self->{elements} ||= [
	map { $self->$_() } qw{ type start children finish }
    ] };
}

sub encoding {
    my ( $self ) = @_;
    return $self->{encoding};
}

sub failures {
    my ( $self ) = @_;
    return $self->{failures};
}

sub find {
    my ( $self, $target ) = @_;

    my $check = CODE_REF eq ref $target ? $target :
    ref $target ? croak 'find() target may not be ' . ref $target :
    sub { $_[0]->isa( $target ) };
    my @found;
    foreach my $elem ( $self, $self->elements() ) {
	$check->( $elem )
	    and push @found, $elem;
    }

    @found
	or return 0;

    return \@found;
}

sub finish {
    my ( $self, $inx ) = @_;
    $self->{finish}
	or return;
    wantarray
	and return @{ $self->{finish} };
    return $self->{finish}[ $inx || 0 ];
}

sub handles {
    my ( $self, $string ) = @_;
    return $self->_stringify_source( $string, test => 1 );
}

sub indentation {
    my ( $self ) = @_;
    return $self->{indentation};
}

sub interpolates {
    my ( $self ) = @_;
    return $self->{interpolates};
}

sub location {
    my ( $self ) = @_;
    return $self->type()->location();
}

sub _make_token {
    my ( $self, $class, $content, %arg ) = @_;
    my $token = $class->__new( content => $content, %arg );
    CLASS_UNKNOWN eq $class
	and $self->{failures}++;
    $self->{index_locations}
	and $self->_update_location( $token );
    return $token;
}

sub _update_location {
    my ( $self, $token ) = @_;
    $token->{location}	# Idempotent
	and return;
    my $loc = $self->{_location} ||= do {
	my %loc = (
	    line_content	=> '',
	    location		=> $self->{location},
	);
	if ( __instance( $self->{source}, 'PPI::Element' ) ) {
	    $loc{location} ||= $self->{source}->location();
	    if ( my $doc = $self->{source}->document() ) {
		$loc{tab_width} = $doc->tab_width();
	    }
	}
	$loc{tab_width} ||= 1;
	\%loc;
    };
    $loc->{location}
	or return;
    $token->{location} = [ @{ $loc->{location} } ];

    if ( defined( my $content = $token->content() ) ) {

	my $lines;
	pos( $content ) = 0;
	$lines++ while $content =~ m/ \n /smxgc;
	if ( pos $content ) {
	    $loc->{location}[LOCATION_LINE] += $lines;
	    $loc->{location}[LOCATION_LOGICAL_LINE] += $lines;
	    $loc->{location}[LOCATION_CHARACTER] =
		$loc->{location}[LOCATION_COLUMN] = 1;
	}

	if ( my $chars = length( $content ) - pos( $content ) ) {
	    $loc->{location}[LOCATION_CHARACTER] += $chars;
	    if ( $loc->{tab_width} > 1 && $content =~ m/ \t /smx ) {
		my $pos = $loc->{location}[LOCATION_COLUMN];
		my $tab_width = $loc->{tab_width};
		# Stolen shamelessly from PPI::Document::_visual_length
		my ( $vis_inc );
		foreach my $part ( split /(\t)/, $content ) {
		    if ($part eq "\t") {
			$vis_inc = $tab_width - ($pos-1) % $tab_width;
		    } else {
			$vis_inc = length $part;
		    }
		    $pos    += $vis_inc;
		}
		$loc->{location}[LOCATION_COLUMN] = $pos;
	    } else {
		$loc->{location}[LOCATION_COLUMN] += $chars;
	    }
	}

    }

    return;
}

sub parent {
    return;
}

sub perl_version_introduced {
    my ( $self ) = @_;
    return List::Util::max( grep { defined $_ } MINIMUM_PERL,
	$self->{perl_version_introduced},
	map { $_->perl_version_introduced() } $self->elements() );
}

sub perl_version_removed {
    my ( $self ) = @_;
    my $max;
    foreach my $elem ( $self->elements() ) {
	if ( defined ( my $ver = $elem->perl_version_removed() ) ) {
	    if ( defined $max ) {
		$ver < $max and $max = $ver;
	    } else {
		$max = $ver;
	    }
	}
    }
    return $max;
}

sub schild {
    my ( $self, $inx ) = @_;
    $inx ||= 0;
    my @kids = $self->schildren();
    return $kids[$inx];
}

sub schildren {
    my ( $self ) = @_;
    return (
	grep { $_->significant() } $self->children()
    );
}

sub source {
    my ( $self ) = @_;
    return $self->{source};
}

sub start {
    my ( $self, $inx ) = @_;
    $self->{start}
	or return;
    wantarray
	and return @{ $self->{start} };
    return $self->{start}[ $inx || 0 ];
}

sub top {
    my ( $self ) = @_;
    return $self;
}

sub type {
    my ( $self, $inx ) = @_;
    $self->{type}
	or return;
    wantarray
	and return @{ $self->{type} };
    return $self->{type}[ $inx || 0 ];
}

sub variables {
    my ( $self ) = @_;

    $self->interpolates()
	or return;

    my %var;
    foreach my $kid ( $self->children() ) {
	foreach my $sym ( $kid->variables() ) {
	    $var{$sym} = 1;
	}
    }
    return ( keys %var );
}

sub _chop {
    my ( $middle ) = @_;
    my $left = substr $middle, 0, 1, '';
    my $right = substr $middle, -1, 1, '';
    return ( $left, $middle, $right );
}

# decode data using the object's {encoding}
# It is anticipated that if I make PPIx::Regexp depend on this package,
# that this will be called there.

sub __decode {
    my ( $self, $data, $encoding ) = @_;
    $encoding ||= $self->{encoding};
    defined $encoding
	and _encode_available()
	or return $data;
    return Encode::decode( $encoding, $data );
}

{

    my $encode_available;

    sub _encode_available {
	defined $encode_available and return $encode_available;
	return ( $encode_available = eval {
		require Encode;
		1;
	    } ? 1 : 0
	);
    }

}

{
    my ( $cached_doc, $cached_encoding );

    # These are the byte order marks documented as being recognized by
    # PPI. Only utf-8 is documented as supported.
    my %known_bom = (
	'EFBBBF'	=> 'utf-8',
	'0000FEFF'	=> 'utf-32be',
	'FFFE0000'	=> 'utf-32le',
	'FEFF'		=> 'utf-16be',
	'FFFE'		=> 'utf-16le',
    );

    sub _get_ppi_encoding {
	my ( $elem ) = @_;

	my $doc = $elem->top()
	    or return;

	$cached_doc
	    and $doc == $cached_doc
	    and return $cached_encoding;

	my $bom = $doc->first_element()
	    or return;

	Scalar::Util::weaken( $cached_doc = $doc );

	if ( $bom->isa( 'PPI::Token::BOM' ) ) {
	    return ( $cached_encoding = $known_bom{
		uc unpack 'H*', $bom->content() } );
	}

	$cached_encoding = undef;

	foreach my $use (
	    @{ $doc->find( 'PPI::Statement::Include' ) || [] }
	) {
	    'use' eq $use->type()
		or next;
	    defined( my $module = $use->module() )
		or next;
	    'utf8' eq $module
		or next;
	    $cached_encoding = 'utf-8';
	    last;
	}

	return $cached_encoding;

    }

}

# This subroutine was created in an attempt to simplify control flow.
# Argument 2 (from 0) is not unpacked because the caller needs to see
# the side effects of matches made on it.

{

    my %special = (
	'$$'	=> sub {	# Process ID.
	    my ( undef, $sigil ) = @_;
	    return [ CLASS_INTERPOLATION, $sigil ];
	},
	'$'	=> sub {	# Called if we find (e.g.) '$@'
	    my ( undef, $sigil ) = @_;
	    $_[2] =~ m/ \G ( [\@] ) /smxgc
		or return;
	    return [ CLASS_INTERPOLATION, "$sigil$1" ];
	},
	'@'	=> sub {	# Called if we find '@@'.
	    my ( undef, $sigil ) = @_;
	    return [ CLASS_STRING, $sigil ];
	},
    );

    sub _interpolation {	## no critic (RequireArgUnpacking)
	my ( $self, $sigil ) = @_;
	# Argument $_[2] is $content, but we can't unpack it because we
	# need the caller to see any changes to pos().

	if ( $_[2] =~ m/ \G (?= \{ ) /smxgc ) {
	    # variable name enclosed in {}
	    my $delim_re = __match_enclosed( qw< { > );
	    if ( $_[2] =~ m/ \G $delim_re /smxgc ) {
		my $rest = $1;
		$rest =~ m/ \A \{ \s* \[ ( .* ) \] \s* \} \z /smx
		    or return [ CLASS_INTERPOLATION, "$sigil$rest" ];
		# At this point we have @{[ ... ]}.
		my @arg;
		_has_postderef( "$1" )
		    and push @arg, postderef => 1;
		return [ CLASS_INTERPOLATION, "$sigil$rest", @arg ];
	    }
	    $_[2] =~ m/ \G ( .* ) /smxgc
		and return [ CLASS_UNKNOWN, "$sigil$1",
		    error => MISMATCHED_DELIM ];
	    confess 'Failed to match /./';
	}

	if ( $_[2] =~ m< \G ( @{[ VARIABLE_RE ]} ) >smxgco
	) {
	    # variable name not enclosed in {}
	    my $interp = "$sigil$1";
	    while ( $_[2] =~ m/ \G  ( (?: -> )? ) (?= ( [[{] ) ) /smxgc ) { # }]
		my $lead_in = $1;
		my $delim_re = __match_enclosed( $2 );
		if ( $_[2] =~ m/ \G ( $delim_re ) /smxgc ) {
		    $interp .= "$lead_in$1";
		} else {
		    $_[2] =~ m/ ( .* ) /smxgc;
		    return (
			[ CLASS_INTERPOLATION, $interp ],
			[ CLASS_UNKNOWN, "$1", error => MISMATCHED_DELIM ],
		    );
		}
	    }

	    my @arg;

	    if ( defined( my $deref = _match_postderef( $_[2] ) ) ) {
		$interp .= $deref;
		push @arg, postderef => 1;
	    }

	    return [ CLASS_INTERPOLATION, $interp, @arg ];
	}

	my $code;
	$code = $special{$sigil}
	    and my $elem = $code->( $self, $sigil, $_[2] )
	    or return [ CLASS_UNKNOWN, $sigil,
		error => 'Sigil without interpolation' ];

	return $elem;
    }

}

sub _link_elems {
    my ( $self, @arg ) = @_;

    push @{ $self->{children} }, @arg;

    foreach my $key ( qw{ type start children finish } ) {
	my $prev;
	foreach my $elem ( @{ $self->{$key} } ) {
	    Scalar::Util::weaken( $elem->{parent} = $self );
	    if ( $prev ) {
		Scalar::Util::weaken( $elem->{previous_sibling} = $prev );
		Scalar::Util::weaken( $prev->{next_sibling} = $elem );
	    }
	    $prev = $elem;
	}
    }

    return $self;
}

{
    my %allow_subscr	= map { $_ => 1 } qw{ % @ };

    # Match a postfix deref at the current position in the argument. If
    # a match occurs it is returned, and the current position is
    # updated. If not, nothing is returned, and the current position in
    # the argument remains unchanged.
    # This would all be much easier if I could count on Perl 5.10
    sub _match_postderef {	## no critic (RequireArgUnpacking)
	my $pos = pos $_[0];
	# Only scalars and arrays interpolate
	$_[0] =~ m/ \G ( -> ) ( \$ \# | [\$\@] ) /smxgc
	    or return;
	my $match = "$1$2";
	my $sigil = $2;
	$_[0] =~ m/ \G ( [*] ) /smxgc
	    and return "$match$1";

	if (
	    $allow_subscr{$sigil} &&
	    $_[0] =~ m/ \G (?= ( [[{] ) ) /smxgc	# }]
	) {
	    my $re = __match_enclosed( "$1" );
	    $_[0] =~ m/ \G $re /smxgc
		and return "$match$1";
	}

	pos $_[0] = $pos;
	return;
    }
}

{
    no warnings qw{ qw };	## no critic (ProhibitNoWarnings)
    my %is_postderef = map { $_ => 1 } qw{ $ $# @ % & * $* $#* @* %* &* ** };
    sub _has_postderef {
	my ( $string ) = @_;
	my $doc = PPI::Document->new( \$string );
	foreach my $elem ( @{ $doc->find( 'PPI::Token::Symbol' ) || [] } ) {
	    my $next = $elem->snext_sibling()
		or next;
	    $next->isa( 'PPI::Token::Operator' )
		or next;
	    $next->content() eq '->'
		or next;
	    $next = $next->snext_sibling()
		or next;
	    $next->isa( 'PPI::Token::Cast' )
		or next;
	    my $content = $next->content();
	    $is_postderef{$content}
		or next;
	    $content =~ m/ \* \z /smx
		and return 1;
	    $next = $next->snext_sibling()
		or next;
	    $next->isa( 'PPI::Structure::Subscript' )
		and return 1;
	}
	return 0;
    }
}

# For various reasons we may get consecutive literals -- typically
# strings. We want to merge these. The arguments are array refs, with
# the class name of the token in [0] and the content in [1]. I know of
# no way we can generate consecutive white space tokens, but if I did I
# would want them merged.
#
# NOTE that merger loses all attributes of the second token, so we MUST
# NOT merge CLASS_UNKNOWN tokens, or any class that might have
# attributes other than content.
{
    my %can_merge = map { $_ => 1 } CLASS_STRING, CLASS_WHITESPACE;

    sub _merge_strings {
	my @arg = @_;
	my @rslt;
	foreach my $elem ( @arg ) {
	    if ( @rslt && $can_merge{$elem->[0]}
		&& $elem->[0] eq $rslt[-1][0]
	    ) {
		$rslt[-1][1] .= $elem->[1];
	    } else {
		push @rslt, $elem;
	    }
	}
	return @rslt;
    }
}

# If we're processing an indented here document, strings must be split
# on new lines and un-indented. We return array refs rather than
# objects because we may be called before we're ready to build the
# objects.
sub _remove_here_doc_indentation {
    my ( $self, $string, %arg ) = @_;

    # NOTE that we rely on the fact that both undef (not indented) and
    # '' (indented by zero characters) evaluate false.
    $self->{indentation}
	or return [ CLASS_STRING, $string ];

    my $ignore_first;
    if ( $arg{sibling} ) {
	# Because the calling code primes the pump, @sibling will never
	# be empty, even when processing the first token. So:
	# * The pump-priming specifies class '', so if that is what we
	#   see we must process the first line; otherwise
	# * If the previous token is a string ending in "\n", we must
	#   process the first line.
	$ignore_first = '' ne $arg{sibling}[-1][0] && (
	    CLASS_STRING ne $arg{sibling}[-1][0] ||
	    $arg{sibling}[-1][1] !~ m/ \n \z /smx );
    } else {
	# Without @sibling, we unconditionally process the first line.
	$ignore_first = 0;
    }

    my @rslt;

    foreach ( split qr/ (?<= \n ) /smx, $string ) {
	if ( $ignore_first ) {
	    push @rslt, [ CLASS_STRING, "$_" ];
	    $ignore_first = 0;
	} else {
	    if ( "\n" eq $_ ) {
		push @rslt,
		    [ CLASS_STRING, "$_" ],
		    ;
	    } elsif ( s/ ( $self->{_indentation_re} ) //smx ) {
		push @rslt,
		    [ CLASS_WHITESPACE, "$1" ],
		    [ CLASS_STRING, "$_" ],
		    ;
	    } else {
		push @rslt,
		    [ CLASS_UNKNOWN, "$_", error => NO_INDENTATION ],
		    ;
	    }
	}
    }

    return @rslt;
}

sub _stringify_source {
    my ( $self, $string, %opt ) = @_;

    if ( Scalar::Util::blessed( $string ) ) {

	$string->isa( 'PPI::Element' )
	    or return;

	foreach my $class ( qw{
	    PPI::Token::Quote
	    PPI::Token::QuoteLike::Backtick
	    PPI::Token::QuoteLike::Command
	    PPI::Token::QuoteLike::Readline
	} ) {
	    $string->isa( $class )
		or next;
	    $opt{test}
		and return 1;

	    my $encoding = _get_ppi_encoding( $string );
	    return $self->__decode( $string->content(), $encoding );
	}

	if ( $string->isa( 'PPI::Token::HereDoc' ) ) {
	    $opt{test}
		and return 1;

	    my $encoding = _get_ppi_encoding( $string );
	    my $heredoc = join '',
		map { $self->__decode( $_, $encoding) }
		$string->heredoc();
	    my $terminator = $self->__decode( $string->terminator(),
		$encoding );
	    $terminator =~ s/ (?<= \n ) \z /\n/smx;
	    return $self->__decode( $string->content(), $encoding ) .
		"\n" . $heredoc . $terminator;
	}

	return;

    }

    ref $string
	and return;

    $string =~ m/ \A \s* (?: q [qx]? | << | [`'"<] ) /smx
	and return $opt{test} ? 1 : $string;

    return;
}

sub _unquote {
    my ( $string ) = @_;
    $string =~ s/ \A ['"] //smx
	and chop $string;
    $string =~ s/ \\ (?= . ) //smxg;
    return $string;
}

1;

__END__

=head1 NAME

PPIx::QuoteLike - Parse Perl string literals and string-literal-like things.

=head1 SYNOPSIS

 use PPIx::QuoteLike;

 my $str = PPIx::QuoteLike->new( q<"fu$bar"> );
 say $str->interpolates() ?
    'interpolates' :
    'does not interpolate';

=head1 DESCRIPTION

This Perl class parses Perl string literals and things that are
reasonably like string literals. Its real reason for being is to find
interpolated variables for L<Perl::Critic|Perl::Critic> policies and
similar code.

The parse is fairly straightforward, and a little poking around with
F<eg/pqldump> should show how it normally goes.

But there is at least one quote-like thing that probably needs some
explanation.

=head2 Indented Here Documents

These were introduced in Perl 5.25.7 (November 2016) but not recognized
by this module until its version 0.015 (February 2021). The indentation
is parsed as
L<PPIx::QuoteLike::Token::Whitespace|PPIx::Regexp::Token::Whitespace>
objects, provided it is at least one character wide, otherwise it is not
represented in the parse. That is to say,

 <<~EOD
     How doth the little crocodile
     Improve his shining tail
     EOD

will have the three indentations represented by whitespace objects and
each line of the literal represented by its own string object, but

 <<~EOD
 How doth the little crocodile
 Improve his shining tail
 EOD

will parse the same as the non-indented version, except for the addition
of the token representing the C<'~'>.

L<PPI|PPI> is ahead of this module, and recognized indented here
documents as of its version 1.246 (May 2019). Unfortunately, as of
version 1.270 the indent gets lost in the parse, so a C<PPIx::QuoteLike>
object initialized from such a
L<PPI::Token::HereDoc|PPI::Token::HereDoc> will be seen as having an
indentation of C<''> regardless of the actual indentation in the source.
I believe this restriction will go away when
L<https://github.com/Perl-Critic/PPI/issues/251> is resolved.

=head1 DEPRECATION NOTICE

The C<postderef> argument to L<new()|/new> is being put through a
deprecation cycle and retracted. After the retraction, postfix
dereferences will always be recognized.

Starting with version 0.012_01, the first use of this argument warned.
With version 0.016_01, all uses warn. With version 0.017_01 all uses are
fatal. With 0.0.021_01, all mention of this argument is removed, except
of course for this notice.

=head1 INHERITANCE

C<PPIx::QuoteLike> is not descended from any other class.

C<PPIx::QuoteLike> has no descendants.

=head1 METHODS

This class supports the following public methods:

=head2 new

 my $str = PPIx::QuoteLike->new( $source, %arg );

This static method parses the argument, and returns a new object
containing the parse. The C<$source> argument can be either a scalar or
an appropriate L<PPI::Element|PPI::Element> object.

If the C<$source> argument is a scalar, it is presumed to represent a
quote-like literal of some sort, provided it begins like one. Otherwise
this method will return nothing. The scalar representation of a here
document is a multi-line string whose first line consists of the leading
C< << > and the start delimiter, and whose subsequent lines consist of
the content of the here document and the end delimiter. Indented here
documents were not supported by this class until version C<0.015>.

C<PPI> classes that can be handled are
L<PPI::Token::Quote|PPI::Token::Quote>,
L<PPI::Token::QuoteLike::Backtick|PPI::Token::QuoteLike::Backtick>,
L<PPI::Token::QuoteLike::Command|PPI::Token::QuoteLike::Command>,
L<PPI::Token::QuoteLike::Readline|PPI::Token::QuoteLike::Readline>, and
L<PPI::Token::HereDoc|PPI::Token::HereDoc>. Any other object will cause
C<new()> to return nothing.

Additional optional arguments can be passed as name/value pairs.
Supported arguments are:

=over

=item encoding

This is the encoding of the C<$source>. If this is specified as
something other than C<undef>, the C<$source> will be decoded before
processing.

If the C<$source> is a C<PPI::Element>, this encoding is used only if
the document that contains the element has neither a byte order mark nor
C<'use utf8'>.

=item index_locations

This Boolean argument determines whether the locations of the tokens
should be computed. It defaults to true if the C<$source> argument is a
L<PPI::Element|PPI::Element> or if the C<location> argument was
provided, and false otherwise.

=item location

This argument is a reference to an array compatible with that returned
by the L<PPI::Element|PPI::Element> location() method. It defaults to
the location of the C<$source> argument if that was a
L<PPI::Element|PPI::Element>, otherwise no locations will be available.

=item trace

This Boolean argument causes a trace of the parse to be written to
standard out. Setting this to a true value is unsupported in the sense
that the author makes no representation as to what will happen if you do
it, and reserves the right to make changes to the functionality, or
retract it completely, without notice.

=back

All other arguments are unsupported and reserved to the author.

=head2 child

 my $kid = $str->child( 0 );

This method returns the child element whose index is given as the
argument. Children do not include the L<type()|/type>, or the
L<start()|/start> or L<finish()|/finish> delimiters. Negative indices
are valid, and given the usual Perl interpretation.

=head2 children

 my @kids = $str->children();

This method returns all child elements. Children do not include the
L<type()|/type>, or the L<start()|/start> or L<finish()|/finish>
delimiters.

=head2 column_number

This method returns the column number of the first character in the
element, or C<undef> if that can not be determined.

=head2 content

 say $str->content();

This method returns the content of the object. If the original argument
was a valid Perl string, this should be the same as the
originally-parsed string.

=head2 delimiters

 say $str->delimiters();

This method returns the delimiters of the object, as a string. This will
be two characters unless the argument to L<new()|/new> was a here
document, missing its end delimiter, or an invalid string. In the latter
case the return might be anything.

=head2 elements

 my @elem = $str->elements();

This method returns all elements of the object. This includes
L<type()|/type>, L<start()|/start>, L<children()|/children>, and
L<finish()|/finish>, in that order.

=head2 failures

 say $str->failures();

This method returns the number of parse failures found. These are
instances where the parser could not figure out what was going on, and
should be the same as the number of
L<PPIx::QuoteLike::Token::Unknown|PPIx::QuoteLike::Token::Unknown>
objects returned by L<elements()|/elements>.

=head2 find

 for ( @{[ $str->find( $criteria ) || [] } ) {
     ...
 }

This method finds and returns a reference to an array of all elements
that meet the given criteria. If nothing is found, a false value is
returned.

The C<$criteria> can be either the name of a
L<PPIx::QuoteLike::Token|PPIx::QuoteLike::Token> class, or a code
reference. In the latter case, the code is called for each element in
L<elements()|/elements>, with the element as the only argument. The
element is included in the output if the code returns a true value.

=head2 finish

 say map { $_->content() } $str->finish();

This method returns the finishing elements of the parse. It is actually
an array, with the first element being a
L<PPIx::QuoteLike::Token::Delimiter|PPIx::QuoteLike::Token::Delimiter>.
If the parse is of a here document there will be a second element, which
will be a
L<PPIx::QuoteLike::Token::Whitespace|PPIx::QuoteLike::Token::Whitespace>
containing the trailing new line character.

If called in list context you get the whole array. If called in scalar
context you get the element whose index is given in the argument, or
element zero if no argument is specified.

=head2 handles

 say PPIx::QuoteLike->handles( $string ) ?
     "We can handle $string" :
     "We can not handle $string";

This convenience static method returns a true value if this package can
be expected to handle the content of C<$string> (be it scalar or
object), and a false value otherwise.

=head2 indentation

This method returns the indentation string if the object represents an
indented here document, or C<undef> if it represents anything else,
including an unindented here document.

B<Note> that if indented syntax is used but the here document is not in
fact indented, this will return C<''>, which evaluates to false.

=head2 interpolates

 say $str->interpolates() ?
     'The string interpolates' :
     'The string does not interpolate';

This method returns a true value if the parsed string interpolates, and
a false value if it does not. This does B<not> indicate whether any
interpolation actually takes place, only whether the string is
double-quotish or single-quotish.

=head2 line_number

This method returns the line number of the first character in the
element, or C<undef> if that can not be determined.

=head2 location

This method returns a reference to an array describing the position of
the string, or C<undef> if the location is unavailable.

The array is compatible with the corresponding
L<PPI::Element|PPI::Element> method.

=head2 logical_filename

This method returns the logical file name (taking C<#line> directives
into account) of the file containing first character in the element, or
C<undef> if that can not be determined.

=head2 logical_line_number

This method returns the logical line number (taking C<#line> directives
into account) of the first character in the element, or C<undef> if that
can not be determined.

=head2 parent

This method returns nothing, since the invocant is only used at the top
of the object hierarchy.

=head2 perl_version_introduced

This method returns the maximum value of C<perl_version_introduced>
returned by any of its elements. In other words, it returns the minimum
version of Perl under which this quote-like object is valid. If there
are no elements, 5.000 is returned, since that is the minimum value of
Perl supported by this package.

=head2 perl_version_removed

This method returns the minimum defined value of C<perl_version_removed>
returned by any of the quote-like object's elements. In other words, it
returns the lowest version of Perl in which this object is C<not> valid.
If there are no elements, or if no element has a defined
C<perl_version_removed>, C<undef> is returned.

=head2 schild

 my $skid = $str->schild( 0 );

This method returns the significant child elements whose index is given
by the argument. Negative indices are interpreted in the usual way.

=head2 schildren

 my @skids = $str->schildren();

This method returns the significant children.

=head2 source

 my $source = $str->source();

This method returns the C<$source> argument to L<new()|/new>, whatever
it was.

=head2 start

 say map { $_->content() } $str->start();

This method returns the starting elements of the parse. It is actually
an array, with the first element being a
L<PPIx::QuoteLike::Token::Delimiter|PPIx::QuoteLike::Token::Delimiter>.
If the parse is of a here document there will be a second element, which
will be a
L<PPIx::QuoteLike::Token::Whitespace|PPIx::QuoteLike::Token::Whitespace>
containing the trailing new line character.

If called in list context you get the whole array. If called in scalar
context you get the element whose index is given in the argument, or
element zero if no argument is specified.

=head2 statement

This method returns the L<PPI::Statement|PPI::Statement> that
contains this string, or nothing if the statement can not be
determined.

In general this method will return something only under the following
conditions:

=over

=item * The string is contained in a L<PPIx::QuoteLike|PPIx::QuoteLike> object;

=item * That object was initialized from a L<PPI::Element|PPI::Element>;

=item * The L<PPI::Element|PPI::Element> is contained in a statement.

=back

=head2 top

This method returns the top of the hierarchy -- in this case, the
invocant.

=head2 type

 my $type = $str->type();

This method returns the type object. This will be a
L<PPIx::QuoteLike::Token::Structure|PPIx::QuoteLike::Token::Structure>
if the parse was successful; otherwise it might be C<undef>. Its
contents will be everything up to the start delimiter, and will
typically be C<'q'>, C<'qq'>, C<'qx'>, C< '<<' > (for here documents),
or C<''> (for quoted strings).

The type data are actually an array. If the second element is present it
will be the white space (if any) separating the actual type from the
value.  If called in list context you get the whole array. If called in
scalar context you get the element whose index is given in the argument,
or element zero if no argument is specified.

=head2 variables

 say "Interpolates $_" for $str->variables();

B<NOTE> that this method is discouraged, and may well be deprecated and
removed. My problem with it is that it returns variable names rather
than L<PPI::Element|PPI::Element> objects, leaving you no idea how the
variables are used. It was originally written for the benefit of
L<Perl::Critic::Policy::Variables::ProhibitUnusedVarsStricter|Perl::Critic::Policy::Variables::ProhibitUnusedVarsStricter>,
but has proven inadequate to that policy's needs.

This convenience method returns all interpolated variables. Each is
returned only once, and they are returned in no particular order. If the
object does not represent a string that interpolates, nothing is
returned.

=head2 visual_column_number

This method returns the visual column number (taking tabs into account)
of the first character in the element, or C<undef> if that can not be
determined.

=head1 RESTRICTIONS

By the nature of this module, it is never going to get everything right.
Many of the known problem areas involve interpolations one way or
another.

=head2 Changes in Syntax

Sometimes the introduction of new syntax changes the way a string is
parsed. For example, the C<\F> (fold case) case control was introduced
in Perl 5.15.8. But it did not represent a syntax error prior to that
version of Perl, it was simply parsed as C<F>. So

 $ perl -le 'print "Foo\FBar"'

prints C<"FooFBar"> under Perl 5.14.4, but C<"Foobar"> under 5.16.0.
C<PPIx::QuoteLike> generally assumes the more modern parse in cases like
this.

=head2 Static Parsing

It is well known that Perl can not be statically parsed. That is, you
can not completely parse a piece of Perl code without executing that
same code.

Nevertheless, this class is trying to statically parse quote-like
things. I do not have any examples of where the parse of a quote-like
thing would change based on what is interpolated, but neither can I rule
it out. I<Caveat user>.

=head2 PPI Restrictions

As of version 0.015 of this module, the only known instance of this is
the handling of indented here documents, as discussed above under
L<Indented Here Documents|/Indented Here Documents>.

=head2 Non-Standard Syntax

There are modules out there that alter the syntax of Perl. If the syntax
of a quote-like string is altered, this module has no way to understand
that it has been altered, much less to adapt to the alteration. The
following modules are known to cause problems:

L<Acme::PerlML|Acme::PerlML>, which renders Perl as XML.

C<Data::PostfixDeref>, which causes Perl to interpret suffixed empty
brackets as dereferencing the thing they suffix. This module by Ben
Morrow (C<BMORROW>) appears to have been retracted.

L<Filter::Trigraph|Filter::Trigraph>, which recognizes ANSI C trigraphs,
allowing Perl to be written in the ISO 646 character set.

L<Perl6::Pugs|Perl6::Pugs>. Enough said.

=head1 SUPPORT

Support is by the author. Please file bug reports at
L<https://rt.cpan.org/Public/Dist/Display.html?Name=PPIx-QuoteLike>,
L<https://github.com/trwyant/perl-PPIx-QuoteLike/issues>, or in
electronic mail to the author.

=head1 AUTHOR

Thomas R. Wyant, III F<wyant at cpan dot org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2016-2022 by Thomas R. Wyant, III

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl 5.10.0. For more details, see the full text
of the licenses in the directory LICENSES.

This program is distributed in the hope that it will be useful, but
without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

=cut

# ex: set textwidth=72 :
