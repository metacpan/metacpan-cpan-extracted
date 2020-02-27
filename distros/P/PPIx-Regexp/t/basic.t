package main;

use strict;
use warnings;

use lib qw{ inc };

use Test::More 0.88;

require_ok( 'My::Module::Mock_Tokenizer' ) or BAIL_OUT;

require_ok( 'PPI::Document' )
    or BAIL_OUT(
    q{PPI::Document is a prerequisite. Without it, we're hosed.} );

require_ok( 'PPIx::Regexp::Util' ) or BAIL_OUT;

can_ok( 'PPIx::Regexp::Util', 'is_ppi_regexp_element' ) or BAIL_OUT;

require_ok( 'PPIx::Regexp' ) or BAIL_OUT;
class_isa_ok( 'PPIx::Regexp', 'PPIx::Regexp::Node' ) or BAIL_OUT;

require_ok( 'PPIx::Regexp::Constant' );
class_isa_ok( 'PPIx::Regexp::Constant', 'Exporter' );

require_ok( 'PPIx::Regexp::Dumper' ) or BAIL_OUT;
class_isa_ok( 'PPIx::Regexp::Dumper', 'PPIx::Regexp::Support' );
isa_ok( PPIx::Regexp::Dumper->new( 'xyzzy' ), 'PPIx::Regexp::Dumper' );

require_ok( 'PPIx::Regexp::Element' );

require_ok( 'PPIx::Regexp::Lexer' );
class_isa_ok( 'PPIx::Regexp::Lexer', 'PPIx::Regexp::Support' );

require_ok( 'PPIx::Regexp::Node' );
class_isa_ok( 'PPIx::Regexp::Node', 'PPIx::Regexp::Element' );

require_ok( 'PPIx::Regexp::Node::Range' );
class_isa_ok( 'PPIx::Regexp::Node::Range', 'PPIx::Regexp::Node' );

require_ok( 'PPIx::Regexp::Node::Unknown' );
class_isa_ok( 'PPIx::Regexp::Node::Unknown', 'PPIx::Regexp::Node' );

require_ok( 'PPIx::Regexp::Structure' );
class_isa_ok( 'PPIx::Regexp::Structure', 'PPIx::Regexp::Node' );

require_ok( 'PPIx::Regexp::Structure::Assertion' );
class_isa_ok( 'PPIx::Regexp::Structure::Assertion',
    'PPIx::Regexp::Structure' );

require_ok( 'PPIx::Regexp::Structure::Atomic_Script_Run' );
class_isa_ok( 'PPIx::Regexp::Structure::Atomic_Script_Run',
    'PPIx::Regexp::Structure' );

require_ok( 'PPIx::Regexp::Structure::BranchReset' );
class_isa_ok( 'PPIx::Regexp::Structure::BranchReset',
    'PPIx::Regexp::Structure' );

require_ok( 'PPIx::Regexp::Structure::Capture' );
class_isa_ok( 'PPIx::Regexp::Structure::Capture',
    'PPIx::Regexp::Structure' );

require_ok( 'PPIx::Regexp::Structure::CharClass' );
class_isa_ok( 'PPIx::Regexp::Structure::CharClass',
    'PPIx::Regexp::Structure' );

require_ok( 'PPIx::Regexp::Structure::Code' );
class_isa_ok( 'PPIx::Regexp::Structure::Code',
    'PPIx::Regexp::Structure' );

require_ok( 'PPIx::Regexp::Structure::Main' );
class_isa_ok( 'PPIx::Regexp::Structure::Main',
    'PPIx::Regexp::Structure' );

require_ok( 'PPIx::Regexp::Structure::Modifier' );
class_isa_ok( 'PPIx::Regexp::Structure::Modifier',
    'PPIx::Regexp::Structure' );

require_ok( 'PPIx::Regexp::Structure::NamedCapture' );
class_isa_ok( 'PPIx::Regexp::Structure::NamedCapture',
    'PPIx::Regexp::Structure::Capture' );

require_ok( 'PPIx::Regexp::Structure::Quantifier' );
class_isa_ok( 'PPIx::Regexp::Structure::Quantifier',
    'PPIx::Regexp::Structure' );

require_ok( 'PPIx::Regexp::Structure::Regexp' );
class_isa_ok( 'PPIx::Regexp::Structure::Regexp',
    'PPIx::Regexp::Structure::Main' );

require_ok( 'PPIx::Regexp::Structure::Replacement' );
class_isa_ok( 'PPIx::Regexp::Structure::Replacement',
    'PPIx::Regexp::Structure::Main' );

require_ok( 'PPIx::Regexp::Structure::Script_Run' );
class_isa_ok( 'PPIx::Regexp::Structure::Script_Run',
    'PPIx::Regexp::Structure' );

require_ok( 'PPIx::Regexp::Structure::Subexpression' );
class_isa_ok( 'PPIx::Regexp::Structure::Subexpression',
    'PPIx::Regexp::Structure' );

require_ok( 'PPIx::Regexp::Structure::Switch' );
class_isa_ok( 'PPIx::Regexp::Structure::Switch',
    'PPIx::Regexp::Structure' );

require_ok( 'PPIx::Regexp::Structure::Unknown' );
class_isa_ok( 'PPIx::Regexp::Structure::Unknown',
    'PPIx::Regexp::Structure' );

require_ok( 'PPIx::Regexp::Support' );

require_ok( 'PPIx::Regexp::Token' );
class_isa_ok( 'PPIx::Regexp::Token', 'PPIx::Regexp::Element' );
isa_ok( PPIx::Regexp::Token->__new( 'xyzzy' ), 'PPIx::Regexp::Token' );

require_ok( 'PPIx::Regexp::Token::Assertion' );
class_isa_ok( 'PPIx::Regexp::Token::Assertion', 'PPIx::Regexp::Token'
    );
isa_ok( PPIx::Regexp::Token::Assertion->__new( 'xyzzy' ),
    'PPIx::Regexp::Token::Assertion' );

require_ok( 'PPIx::Regexp::Token::Backreference' );
class_isa_ok( 'PPIx::Regexp::Token::Backreference',
    'PPIx::Regexp::Token::Reference' );
isa_ok( PPIx::Regexp::Token::Backreference->__new( '\\1' ),
    'PPIx::Regexp::Token::Backreference' );

require_ok( 'PPIx::Regexp::Token::Backtrack' );
class_isa_ok( 'PPIx::Regexp::Token::Backtrack', 'PPIx::Regexp::Token'
    );
isa_ok( PPIx::Regexp::Token::Backtrack->__new( 'xyzzy' ),
    'PPIx::Regexp::Token::Backtrack' );

require_ok( 'PPIx::Regexp::Token::CharClass' );
class_isa_ok( 'PPIx::Regexp::Token::CharClass', 'PPIx::Regexp::Token'
    );
isa_ok( PPIx::Regexp::Token::CharClass->__new( 'xyzzy' ),
    'PPIx::Regexp::Token::CharClass' );

require_ok( 'PPIx::Regexp::Token::CharClass::POSIX' );
class_isa_ok( 'PPIx::Regexp::Token::CharClass::POSIX',
    'PPIx::Regexp::Token::CharClass' );
isa_ok( PPIx::Regexp::Token::CharClass::POSIX->__new( 'xyzzy' ),
    'PPIx::Regexp::Token::CharClass::POSIX' );

require_ok( 'PPIx::Regexp::Token::CharClass::Simple' );
class_isa_ok( 'PPIx::Regexp::Token::CharClass::Simple',
    'PPIx::Regexp::Token::CharClass' );
isa_ok( PPIx::Regexp::Token::CharClass::Simple->__new( 'xyzzy' ),
    'PPIx::Regexp::Token::CharClass::Simple' );

require_ok( 'PPIx::Regexp::Token::Code' );
class_isa_ok( 'PPIx::Regexp::Token::Code', 'PPIx::Regexp::Token' );
isa_ok( PPIx::Regexp::Token::Code->__new( 'xyzzy',
	tokenizer => My::Module::Mock_Tokenizer->new(),
    ),
    'PPIx::Regexp::Token::Code' );

require_ok( 'PPIx::Regexp::Token::Comment' );
class_isa_ok( 'PPIx::Regexp::Token::Comment', 'PPIx::Regexp::Token' );
isa_ok( PPIx::Regexp::Token::Comment->__new( 'xyzzy' ),
    'PPIx::Regexp::Token::Comment' );

require_ok( 'PPIx::Regexp::Token::Condition' );
class_isa_ok( 'PPIx::Regexp::Token::Condition',
    'PPIx::Regexp::Token::Reference' );
isa_ok( PPIx::Regexp::Token::Condition->__new( '(1)' ),
    'PPIx::Regexp::Token::Condition' );

require_ok( 'PPIx::Regexp::Token::Control' );
class_isa_ok( 'PPIx::Regexp::Token::Control', 'PPIx::Regexp::Token' );
isa_ok( PPIx::Regexp::Token::Control->__new( 'xyzzy' ),
    'PPIx::Regexp::Token::Control' );

require_ok( 'PPIx::Regexp::Token::Delimiter' );
class_isa_ok( 'PPIx::Regexp::Token::Delimiter', 'PPIx::Regexp::Token'
    );
isa_ok( PPIx::Regexp::Token::Delimiter->__new( 'xyzzy' ),
    'PPIx::Regexp::Token::Delimiter' );

require_ok( 'PPIx::Regexp::Token::Greediness' );
class_isa_ok( 'PPIx::Regexp::Token::Greediness', 'PPIx::Regexp::Token'
    );
isa_ok( PPIx::Regexp::Token::Greediness->__new( 'xyzzy' ),
    'PPIx::Regexp::Token::Greediness' );

require_ok( 'PPIx::Regexp::Token::GroupType' );
class_isa_ok( 'PPIx::Regexp::Token::GroupType', 'PPIx::Regexp::Token'
    );
isa_ok( PPIx::Regexp::Token::GroupType->__new( 'xyzzy' ),
    'PPIx::Regexp::Token::GroupType' );

require_ok( 'PPIx::Regexp::Token::GroupType::Assertion' );
class_isa_ok( 'PPIx::Regexp::Token::GroupType::Assertion',
    'PPIx::Regexp::Token::GroupType' );
isa_ok( PPIx::Regexp::Token::GroupType::Assertion->__new( 'xyzzy' ),
    'PPIx::Regexp::Token::GroupType::Assertion' );

require_ok( 'PPIx::Regexp::Token::GroupType::Atomic_Script_Run' );
class_isa_ok( 'PPIx::Regexp::Token::GroupType::Atomic_Script_Run',
    'PPIx::Regexp::Token::GroupType' );
isa_ok( PPIx::Regexp::Token::GroupType::Atomic_Script_Run->__new( 'xyzzy' ),
    'PPIx::Regexp::Token::GroupType::Atomic_Script_Run' );

require_ok( 'PPIx::Regexp::Token::GroupType::BranchReset' );
class_isa_ok( 'PPIx::Regexp::Token::GroupType::BranchReset',
    'PPIx::Regexp::Token::GroupType' );
isa_ok( PPIx::Regexp::Token::GroupType::BranchReset->__new( 'xyzzy' ),
    'PPIx::Regexp::Token::GroupType::BranchReset' );

require_ok( 'PPIx::Regexp::Token::GroupType::Code' );
class_isa_ok( 'PPIx::Regexp::Token::GroupType::Code',
    'PPIx::Regexp::Token::GroupType' );
isa_ok( PPIx::Regexp::Token::GroupType::Code->__new( 'xyzzy',
	tokenizer => My::Module::Mock_Tokenizer->new(),
    ),
    'PPIx::Regexp::Token::GroupType::Code' );

require_ok( 'PPIx::Regexp::Token::GroupType::Modifier' );
class_isa_ok( 'PPIx::Regexp::Token::GroupType::Modifier',
    'PPIx::Regexp::Token::GroupType' );
class_isa_ok( 'PPIx::Regexp::Token::GroupType::Modifier',
    'PPIx::Regexp::Token::Modifier' );
isa_ok( PPIx::Regexp::Token::GroupType::Modifier->__new( 'xyzzy',
	tokenizer => My::Module::Mock_Tokenizer->new(),
    ),
    'PPIx::Regexp::Token::GroupType::Modifier' );

require_ok( 'PPIx::Regexp::Token::GroupType::NamedCapture' );
class_isa_ok( 'PPIx::Regexp::Token::GroupType::NamedCapture',
    'PPIx::Regexp::Token::GroupType' );
isa_ok( PPIx::Regexp::Token::GroupType::NamedCapture->__new( 'xyzzy',
	tokenizer => My::Module::Mock_Tokenizer->new(
	    capture => [ 'foo' ],
	),
     ),
    'PPIx::Regexp::Token::GroupType::NamedCapture' );

require_ok( 'PPIx::Regexp::Token::GroupType::Subexpression' );
class_isa_ok( 'PPIx::Regexp::Token::GroupType::Subexpression',
    'PPIx::Regexp::Token::GroupType' );
isa_ok( PPIx::Regexp::Token::GroupType::Subexpression->__new( 'xyzzy' ),
    'PPIx::Regexp::Token::GroupType::Subexpression' );

require_ok( 'PPIx::Regexp::Token::GroupType::Script_Run' );
class_isa_ok( 'PPIx::Regexp::Token::GroupType::Script_Run',
    'PPIx::Regexp::Token::GroupType' );
isa_ok( PPIx::Regexp::Token::GroupType::Script_Run->__new( 'xyzzy' ),
    'PPIx::Regexp::Token::GroupType::Script_Run' );

require_ok( 'PPIx::Regexp::Token::GroupType::Switch' );
class_isa_ok( 'PPIx::Regexp::Token::GroupType::Switch',
    'PPIx::Regexp::Token::GroupType' );
isa_ok( PPIx::Regexp::Token::GroupType::Switch->__new( 'xyzzy' ),
    'PPIx::Regexp::Token::GroupType::Switch' );

require_ok( 'PPIx::Regexp::Token::Interpolation' );
class_isa_ok( 'PPIx::Regexp::Token::Interpolation',
    'PPIx::Regexp::Token::Code' );
isa_ok( PPIx::Regexp::Token::Interpolation->__new( 'xyzzy',
	tokenizer => My::Module::Mock_Tokenizer->new(),
    ),
    'PPIx::Regexp::Token::Interpolation' );

require_ok( 'PPIx::Regexp::Token::Literal' );
class_isa_ok( 'PPIx::Regexp::Token::Literal', 'PPIx::Regexp::Token' );
isa_ok( PPIx::Regexp::Token::Literal->__new( 'xyzzy' ),
    'PPIx::Regexp::Token::Literal' );

require_ok( 'PPIx::Regexp::Token::Modifier' );
class_isa_ok( 'PPIx::Regexp::Token::Modifier', 'PPIx::Regexp::Token' );
isa_ok( PPIx::Regexp::Token::Modifier->__new( 'xyzzy',
	tokenizer => My::Module::Mock_Tokenizer->new(),
    ),
    'PPIx::Regexp::Token::Modifier' );

require_ok( 'PPIx::Regexp::Token::NoOp' );
class_isa_ok( 'PPIx::Regexp::Token::NoOp',
    'PPIx::Regexp::Token' );
isa_ok( PPIx::Regexp::Token::NoOp->__new( 'xyzzy' ),
    'PPIx::Regexp::Token::NoOp' );

require_ok( 'PPIx::Regexp::Token::Operator' );
class_isa_ok( 'PPIx::Regexp::Token::Operator', 'PPIx::Regexp::Token' );
isa_ok( PPIx::Regexp::Token::Operator->__new( 'xyzzy',
	tokenizer => My::Module::Mock_Tokenizer->new(),
    ),
    'PPIx::Regexp::Token::Operator' );

require_ok( 'PPIx::Regexp::Token::Quantifier' );
class_isa_ok( 'PPIx::Regexp::Token::Quantifier', 'PPIx::Regexp::Token'
    );
isa_ok( PPIx::Regexp::Token::Quantifier->__new( 'xyzzy' ),
    'PPIx::Regexp::Token::Quantifier' );

require_ok( 'PPIx::Regexp::Token::Recursion' );
class_isa_ok( 'PPIx::Regexp::Token::Recursion',
    'PPIx::Regexp::Token::Reference' );
isa_ok( PPIx::Regexp::Token::Recursion->__new( '(?1)' ),
    'PPIx::Regexp::Token::Recursion' );

require_ok( 'PPIx::Regexp::Token::Reference' );
class_isa_ok( 'PPIx::Regexp::Token::Reference', 'PPIx::Regexp::Token'
    );
# This is an abstract class and should never be instantiated in the
# first place.
# isa_ok( PPIx::Regexp::Token::Reference->__new( 'xyzzy' ),
#     'PPIx::Regexp::Token::Reference' );

require_ok( 'PPIx::Regexp::Token::Structure' );
class_isa_ok( 'PPIx::Regexp::Token::Structure', 'PPIx::Regexp::Token'
    );
isa_ok( PPIx::Regexp::Token::Structure->__new( 'xyzzy' ),
    'PPIx::Regexp::Token::Structure' );

require_ok( 'PPIx::Regexp::Token::Unknown' );
class_isa_ok( 'PPIx::Regexp::Token::Unknown', 'PPIx::Regexp::Token' );
isa_ok( PPIx::Regexp::Token::Unknown->__new( 'xyzzy', error => 'bogus' ),
    'PPIx::Regexp::Token::Unknown' );

require_ok( 'PPIx::Regexp::Token::Unmatched' );
class_isa_ok( 'PPIx::Regexp::Token::Unmatched', 'PPIx::Regexp::Token'
    );
isa_ok( PPIx::Regexp::Token::Unmatched->__new( 'xyzzy' ),
    'PPIx::Regexp::Token::Unmatched' );

require_ok( 'PPIx::Regexp::Token::Whitespace' );
class_isa_ok( 'PPIx::Regexp::Token::Whitespace',
    'PPIx::Regexp::Token::NoOp' );
isa_ok( PPIx::Regexp::Token::Whitespace->__new( 'xyzzy' ),
    'PPIx::Regexp::Token::Whitespace' );

require_ok( 'PPIx::Regexp::Tokenizer' );
class_isa_ok( 'PPIx::Regexp::Tokenizer', 'PPIx::Regexp::Support' );
isa_ok( PPIx::Regexp::Tokenizer->new( 'xyzzy' ),
    'PPIx::Regexp::Tokenizer' );

done_testing;

sub class_isa_ok {
    my ( $class, $isa ) = @_;
    @_ = (
	eval { $class->isa( $isa ) },
	"$class isa $isa",
    );
    goto &ok,
}

1;

__END__

# ex: set textwidth=72 :
