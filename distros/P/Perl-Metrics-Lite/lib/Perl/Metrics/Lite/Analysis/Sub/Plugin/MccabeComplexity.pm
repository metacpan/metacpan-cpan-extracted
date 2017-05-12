package Perl::Metrics::Lite::Analysis::Sub::Plugin::MccabeComplexity;
use strict;
use warnings;

use Readonly;
Readonly::Array our @DEFAULT_LOGIC_OPERATORS => qw(
    !
    !~
    &&
    &&=
    //
    <
    <<=
    <=>
    ==
    =~
    >
    >>=
    ?
    and
    cmp
    eq
    gt
    lt
    ne
    not
    or
    xor
    ||
    ||=
    ~~
);

Readonly::Array our @DEFAULT_LOGIC_KEYWORDS => qw(
    else
    elsif
    for
    foreach
    goto
    grep
    if
    last
    map
    next
    unless
    until
    while
);
Readonly::Scalar my $LAST_CHARACTER => -1;

our ( @LOGIC_KEYWORDS, @LOGIC_OPERATORS );    # For user-supplied values;

our ( %LOGIC_KEYWORDS, %LOGIC_OPERATORS );    # Populated in _init()

my %_LOGIC_KEYWORDS  = ();
my %_LOGIC_OPERATORS = ();

sub init {
    my $class = shift;
    my @logic_keywords
        = @LOGIC_KEYWORDS ? @LOGIC_KEYWORDS : @DEFAULT_LOGIC_KEYWORDS;
    %LOGIC_KEYWORDS = hashify(@logic_keywords);
    $_LOGIC_OPERATORS{$class} = \%LOGIC_KEYWORDS;

    my @logic_operators
        = @LOGIC_OPERATORS ? @LOGIC_OPERATORS : @DEFAULT_LOGIC_OPERATORS;
    %LOGIC_OPERATORS = hashify(@logic_operators);
    $_LOGIC_OPERATORS{$class} = \%LOGIC_OPERATORS;
}

sub measure {
    my ( $class, $context, $elem ) = @_;

    my $complexity_count = 0;
    if ( Perl::Metrics::Lite::Analysis::Util::get_node_length($elem) == 0 ) {
        return $complexity_count;
    }

    if ($elem) {
        $complexity_count++;
    }
    $complexity_count += _countup_logic_keywords($elem); 
    $complexity_count += _counup_logic_operators($elem);

    return $complexity_count;
}

# Count up all the logic keywords, weed out hash keys
sub _countup_logic_keywords {
    my $elem = shift;
    my $keywords_ref = $elem->find('PPI::Token::Word') || [];
    my @filtered = grep { !is_hash_key($_) } @{$keywords_ref};
    my $complexity_count = grep { exists $LOGIC_KEYWORDS{$_} } @filtered;
    return $complexity_count;
}

sub _counup_logic_operators {
    my $elem = shift;
    my $complexity_count = 0;
    my $operators_ref = $elem->find('PPI::Token::Operator');
    if ($operators_ref) {
        $complexity_count
            += grep { exists $LOGIC_OPERATORS{$_} } @{$operators_ref};
    }
    return $complexity_count;
}

#-------------------------------------------------------------------------
# Copied from
# http://search.cpan.org/src/THALJEF/Perl-Critic-0.19/lib/Perl/Critic/Utils.pm
sub hashify {
    my @hash_keys = @_;
    return map { $_ => 1 } @hash_keys;
}

#-------------------------------------------------------------------------
# Copied and somehwat simplified from
# http://search.cpan.org/src/THALJEF/Perl-Critic-0.19/lib/Perl/Critic/Utils.pm
sub is_hash_key {
    my $ppi_elem = shift;

    my $is_hash_key = eval {
        my $parent      = $ppi_elem->parent();
        my $grandparent = $parent->parent();
        if ( $grandparent->isa('PPI::Structure::Subscript') ) {
            return 1;
        }
        my $sib = $ppi_elem->snext_sibling();
        if ( $sib->isa('PPI::Token::Operator') && $sib eq '=>' ) {
            return 1;
        }
        return;
    };

    return $is_hash_key;
}

1;

