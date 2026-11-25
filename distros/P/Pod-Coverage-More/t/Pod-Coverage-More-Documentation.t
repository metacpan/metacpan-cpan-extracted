#!perl

use 5.036;
use warnings FATAL => q{all};

use Test2::V1 -i;    ## no critic (ProhibitUnusedImports) -i imports every tool, which the policy cannot see
use Test2::Plugin::NoWarnings;

use Pod::Coverage::More::Documentation;

# Reads POD from lines, with the =cut that every fixture here ends with.
sub read_pod {
    my ( $subs, @lines ) = @_;
    my $doc = Pod::Coverage::More::Documentation->new( $subs ? ( subs => $subs ) : () );
    return $doc->parse_string( join( "\n\n", @lines, '=cut' ) . "\n" );
}

# The return statement of a section, as text: the names of its types, or "nothing".
sub returns_of {
    my ($section) = @_;
    my @short;
    foreach my $statement ( @{ $section->{returns} } ) {
        my @names;
        foreach my $type ( @{ $statement->{types} } ) {
            push @names, $type->display_name;
        }
        push @short, $statement->{nothing} ? 'nothing' : join( ' or ', @names );
    }
    return \@short;
}

subtest headings => sub {
    my $doc = read_pod(
        undef,
        '=head2 fun1(arg0, arg1), fun2(arg2)',
        '=head2 B<formatted>, Some::Module::qualified($x)',
        '=head2 $obj->method_call(arr)',
        '=head2 spaced spaced2(a, b) spaced3',
        '=method woven(size)',
    );
    is( [ map { $_->{functions} } $doc->sections ],        [ [qw{fun1 fun2}], [qw{formatted qualified}], ['method_call'], [qw{spaced spaced2 spaced3}], ['woven'] ], "each kind of heading names its subs" );
    is( $doc->section_for('fun2')->{args},                 { fun1 => [qw{arg0 arg1}], fun2 => ['arg2'] },                                                            "each sub keeps its own argument list" );
    is( $doc->section_for('qualified')->{args}{qualified}, ['$x'],                                                                                                   "an argument keeps its sigil" );
    is( [ $doc->identifiers ],                             [qw{fun1 fun2 formatted qualified method_call spaced spaced2 spaced3 woven}],                             "the identifiers are every sub that a heading names" );
};

subtest sections => sub {
    my $doc = read_pod( [qw{first second}], '=head2 first', '=head3 Caveats', 'Returns Int.', '=head2 Return values', 'Returns Str.', '=head2 second', 'Returns Num.' );
    is( returns_of( $doc->section_for('first') ),                      ['Int'],            "a deeper heading that names no sub stays part of the section" );
    is( returns_of( $doc->section_for('second') ),                     ['Num'],            "a heading of the same level that names no sub ends the section" );
    is( [ map { $_->{heading} } $doc->sections ],                      [qw{first second}], "a heading that names no sub is no section" );
    is( scalar( read_pod( undef, '=head2 Return values' )->sections ), 1,                  "without the names of the subs, every heading is a section" );
};

subtest items => sub {
    my $doc = read_pod(
        undef,
        '=head2 typed(count, input, name, plain, list, cat, catalog, thing)',
        '=over 4',
        '=item B<count> - INTEGER - how many',
        '=item input (array) - the lines',
        '=item name - string: who',
        '=item plain - how big it is, with no type',
        '=item list - ArrayRef[Int] - the numbers',
        '=item catalog - Str',
        '=item cat - Int',
        '=item thing - InstanceOf["Foo::Bar"] - a type with colons in it',
        '=back',
    );
    my $types = $doc->section_for('typed')->{types}{typed};
    my %words = map { $_ => $types->{$_}{word} } keys %$types;
    is( \%words,                            { count => 'integer', input => 'array', name => 'string', plain => q{}, list => 'arrayref[int]', cat => 'int', catalog => 'str', thing => 'instanceof["foo::bar"]' }, "the first word names the argument, and the segment after it is the type" );
    is( $types->{list}{type}->display_name, 'ArrayRef[Int]',                                                                                                                                                      "a type expression becomes its constraint" );
    ok( !$types->{plain}{type}, "a description is no type" );
};

subtest list_items => sub {
    my $doc   = read_pod( undef, '=head2 listed(paths, opts, one)', '=over 4', '=item @paths - Str - each path', '=item %opts - Int', '=item one - Str', '=back' );
    my $types = $doc->section_for('listed')->{types}{listed};
    is( { map { $_ => $types->{$_}{sigil} } keys %$types }, { paths => '@', opts => '%', one => undef }, "an item with the sigil of a list records the sigil, for the type of each element" );
    is( $types->{paths}{word},                              'str',                                       "and the type is the type of the elements" );
};

subtest returns => sub {
    my %expected = (
        'Returns nothing.'                          => ['nothing'],
        'Returns undef.'                            => ['Undef'],
        'Returns true or false.'                    => ['Bool or Bool'],
        'Returns 1 when it worked.'                 => ['Int'],
        'Returns a Foo object.'                     => ['InstanceOf["Foo"]'],
        q{Returns an instance of class 'Bar'.}      => ['InstanceOf["Bar"]'],
        'Returns HashRef[Str] or undef when empty.' => ['HashRef[Str] or Undef'],
        'Returns MIXED: 1 or 0'                     => ['Any'],
        'Returns the output of the other function.' => [q{}],
        'Returns an analyzer object.'               => [q{}],
    );
    foreach my $text ( sort keys %expected ) {
        my $doc = read_pod( undef, '=head2 one', $text );
        is( returns_of( $doc->section_for('one') ), $expected{$text}, "'$text'" );
    }
    my $item = read_pod( undef, '=head2 one', '=over 4', '=item Returns - Str - the name', '=back' );
    is( returns_of( $item->section_for('one') ), ['Str'], "an =item Returns states the return value" );
};

subtest terminations_and_examples => sub {
    my $doc     = read_pod( undef, '=head2 one', 'Croaks when the file is missing.', 'The method is studied here.', '    my $x = one(1);' );
    my $section = $doc->section_for('one');
    is( $section->{terminations}, ['Croaks when the file is missing.'], "a paragraph that says it croaks is a termination, and a word that only contains die is not" );
    is( $section->{verbatim},     ['    my $x = one(1);'],              "verbatim paragraphs are kept" );
};

subtest bare_name => sub {
    is( Pod::Coverage::More::Documentation->bare_name('\@Items'), 'items', "sigils and backslashes go, and the case is lowered" );
};

done_testing;
