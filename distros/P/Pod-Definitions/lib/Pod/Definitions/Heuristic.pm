package Pod::Definitions::Heuristic;

use Pod::Headings;
our $VERSION = '0.02';

use v5.20;

use strict;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

#
# Instantiation
#

sub new ($class, @args) {
    my $self = {@args};
    bless $self, $class;

    return $self;
}

#
# Accessors
#

sub text ($self, $new = undef) {
    $self->{text} = $new if defined $new;
    return $self->{text};
}

sub clean ($self) {
    # Clean headings for index display

    #
    # TODO:
    # 
    # Rewrite this as a series of filters, in the style of
    # Mail::Filter, or iptables, where each filter's output is passed
    # to the next in the chain, with the possibility of:
    # 
    #  - skipping the remainder of the chain with a final result (PASS)
    #  - skipping the remainder of the chain without saving (FAIL)
    #  - modifying the text (as iptables lets you modify a packet)
    #
    # TODO:
    #
    # - Perhaps an alternate heuristic for 'item' entries?
    #

    my $original = $self->{text};
    $original =~ s/^\s+//;
    $original =~ s/\s(?:mean|go)\?$//;
    $original =~ s/\?$//;
    # Which versions are supported -> Versions supported
    # How much does... How well is... How many...
    $original =~ s/^(?:(what|which|how|many|much|well|is|are|do)\s+)+(\S.*?)?\s+(?:is|are|do)\s+(.+)\z/\u$2, $3/i;
    $original =~ s/\s{2,}/ /g;

    # What does the error "Oops" mean? -> Oops, error
    if ($original =~ m/^(?:(?:what|do|does|a|an|the)\s+)+((?:error|message)\s+)"?(.*)\z/i) {
        my ($prefix, $main) = ($1, ucfirst($2));
        $main =~ s/[?"]//g;
        $main =~ s/^\s+//;
        $prefix =~ s/[?"]//g;
        $prefix =~ s/\s+\z//;
        return "$main, $prefix";
    }

    # How can I blip the blop? -> Blip the blop, How can I
    # Why doesn't my socket have a packet? -> Socket have a packet, Why doesn't my
    # Where are the pockets on the port? -> Pockets on the port, Where are the
    if ($original =~ m/^((?:(?:who|what|when|where|which|why|how|is|are|did|a|an|the|do|does|don't|doesn't|can|not|I|my|need|to|about|there|much|many)\s+|go\s+for|error\s+"\.*|message\s+"\.*)+)(.*)$/i) {
        my ($prefix, $main) = ($1, ucfirst($2));
        $main =~ s/[?"]//g;
        $main =~ s/^\s+//;
        $prefix =~ s/[?"]//g;
        $prefix =~ s/\s+\z//;
        return "$main, $prefix";
    }
    # Nibbling the carrot -> Carrot, nibbling the
    if ($original =~ m/^(\w+ing(?:\s+and\s+\w+ing)?)\s+(a|an|the|some|any|all|to|from|your)?\b\s*(.*)$/) {
        my ($verb, $qualifier, $remainder) = ($1, $2, $3);
        $qualifier ||= '';
        # print ucfirst("$remainder, $verb $qualifier\n");
        return ucfirst("$remainder, $verb $qualifier");
    }
    # $variable=function_name(...) -> function_name
    if ($original =~ m/^[\$@]\w+\s*=\s*(?:\$\w+\s*->\s*)?(\w+)/) {
        return $1;
    }
    # $variable->function_name(...) -> function_name
    if ($original =~ m/^\$?\w+\s*->\s*(\w+)/) {
        return $1;
    }
    # Module::Module->function_name(...) -> function_name
    if ($original =~ m/^\w+(?:::\w+)+\s*->\s*(\w+)/) {
        return $1;
    }
    # function_name($args,...) -> function_name
    if ($original =~ m/^(\w+)\s*\(\s*[\$@%]\w+/) {
        return $1;
    }
    # ($var, $var) = function_name(...) -> function_name
    if ($original =~ m/^\([\$@%][^)]+\)\s*=\s*(?:\$\w+\s*->\s*)?(\w+)/) {
        return $1;
    }
    # function_name BLOCK LIST [EXPR] -> function_name
    if ($original =~ m/^((?:\w|_)+)\s+(?:(?:BLOCK|EXPR|LIST|COUNT|ARRAY\d*|VALUE|STRING|ITEM|\.+)\s*)+/) {
        return $1;
    }
    return $original;
}

1;

__END__

=pod

=head1 NAME

Pod::Definitions::Heuristic -- Apply heuristics to headings defined in
Pod, presumably in English, for indexing and cross-referencing

=head1 VERSION

version 0.02

=head1 SYNOPSIS

    my $h = Pod::Headings::Heuristic->new(
                text => "Splitting the infinitive");
    $h->clean();  # returns "Infinitive, splitting the"

=head1 DESCRIPTION

This class assumes that headings are written in the English language,
and in a style typical of Pod pages written for CPAN. A set of
heuristics are applied to select keywords and place them at the start
of the heading.

=head1 METHODS

=head2 new

Creates a new object of type Pod::Headings::Heuristic.  To this should
be passed a list of items to be saved as a hash in the object.  The
only item currently required or defined is 'text'.

=head2 clean

Applies the keyword-finding heuristics on text in 'text' and returns a
best guess version with the keyword in first position.

=head2 text

The content of the text to be parsed.

=head1 SEE ALSO

L<Pod::Headings>

=head1 SUPPORT

This module is managed in an open GitHub repository,
L<https://github.com/lindleyw/Pod-Definitions>. Feel free to fork and
contribute, or to clone and send patches.

=head1 AUTHOR

This module was written and is maintained by William Lindley
<wlindley@cpan.org>.

=cut
