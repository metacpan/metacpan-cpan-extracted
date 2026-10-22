#!/usr/bin/env perl

use 5.014;

use strict;
use warnings FATAL => 'all';

use re '/aa';

=head1 NAME

t/Perl-Critic-Policy-ProhibitMisplacedMethods.t - which subs it calls
misplaced, which it does not, and where it says they go

=head1 DESCRIPTION

Every case is a small distribution written to a temporary directory, because
the question this policy answers is about a distribution rather than a file.
Each one gets a directory of its own, and so an index of its own.

The second list in each subtest matters as much as the first.  A policy that
reports a hook, which is where a hook belongs, gets switched off.

=cut

use Test::More;
use Test::NoWarnings;
use File::Temp     qw{tempdir};
use File::Path     qw{make_path};
use File::Basename qw{dirname};

use FindBin::libs;

use Perl::Critic ();

use_ok('Perl::Critic::Policy::ProhibitMisplacedMethods');

# What the collector keeps on disk goes somewhere of its own, never into the
# cache of whoever runs the tests.
local $ENV{XDG_CACHE_HOME} = tempdir( CLEANUP => 1 );

# -profile => q{} so Perl::Critic does not find this dist's own .perlcriticrc
# and run every policy in it against the fixtures.
sub critic {
    my ($profile) = @_;
    return Perl::Critic->new(
        -profile         => $profile // q{},
        '-single-policy' => 'ProhibitMisplacedMethods',
        -severity        => 1,
    );
}

# A fresh distribution with these files in it, and a dist.ini to be found as
# the root.
sub dist {
    my (%files) = @_;

    my $root = tempdir( CLEANUP => 1 );
    %files = ( 'dist.ini' => "name = Fixture\n", %files );
    foreach my $name ( keys %files ) {
        make_path( dirname("$root/$name") );
        open( my $fh, '>', "$root/$name" ) or die "$root/$name: $!";
        print {$fh} $files{$name};
        close($fh) or die "$root/$name: $!";
    }
    return $root;
}

sub found {
    my ( $root, $file, $critic ) = @_;
    return [ map { $_->description() } ( $critic // critic() )->critique("$root/$file") ];
}

sub only_below { return "Sub $_[0] is used only by $_[1], a subclass of $_[2]" }
sub beside     { return "Sub $_[0] is also defined in $_[1], and $_[2], which they inherit from, does not define it" }

# A class in lib/, from its name, its parent and its body.
sub class_file {
    my ( $name, $parent, $body ) = @_;
    ( my $path = $name ) =~ s{::}{/}gxs;
    my $isa = defined $parent ? "use parent -norequire, '$parent';\n" : q{};
    return ( "lib/$path.pm" => "package $name;\n${isa}$body\n1;\n" );
}

subtest 'a sub that only one subclass uses goes down into it' => sub {
    my @cases = (
        [
            'one subclass calls it',
            { class_file( 'Base', undef, 'sub helper { 1 }' ), class_file( 'Base::One', 'Base', 'sub run { $_[0]->helper }' ), class_file( 'Base::Two', 'Base', 'sub run { 2 }' ) },
            [ only_below(qw{Base::helper Base::One Base}) ],
        ],
        [
            'one subclass overrides it and calls the original',
            { class_file( 'Base', undef, 'sub helper { 1 }' ), class_file( 'Base::One', 'Base', 'sub helper { $_[0]->SUPER::helper + 1 }' ), class_file( 'Base::Two', 'Base', 'sub run { 2 }' ) },
            [ only_below(qw{Base::helper Base::One Base}) ],
        ],
        [
            'two classes below one subclass use it, so it goes to that subclass',
            {
                class_file( 'Base',            undef,       'sub helper { 1 }' ),
                class_file( 'Base::Mid',       'Base',      'sub mid { 1 }' ),
                class_file( 'Base::Mid::One',  'Base::Mid', 'sub run { $_[0]->helper }' ),
                class_file( 'Base::Mid::Two',  'Base::Mid', 'sub run { $_[0]->helper }' ),
                class_file( 'Base::Elsewhere', 'Base',      'sub run { 3 }' ),
            },
            [ only_below(qw{Base::helper Base::Mid Base}) ],
        ],
        [
            'a call from a test does not count',
            {
                class_file( 'Base', undef, 'sub helper { 1 }' ), class_file( 'Base::One', 'Base', 'sub run { $_[0]->helper }' ),
                't/base.t' => "Base->helper;\n",
            },
            [ only_below(qw{Base::helper Base::One Base}) ],
        ],
    );
    foreach my $case (@cases) {
        my ( $what, $files, $want ) = @$case;
        is_deeply( found( dist(%$files), 'lib/Base.pm' ), $want, $what );
    }

    my @kept = (
        [ 'the class itself calls it, which makes it a hook', { class_file( 'Base', undef, 'sub hook { () } sub run { $_[0]->hook }' ), class_file( 'Base::One', 'Base', 'sub hook { 1 }' ) } ],
        [ 'two subclasses call it',                           { class_file( 'Base', undef, 'sub helper { 1 }' ), class_file( 'Base::One', 'Base', 'sub a { $_[0]->helper }' ), class_file( 'Base::Two', 'Base', 'sub b { $_[0]->helper }' ) } ],
        [ 'a program calls it',                               { class_file( 'Base', undef, 'sub helper { 1 }' ), class_file( 'Base::One', 'Base', 'sub a { $_[0]->helper }' ), 'bin/prog' => "#!/usr/bin/perl\nBase::One->helper;\n" } ],
        [ 'the class names it in a string',                   { class_file( 'Base', undef, q{sub helper { 1 } sub run { $_[0]->can('helper') }} ), class_file( 'Base::One', 'Base', 'sub a { $_[0]->helper }' ) } ],
        [ 'the class calls it inside a string',               { class_file( 'Base', undef, 'sub helper { 1 } sub run { "@{[ $_[0]->helper ]}" }' ), class_file( 'Base::One', 'Base', 'sub a { $_[0]->helper }' ) } ],
        [ 'the class takes a reference to it',                { class_file( 'Base', undef, 'sub helper { 1 } sub run { \\&helper }' ), class_file( 'Base::One', 'Base', 'sub a { $_[0]->helper }' ) } ],
        [ 'the class lists it in a qw{}',                     { class_file( 'Base', undef, 'sub helper { 1 } sub run { qw{helper other} }' ), class_file( 'Base::One', 'Base', 'sub a { $_[0]->helper }' ) } ],
        [ 'an unrelated class calls it',                      { class_file( 'Base', undef, 'sub helper { 1 }' ), class_file( 'Base::One', 'Base', 'sub a { $_[0]->helper }' ), class_file( 'Other', undef, 'sub b { $_[0]->helper }' ) } ],
        [ 'nothing uses it, which is another policy',         { class_file( 'Base', undef, 'sub helper { 1 }' ), class_file( 'Base::One', 'Base', 'sub a { 1 }' ) } ],
        [
            'the subclass that calls it has two parents',
            { class_file( 'Base', undef, 'sub helper { 1 }' ), class_file( 'Mixin', undef, 'sub mix { 1 }' ), 'lib/Base/One.pm' => "package Base::One;\nuse parent -norequire, 'Base', 'Mixin';\nsub a { \$_[0]->helper }\n1;\n" }
        ],
    );
    foreach my $case (@kept) {
        my ( $what, $files ) = @$case;
        my $root = dist(%$files);
        is_deeply( found( $root, 'lib/Base.pm' ), [], "not when $what" );
    }

    # The one that counts as reported is only so while it calls itself only.
    my $recursive = found( dist( class_file( 'Base', undef, 'sub helper { $_[0]->helper }' ), class_file( 'Base::One', 'Base', 'sub a { $_[0]->helper }' ) ), 'lib/Base.pm' );
    is_deeply( $recursive, [ only_below(qw{Base::helper Base::One Base}) ], 'and recursion is not a use by the class' );
};

subtest 'a sub that two subclasses define goes up into the class above them' => sub {
    my %siblings = ( class_file( 'Base', undef, 'sub new { 1 }' ), class_file( 'Base::One', 'Base', 'sub release { 1 }' ), class_file( 'Base::Two', 'Base', 'sub release { 2 }' ) );
    my $root     = dist(%siblings);
    is_deeply( found( $root, 'lib/Base/One.pm' ), [ beside(qw{Base::One::release Base::Two Base}) ], 'each definition is reported' );
    is_deeply( found( $root, 'lib/Base/Two.pm' ), [ beside(qw{Base::Two::release Base::One Base}) ], 'and names the other' );

    my $cousins = dist(
        class_file( 'Base',         undef,     q{} ),
        class_file( 'Base::A',      'Base',    q{} ),
        class_file( 'Base::B',      'Base',    q{} ),
        class_file( 'Base::A::One', 'Base::A', 'sub release { 1 }' ),
        class_file( 'Base::B::One', 'Base::B', 'sub release { 2 }' ),
        class_file( 'Base::A::Two', 'Base::A', 'sub release { 3 }' ),
    );
    is_deeply(
        found( $cousins, 'lib/Base/A/One.pm' ),
        [ beside(qw{Base::A::One::release Base::A::Two Base::A}) ],
        'the nearest class that shares one is named, with the others that share it'
    );
    is_deeply( found( $cousins, 'lib/Base/B/One.pm' ), [ beside( 'Base::B::One::release', 'Base::A::One, Base::A::Two', 'Base' ) ], 'and a cousin gets the class above both' );

    my $override = dist(
        class_file( 'Base',           undef,       'sub new { 1 }' ),
        class_file( 'Base::Mid',      'Base',      'sub release { 0 }' ),
        class_file( 'Base::Mid::One', 'Base::Mid', 'sub release { 1 }' ),
        class_file( 'Base::Two',      'Base',      'sub release { 2 }' ),
    );
    is_deeply( found( $override, 'lib/Base/Two.pm' ), [ beside(qw{Base::Two::release Base::Mid Base}) ], 'an override of the other is not another copy' );

    my @kept = (
        [ 'the class above defines it, so both override it', { class_file( 'Base', undef, 'sub release { 0 }' ), class_file( 'Base::One', 'Base', 'sub release { 1 }' ), class_file( 'Base::Two', 'Base', 'sub release { 2 }' ) } ],
        [
            'a class two levels up defines it',
            { class_file( 'Root', undef, 'sub release { 0 }' ), class_file( 'Base', 'Root', q{} ), class_file( 'Base::One', 'Base', 'sub release { 1 }' ), class_file( 'Base::Two', 'Base', 'sub release { 2 }' ) }
        ],
        [
            'a class between it and the other defines it, so it overrides that one',
            {
                class_file( 'Base',           undef,       'sub new { 1 }' ),
                class_file( 'Base::Mid',      'Base',      'sub release { 0 }' ),
                class_file( 'Base::Mid::One', 'Base::Mid', 'sub release { 1 }' ),
                class_file( 'Base::Two',      'Base',      'sub release { 2 }' ),
            }
        ],
        [ 'the class above is in another distribution', { class_file( 'Base::One', 'Some::Cpan::Base', 'sub release { 1 }' ), class_file( 'Base::Two', 'Some::Cpan::Base', 'sub release { 2 }' ) } ],
        [ 'only one subclass defines it',               { class_file( 'Base', undef, 'sub new { 1 }' ), class_file( 'Base::One', 'Base', 'sub release { 1 }' ), class_file( 'Base::Two', 'Base', 'sub other { 2 }' ) } ],
        [ 'the two share no class',                     { class_file( 'One', undef, 'sub release { 1 }' ), class_file( 'Two', undef, 'sub release { 2 }' ) } ],
        [ 'they are lexical subs',                      { class_file( 'Base', undef, 'sub new { 1 }' ), class_file( 'Base::One', 'Base', 'my sub release { 1 }' ), class_file( 'Base::Two', 'Base', 'my sub release { 2 }' ) } ],
        [ 'the other is in a test',                     { class_file( 'Base', undef, 'sub new { 1 }' ), class_file( 'Base::One', 'Base', 'sub release { 1 }' ), 't/lib/Base/Two.pm' => "package Base::Two;\nuse parent -norequire, 'Base';\nsub release { 2 }\n1;\n" } ],
        [ 'perl calls it',                              { class_file( 'Base', undef, 'sub new { 1 }' ), class_file( 'Base::One', 'Base', 'sub DESTROY { 1 }' ), class_file( 'Base::Two', 'Base', 'sub DESTROY { 2 }' ) } ],
    );
    foreach my $case (@kept) {
        my ( $what, $files ) = @$case;
        my $file = ( grep { m{\Alib/.*One[.]pm\z}xs } keys %$files )[0];
        is_deeply( found( dist(%$files), $file ), [], "not when $what" );
    }

    my $allowed = critic( \"[ProhibitMisplacedMethods]\nallow_subs = Base::One::release\n" );
    is_deeply( found( $root, 'lib/Base/One.pm', $allowed ), [],                                                'not when allow_subs names it with its package' );
    is_deeply( found( $root, 'lib/Base/Two.pm', $allowed ), [ beside(qw{Base::Two::release Base::One Base}) ], 'and only that one' );
};

subtest 'every way to name a parent is read' => sub {
    my %parent_by = (
        'use parent'      => "use parent qw{Base};\n",
        'use base'        => "use base 'Base';\n",
        'our @ISA'        => "our \@ISA = ('Base');\n",
        'push @ISA'       => "push \@ISA, 'Base';\n",
        'extends'         => "extends 'Base';\n",
        'a package block' => undef,
    );
    foreach my $how ( sort keys %parent_by ) {
        my %files = ( class_file( 'Base', undef, 'sub new { 1 }' ) );
        if ( defined $parent_by{$how} ) {
            $files{'lib/Base/One.pm'} = "package Base::One;\n$parent_by{$how}sub release { 1 }\n1;\n";
            $files{'lib/Base/Two.pm'} = "package Base::Two;\n$parent_by{$how}sub release { 2 }\n1;\n";
        }
        else {
            $files{'lib/Base/One.pm'} = "package Base::One {\n    use parent -norequire, 'Base';\n    sub release { 1 }\n}\npackage Base::Two {\n    use parent -norequire, 'Base';\n    sub release { 2 }\n}\n1;\n";
        }
        is_deeply( found( dist(%files), 'lib/Base/One.pm' )->[0], beside(qw{Base::One::release Base::Two Base}), $how );
    }
};

subtest 'only a file in bin/ or lib/ is checked' => sub {
    my $root = dist( class_file( 'Base', undef, 'sub new { 1 }' ), 't/lib/Base/One.pm' => "package Base::One;\nuse parent -norequire, 'Base';\nsub release { 1 }\n1;\n" );
    is_deeply( found( $root, 't/lib/Base/One.pm' ),                                                          [], 'a test is not' );
    is_deeply( [ map { $_->description() } critic()->critique( \"package Base;\nsub helper { 1 }\n1;\n" ) ], [], 'nor source with no file' );
};

Test::NoWarnings::had_no_warnings();

done_testing;
