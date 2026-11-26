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

subtest call_headings => sub {
    my $doc = read_pod(
        undef,
        '=head2 Provisioner::Recipe::acmeca->issuing_authority()',
        '=head2 $paths = Some::Class->named_paths()',
        '=head2 \%plan = Trog::HV::Libvirt->guest_network_plan(%args)',
        '=head2 ($advice, $port) = $hv->vnc_access($name)',
        '=head2 @names = $hv->preflight_checks(), $hv->preflight_notes(@extra)',
    );
    is( [ map { $_->{functions} } $doc->sections ], [ ['issuing_authority'], ['named_paths'], ['guest_network_plan'], ['vnc_access'], [qw{preflight_checks preflight_notes}] ], "a method called on a class, and a call assigned to a variable, name their subs" );
    my $tails = read_pod( undef, '=head2 config($key) = HASHREF', '=head2 drag_and_drop - NOT WORKING' );
    is( [ map { $_->{functions} } $tails->sections ],    [ ['config'], ['drag_and_drop'] ], "what a call returns after an =, and a description after a dash, name no sub" );
    is( $doc->section_for('guest_network_plan')->{args}, { guest_network_plan => ['%args'] },                         "and keep their argument lists" );
    is( $doc->section_for('preflight_checks')->{args},   { preflight_checks   => [], preflight_notes => ['@extra'] }, "each call of a heading that names two keeps its own argument list" );
};

subtest assigning_headings => sub {
    my $doc = read_pod( undef, '=head2 $paths = Some::Class->named_paths()', '=head2 Some::Class->plain_call($x)', '=head2 config($key) = HASHREF' );
    is( { map { $_->{functions}[0] => $_->{assigns} } $doc->sections }, { named_paths => 1, plain_call => 0, config => 0 }, "a heading that assigns its call says so, and a call alone, or what it returns after an =, does not" );
};

subtest prose_headings => sub {
    my $doc = read_pod(
        [qw{token helper args cache}],
        '=head1 DESCRIPTION',
        '=head2 The token cache',
        'Returns nothing, being prose.',
        '=head2 Why there is a bridge helper at all',
        '=head2 Configuration',
        '=head3 args',
        'The options.',
        '=head1 METHODS',
        '=head2 token',
        'Returns Str.',
        '=head2 $recipe->args()',
        'Returns HashRef.',
        '=head2 cache, helper',
        'Returns Int.',
    );
    is( $doc->section_for('token')->{heading},  'token',           "a heading of prose names no sub by one of its words" );
    is( $doc->section_for('helper')->{heading}, 'cache, helper',   "nor by its last word" );
    is( $doc->section_for('args')->{heading},   '$recipe->args()', "a call names its sub before a heading that is only the bare name" );
    my $levels = read_pod( [qw{args}], '=head2 Configuration', '=head3 args', 'The options.', '=head2 args', 'Returns HashRef.' );
    is( $levels->section_for('args')->{line}, 7, "and of two bare names, the shallower heading names the sub" );
};

subtest named_argument_headings => sub {
    my $doc = read_pod( undef, '=head2 account_for($domain, \%conf, above => $bool)', '=head2 put($file, ref => $ref, overwrite => 1)' );
    is( $doc->section_for('account_for')->{args}{account_for}, [ '$domain', '\%conf', 'above' ], "a key => value pair in a heading names the argument by its key" );
    is( $doc->section_for('put')->{args}{put}, [ q{$file}, qw{ref overwrite} ], "whatever its value" );
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
