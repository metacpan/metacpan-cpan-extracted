package My::Module::Test;

use strict;
use warnings;

use Exporter;

our @ISA = ( qw{ Exporter } );

use PPIx::Regexp;
use PPIx::Regexp::Constant qw{ INFINITY };
use PPIx::Regexp::Dumper;
use PPIx::Regexp::Element;
use PPIx::Regexp::Tokenizer;
use PPIx::Regexp::Util qw{ __choose_tokenizer_class __instance };
use Scalar::Util qw{ looks_like_number refaddr };
use Test::More 0.88;

our $VERSION = '0.089';

use constant ARRAY_REF	=> ref [];

our @EXPORT_OK = qw{
    cache_count
    choose
    klass
    cmp_ok
    content
    count
    diag
    different
    done_testing
    dump_result
    equals
    error
    fail
    false
    finis
    format_want
    invocant
    is
    navigate
    note
    ok
    parse
    pass
    plan
    ppi
    raw_width
    result
    replace_characters
    skip
    tokenize
    true
    value
    width
    INFINITY
};

our @EXPORT = @EXPORT_OK;	## no critic (ProhibitAutomaticExportation)

push @EXPORT_OK, qw{ __quote };

my (
    $initial_class,	# For static methods; set by parse() or tokenize()
    $kind,		# of thing; set by parse() or tokenize()
    $nav,		# Navigation used to get to current object, as a
			#    string.
    $obj,		# Current object:
    			#    PPIx::Regexp::Tokenizer if set by tokenize(),
			#    PPIx::Regexp if set by parse(), or
			#    PPIx::Regexp::Element if set by navigate().
    $parse,		# Result of parse:
    			#    array ref if set by tokenize(), or
			#    PPIx::Regexp object if set by parse()
    %replace_characters, # Troublesome characters replaced in output
			# before testing
    $result,		# Operation result.
);

sub cache_count {
    my ( $expect ) = @_;
    defined $expect or $expect = 0;
    $obj = undef;
    $parse = undef;
    _pause();
    $result = PPIx::Regexp->__cache_size();
    # cperl does not seem to like goto &xxx; it throws a deep recursion
    # error if you do it enough times.
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    return is( $result, $expect,
	"Should be $expect leftover cache contents" );
}

sub choose {
    my @args = @_;
    $obj = $parse;
    return navigate( @args );
}

sub klass {
    my ( $class ) = @_;
    $result = ref $obj || $obj;
    # cperl does not seem to like goto &xxx; it throws a deep recursion
    # error if you do it enough times.
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    if ( defined $class ) {
	my $rslt = isa_ok( $obj, $class )
	    or diag "    Instead, $kind $nav isa $result";
	return $rslt;
    } else {
	return is( ref $obj || undef, $class, "Class of $kind $nav" );
    }
}

sub content {		## no critic (RequireArgUnpacking)
    # For some reason cperl seems to have no problem with this
    unshift @_, 'content';
    goto &_method_result;
}

sub count {
    my ( @args ) = @_;
    my $expect = pop @args;
    # cperl does not seem to like goto &xxx; it throws a deep recursion
    # error if you do it enough times.
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    if ( ARRAY_REF eq ref $parse ) {
	$result = @{ $parse };
	return is( $result, $expect, "Expect $expect tokens" );
    } elsif ( ARRAY_REF eq ref $obj ) {
	$result = @{ $obj };
	return is( $result, $expect, "Expect $expect tokens" );
    } elsif ( $obj->can( 'children' ) ) {
	$result = $obj->children();
	return is( $result, $expect, "Expect $expect children" );
    } else {
	$result = $obj->can( 'children' );
	return ok( $result, ref( $obj ) . "->can( 'children')" );
    }
}

sub different {
    my @args = @_;
    @args < 3 and unshift @args, $obj;
    my ( $left, $right, $name ) = @args;
    # cperl does not seem to like goto &xxx; it throws a deep recursion
    # error if you do it enough times.
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    if ( ! defined $left && ! defined $right ) {
	return ok( undef, $name );
    } elsif ( ! defined $left || ! defined $right ) {
	return ok( 1, $name );
    } elsif ( ref $left && ref $right ) {
	return ok( refaddr( $left ) != refaddr( $right ), $name );
    } elsif ( ref $left || ref $right ) {
	return ok( 1, $name );
    } elsif ( looks_like_number( $left ) && looks_like_number( $right ) ) {
	return ok( $left != $right, $name );
    } else {
	return ok( $left ne $right, $name );
    }
}

sub dump_result {
    my ( $opt, @args ) = _parse_constructor_args( { test => 1 }, @_ );
    if ( $opt->{test} ) {
	my ( $expect, $name ) = splice @args, -2;
	my $got = PPIx::Regexp::Dumper->new( $obj, @args )->string();
	# cperl does not seem to like goto &xxx; it throws a deep
	# recursion error if you do it enough times.
	local $Test::Builder::Level = $Test::Builder::Level + 1;
	return is( $got, $expect, $name );
    } elsif ( __instance( $result, 'PPIx::Regexp::Tokenizer' ) ||
	__instance( $result, 'PPIx::Regexp::Element' ) ) {
	diag( PPIx::Regexp::Dumper->new( $obj, @args )->string() );
    } elsif ( eval { require YAML; 1; } ) {
	diag( "Result dump:\n", YAML::Dump( $result ) );
    } elsif ( eval { require Data::Dumper; 1 } ) {
	diag( "Result dump:\n", Data::Dumper::Dumper( $result ) );
    } else {
	diag( "Result dump unavailable.\n" );
    }
    return;
}

sub equals {
    my @args = @_;
    @args < 3 and unshift @args, $obj;
    my ( $left, $right, $name ) = @args;
    # cperl does not seem to like goto &xxx; it throws a deep recursion
    # error if you do it enough times.
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    if ( ! defined $left && ! defined $right ) {
	return ok( 1, $name );
    } elsif ( ! defined $left || ! defined $right ) {
	return ok( undef, $name );
    } elsif ( ref $left && ref $right ) {
	return ok( refaddr( $left ) == refaddr( $right ), $name );
    } elsif ( ref $left || ref $right ) {
	return ok( undef, $name );
    } elsif ( looks_like_number( $left ) && looks_like_number( $right ) ) {
	return ok( $left == $right, $name );
    } else {
	return ok( $left eq $right, $name );
    }
}

sub error {		## no critic (RequireArgUnpacking)
    unshift @_, 'error';
    goto &_method_result;
}

sub false {
    my ( $method, $args ) = @_;
    ARRAY_REF eq ref $args
	or $args = [ $args ];
    my $class = ref $obj;
    # cperl does not seem to like goto &xxx; it throws a deep recursion
    # error if you do it enough times.
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    if ( $obj->can( $method ) ) {
	$result = $obj->$method( @{ $args } );
	my $fmtd = _format_args( $args );
	return ok( ! $result, "$class->$method$fmtd is false" );
    } else {
	$result = undef;
	return ok( undef, "$class->$method() exists" );
    }
}

sub finis {
    $obj = $parse = $result = undef;
    _pause();
    $result = PPIx::Regexp::Element->__parent_keys();
    # cperl does not seem to like goto &xxx; it throws a deep recursion
    # error if you do it enough times.
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    return is( $result, 0, 'Should be no leftover objects' );
}

sub format_want {
    my ( $want ) = @_;
    return _format_args( $want, bare => ref $want ? 0 : 1 );
}

sub invocant {
    return $obj;
}

{

    my %array = map { $_ => 1 } qw{
	children delimiters finish schildren start tokens type
    };

    sub navigate {
	my @args = @_;
	my $scalar = 1;
	@args > 1
	    and ARRAY_REF eq ref $args[-1]
	    and @{ $args[-1] } == 0
	    and $array{$args[-2]}
	    and $scalar = 0;
	my @nav = ();
	while ( @args ) {
	    if ( __instance( $args[0], 'PPIx::Regexp::Element' ) ) {
		$obj = shift @args;
	    } elsif ( ARRAY_REF eq ref $obj ) {
		my $inx = shift @args;
		push @nav, $inx;
		$obj = $obj->[$inx];
	    } else {
		my $method = shift @args;
		my $args = shift @args;
		ARRAY_REF eq ref $args
		    or $args = [ $args ];
		push @nav, $method, $args;
		$obj->can( $method ) or return;
		if ( @args || $scalar ) {
		    $obj = $obj->$method( @{ $args } ) or return;
		} else {
		    $obj = [ $obj->$method( @{ $args } ) ];
		}
	    }
	}
	$nav = __quote( @nav );
	$nav =~ s/ ' ( \w+ ) ' , /$1 =>/smxg;
	$nav =~ s/ \[ \s+ \] /[]/smxg;
	$result = $obj;
	return $obj;
    }

}

sub parse {		## no critic (RequireArgUnpacking)
    my ( $opt, $regexp, @args ) = _parse_constructor_args(
	{ test => 1 }, @_ );
    $initial_class = 'PPIx::Regexp';
    $kind = 'element';
    $result = $obj = $parse = PPIx::Regexp->new( $regexp, @args );
    $nav = '';
    $opt->{test} or return;
    # cperl does not seem to like goto &xxx; it throws a deep recursion
    # error if you do it enough times.
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    return isa_ok( $parse, 'PPIx::Regexp' );
}

sub ppi {		## no critic (RequireArgUnpacking)
    my @args = @_;
    my $expect = pop @args;
    $result = undef;
    defined $obj and $result = $obj->ppi()->content();
    my $safe;
    if ( defined $result ) {
	($safe = $result) =~ s/([\\'])/\\$1/smxg;
    } else {
	$safe = 'undef';
    }
    # cperl does not seem to like goto &xxx; it throws a deep recursion
    # error if you do it enough times.
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    return is( $result, $expect, "$kind $nav ppi() content '$safe'" );
}

sub raw_width {
    my ( $min, $max, $name ) = @_;
    defined $name
	or $name = sprintf q<%s '%s'>, ref $obj, $obj->content();
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my @width = $obj->raw_width();
    return is( $width[0], $min, "$name raw minimum witdh" ) && is(
	$width[1], $max, "$name raw maximum width" );
}

sub replace_characters {
    %replace_characters	= @_;
    return;
}

sub result {
    return $result;
}

sub tokenize {		## no critic (RequireArgUnpacking)
    my ( $opt, $regexp, @args ) = _parse_constructor_args(
	{ test => 1, tokens => 1 }, @_ );
    my %args = @args;
    $initial_class = __choose_tokenizer_class( $regexp, \%args );
    $kind = 'token';
    $obj = $initial_class->new( $regexp, @args );
    if ( $obj && $opt->{tokens} ) {
	$parse = [ $obj->tokens() ];
    } else {
	$parse = [];
    }
    $result = $parse;
    $nav = '';
    $opt->{test} or return;
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    return isa_ok( $obj, 'PPIx::Regexp::Tokenizer' );
}

sub true {		## no critic (RequireArgUnpacking)
    my ( $method, $args ) = @_;
    ARRAY_REF eq ref $args
	or $args = [ $args ];
    my $class = ref $obj;
    # cperl does not seem to like goto &xxx; it throws a deep recursion
    # error if you do it enough times.
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    if ( $obj->can( $method ) ) {
	$result = $obj->$method( @{ $args } );
	my $fmtd = _format_args( $args );
	return ok( $result, "$class->$method$fmtd is true" );
    } else {
	$result = undef;
	return ok( undef, "$class->$method() exists" );
    }
}

sub value {		## no critic (RequireArgUnpacking)
    my ( $method, $args, $want, $name ) = @_;
    ARRAY_REF eq ref $args
	or $args = [ $args ];

    my $invocant = $obj || $initial_class;
    my $class = ref $obj || $obj || $initial_class;
    # cperl does not seem to like goto &xxx; it throws a deep recursion
    # error if you do it enough times.
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    if ( ! $invocant->can( $method ) ) {
	return ok( undef, "$class->$method() exists" );
    }

    $result = ARRAY_REF eq ref $want ?
	[ $invocant->$method( @{ $args } ) ] :
	$invocant->$method( @{ $args } );

    my $fmtd = _format_args( $args );
    my $answer = format_want( $want, bare => ref $want ? 0 : 1 );
    defined $name
	or $name = "${class}->$method$fmtd is $answer";
    if ( ref $result ) {
	return is_deeply( $result, $want, $name );
    } else {
	return is( $result, $want, $name );
    }
}

sub width {
    my ( $min, $max, $name ) = @_;
    defined $name
	or $name = sprintf q<%s '%s'>, ref $obj, $obj->content();
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my @width = $obj->width();
    return is( $width[0], $min, "$name minimum witdh" ) && is(
	$width[1], $max, "$name maximum width" );
}

sub _format_args {
    my ( $args, %opt ) = @_;
    ARRAY_REF eq ref $args
	or $args = [ $args ];
    my @rslt;
    foreach my $arg ( @{ $args } ) {
	if ( ! defined $arg ) {
	    push @rslt, 'undef';
	} elsif ( looks_like_number( $arg ) ) {
	    push @rslt, $arg;
	} else {
	    push @rslt, $arg;
	    $rslt[-1] =~ s/ ' /\\'/smxg;
	    $rslt[-1] = "'$rslt[-1]'";
	}
    }
    my $string = join ', ', @rslt;
    $opt{bare} and return $string;
    @rslt or return '()';
    return "( $string )";
}

sub _method_result {		## no critic (RequireArgUnpacking)
    my ( $method, @args ) = @_;
    my $expect = pop @args;
    $result = undef;
    defined $obj and $result = $obj->$method();
    my $safe;
    if ( defined $result ) {
	($safe = $result) =~ s/([\\'])/\\$1/smxg;
	$safe = "'$safe'";
    } else {
	$safe = 'undef';
    }
    @_ = _replace_characters( $result, $expect, "$kind $nav $method $safe" );
    goto &is;
}

sub _parse_constructor_args {
    my ( $opt, @args ) = @_;
    my @rslt = ( $opt );
    foreach my $arg ( @args ) {
	if ( $arg =~ m/ \A - -? (no)? (\w+) \z /smx &&
	    exists $opt->{$2} ) {
	    $opt->{$2} = !$1;
	} else {
	    push @rslt, $arg;
	}
    }
    return @rslt;
}

sub _pause {
    if ( eval { require Time::HiRes; 1 } ) {	# Cargo cult programming.
	Time::HiRes::sleep( 0.1 );		# Something like this is
    } else {					# in PPI's
	sleep 1;				# t/08_regression.t, and
    }						# who am I to argue?
    return;
}

# quote a string.
sub __quote {
    my @args = @_;
    my @rslt;
    foreach my $item ( @args ) {
	if ( __instance( $item, 'PPIx::Regexp::Element' ) ) {
	    $item = $item->content();
	}
	if ( ! defined $item ) {
	    push @rslt, 'undef';
	} elsif ( ARRAY_REF eq ref $item ) {
	    push @rslt, join( ' ', '[', __quote( @{ $item } ), ']' );
	} elsif ( looks_like_number( $item ) ) {
	    push @rslt, $item;
	} else {
	    $item =~ s/ ( [\\'] ) /\\$1/smxg;
	    push @rslt, "'$item'";
	}
    }
    return join( ', ', @rslt );
}

sub _replace_characters {
    my @arg = @_;
    if ( keys %replace_characters ) {
	foreach ( @arg ) {
	    $_ = join '',
	    # The following assumes I will never want to replace 0.
	    map { $replace_characters{$_} || $_ }
	    split qr<>;
	}
    }
    wantarray
	or return join '', @arg;
    return @arg;
}

1;

__END__

=head1 NAME

My::Module::Test - support for testing PPIx::Regexp

=head1 SYNOPSIS

 use lib qw{ inc };
 use My::Module::Test;

 parse   ( '/foo/' );
 value   ( failures => [], 0 );
 klass   ( 'PPIx::Regexp' );
 choose  ( child => 0 );
 klass   ( 'PPIx::Regexp::Token::Structure' );
 content ( '' );
 # and so on

=head1 DETAILS

This module is B<private> to the C<PPIx-Regexp> module. Its contents can
be changed without warning. This was always the intent, and this
paragraph should have been included in the POD much earlier than it
actually was.

This module exports various subroutines in support of testing
C<PPIx::Regexp>. Most of these are tests, with C<Test::More> doing the
dirty work. A few simply set up data for tests.

The whole test rig works by parsing (or tokenizing) a regular
expression, followed by a series of unit tests on the results of the
parse. Each set of unit tests is performed by selecting an object to
test using the C<choose> or C<navigate> subroutine, followed by the
tests to be performed on that object. A few tests do not test parse
objects, but rather the state of the system as a whole.

The following subroutines are exported:

=head2 cache_count

 cache_count( 1 );

This test compares the number of objects in the C<new_from_cache> cache
to its argument, succeeding if they are equal. If no argument is passed,
the default is 0.

=head2 choose

 choose( 2 );  # For tokenizer
 choose( child => 1, child => 2, type => 0 ); # For full parse

This subroutine does not itself represent a test. It chooses an object
from the parse tree for further testing. If testing a tokenizer, the
argument is the token number (from 0) to select. If testing a full
parse, the arguments are the navigation methods used to reach the
object to be tested, starting from the C<PPIx::Regexp> object. The
arguments to the methods are passed in an array reference, but if there
is a single argument it can be passed as a scalar, as in the example.

=head2 klass

 klass( 'PPIx::Regexp::Token::Structure' );

This test checks to see if the current object is of the given class, and
succeeds if it is. If the current object is C<undef>, the test fails.

This test was C<class>, but that tends to conflict with object systems.

=head2 content

 content( '\N{LATIN SMALL LETTER A}' );

This test checks to see if the C<content> method of the current object
is equal to the given string. If the current object is C<undef>, the
test fails.

=head2 cmp_ok

This subroutine is exported from L<Test::More|Test::More>.

=head2 count

 count( 42 );

This test checks the number of objects returned by an operation that
returns more than one object. It succeeds if the number of objects
returned is equal to the given number.

This test is valid only after C<tokenize>, or a C<choose> or C<navigate>
whose argument list ends in one of

 children => []
 finish => []
 start => []
 type => []

=head2 different

 different( $o1, $o2, 'Test name' );

This test compares two things, succeeding if they are different.
References are compared by reference address and scalars by value
(numeric or string comparison as appropriate). If the first argument is
omitted it defaults to the current object.

=head2 dump_result

 dump_result( tokens => 1, <<'EOD', 'Test tokenization dump' );
 ... expected dump here ...
 EOD

This test performs the specified dump on the current object and succeeds
if the result matches the expectation. The name of the test is the last
argument, and the expected result is the next-to-last argument. All
other arguments are passed to
L<PPIx::Regexp::Dumper|PPIx::Regexp::Dumper>.

Well, almost all other arguments are passed to the dumper. You can
specify C<--notest> to skip the test. In this case the result of the
last operation is dumped. L<PPIx::Regexp::Dumper|PPIx::Regexp::Dumper>
is used if appropriate; otherwise you get a L<YAML|YAML> dump if that is
available, or a L<Data::Dumper|Data::Dumper> dump if not. If no dumper
class can be found, a diagnostic is produced. You can also specify
C<--test>, but this is the default. This option is removed from the
argument list before the test name (etc) is determined.

=head2 equals

 equals( $o1, $o2, 'Test name' );

This test compares two things, succeeding if they are equal. References
are compared by reference address and scalars by value (numeric or string
comparison as appropriate). If the first argument is omitted it defaults
to the current object.

=head2 format_want

 is $got, $want, 'Want ' . format_want( $want );

This convenience subroutine formats the wanted result. If an ARRAY
reference, the contents are enclosed in parentheses.

=head2 false

 false( significant => [] );

This test succeeds if the given method, with the given arguments, called
on the current object, returns a false value.

=head2 finis

 finis();

This test should be last in a series, and no references to parse objects
should be held when it is run. It checks the number of objects in the
internal C<%parent> hash, and succeeds if it is zero.

=head2 invocant

 invocant();

Returns the current object.

=head2 navigate

 navigate( snext_sibling => [] );

Like C<choose>, this is not a test, but selects an object for testing.
Unlike C<choose>, selection starts from the current object, not the top
of the parse tree.

=head2 parse

 parse( 's/foo/bar/g' );

This test parses the given regular expression into a C<PPIx::Regexp>
object, and succeeds if a C<PPIx::Regexp> object was in fact generated.

If you specify argument C<--notest>, the parse is done but no test is
performed. You would do this if you expected the parse to fail (e.g. you
are testing error handling). You can also explicitly specify C<--test>,
but this is the default.

All other arguments are passed to the L<PPIx::Regexp|PPIx::Regexp>
constructor.

=head2 plan

This subroutine is exported from L<Test::More|Test::More>.

=head2 ppi

 ppi( '$foo' );

This test calls the current object's C<ppi()> method, and checks to see
if the content of the returned L<PPI::Document|PPI::Document> is equal
to the given string. If the current object is C<undef> or does not have
a C<ppi()> method, the test fails.

=head2 raw_width

 raw_width( 0, undef, "Some title" );

This tests invokes the raw_width() method on the current object. The
arguments are the expected minimum width, the expected maximum width,
and a test title. The title defaults to the class and content of the
current object.

Two tests are actually run. The titles of these will have
C<' raw minimum width'> and C<' raw maximum width'> appended. This
subroutine returns true if both tests pass.

=head2 result

 my $val = result();

This subroutine returns the result of the most recent operation that
actually produces one. It should be called immediately after the
operation, mostly because I have not documented all the subroutines that
produce a result.

=head2 tokenize

 tokenize( 'm/foo/smx' );

This test tokenizes the given regular expression into a
C<PPIx::Regexp::Tokenizer> object, and succeeds if a
C<PPIx::Regexp::Tokenizer> object was in fact generated.

If you specify argument C<--notest>, the parse is done but no test is
performed. You would do this if you expected the parse to fail (e.g. you
are testing error handling). You can also explicitly specify C<--test>,
but this is the default.

If you specify argument C<--notokens>, the tokenizer is built, but the
tokens are not extracted. You would do this when you want a subsequent
operation to call C<tokens()>. You can also explicitly specify
C<--tokens>, but this is the default.

All other arguments are passed to the
L<PPIx::Regexp::Tokenizer|PPIx::Regexp::Tokenizer> constructor.

=head2 true

 true( significant => [] );

This test succeeds if the given method, with the given arguments, called
on the current object, returns a true value.

=head2 value

 value( max_capture_number => [], 3 );

This test succeeds if the given method, with the given arguments, called
on the current object, returns the given value. If the wanted value is
a reference, C<is_deeply()> is used for the comparison; otherwise
C<is()> is used.

If the current object is undefined, the given method is called on the
intended initial class, otherwise there would be no way to test the
errstr() method.

The result of the method call is accessable via the L<result()|/result>
subroutine.

An optional fourth argument specifies the name of the test. If this is
omitted or specified as C<undef>, a name is generated describing the
arguments.

=head2 width

 width( 0, undef, "Some title" );

This tests invokes the width() method on the current object. The
arguments are the expected minimum width, the expected maximum width,
and a test title. The title defaults to the class and content of the
current object.

Two tests are actually run. The titles of these will have
C<' minimum width'> and C<' maximum width'> appended. This subroutine
returns true if both tests pass.

=head1 SUPPORT

Support is by the author. Please file bug reports at
L<https://rt.cpan.org/Public/Dist/Display.html?Name=PPIx-Regexp>,
L<https://github.com/trwyant/perl-PPIx-Regexp/issues>, or in
electronic mail to the author.

=head1 AUTHOR

Thomas R. Wyant, III F<wyant at cpan dot org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009-2023, 2025 by Thomas R. Wyant, III

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl 5.10.0. For more details, see the full text
of the licenses in the directory LICENSES.

This program is distributed in the hope that it will be useful, but
without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

=cut

# ex: set textwidth=72 :
