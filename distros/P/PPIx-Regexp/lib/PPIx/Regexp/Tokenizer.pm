package PPIx::Regexp::Tokenizer;

use strict;
use warnings;

use base qw{ PPIx::Regexp::Support };

use Carp qw{ carp croak confess };
use PPIx::Regexp::Constant qw{
    ARRAY_REF
    CODE_REF
    HASH_REF
    MINIMUM_PERL
    REGEXP_REF
    TOKEN_LITERAL
    TOKEN_UNKNOWN
    @CARP_NOT
};
use PPIx::Regexp::Token::Assertion		();
use PPIx::Regexp::Token::Backreference		();
use PPIx::Regexp::Token::Backtrack		();
use PPIx::Regexp::Token::CharClass::POSIX	();
use PPIx::Regexp::Token::CharClass::POSIX::Unknown	();
use PPIx::Regexp::Token::CharClass::Simple	();
use PPIx::Regexp::Token::Code			();
use PPIx::Regexp::Token::Comment		();
use PPIx::Regexp::Token::Condition		();
use PPIx::Regexp::Token::Control		();
use PPIx::Regexp::Token::Delimiter		();
use PPIx::Regexp::Token::Greediness		();
use PPIx::Regexp::Token::GroupType::Assertion	();
use PPIx::Regexp::Token::GroupType::Atomic_Script_Run	();
use PPIx::Regexp::Token::GroupType::BranchReset	();
use PPIx::Regexp::Token::GroupType::Code	();
use PPIx::Regexp::Token::GroupType::Modifier	();
use PPIx::Regexp::Token::GroupType::NamedCapture	();
use PPIx::Regexp::Token::GroupType::Script_Run	();
use PPIx::Regexp::Token::GroupType::Subexpression	();
use PPIx::Regexp::Token::GroupType::Switch	();
use PPIx::Regexp::Token::Interpolation		();
use PPIx::Regexp::Token::Literal		();
use PPIx::Regexp::Token::Modifier		();
use PPIx::Regexp::Token::Operator		();
use PPIx::Regexp::Token::Quantifier		();
use PPIx::Regexp::Token::Recursion		();
use PPIx::Regexp::Token::Structure		();
use PPIx::Regexp::Token::Unknown		();
use PPIx::Regexp::Token::Whitespace		();
use PPIx::Regexp::Util qw{ __is_ppi_regexp_element __instance };
use Scalar::Util qw{ looks_like_number };

our $VERSION = '0.063';

our $DEFAULT_POSTDEREF;
defined $DEFAULT_POSTDEREF
    or $DEFAULT_POSTDEREF = 1;

{
    # Names of classes containing tokenization machinery. There are few
    # known ordering requirements, since each class recognizes its own,
    # and I have tried to prevent overlap. Absent such constraints, the
    # order is in perceived frequency of acceptance, to keep the search
    # as short as possible. If I were conscientious I would gather
    # statistics on this.
    my @classes = (	# TODO make readonly when acceptable way appears
	'PPIx::Regexp::Token::Literal',
	'PPIx::Regexp::Token::Interpolation',
	'PPIx::Regexp::Token::Control',			# Note 1
	'PPIx::Regexp::Token::CharClass::Simple',	# Note 2
	'PPIx::Regexp::Token::Quantifier',
	'PPIx::Regexp::Token::Greediness',
	'PPIx::Regexp::Token::CharClass::POSIX',	# Note 3
	'PPIx::Regexp::Token::Structure',
	'PPIx::Regexp::Token::Assertion',
	'PPIx::Regexp::Token::Backreference',
	'PPIx::Regexp::Token::Operator',		# Note 4
    );

    # Note 1: If we are in quote mode ( \Q ... \E ), Control makes a
    #		literal out of anything it sees other than \E. So it
    #		needs to come before almost all other tokenizers. Not
    #		Literal, which already makes literals, and not
    #		Interpolation, which is legal in quote mode, but
    #		everything else.

    # Note 2: CharClass::Simple must come after Literal, because it
    #		relies on Literal to recognize a Unicode named character
    #		( \N{something} ), so any \N that comes through to it
    #		must be the \N simple character class (which represents
    #		anything but a newline, and was introduced in Perl
    #		5.11.0.

    # Note 3: CharClass::POSIX has to come before Structure, since both
    #		look for square brackets, and CharClass::POSIX is the
    #		more particular.

    # Note 4: Operator relies on Literal making the characters literal
    #		if they appear in a context where they can not be
    #		operators, and Control making them literals if quoting,
    #		so it must come after both.

    # Return the declared tokenizer classes.
    sub __tokenizer_classes {
	return @classes;
    }

}

{
    my $errstr;

    sub new {
	my ( $class, $re, %args ) = @_;
	ref $class and $class = ref $class;

	$errstr = undef;

	exists $args{default_modifiers}
	    and ARRAY_REF ne ref $args{default_modifiers}
	    and do {
		$errstr = 'default_modifiers must be an array reference';
		return;
	    };

	my $self = {
	    capture => undef,	# Captures from find_regexp.
	    content => undef,	# The string we are tokenizing.
	    cookie => {},	# Cookies
	    cursor_curr => 0,	# The current position in the string.
	    cursor_limit => undef, # The end of the portion of the
	    			   # string being tokenized.
	    cursor_orig => undef, # Position of cursor when tokenizer
	    			# called. Used by get_token to prevent
				# recursion.
	    cursor_modifiers => undef,	# Position of modifiers.
	    default_modifiers => $args{default_modifiers} || [],
	    delimiter_finish => undef,	# Finishing delimiter of regexp.
	    delimiter_start => undef,	# Starting delimiter of regexp.
	    encoding => $args{encoding}, # Character encoding.
	    expect => undef,	# Extra classes to expect.
	    expect_next => undef, # Extra classes as of next parse cycle
	    failures => 0,	# Number of parse failures.
	    find => undef,	# String for find_regexp
	    known => {},	# Known tokenizers, by mode.
	    match => undef,	# Match from find_regexp.
	    mode => 'init',	# Initialize
	    modifiers => [{}],	# Modifier hash.
	    pending => [],	# Tokens made but not returned.
	    postderef => defined $args{postderef} ?
		$args{postderef} :
		$DEFAULT_POSTDEREF,
	    prior => TOKEN_UNKNOWN,	# Prior significant token.
	    source => $re,	# The object we were initialized with.
	    strict => $args{strict},	# like "use re 'strict';".
	    trace => __PACKAGE__->__defined_or(
		$args{trace}, $ENV{PPIX_REGEXP_TOKENIZER_TRACE}, 0 ),
	};

	if ( __instance( $re, 'PPI::Element' ) ) {
	    __is_ppi_regexp_element( $re )
		or return __set_errstr( ref $re, 'not supported by', $class );
	    # TODO conditionalizstion on PPI class does not really
	    # belong here, but at the moment I have no other idea of
	    # where to put it.
	    $self->{content} = $re->isa( 'PPI::Token::HereDoc' ) ?
		join( '', $re->content(), "\n", $re->heredoc(),
		    $re->terminator(), "\n" ) :
		$re->content();
	} elsif ( ref $re ) {
	    return __set_errstr( ref $re, 'not supported' );
	} else {
	    $self->{content} = $re;
	}

	bless $self, $class;

	$self->{content} = $self->decode( $self->{content} );

	$self->{cursor_limit} = length $self->{content};

	$self->{trace}
	    and warn "\ntokenizing '$self->{content}'\n";

	return $self;
    }

    sub __set_errstr {
	$errstr = join ' ', @_;
	return;
    }

    sub errstr {
	return $errstr;
    }

}

sub capture {
    my ( $self ) = @_;
    $self->{capture} or return;
    defined wantarray or return;
    return wantarray ? @{ $self->{capture} } : $self->{capture};
}

sub content {
    my ( $self ) = @_;
    return $self->{content};
}

sub cookie {
    my ( $self, $name, @args ) = @_;
    defined $name
	or confess "Programming error - undefined cookie name";
    @args or return $self->{cookie}{$name};
    my $cookie = shift @args;
    if ( CODE_REF eq ref $cookie ) {
	return ( $self->{cookie}{$name} = $cookie );
    } elsif ( defined $cookie ) {
	confess "Programming error - cookie must be CODE ref or undef";
    } else {
	return delete $self->{cookie}{$name};
    }
}

sub default_modifiers {
    my ( $self ) = @_;
    return [ @{ $self->{default_modifiers} } ];
}

sub __effective_modifiers {
    my ( $self ) = @_;
    HASH_REF eq ref $self->{effective_modifiers}
	or return {};
    return { %{ $self->{effective_modifiers} } };
}

sub encoding {
    my ( $self ) = @_;
    return $self->{encoding};
}

sub expect {
    my ( $self, @args ) = @_;

    @args
	or return;

    $self->{expect_next} = [
	map { m/ \A PPIx::Regexp:: /smx ? $_ : 'PPIx::Regexp::' . $_ }
	@args
    ];
    $self->{expect} = undef;
    return;
}

sub failures {
    my ( $self ) = @_;
    return $self->{failures};
}

sub find_matching_delimiter {
    my ( $self ) = @_;
    $self->{cursor_curr} ||= 0;
    my $start = substr
	$self->{content},
	$self->{cursor_curr},
	1;

    my $inx = $self->{cursor_curr};
    my $finish = (
	my $bracketed = $self->close_bracket( $start ) ) || $start;

=begin comment

    $self->{trace}
	and warn "Find matching delimiter: Start with '$start' at $self->{cursor_curr}, end with '$finish' at or before $self->{cursor_limit}\n";

=end comment

=cut

    my $nest = 0;

    while ( ++$inx < $self->{cursor_limit} ) {
	my $char = substr $self->{content}, $inx, 1;

=begin comment

	$self->{trace}
	    and warn "    looking at '$char' at $inx, nest level $nest\n";

=end comment

=cut

	if ( $char eq '\\' && $finish ne '\\' ) {
	    ++$inx;
	} elsif ( $bracketed && $char eq $start ) {
	    ++$nest;
	} elsif ( $char eq $finish ) {
	    --$nest < 0
		and return $inx - $self->{cursor_curr};
	}
    }

    return;
}

sub find_regexp {
    my ( $self, $regexp ) = @_;

    REGEXP_REF eq ref $regexp
	or confess
	'Argument is a ', ( ref $regexp || 'scalar' ), ' not a Regexp';

    defined $self->{find} or $self->_remainder();

    $self->{find} =~ $regexp
	or return;

    my @capture;
    foreach my $inx ( 0 .. $#+ ) {
	if ( defined $-[$inx] && defined $+[$inx] ) {
	push @capture, $self->{capture} = substr
		    $self->{find},
		    $-[$inx],
		    $+[$inx] - $-[$inx];
	} else {
	    push @capture, undef;
	}
    }
    $self->{match} = shift @capture;
    $self->{capture} = \@capture;

    # The following circumlocution seems to be needed under Perl 5.13.0
    # for reasons I do not fathom -- at least in the case where
    # wantarray is false. RT 56864 details the symptoms, which I was
    # never able to reproduce outside Perl::Critic. But returning $+[0]
    # directly, the value could transmogrify between here and the
    # calling module.
##  my @data = ( $-[0], $+[0] );
##  return wantarray ? @data : $data[1];
    return wantarray ? ( $-[0] + 0, $+[0] + 0 ) : $+[0] + 0;
}

sub get_mode {
    my ( $self ) = @_;
    return $self->{mode};
}

sub get_start_delimiter {
    my ( $self ) = @_;
    return $self->{delimiter_start};
}

sub get_token {
    my ( $self ) = @_;

    caller eq __PACKAGE__ or $self->{cursor_curr} > $self->{cursor_orig}
	or confess 'Programming error - get_token() called without ',
	    'first calling make_token()';

    my $handler = '__PPIX_TOKENIZER__' . $self->{mode};

    my $code = $self->can( $handler )
	or confess 'Programming error - ',
	    "Getting token in mode '$self->{mode}'. ",
	    "cursor_curr = $self->{cursor_curr}; ",
	    "cursor_limit = $self->{cursor_limit}; ",
	    "length( content ) = ", length $self->{content},
	    "; content = '$self->{content}'";

    my $character = substr(
	$self->{content},
	$self->{cursor_curr},
	1
    );

    $self->{trace}
	and warn "get_token() got '$character' from $self->{cursor_curr}\n";

    return ( $code->( $self, $character ) );
}

sub interpolates {
    my ( $self ) = @_;
    return $self->{delimiter_start} ne q{'};
}

sub make_token {
    my ( $self, $length, $class, $arg ) = @_;
    defined $class or $class = caller;

    if ( $length + $self->{cursor_curr} > $self->{cursor_limit} ) {
	$length = $self->{cursor_limit} - $self->{cursor_curr}
	    or return;
    }

    $class =~ m/ \A PPIx::Regexp:: /smx
	or $class = 'PPIx::Regexp::' . $class;
    my $content = substr
	    $self->{content},
	    $self->{cursor_curr},
	    $length;

    $self->{trace}
	and warn "make_token( $length, '$class' ) => '$content'\n";
    $self->{trace} > 1
	and warn "    make_token: cursor_curr = $self->{cursor_curr}; ",
	    "cursor_limit = $self->{cursor_limit}\n";
    my $token = $class->__new( $content,
	tokenizer	=> $self,
	%{ $arg || {} } )
	or return;

    $token->significant()
	and $self->{expect} = undef;

    $token->isa( TOKEN_UNKNOWN ) and $self->{failures}++;

    $self->{cursor_curr} += $length;
    $self->{find} = undef;
    $self->{match} = undef;
    $self->{capture} = undef;

    foreach my $name ( keys %{ $self->{cookie} } ) {
	my $cookie = $self->{cookie}{$name};
	$cookie->( $self, $token )
	    or delete $self->{cookie}{$name};
    }

    # Record this token as the prior token if it is significant. We must
    # do this after processing cookies, so that the cookies have access
    # to the old token if they want.
    $token->significant()
	and $self->{prior_significant_token} = $token;

    return $token;
}

sub match {
    my ( $self ) = @_;
    return $self->{match};
}

sub modifier {
    my ( $self, $modifier ) = @_;
    return PPIx::Regexp::Token::Modifier::__asserts(
	$self->{modifiers}[-1], $modifier );
}

sub modifier_duplicate {
    my ( $self ) = @_;
    push @{ $self->{modifiers} },
	{ %{ $self->{modifiers}[-1] } };
    return;
}

sub modifier_modify {
    my ( $self, %args ) = @_;

    # Modifier code is centralized in PPIx::Regexp::Token::Modifier
    $self->{modifiers}[-1] =
	PPIx::Regexp::Token::Modifier::__PPIX_TOKENIZER__modifier_modify(
	$self->{modifiers}[-1], \%args );

    return;

}

sub modifier_pop {
    my ( $self ) = @_;
    @{ $self->{modifiers} } > 1
	and pop @{ $self->{modifiers} };
    return;
}

sub modifier_seen {
    my ( $self, $modifier ) = @_;
    foreach my $mod ( reverse @{ $self->{modifiers} } ) {
	exists $mod->{$modifier}
	    and return 1;
    }
    return;
}

sub next_token {
    my ( $self ) = @_;

    {

	if ( @{ $self->{pending} } ) {
	    return shift @{ $self->{pending} };
	}

	if ( $self->{cursor_curr} >= $self->{cursor_limit} ) {
	    $self->{cursor_limit} >= length $self->{content}
		and return;
	    $self->{mode} eq 'finish' and return;
	    $self->_set_mode( 'finish' );
	    $self->{cursor_limit} += length $self->{delimiter_finish};
	}

	if ( my @tokens = $self->get_token() ) {
	    push @{ $self->{pending} }, @tokens;
	    redo;

	}

    }

    return;

}

sub peek {
    my ( $self, $offset ) = @_;
    defined $offset or $offset = 0;
    $offset < 0 and return;
    $offset += $self->{cursor_curr};
    $offset >= $self->{cursor_limit} and return;
    return substr $self->{content}, $offset, 1;
}

sub ppi_document {
    my ( $self ) = @_;

    defined $self->{find} or $self->_remainder();

    return PPI::Document->new( \"$self->{find}" );
}

sub prior_significant_token {
    my ( $self, $method, @args ) = @_;
    defined $method or return $self->{prior_significant_token};
    $self->{prior_significant_token}->can( $method )
	or confess 'Programming error - ',
	    ( ref $self->{prior_significant_token} ||
		$self->{prior_significant_token} ),
	    ' does not support method ', $method;
    return $self->{prior_significant_token}->$method( @args );
}

# my $length = $token->__recognize_postderef( $tokenizer, $iterator ).
#
# This method is private to the PPIx-Regexp package, and may be changed
# or retracted without warning. What it does is to recognize postfix
# dereferences. It returns the length in characters of the first postfix
# dereference found, or a false value if none is found. This returns
# false immediately unless the tokenizer was instantiated with the
# C<postderef> argument true, or if it was not specified and
# C<$DEFAULT_POSTDEREF> was true when the tokenizer was instantiated.
#
# The optional $iterator argument can be one of the following:
#   - A code reference, which will be called to provide PPI::Element
#     objects to be checked to see if they represent a postfix
#     dereference.
#   - A PPI::Element, which is checked to see if it is a postfix
#     dereference.
#   - Undef, or omitted, in which case ppi() is called on the invocant,
#     and everything that follows the '->' operator is checked to see if
#     it is a postfix dereference.
#   - Anything else results in an exception and stack trace.

{
    # %* &* **
    my %magic_var = map { $_ => 1 } qw{ @* $* };
    my %magic_oper = map { $_ => 1 } qw{ & ** % };
    my %sliceable = map { $_ => 1 } qw{ @ % };
    my %post_slice = map { $_ => 1 } qw< { [ >;	# ] }

    sub __recognize_postderef {
	my ( $self, $token, $iterator ) = @_;
	$self->{postderef}
	    or return;
	# Note that if ppi() gets called I have to hold a reference to
	# the returned object until I am done with all its children.
	my $ppi;
	if ( ! defined $iterator ) {
	    $ppi = $token->ppi();
	    my @ops = grep { '->' eq $_->content() } @{
		$ppi->find( 'PPI::Token::Operator' ) || [] };
	    $iterator = sub {
		my $op = shift @ops
		    or return;
		return $op->snext_sibling();
	    };
	} elsif ( $iterator->isa( 'PPI::Element' ) ) {
	    my @eles = ( $iterator );
	    $iterator = sub {
		return shift @eles;
	    };
	} elsif ( CODE_REF ne ref $iterator ) {
	    confess 'Programming error - Iterator not understood';
	}

	my $accept = $token->__postderef_accept_cast();

	while ( my $elem = $iterator->() ) {

	    my $content = $elem->content();
	    $content =~ m/ \A ( . \#? ) /smx
		and $accept->{$1}
		or next;

	    my $length = length $content;

	    # PPI parses '$x->@*' as containing magic variable '@*'.
	    # Similarly for '$*' and '$#*'. I think this is a bug, and
	    # they should be parsed as casts, but ...
	    if ( $elem->isa( 'PPI::Token::Magic' ) ) {
		$magic_var{$content}
		    and return $length;
		if ( '$#' eq $content ) {
		    my $next = $elem->snext_sibling()
			or return $length;
		    '*' eq substr $next->content(), 0, 1
			and return $length + 1;
		}
	    }

	    # PPI parses '%*' as a cast of '%' followed by a splat, but
	    # I think it is likely that if it ever supports postderef
	    # operators that they will be casts. It currently parses
	    # '**' as an operator and '&*' as two operators, but the
	    # logic is pretty much the same as for a cast, so they get
	    # handled here too.
	    if ( $elem->isa( 'PPI::Token::Cast' ) || $elem->isa(
		    'PPI::Token::Operator' ) && $magic_oper{$content} ) {
		# Maybe PPI will eventually parse something like '$*' as
		# a cast, so ...
		$content =~ m/ [*] \z /smx
		    and return $length;
		# Or maybe it will parse the asterisk separately, but I
		# have no idea what its class will be.
		my $next = $elem->snext_sibling()
		    or return;
		my $next_content = $next->content();
		my $next_char = substr $next_content, 0, 1;
		'*' eq $next_char
		    and return $length + 1;
		# We may still have a slice.
		$sliceable{$content}
		    and $post_slice{$next_char}
		    and return $length + length $next_content;
		# TODO maybe PPI will do something completely
		# unanticipated with postderef.
	    }

	    # Otherwise, we're not a postfix dereference; try the next
	    # iteration.
	}

	# No postfix dereference found.
	return;
    }
}

sub significant {
    return 1;
}

sub strict {
    my ( $self ) = @_;
    return $self->{strict};
}

sub _known_tokenizers {
    my ( $self ) = @_;

    my $mode = $self->{mode};

    my @expect;
    if ( $self->{expect_next} ) {
	$self->{expect} = $self->{expect_next};
	$self->{expect_next} = undef;
    }
    if ( $self->{expect} ) {
	@expect = $self->_known_tokenizer_check(
	    @{ $self->{expect} } );
    }

    exists $self->{known}{$mode} and return (
	@expect, @{ $self->{known}{$mode} } );

    my @found = $self->_known_tokenizer_check(
	$self->__tokenizer_classes() );

    $self->{known}{$mode} = \@found;
    return (@expect, @found);
}

sub _known_tokenizer_check {
    my ( $self, @args ) = @_;

    my $handler = '__PPIX_TOKENIZER__' . $self->{mode};
    my @found;

    foreach my $class ( @args ) {

	$class->can( $handler ) or next;
	push @found, $class;

    }

    return @found;
}

sub tokens {
    my ( $self ) = @_;

    my @rslt;
    while ( my $token = $self->next_token() ) {
	push @rslt, $token;
    }

    return @rslt;
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

{

    my %deprecate = (
	attribute => {
	},
	method => {
	    prior	=> 3,
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

    sub _deprecation_in_progress {
	my ( $self, $type, $name ) = @_;
	$deprecate{$type} or return;
	return $deprecate{$type}{$name};
    }

}

=end comment

=cut

sub _remainder {
    my ( $self ) = @_;

    $self->{cursor_curr} > $self->{cursor_limit}
	and confess "Programming error - Trying to find past end of string";
    $self->{find} = substr(
	$self->{content},
	$self->{cursor_curr},
	$self->{cursor_limit} - $self->{cursor_curr}
    );

    return;
}

sub _make_final_token {
    my ( $self, $len, $class, $arg ) = @_;
    my $token = $self->make_token( $len, $class, $arg );
    $self->_set_mode( 'kaput' );
    return $token;
}

sub _set_mode {
    my ( $self, $mode ) = @_;
    $self->{trace}
	and warn "Tokenizer going from mode $self->{mode} to $mode\n";
    $self->{mode} = $mode;
    if ( 'kaput' eq $mode ) {
	$self->{cursor_curr} = $self->{cursor_limit} =
	    length $self->{content};
    }
    return;
}

sub __init_error {
    my ( $self , $err ) = @_;
    defined $err
	or $err = 'Tokenizer found illegal first characters';
    return $self->_make_final_token(
	length $self->{content}, TOKEN_UNKNOWN, {
	    error	=> $err,
	},
    );
}

sub __PPIX_TOKENIZER__init {
    my ( $self ) = @_;

    $self->find_regexp(
	qr{ \A ( \s* ) ( qr | m | s )? ( \s* ) ( . ) }smx )
	or return $self->__init_error();

    my ( $leading_white, $type, $next_white, $delim_start ) = $self->capture();

    defined $type
	or $type = '';

    $type
	or $delim_start =~ m< \A [/?] \z >smx
	or return $self->__init_error();
    $type
	and not $next_white
	and $delim_start =~ m< \A \w \z >smx
	and return $self->__init_error();

    $self->{type} = $type;

    my @tokens;

    '' ne $leading_white
	and push @tokens, $self->make_token( length $leading_white,
	'PPIx::Regexp::Token::Whitespace' );
    push @tokens, $self->make_token( length $type,
	'PPIx::Regexp::Token::Structure' );
    '' ne $next_white
	and push @tokens, $self->make_token( length $next_white,
	'PPIx::Regexp::Token::Whitespace' );

    $self->{delimiter_start} = $delim_start;

    $self->{trace}
	and warn "Tokenizer found regexp start delimiter '$delim_start' at $self->{cursor_curr}\n";

    if ( my $offset = $self->find_matching_delimiter() ) {
	my $cursor_limit = $self->{cursor_curr} + $offset;
	$self->{trace}
	    and warn "Tokenizer found regexp end delimiter at $cursor_limit\n";
	if ( $self->__number_of_extra_parts() ) {
###	    my $found_embedded_comments;
	    if ( $self->close_bracket(
		    $self->{delimiter_start} ) ) {
		pos $self->{content} = $self->{cursor_curr} +
		$offset + 1;
		# If we're bracketed, there may be Perl comments between
		# the regex and the replacement. PPI gets the parse
		# wrong as of 1.220, but if we get the handling of the
		# underlying string right, we will Just Work when PPI
		# gets it right.
		while ( $self->{content} =~
		    m/ \G \s* \n \s* \# [^\n]* /smxgc ) {
##		    $found_embedded_comments = 1;
		}
		$self->{content} =~ m/ \s* /smxgc;
	    } else {
		pos $self->{content} = $self->{cursor_curr} +
		$offset;
	    }
	    # Localizing cursor_curr and delimiter_start would be
	    # cleaner, but I don't want the old values restored if a
	    # parse error occurs.
	    my $cursor_curr = $self->{cursor_curr};
	    my $delimiter_start = $self->{delimiter_start};
	    $self->{cursor_curr} = pos $self->{content};
	    $self->{delimiter_start} = substr
		$self->{content},
		$self->{cursor_curr},
		1;
	    $self->{trace}
		and warn "Tokenizer found replacement start delimiter '$self->{delimiter_start}' at $self->{cursor_curr}\n";
	    if ( my $s_off = $self->find_matching_delimiter() ) {
		$self->{cursor_modifiers} =
		    $self->{cursor_curr} + $s_off + 1;
		$self->{trace}
		    and warn "Tokenizer found replacement end delimiter at @{[
			$self->{cursor_curr} + $s_off ]}\n";
		$self->{cursor_curr} = $cursor_curr;
		$self->{delimiter_start} = $delimiter_start;
	    } else {
		$self->{trace}
		    and warn 'Tokenizer failed to find replacement',
			"end delimiter starting at $self->{cursor_curr}\n";
		$self->{cursor_curr} = 0;
		# TODO If I were smart enough here I could check for
		# PPI mis-parses like s{foo}
		#                     #{bar}
		#                      {baz}
		# here, doing so if $found_embedded_comments (commented
		# out above) is true. The problem is that there seem to
		# as many mis-parses as there are possible delimiters.
		return $self->__init_error(
		    'Tokenizer found mismatched replacement delimiters',
		);
	    }
	} else {
	    $self->{cursor_modifiers} = $cursor_limit + 1;
	}
	$self->{cursor_limit} = $cursor_limit;
    } else {
	$self->{cursor_curr} = 0;
	return $self->_make_final_token(
	    length( $self->{content} ), TOKEN_UNKNOWN, {
		error	=> 'Tokenizer found mismatched regexp delimiters',
	    },
	);
    }

    {
	my @mods = @{ $self->{default_modifiers} };
	pos $self->{content} = $self->{cursor_modifiers};
	local $self->{cursor_curr} = $self->{cursor_modifiers};
	local $self->{cursor_limit} = length $self->{content};
	my @trailing;
	{
	    my $len = $self->find_regexp( qr{ \A [[:lower:]]* }smx );
	    push @trailing, $self->make_token( $len,
		'PPIx::Regexp::Token::Modifier' );
	}
	if ( my $len = $self->find_regexp( qr{ \A \s+ }smx ) ) {
	    push @trailing, $self->make_token( $len,
		'PPIx::Regexp::Token::Whitespace' );
	}
	if ( my $len = $self->find_regexp( qr{ \A .+ }smx ) ) {
	    push @trailing, $self->make_token( $len, TOKEN_UNKNOWN, {
		    error	=> 'Trailing characters after expression',
		} );
	}
	$self->{trailing_tokens} = \@trailing;
	push @mods, $trailing[0]->content();
	$self->{effective_modifiers} =
	    PPIx::Regexp::Token::Modifier::__aggregate_modifiers (
		@mods );
	$self->{modifiers} = [
	    { %{ $self->{effective_modifiers} } },
	];
    }

    $self->{delimiter_finish} = substr
	$self->{content},
	$self->{cursor_limit},
	1;

    push @tokens, $self->make_token( 1,
	'PPIx::Regexp::Token::Delimiter' );

    $self->_set_mode( 'regexp' );

    $self->{find} = undef;

    return @tokens;
}

# Match the initial part of the regexp including any leading white
# space. The initial delimiter is the first thing not consumed, though
# we check it for sanity.
sub __initial_match {
    my ( $self ) = @_;

    $self->find_regexp(
	qr{ \A ( \s* ) ( qr | m | s )? ( \s* ) (?: [^\w\s] ) }smx )
	or return;

    my ( $leading_white, $type, $next_white ) = $self->capture();

    defined $type
	or $type = '';

    $self->{type} = $type;

    my @tokens;

    '' ne $leading_white
	and push @tokens, $self->make_token( length $leading_white,
	'PPIx::Regexp::Token::Whitespace' );
    push @tokens, $self->make_token( length $type,
	'PPIx::Regexp::Token::Structure' );
    '' ne $next_white
	and push @tokens, $self->make_token( length $next_white,
	'PPIx::Regexp::Token::Whitespace' );

    return @tokens;
}

{
    my %extra_parts = (
	s	=> 1,
    );

    # Return the number of extra delimited parts. This will be 0 except
    # for s///, which will be 1.
    sub __number_of_extra_parts {
	my ( $self ) = @_;
	return $extra_parts{$self->{type}} || 0;
    }
}

{
    my @part_class = qw{
	PPIx::Regexp::Structure::Regexp
	PPIx::Regexp::Structure::Replacement
    };

    # Return the classes for the parts of the expression.
    sub __part_classes {
	my ( $self ) = @_;
	my $max = $self->__number_of_extra_parts();
	return @part_class[ 0 .. $max ];
    }
}

sub __PPIX_TOKENIZER__regexp {
    my ( $self, $character ) = @_;

    my $mode = $self->{mode};
    my $handler = '__PPIX_TOKENIZER__' . $mode;

    $self->{cursor_orig} = $self->{cursor_curr};
    foreach my $class ( $self->_known_tokenizers() ) {
	my @tokens = grep { $_ } $class->$handler( $self, $character );
	$self->{trace}
	    and warn $class, "->$handler( \$self, '$character' )",
		" => (@tokens)\n";
	@tokens
	    and return ( map {
		ref $_ ? $_ : $self->make_token( $_,
		    $class ) } @tokens );
    }

    # Find a fallback processor for the character.
    my $fallback = __PACKAGE__->can( '__PPIX_TOKEN_FALLBACK__' . $mode )
	|| __PACKAGE__->can( '__PPIX_TOKEN_FALLBACK__regexp' )
	|| confess "Programming error - unable to find fallback for $mode";
    return $fallback->( $self, $character );
}

*__PPIX_TOKENIZER__repl = \&__PPIX_TOKENIZER__regexp;

sub __PPIX_TOKEN_FALLBACK__regexp {
    my ( $self, $character ) = @_;

    # As a fallback in regexp mode, any escaped character is a literal.
    if ( $character eq '\\'
	&& $self->{cursor_limit} - $self->{cursor_curr} > 1
    ) {
	return $self->make_token( 2, TOKEN_LITERAL );
    }

    # Any normal character is unknown.
    return $self->make_token( 1, TOKEN_UNKNOWN, {
	    error	=> 'Tokenizer found unexpected literal',
	},
    );
}

sub __PPIX_TOKEN_FALLBACK__repl {
    my ( $self, $character ) = @_;

    # As a fallback in replacement mode, any escaped character is a literal.
    if ( $character eq '\\'
	&& defined ( my $next = $self->peek( 1 ) ) ) {

	if ( $self->interpolates() || $next eq q<'> || $next eq '\\' ) {
	    return $self->make_token( 2, TOKEN_LITERAL );
	}
	return $self->make_token( 1, TOKEN_LITERAL );
    }

    # So is any normal character.
    return $self->make_token( 1, TOKEN_LITERAL );
}

sub __PPIX_TOKENIZER__finish {
    my ( $self ) = @_;		# $character unused

    $self->{cursor_limit} > length $self->{content}
	and confess "Programming error - ran off string";

    my @tokens = $self->make_token( length $self->{delimiter_finish},
	'PPIx::Regexp::Token::Delimiter' );

    if ( $self->{cursor_curr} == $self->{cursor_modifiers} ) {

	# We are out of string. Add the trailing tokens (created when we
	# did the initial bracket scan) and close up shop.

	push @tokens, @{ delete $self->{trailing_tokens} };

	$self->_set_mode( 'kaput' );

    } else {

	# Clear the cookies, because we are going around again.
	$self->{cookie} = {};

	# Move the cursor limit to just before the modifiers.
	$self->{cursor_limit} = $self->{cursor_modifiers} - 1;

	# If the preceding regular expression was bracketed, we need to
	# consume possible whitespace and find another delimiter.

	if ( $self->close_bracket( $self->{delimiter_start} ) ) {
	    my $accept;
	    # If we are bracketed, there can be honest-to-God Perl
	    # comments between the regexp and the replacement, not just
	    # regexp comments. As of version 1.220, PPI does not get
	    # this parse right, but if we can handle this is a string,
	    # then we will Just Work when PPI gets itself straight.
	    while ( $self->find_regexp(
		    qr{ \A ( \s* \n \s* ) ( \# [^\n]* \n ) }smx ) ) {
		my ( $white_space, $comment ) = $self->capture();
		push @tokens, $self->make_token(
		    length $white_space,
		    'PPIx::Regexp::Token::Whitespace',
		), $self->make_token(
		    length $comment,
		    'PPIx::Regexp::Token::Comment',
		);
	    }
	    $accept = $self->find_regexp( qr{ \A \s+ }smx )
		and push @tokens, $self->make_token(
		$accept, 'PPIx::Regexp::Token::Whitespace' );
	    my $character = $self->peek();
	    $self->{delimiter_start} = $character;
	    push @tokens, $self->make_token(
		1, 'PPIx::Regexp::Token::Delimiter' );
	    $self->{delimiter_finish} = substr
		$self->{content},
		$self->{cursor_limit} - 1,
		1;
	}

	if ( $self->modifier( 'e*' ) ) {
	    # With /e or /ee, the replacement portion is code. We make
	    # it all into one big PPIx::Regexp::Token::Code, slap on the
	    # trailing delimiter and modifiers, and return it all.
	    push @tokens, $self->make_token(
		$self->{cursor_limit} - $self->{cursor_curr},
		'PPIx::Regexp::Token::Code',
		{ perl_version_introduced => MINIMUM_PERL },
	    );
	    $self->{cursor_limit} = length $self->{content};
	    push @tokens, $self->make_token( 1,
		'PPIx::Regexp::Token::Delimiter' ),
		@{ delete $self->{trailing_tokens} };
	    $self->_set_mode( 'kaput' );
	} else {
	    # Put our mode to replacement.
	    $self->_set_mode( 'repl' );
	}

    }

    return @tokens;

}

1;

__END__

=head1 NAME

PPIx::Regexp::Tokenizer - Tokenize a regular expression

=head1 SYNOPSIS

 use PPIx::Regexp::Dumper;
 PPIx::Regexp::Dumper->new( 'qr{foo}smx' )
     ->print();

=head1 INHERITANCE

C<PPIx::Regexp::Tokenizer> is a
L<PPIx::Regexp::Support|PPIx::Regexp::Support>.

C<PPIx::Regexp::Tokenizer> has no descendants.

=head1 DESCRIPTION

This class provides tokenization of the regular expression.

=head1 METHODS

This class provides the following public methods. Methods not documented
here (or documented below under L</EXTERNAL TOKENIZERS>) are private,
and unsupported in the sense that the author reserves the right to
change or remove them without notice.

=head2 new

 my $tokenizer = PPIx::Regexp::Tokenizer->new( 'xyzzy' );

This static method instantiates the tokenizer. You must pass it the
regular expression to be parsed, either as a string or as a
L<PPI::Element|PPI::Element> of some sort. You can also pass optional
name/value pairs of arguments. The option names are specified B<without>
a leading dash. Supported options are:

=over

=item default_modifiers array_reference

This argument specifies default statement modifiers. It is optional, but
if specified must be an array reference. See the
L<PPIx::Regexp|PPIx::Regexp> L<new()|PPIx::Regexp/new> documentation for
the details.

=item encoding name

This option specifies the encoding of the string to be tokenized. If
specified, an C<Encode::decode> is done on the string (or the C<content>
of the PPI class) before it is tokenized.

=item postderef boolean

This option specifies whether the tokenizer recognizes postfix
dereferencing. See the L<PPIx::Regexp|PPIx::Regexp>
L<new()|PPIx::Regexp/new> documentation for the details.

C<$PPIx::Regexp::Tokenizer::DEFAULT_POSTDEREF> is not exported.

=item strict boolean

This option specifies whether tokenization should assume
C<use re 'strict';> is in effect.

The C<'strict'> pragma was introduced in Perl 5.22, and its
documentation says that it is experimental, and that there is no
commitment to backward compatibility. The same applies to the
tokenization produced when this option is asserted.

=item trace number

Specifying a positive value for this option causes a trace of the
tokenization. This option is unsupported in the sense that the author
reserves the right to alter it without notice.

If this option is unspecified, the value comes from environment variable
C<PPIX_REGEXP_TOKENIZER_TRACE> (see L</ENVIRONMENT VARIABLES>). If this
environment variable does not exist, the default is 0.

=back

Undocumented options are unsupported.

The returned value is the instantiated tokenizer, or C<undef> if
instantiation failed. In the latter case a call to L</errstr> will
return the reason.

=head2 content

 print $tokenizer->content();

This method returns the string being tokenized. This will be the result
of the L<< PPI::Element->content()|PPI::Element/content >> method if the
object was instantiated with a L<PPI::Element|PPI::Element>.

=head2 default_modifiers

 print join ', ', @{ $tokenizer->default_modifiers() };

This method returns a reference to a copy of the array passed to the
C<default_modifiers> argument to L<new()|/new>. If this argument was not
used to instantiate the object, the return is a reference to an empty
array.

=head2 encoding

This method returns the encoding of the data being parsed, if one was
set when the class was instantiated; otherwise it simply returns undef.

=head2 errstr

 my $tokenizer = PPIx::Regexp::Tokenizer->new( 'xyzzy' )
     or die PPIx::Regexp::Tokenizer->errstr();

This static method returns an error description if tokenizer
instantiation failed.

=head2 failures

 print $tokenizer->failures(), " tokenization failures\n";

This method returns the number of tokenization failures encountered. A
tokenization failure is represented in the output token stream by a
L<PPIx::Regexp::Token::Unknown|PPIx::Regexp::Token::Unknown>.

=head2 modifier

 $tokenizer->modifier( 'x' )
     and print "Tokenizing an extended regular expression\n";

This method returns true if the given modifier character was found on
the end of the regular expression, and false otherwise.

Starting with version 0.036_01, if the argument is a
single-character modifier followed by an asterisk (intended as a wild
card character), the return is the number of times that modifier
appears. In this case an exception will be thrown if you specify a
multi-character modifier (e.g.  C<'ee*'>), or if you specify one of the
match semantics modifiers (e.g.  C<'a*'>).

If called by an external tokenizer, this method returns true if if the
given modifier was true at the current point in the tokenization.

=head2 next_token

 my $token = $tokenizer->next_token();

This method returns the next token in the token stream, or nothing if
there are no more tokens.

=head2 significant

This method exists simply for the convenience of
L<PPIx::Regexp::Dumper|PPIx::Regexp::Dumper>. It always returns true.

=head2 tokens

 my @tokens = $tokenizer->tokens();

This method returns all remaining tokens in the token stream.

=head1 EXTERNAL TOKENIZERS

This class does very little of its own tokenization. Instead the token
classes contain external tokenization routines, whose name is
'__PPIX_TOKENIZER__' concatenated with the current mode of the tokenizer
('regexp' for regular expressions, 'repl' for the replacement string).

These external tokenizers are called as static methods, and passed the
C<PPIx::Regexp::Tokenizer> object and the current character in the
character stream.

If the external tokenizer wants to make one or more tokens, it returns
an array containing either length in characters for tokens of the
tokenizer's own class, or the results of one or more L</make_token>
calls for tokens of an arbitrary class.

If the external tokenizer is not interested in the characters starting
at the current position it simply returns.

The following methods are for the use of external tokenizers, and B<are
not part of the public interface to this class.>

=head2 capture

 if ( $tokenizer->find_regexp( qr{ \A ( foo ) }smx ) ) {
     foreach ( $tokenizer->capture() ) {
         print "$_\n";
     }
 }

This method returns all the contents of any capture buffers from the
previous call to L</find_regexp>. The first element of the array (i.e.
element 0) corresponds to C<$1>, and so on.

The captures are cleared by L</make_token>, as well as by another call
to L</find_regexp>.

=head2 cookie

 $tokenizer->cookie( foo => sub { 1 } );
 my $cookie = $tokenizer->cookie( 'foo' );
 my $old_hint = $tokenizer->cookie( foo => undef );

This method either creates, deletes, or accesses a cookie.

A cookie is a code reference which is called whenever the tokenizer makes
a token. If it returns a false value, it is deleted. Explicitly setting
the cookie to C<undef> also deletes it.

When you call C<< $tokenizer->cookie( 'foo' ) >>, the current cookie is
returned. If you pass a new value of C<undef> to delete the token, the
deleted cookie (if any) is returned.

When the L</make_token> method calls a cookie, it passes it the tokenizer
and the token just made. If a token calls a cookie, it is recommended that
it merely pass the tokenizer, though of course the token can do whatever
it wants.

The cookie mechanism seems to be a bit of a crock, but it appeared to be
more work to fix things up in the lexer after the tokenizer got
something wrong.

The recommended way to write a cookie is to use a closure to store any
necessary data, and have a call to the cookie return the data; otherwise
the ultimate consumer of the cookie has no way to access the data. Of
course, it may be that the presence of the cookie at a certain point in
the parse is all that is required.

=head2 expect

 $tokenizer->expect( 'PPIx::Regexp::Token::Code' );

This method inserts a given class at the head of the token scan, for the
next iteration only. More than one class can be specified. Class names
can be abbreviated by removing the leading 'PPIx::Regexp::'.

If no class is specified, this method does nothing.

The expectation lasts from the next time L</get_token> is called until
the next time L<make_token> makes a significant token, or until the next
C<expect> call if that is done sooner.

=head2 find_regexp

 my $end = $tokenizer->find_regexp( qr{ \A \w+ }smx );
 my ( $begin, $end ) = $tokenizer->find_regexp(
     qr{ \A \w+ }smx );

This method finds the given regular expression in the content, starting
at the current position. If called in scalar context, the offset from
the current position to the end of the matched string is returned. If
called in list context, the offsets to both the beginning and the end of
the matched string are returned.

=head2 find_matching_delimiter

 my $offset = $tokenizer->find_matching_delimiter();

This method is used by tokenizers to find the delimiter matching the
character at the current position in the content string. If the
delimiter is an opening bracket of some sort, bracket nesting will be
taken into account.

When searching for the matching delimiter, the back slash character is
considered to escape the following character, so back-slashed delimiters
will be ignored. No other quoting mechanisms are recognized, though, so
delimiters inside quotes still count. This is actually the way Perl
works, as

 $ perl -e 'qr<(?{ print "}" })>'

demonstrates.

This method returns the offset from the current position in the content
string to the matching delimiter (which will always be positive), or
undef if no match can be found.

=head2 get_mode

This method returns the name of the current mode of the tokenizer.

=head2 get_start_delimiter

 my $start_delimiter = $tokenizer->get_start_delimiter();

This method is used by tokenizers to access the start delimiter for the
regular expression.

=head2 get_token

 my $token = $tokenizer->make_token( 3 );
 my @tokens = $tokenizer->get_token();

This method returns the next token that can be made from the input
stream. It is B<not> part of the external interface, but is intended for
the use of an external tokenizer which calls it after making and
retaining its own token to look at the next token ( if any ) in the
input stream.

If any external tokenizer calls get_token without first calling
make_token, a fatal error occurs; this is better than the infinite
recursion which would occur if the condition were not trapped.

An external tokenizer B<must> return anything returned by get_token;
otherwise tokens get lost.

=head2 interpolates

This method returns true if the top-level structure being tokenized
interpolates; that is, if the delimiter is not a single quote.

=head2 make_token

 return $tokenizer->make_token( 3, 'PPIx::Regexp::Token::Unknown' );

This method is used by this class (and possibly by individual
tokenizers) to manufacture a token. Its arguments are the number of
characters to include in the token, and optionally the class of the
token. If no class name is given, the caller's class is used. Class
names may be shortened by removing the initial 'PPIx::Regexp::', which
will be restored by this method.

The token will be manufactured from the given number of characters
starting at the current cursor position, which will be adjusted.

If the given length would include characters past the end of the string
being tokenized, the length is reduced appropriately. If this means a
token with no characters, nothing is returned.

=head2 match

 if ( $tokenizer->find_regexp( qr{ \A \w+ }smx ) ) {
     print $tokenizer->match(), "\n";
 }

This method returns the string matched by the previous call to
L</find_regexp>.

The match is set to C<undef> by L</make_token>, as well as by another
call to L</find_regexp>.

=head2 modifier_duplicate

 $tokenizer->modifier_duplicate();

This method duplicates the modifiers on the top of the modifier stack,
with the intent of creating a locally-scoped copy of the modifiers. This
should only be called by an external tokenizer that is actually creating
a modifier scope. In other words, only when creating a
L<PPIx::Regexp::Token::Structure|PPIx::Regexp::Token::Structure> token
whose content is '('.

=head2 modifier_modify

 $tokenizer->modifier_modify( name => $value ... );

This method sets new values for the modifiers in the local scope. Only
the modifiers whose names are actually passed have their values changed.

This method is intended to be called after manufacturing a
L<PPIx::Regexp::Token::Modifier|PPIx::Regexp::Token::Modifier> token,
and passed the results of its C<modifiers> method.

=head2 modifier_pop

 $tokenizer->modifier_pop();

This method removes the modifiers on the top of the modifier stack. This
should only be called by an external tokenizer that is ending a modifier
scope. In other words, only when creating a
L<PPIx::Regexp::Token::Structure|PPIx::Regexp::Token::Structure> token
whose content is ')'.

Note that this method will never pop the last modifier item off the
stack, to guard against unmatched right parentheses.

=head2 modifier_seen

 $tokenizer->modifier_seen( 'i' )
     and print "/i was seen at some point.\n";

Unlike L<modifier()|/modifier>, this method returns a true value if the
given modifier has been seen in any scope visible from the current
location in the parse. There is no magic for group match semantics (
/a, /aa, /d, /l, /u) or modifiers that can be repeated, like /x and /xx,
or /e and /ee.

=head2 peek

 my $character = $tokenizer->peek();
 my $next_char = $tokenizer->peek( 1 );

This method returns the character at the given non-negative offset from
the current position. If no offset is given, an offset of 0 is used.

If you ask for a negative offset or an offset off the end of the sting,
C<undef> is returned.

=head2 ppi_document

This method makes a PPI document out of the remainder of the string, and
returns it.

=head2 prior_significant_token

 $tokenizer->prior_significant_token( 'can_be_quantified' )
    and print "The prior token can be quantified.\n";

This method calls the named method on the most-recently-instantiated
significant token, and returns the result. Any arguments subsequent to
the method name will be passed to the method.

Because this method is designed to be used within the tokenizing system,
it will die horribly if the named method does not exist.

If called with no arguments at all the most-recently-instantiated
significant token is returned.

=head2 strict

 say 'Parse is ', $tokenizer->strict() ? 'strict' : 'lenient';

This method simply returns true or false, depending on whether the
C<'strict'> option to C<new()> was true or false.

=head1 ENVIRONMENT VARIABLES

A tokenizer trace can be requested by setting environment variable
PPIX_REGEXP_TOKENIZER_TRACE to a numeric value other than 0. Use of this
environment variable is unsupported in the same sense that the C<trace>
option of L</new> is unsupported. Explicitly specifying the C<trace>
option to L</new> overrides the environment variable.

The real reason this is documented is to give the user a way to
troubleshoot funny output from the tokenizer.

=head1 SUPPORT

Support is by the author. Please file bug reports at
L<http://rt.cpan.org>, or in electronic mail to the author.

=head1 AUTHOR

Thomas R. Wyant, III F<wyant at cpan dot org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009-2018 by Thomas R. Wyant, III

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl 5.10.0. For more details, see the full text
of the licenses in the directory LICENSES.

This program is distributed in the hope that it will be useful, but
without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

=cut

# ex: set textwidth=72 :
