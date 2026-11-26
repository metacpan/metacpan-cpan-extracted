# ABSTRACT: What the POD of a module says about each of its subs
# PODNAME: Pod::Coverage::More::Documentation

package Pod::Coverage::More::Documentation 0.005;

use 5.036;
use warnings FATAL => q{all};
use re q{/xsaa};

use List::Util qw{any};
use Pod::Simple::SimpleTree;
use Types::Standard qw{Bool InstanceOf Int Str Undef};

use Pod::Coverage::More::Types qw{type_named};


# A reader of POD.
# @param   subs  ArrayRef[Str]  optional: the names of the subs of the package, which tell the headings that document subs from the others
# @returns Pod::Coverage::More::Documentation  the reader
# @example my $doc = Pod::Coverage::More::Documentation->new( subs => [ 'resize', 'crop' ] );
sub new {
    my ( $class, %args ) = @_;
    return bless( { subs => $args{subs} ? { map { $_ => 1 } @{ $args{subs} } } : undef, sections => [] }, $class );
}

# Reads the POD of C<file>.
# @param   file  Str  the path of the file
# @returns Pod::Coverage::More::Documentation  the reader
# @example my $doc = Pod::Coverage::More::Documentation->new->parse_file('lib/Some/Module.pm');
sub parse_file {
    my ( $self, $file ) = @_;
    return $self->_read( _parser()->parse_file($file)->root );
}

# Reads the POD in the string C<pod>.
# @param   pod  Str  the POD
# @returns Pod::Coverage::More::Documentation  the reader
# @example my $doc = Pod::Coverage::More::Documentation->new->parse_string($pod);
sub parse_string {
    my ( $self, $pod ) = @_;
    return $self->_read( _parser()->parse_string_document($pod)->root );
}

# The sections, in the order of the POD, as SECTIONS describes them.
# @returns the sections, as a list of HASHREFs
# @example my @headings = map { $_->{heading} } $doc->sections;
sub sections {
    my ($self) = @_;
    return @{ $self->{sections} };
}

# The section whose heading names the sub C<name>, or nothing.
# A heading that writes it as a call, as C<name(...)>, C<< $obj->name >> or C<Pkg::name>, comes before one that writes only its bare name,
# then a shallower heading before a deeper one, then the first in the POD.
# @param   name  Str  the name of the sub
# @returns HashRef  the section
# @example my $section = $doc->section_for('resize');
sub section_for {
    my ( $self, $name ) = @_;
    my $best;
    foreach my $section ( @{ $self->{sections} } ) {
        my $strength = $section->{strength}{$name} or next;
        $best = $section if !$best || $strength > $best->{strength}{$name} || ( $strength == $best->{strength}{$name} && $section->{level} < $best->{level} );
    }
    return $best if $best;
    return;
}

# The names of all the subs that the headings name, which L<Pod::Coverage> counts as documented.
# @returns the names, as a list
# @example my @documented = $doc->identifiers;
sub identifiers {
    my ($self) = @_;
    return map { @{ $_->{functions} } } @{ $self->{sections} };
}

sub _parser {
    my $parser = Pod::Simple::SimpleTree->new;
    $parser->accept_directive_as_processed(qw{method func attr});
    return $parser;
}

# A type word or a parameterized type expression, such as Str, Types::Standard::Int or ArrayRef[HashRef[Str]].
our $TYPE_NAME   = qr/[[:alpha:]_]\w*(?:::\w+)*/;
our $TYPE_PARAMS = qr/(?<params>\[(?:[^\[\]]++|(?&params))*\])/;

# The words of a paragraph that says how a sub terminates.
our @TERMINATION_WORDS = qw{die dies died croak croaks croaked confess confesses confessed throw throws exception exceptions exit exits exited};
our $TERMINATION       = do { my $words = join q{|}, @TERMINATION_WORDS; qr/\b(?:$words|terminat\w*)\b/i };

# A class name, maybe quoted, as prose names the class of a returned object.
our $CLASS_NAME = qr/['"]?([\w:]+)['"]?/;

# A class name that starts with a capital, followed by "object" or "instance", as in "a new Foo object".
our $CLASS_OBJECT = qr/(?-i:(?=['"]?[[:upper:]]))$CLASS_NAME\s+(?:object|instance)\b/i;

our %LEVEL = ( head1 => 1, head2 => 2, head3 => 3, head4 => 4, method => 2, func => 2, attr => 2 );

sub _read {
    my ( $self, $root ) = @_;
    my ( undef, undef, @nodes ) = @$root;
    my $current;
    foreach my $node (@nodes) {
        next if !ref $node;
        my $type  = $node->[0];
        my $level = $LEVEL{$type};
        if ($level) {
            my $text    = _flatten($node);
            my $section = $level > 1 ? $self->_heading( $text, $node->[1]{start_line} ) : undef;
            if ( $section && ( !$self->{subs} || any { $self->{subs}{$_} } @{ $section->{functions} } ) ) {
                $section->{level} = $level;
                push @{ $self->{sections} }, $section;
                $current = $section;
                next;
            }
            undef $current if !$current || $level <= $current->{level};
            next;
        }
        $self->_content( $current, $node ) if $current;
    }
    return $self;
}

# _flatten and _content walk the tree of the POD, which is as deep as its nesting, and so recursion is their natural form.
## no critic (Subroutines::ProhibitTailRecursion)

# The text of a node, with its formatting codes and their markup left out.
sub _flatten {
    my ($node) = @_;
    return $node if !ref $node;
    my ( undef, undef, @kids ) = @$node;
    my $text = q{};
    foreach my $kid (@kids) {
        $text .= _flatten($kid);
    }
    return $text;
}

# What a heading assigns its call to: a variable, a reference to one, or a list of them in parentheses.
our $ASSIGNEE = qr/(?:(?:my|our)\s+)? (?:\\?[\$@%]\w+ | \([^()]*\))/;
our $ASSIGNED = qr/\A $ASSIGNEE \s* =(?![=>~]) \s*/;

sub _heading {
    my ( $self, $text, $line ) = @_;
    $text =~ s/[;#]//g;
    $text =~ s/\A\s+|\s+\z//g;

    my ( %args, %strength, @functions );
    foreach my $named ( $self->_named_by($text) ) {
        my $function = $named->{name};
        push @functions, $function if !$strength{$function};
        $args{$function} = [ grep { $_ ne q{} } map { s/\A\s+|\s+\z//gr =~ s/\A(\w+)\s*=>.*\z/$1/r } split m/,/, $named->{args} ] if defined $named->{args};
        my $strength = $named->{call} ? 2 : 1;
        $strength{$function} = $strength if ( $strength{$function} // 0 ) < $strength;
    }
    return if !@functions;

    return {
        heading      => $text,
        line         => $line,
        assigns      => $text =~ $ASSIGNED ? 1 : 0,
        functions    => \@functions,
        args         => \%args,
        strength     => \%strength,
        types        => {},
        returns      => [],
        terminations => [],
        verbatim     => [],
    };
}

# What may follow the last call or name of a heading: what it returns, after an =, or a description after a dash.
our $DASH         = qr/[-\N{EM DASH}]-?/;
our $HEADING_TAIL = qr/\s*=(?![=>~]).*\z | \s+$DASH\s.*\z/;

# One call or name in a heading: an optional invocant, an object or a class, or package,
# then the name of the sub, then an optional argument list.
our $INVOCANT     = qr/(?:\$\w+ | \w+(?:::\w+)*) \s*->\s*/;
our $CALL_ARGS    = qr/\s*\((?<args>[^()]*)\)/;
our $HEADING_ITEM = qr/(?<invocant>$INVOCANT)? (?<package>(?:\w+::)+)? (?<name>\w+) $CALL_ARGS?/;

# The subs that the heading TEXT names, each a HASHREF with C<name>, C<args>, the text of its argument list or undef,
# and C<call>, true when the heading writes it as a call rather than as a bare name, in the forms that DESCRIPTION lists.
sub _named_by {
    my ( $self, $text ) = @_;
    $text =~ s/$ASSIGNED//;
    my ( @items, $spaced );
    while (1) {
        $text =~ m/\G$HEADING_ITEM/gc or return;
        push @items, { name => $+{name}, args => $+{args}, call => ( defined $+{invocant} || defined $+{package} || defined $+{args} ) ? 1 : 0 };
        last if pos($text) == length $text || $text =~ m/\G$HEADING_TAIL/gc;
        next if $text                               =~ m/\G\s*,\s*/gc;
        $text =~ m/\G\s+/gc or return;
        $spaced = 1;
    }
    my $subs = $self->{subs};
    return @items if !$spaced || !$subs;
    my $has_call  = any  { $_->{call} } @items;
    my $all_known = !any { !$subs->{ $_->{name} } } @items;
    return if !$has_call && !$all_known;
    return grep { $_->{call} || $subs->{ $_->{name} } } @items;
}

sub _content {
    my ( $self, $section, $node ) = @_;
    my $type = $node->[0];
    my $line = $node->[1]{start_line};

    if ( $type =~ m/\Aover-/ ) {
        my ( undef, undef, @kids ) = @$node;
        foreach my $kid ( grep { ref } @kids ) {
            $self->_content( $section, $kid );
        }
        return;
    }
    my $text = _flatten($node);
    if ( $type eq 'Verbatim' ) {
        push @{ $section->{verbatim} }, $text;
        return;
    }
    if ( $type =~ m/\Aitem-/ ) {
        $self->_item( $section, $text, $line );
    }
    elsif ( $text =~ m/\A\s*returns?\b\s*(.*)/i ) {
        push @{ $section->{returns} }, { %{ _returned($1) }, text => $text, line => $line };
    }
    push @{ $section->{terminations} }, $text if $text =~ $TERMINATION;
    return;
}

## use critic

sub _item {
    my ( $self, $section, $text, $line ) = @_;
    my ( $name, $rest ) = $text =~ m/\A\s*(\S+?)[:,]?(?:\s+(.*))?\z/;
    return if !defined $name;
    $rest //= q{};

    if ( lc $name eq 'returns' || lc $name eq 'return' ) {
        $rest =~ s/\A[-:\s]+//;
        push @{ $section->{returns} }, { %{ _returned($rest) }, text => $text, line => $line };
        return;
    }

    my $word = q{};
    if    ( $rest =~ m/\A\((.*?)\)/ )                       { $word = $1 }
    elsif ( $rest =~ m/\A[-:\s]*(.*?)\s*(?:\s-\s|:\s|\z)/ ) { $word = $1 }
    $word =~ s/\A\s+|\s+\z//g;
    my $type       = type_named($word);
    my $documented = { word => $type ? lc $word : q{}, type => $type, sigil => $name =~ m/\A([@%])/ ? $1 : undef };

    my $bare = _bare($name);
    foreach my $function ( @{ $section->{functions} } ) {
        my @args = map { _bare($_) } @{ $section->{args}{$function} || [] };
        next if !any { $_ eq $bare } @args;
        $section->{types}{$function}{$bare} = $documented;
    }
    return;
}

# C<name> without its sigils and backslashes, in lower case, as arguments in the POD and parameters in the code are compared.
# @param   name  Str  an argument or a parameter, such as C<\%Options>
# @returns Str  the bare name
# @example my $bare = Pod::Coverage::More::Documentation->bare_name('\%Options');
sub bare_name {
    my ( $class, $name ) = @_;
    return _bare($name);
}

sub _bare {
    my ($name) = @_;
    $name =~ tr/$*\\@%&|//d;
    return lc $name;
}

our %LITERAL_TYPES = ( undef => Undef, true => Bool, false => Bool, boolean => Bool, 'a boolean' => Bool );

# The types that the words after "Returns" name, and whether they say that it returns nothing.
sub _returned {
    my ($rest) = @_;
    my @types;
    while (1) {
        $rest =~ s/\A\s*(?:an?|the)\s+(?=\S)//i;
        return { types => [], nothing => 1 } if !@types && $rest =~ m/\A\s*(?:nothing|no\s+value|an?\s+empty\s+list)\b/i;
        my $type = _type_at_start( \$rest ) or last;
        push @types, $type;
        last if $rest !~ s/\A\s*(?:,\s*)?(?:or\b|\|)\s*//i;
    }
    return { types => \@types, nothing => 0 };
}

sub _type_at_start {
    my ($rest) = @_;
    if ( $$rest =~ s/\A\s*(?:an?\s+)?instance\s+of\s+(?:class\s+)?$CLASS_NAME//i ) {
        return InstanceOf [$1];
    }
    if ( $$rest =~ s/\A\s*(?:new\s+)?$CLASS_OBJECT//i ) {
        return InstanceOf [$1];
    }
    my $literals = join q{|}, map { s/[ ]/\\s+/gr } sort keys %LITERAL_TYPES;
    if ( $$rest =~ s/\A\s*($literals)\b//i ) {
        return $LITERAL_TYPES{ lc( $1 =~ s/\s+/ /gr ) };
    }
    return Int if $$rest =~ s/\A\s*-?\d+(?!\.\d)\b//;
    return Str if $$rest =~ s/\A\s*(?:'[^']*'|"[^"]*")//;

    my ($word) = $$rest =~ m/\A\s*($TYPE_NAME $TYPE_PARAMS?)/;
    return if !defined $word;
    my $type = type_named($word) or return;
    $$rest =~ s/\A\s*\Q$word\E//;
    return $type;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Pod::Coverage::More::Documentation - What the POD of a module says about each of its subs

=head1 VERSION

version 0.005

=head1 SYNOPSIS

    use Pod::Coverage::More::Documentation;

    my $doc     = Pod::Coverage::More::Documentation->new( subs => [qw{new parse_file section_for}] );
    $doc->parse_file( $INC{'Pod/Coverage/More/Documentation.pm'} );
    my $section = $doc->section_for('parse_file');

=head1 DESCRIPTION

Reads the POD of a module into one section per heading that documents subs.
A heading documents subs when it is a C<=head2>, C<=head3> or C<=head4>, or a C<=method>, C<=func> or C<=attr> of L<Pod::Weaver>.
It names one or more subs, each with an optional argument list in parentheses,
called on an object or a class or qualified by its package, and maybe assigned to a variable.
A C<< key => value >> pair in an argument list names the argument C<key>, a key of a hash of named arguments:

    =head2 fun1(arg0, arg1), fun2(arg2)
    =head2 snapshot($domain, leave_down => $bool)
    =head2 wsSep wsSep2(whee, zap)
    =head2 $obj->some_method(arr)
    =head2 @names = $obj->first(), $obj->second($x)
    =head2 \%plan = Some::Class->plan(%args)
    =method Some::Module::fully_qualified($x)

A heading that assigns its call still names its sub, but L<Pod::Coverage::More> takes it for an example, which belongs in a verbatim block.

A heading names subs in one of three forms: a single call or name,
a list of calls and names separated by commas,
or a list separated by spaces that has a call in it or that names only subs of the package.
Any other heading, such as C<=head2 The token cache>, names no sub, although one of its words is the name of a sub.
When several headings name a sub, C<section_for> prefers a call to a bare name.

A section lasts until the next heading of the same level or a higher one.
When C<new> was given the names of the subs of the package, a heading that names none of them is not a section of its own,
and a deeper one, such as C<=head3 CAVEAT>, stays part of the section above it.

Within a section, an C<=item> documents an argument: its first word is the name of the argument, and the segment after it,
up to the next C<-> or C<:>, or in parentheses, is its type, a type word or a type expression that C<type_named> of
L<Pod::Coverage::More::Types> reads:

    =item count - INTEGER - how many
    =item B<input> (ArrayRef[Str]) - the lines

An item whose name has the sigil C<@> or C<%> documents a list parameter, and its type is the type of each element,
or of each value of the hash:

    =item @paths - Str - each path to look for

A paragraph that starts with C<Returns>, or an C<=item Returns>, documents the return value:

    Returns HashRef[Str] or undef when the file is empty.
    Returns a Foo object.
    Returns nothing.

=head1 SECTIONS

C<section_for> returns a HASHREF with these keys:

=over 4

=item B<heading> - STRING - the text of the heading, without formatting codes

=item B<line> - INTEGER - the line of the heading

=item B<functions> - ARRAYREF - the names of the subs that the heading names

=item B<assigns> - BOOLEAN - true when the heading assigns its call to a variable, as C<$paths = $obj-E<gt>paths()>

=item B<strength> - HASHREF - per sub, 2 when the heading writes it as a call, 1 when it writes only its bare name

=item B<args> - HASHREF - per sub, the ARRAYREF of the argument names in its argument list, for a sub that has one

=item B<types> - HASHREF - per sub, a HASHREF from the lower case name of an argument without sigils to its documented type:
a HASHREF with C<word>, the lower case text of the type, and C<type>, its L<Type::Tiny> constraint or undef,
or a C<word> of the empty string for an item with no type, and C<sigil>, the C<@> or C<%> that the item wrote before the name, or undef

=item B<returns> - ARRAYREF - one HASHREF per statement of the return value, with C<types>, an ARRAYREF of L<Type::Tiny> constraints,
C<nothing>, true for "Returns nothing", C<text> and C<line>

=item B<terminations> - ARRAYREF - the paragraphs that say how the sub dies, croaks, throws or exits

=item B<verbatim> - ARRAYREF - the verbatim paragraphs

=back

=head1 METHODS

=head2 bare_name(name)

C<name> without its sigils and backslashes, in lower case, as arguments in the POD and parameters in the code are compared.

=over 4

=item name - Str - an argument or a parameter, such as C<\%Options>

=back

Returns Str, the bare name.

    my $bare = Pod::Coverage::More::Documentation->bare_name('\%Options');

=head2 identifiers

The names of all the subs that the headings name, which L<Pod::Coverage> counts as documented.

Returns the names, as a list.

    my @documented = $doc->identifiers;

=head2 new(subs)

A reader of POD.

=over 4

=item subs - ArrayRef[Str] - optional: the names of the subs of the package, which tell the headings that document subs from the others

=back

Returns a Pod::Coverage::More::Documentation object, the reader.

    my $doc = Pod::Coverage::More::Documentation->new( subs => [ 'resize', 'crop' ] );

=head2 parse_file(file)

Reads the POD of C<file>.

=over 4

=item file - Str - the path of the file

=back

Returns a Pod::Coverage::More::Documentation object, the reader.

    my $doc = Pod::Coverage::More::Documentation->new->parse_file('lib/Some/Module.pm');

=head2 parse_string(pod)

Reads the POD in the string C<pod>.

=over 4

=item pod - Str - the POD

=back

Returns a Pod::Coverage::More::Documentation object, the reader.

    my $doc = Pod::Coverage::More::Documentation->new->parse_string($pod);

=head2 section_for(name)

The section whose heading names the sub C<name>, or nothing. A heading that writes it as a call, as C<name(...)>, C<< $obj->name >> or C<Pkg::name>, comes before one that writes only its bare name, then a shallower heading before a deeper one, then the first in the POD.

=over 4

=item name - Str - the name of the sub

=back

Returns HashRef, the section.

    my $section = $doc->section_for('resize');

=head2 sections

The sections, in the order of the POD, as SECTIONS describes them.

Returns the sections, as a list of HASHREFs.

    my @headings = map { $_->{heading} } $doc->sections;

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<Pod::Coverage::More|Pod::Coverage::More>

=item *

L<Pod::Simple::SimpleTree>

=item *

L<Pod::Coverage::More>

=back

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/teodesian/Pod-Coverage-More/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHORS

Current Maintainers:

=over 4

=item *

George S. Baugh <teodesian@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2026 George S. Baugh


Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:
The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

=cut
