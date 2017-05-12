package Pinwheel::TagSelect;

use strict;
use warnings;

use Carp qw(croak);

my $use_distinct_hack;
eval 'use XML::LibXML 1.61; *read = \&_read_libxml; $use_distinct_hack = 1; 1'
    or
eval 'use XML::XPath; *read = \&_read_xpath; 1'
    or
die "No usable XPath implementation!";

sub new
{
    my $class = shift;
    my $self = bless({xp => undef}, $class);
    return $self;
}

sub _read_xpath
{
    my ($self, $s) = @_;
    $self->{xp} = XML::XPath->new(xml => $s);
}

sub _read_libxml
{
    my ($self, $s) = @_;
    my ($parser, $doc);

    $parser = XML::LibXML->new();
    $doc = $parser->parse_string($s);
    $doc->documentElement->setAttribute('xmlns', '');
    $self->{xp} = XML::LibXML::XPathContext->new($doc);
}

# Work around an intermittent problem whereby the returned NodeList
# can have the same node in multiple times
sub _make_list_unique
{
    my ($nodes) = @_;
    my @uniq;
    for (@$nodes) { push @uniq, $_ unless @uniq and $_->isSameNode($uniq[-1]) }
    if (@uniq != $nodes->size)
    {
        warn sprintf "Warning: node list contained duplicates!  was %d, now %d",
            $nodes->size, 0+@uniq;
        @$nodes = @uniq;
    }
}

sub select
{
    my ($self, $selector, $args) = @_;
    my ($xpath, $nodes);

    $xpath = selector_to_xpath($selector, $args);
    $nodes = $self->{xp}->findnodes($xpath);
    _make_list_unique($nodes) if $use_distinct_hack;
    return $nodes;
}

=item $xpath = selector_to_xpath($selector_text, \@args)

Turns C<$selector_text> into an XPath selector.

Each instance of "=?" in C<$selector_text> consumes one item from the front of C<@args>.

Each instance of ".?" or "#?" in C<$selector_text> consumes one item from the front of C<@args>.

=cut

sub selector_to_xpath
{
    my ($s, $args) = @_;
    my ($lexer, $xpath);

    $s =~ s/=\?/'="' . shift(@$args) . '"'/ge;
    $s =~ s/([.#])\?/$1 . shift(@$args)/ge;

    # Assume already XPath if it starts with '/'
    return $s if $s =~ m[^/];

    $lexer = lexer($s);
    $xpath = parse_selector($lexer);
    croak 'Unexpected trailing content' if ($lexer->()[0] ne '');

    $xpath = ('*' . $xpath) if ($xpath =~ /^\[/);
    return '//' . $xpath;
}


sub parse_element_name
{
    my ($lexer) = @_;
    my ($type, $value);

    $type = $lexer->(1)[0];
    return if ($type ne '*' && $type ne 'ID' && $type ne 'NSID');

    $value = $lexer->()[1];
    $value =~ s/\|/:/ if $type eq 'NSID';
    return $value if $type ne '*';
    return '*';
}

sub parse_attrib
{
    my ($lexer) = @_;
    my ($token, $attrib, $cmp, $m1, $m2);

    $token = $lexer->();
    croak 'Expected [' if ($token->[0] ne '[');
    $token = $lexer->();
    if ($token->[0] eq 'ID' || $token->[0] eq 'NSID') {
        $attrib = '@' . $token->[1];
        $attrib =~ s/\|/:/;
    } else {
        croak 'Expected attribute name';
    }

    $token = $lexer->();
    return '[' . $attrib . ']' if ($token->[0] eq ']');
    croak 'Expected ] or comparison' unless ($token->[0] eq 'CMP');
    $cmp = $token->[1];
    $token = $lexer->();
    croak 'Expected string' unless ($token->[0] eq 'STR');
    $m1 = $token->[1];
    croak 'Expected ]' unless ($lexer->()[0] eq ']');

    if ($cmp eq '~=') {
        $m1 =~ s/^(.)(.*)(.)$/$1 $2 $3/;
        return "[contains(concat(\" \",$attrib,\" \"),$m1)]";
    } elsif ($cmp eq '^=') {
        return "[starts-with($attrib,$m1)]";
    } elsif ($cmp eq '$=') {
        $m2 = $m1;
        $m2 =~ s/\\././g;
        $m2 = length($m2) - 2;
        return
            '[substring(' .
                "$attrib," .
                "string-length($attrib)-" . ($m2 - 1) . ',' . $m2 .
            ")=$m1]";
    } elsif ($cmp eq '*=') {
        return "[contains($attrib,$m1)]";
    } elsif ($cmp eq '|=') {
        $m2 = $m1;
        $m2 =~ s/^(.)(.*)(.)$/$1$2-$3/;
        return "[$attrib=$m1 or starts-with($attrib,$m2)]";
    } else {
        return "[$attrib=$m1]";
    }
}

sub parse_function
{
    my ($lexer) = @_;
    my ($token, $name, $arg, $xpath);

    $token = $lexer->();
    croak 'Expected function name' unless ($token->[0] eq 'ID');
    $name = $token->[1];
    $token = $lexer->();
    croak 'Expected (' unless ($token->[0] eq '(');

    if ($name eq 'not') {
        $xpath = parse_selector($lexer);
        $xpath =~ s/^\[(.*)\]$/$1/;
        $xpath = "[not($xpath)]";
    } elsif ($name eq 'nth-child') {
        $token = $lexer->();
        croak 'Expected number' unless ($token->[0] eq 'NUM');
        $arg = $token->[1] - 1;
        $xpath = "[count(./preceding-sibling::*)=$arg]";
    } elsif ($name eq 'nth-last-child') {
        $token = $lexer->();
        croak 'Expected number' unless ($token->[0] eq 'NUM');
        $arg = $token->[1] - 1;
        $xpath = "[count(./following-sibling::*)=$arg]";
    } elsif ($name eq 'nth-of-type') {
        $token = $lexer->();
        croak 'Expected number' unless ($token->[0] eq 'NUM');
        $arg = $token->[1];
        $xpath = "[position()=$arg]";
    } elsif ($name eq 'nth-last-of-type') {
        $token = $lexer->();
        croak 'Expected number' unless ($token->[0] eq 'NUM');
        $arg = $token->[1] - 1;
        $xpath = "[last()-position()=$arg]";
    } elsif ($name eq 'first-of-type') {
        $xpath = '[position()=1]';
    } elsif ($name eq 'last-of-type') {
        $xpath = '[position()=last()]';
    } elsif ($name eq 'only-of-type') {
        $xpath = '[last()=1]';
    } else {
        croak "Unknown function: $name";
    }

    croak 'Expected )' unless $lexer->()[0] eq ')';
    return $xpath;
}

sub parse_pseudo
{
    my ($lexer) = @_;
    my ($token, $name, $xpath);

    $token = $lexer->();
    croak 'Expected :' unless ($token->[0] eq ':');
    return parse_function($lexer) if ($lexer->(2)[0] eq '(');

    $token = $lexer->();
    croak 'Expected identifier' unless ($token->[0] eq 'ID');
    $name = $token->[1];

    if ($name eq 'first-child') {
        $xpath = '[not(preceding-sibling::*)]';
    } elsif ($name eq 'first-of-type') {
        $xpath = '[position()=1]';
    } elsif ($name eq 'last-child') {
        $xpath = '[not(following-sibling::*)]';
    } elsif ($name eq 'last-of-type') {
        $xpath = '[position()=last()]';
    } elsif ($name eq 'only-child') {
        $xpath = '[not(preceding-sibling::* or following-sibling::*)]';
    } elsif ($name eq 'only-of-type') {
        $xpath = '[position()=1 and last()=1]';
    } elsif ($name eq 'empty') {
        $xpath =
            '[count(*)=0 and (' .
                'count(text())=0 or translate(text()," \t\r\n","")=""' .
            ')]';
    } elsif ($name eq 'checked') {
        $xpath = '[@checked]';
    } elsif ($name eq 'disabled') {
        $xpath = '[@disabled]';
    } elsif ($name eq 'enabled') {
        $xpath = '[not(@disabled)]';
    } else {
        croak 'Unknown pseudo element or class';
    }

    return $xpath;
}

sub parse_selector
{
    my ($lexer) = @_;
    my ($token, $xpath);

    $xpath = '';
    while (1) {
        $xpath .= parse_element_name($lexer) || '';

        while (1) {
            $token = $lexer->(1);
            if ($token->[0] eq '#ID') {
                $xpath .= '[@id="' . $lexer->()[1] . '"]';
            } elsif ($token->[0] eq '.ID') {
                $xpath .=
                    '[contains(' .
                        'concat(" ",@class," "),' .
                        '" ' . $lexer->()[1] . ' "' .
                    ')]';
            } elsif ($token->[0] eq '[') {
                $xpath .= parse_attrib($lexer);
            } elsif ($token->[0] eq ':') {
                $xpath .= parse_pseudo($lexer);
            } else {
                last;
            }
        }

        $token = $lexer->(1);
        if ($token->[0] eq '') {
            last;
        } elsif ($token->[0] eq '>') {
            $lexer->();
            $xpath .= '/';
        } elsif ($token->[0] eq '~') {
            $lexer->();
            $xpath .= '/following-sibling::*/self::';
        } elsif ($token->[0] eq '+') {
            $lexer->();
            $xpath .= '/following-sibling::*[1]/self::';
        } elsif ($token->[0] eq 'ID' || $token->[0] eq '*') {
            $xpath .= '//';
        } else {
            last;
        }
    }

    return $xpath;
}


sub lexer
{
    my $s = shift;
    my @buf;
    my $lexer = sub {
        while (1) {
            # The CSS 2 spec doesn't allow underscores in IDs / classes.
            # See http://www.w3.org/TR/CSS2/grammar.html
            return ['STR',  $1] if $s =~ /\G((['"])((?:\\.|.)*?)\2)/gc;
            return ['NUM',  $1] if $s =~ /\G(\d+)/gc;
            return ['NSID', $1] if $s =~ /\G([a-z][a-z0-9_-]*\|[a-z][a-z0-9_-]*)/igc;
            return ['ID',   $1] if $s =~ /\G([a-z][a-z0-9_-]*)/igc;
            return ['#ID',  $1] if $s =~ /\G#([a-z][a-z0-9-]*)/igc;
            return ['@ID',  $1] if $s =~ /\G@([a-z][a-z0-9-]*)/igc;
            return ['.ID',  $1] if $s =~ /\G\.([a-z][a-z0-9-]*)/igc;
            return ['CMP',  $1] if $s =~ /\G([\$*~^|]?=)/gc;
            return [$1,     ''] if $s =~ /\G(:|\.|[][>+~*()])/gc;
            last                if $s !~ /\G\s+/gc; 
        }
        $s =~ /\G(.*)/;
        return ['', $1];
    };
    return sub {
        if ($_[0]) {
            my $n = shift;
            push @buf, &$lexer() while (@buf < $n);
            return $buf[$n - 1];
        } else { 
            return shift(@buf) if (@buf > 0);
            return &$lexer();
        }
    };
}


1;
