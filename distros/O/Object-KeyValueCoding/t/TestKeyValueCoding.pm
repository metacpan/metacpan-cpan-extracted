package TestKeyValueCoding;

use strict;

use base qw(
    Test::Class
);

use Test::More;
use Test::Exception;
use Data::Dumper;
use Object::KeyValueCoding cache_keys => 1, implementation => "Complex";

sub test_names : Test(42) {
    my ($self) = @_;

    my $NAME_MAP = {
        'LIKE_THIS'        => [qw(like this)],
        'like_this'        => [qw(like this)],
        'likeThis'         => [qw(like this)],
        'LikeThis'         => [qw(like this)],
        '_LIKE_THIS'       => [qw(like this)],
        '__likeThis'       => [qw(like this)],
        'LIKEThis'         => [qw(LIKE this)],
        'LikeThisLikeThat' => [qw(like this like that)],
        'LIKEThisLIKEThat' => [qw(LIKE this LIKE that)],
        '_a'               => [qw(a)],
    };

    foreach my $key (keys %$NAME_MAP) {
        my $value = Object::KeyValueCoding::Key->new( $key );
        is_deeply($NAME_MAP->{$key}, $value->{parts}, "normalised $key");
    }

    my $name = Object::KeyValueCoding::Key->new( "LikeThisLikeThat" );
    ok( $name->asCamelCase()   eq "likeThisLikeThat", "camel case" );
    ok( $name->asTitleCase()   eq "LikeThisLikeThat", "title case" );
    ok( $name->asUnderscorey() eq "like_this_like_that", "underscorey" );
    ok( $name->asConstant()    eq "LIKE_THIS_LIKE_THAT", "constant format" );

    $name = Object::KeyValueCoding::Key->new( "LIKEThisLIKEThat" );
    ok( $name->asCamelCase()   eq "LIKEThisLIKEThat", "camel case" );
    ok( $name->asTitleCase()   eq "LIKEThisLIKEThat", "title case" );
    ok( $name->asUnderscorey() eq "LIKE_this_LIKE_that", "underscorey" );
    ok( $name->asConstant()    eq "LIKE_THIS_LIKE_THAT", "constant format" );
    ok( $name->asCamelCaseProperty()   eq "LIKEThisLIKEThat", "camel case property" );
    ok( $name->asTitleCaseProperty()   eq "LIKEThisLIKEThat", "title case property" );
    ok( $name->asUnderscoreyProperty() eq "LIKE_this_LIKE_that", "underscorey property" );
    ok( $name->asConstantProperty()    eq "LIKE_THIS_LIKE_THAT", "constant format property" );
    ok( $name->asCamelCaseSetter()   eq "setLIKEThisLIKEThat", "camel case setter" );
    ok( $name->asTitleCaseSetter()   eq "setLIKEThisLIKEThat", "title case setter" );
    ok( $name->asUnderscoreySetter() eq "set_LIKE_this_LIKE_that", "underscorey setter" );
    ok( $name->asConstantSetter()    eq "set_LIKE_THIS_LIKE_THAT", "constant format setter" );

    $name = Object::KeyValueCoding::Key->new( "__LIKEThis" );
    ok( $name->asCamelCaseProperty()   eq "__LIKEThis", "camel case property" );
    ok( $name->asTitleCaseProperty()   eq "__LIKEThis", "title case property" );
    ok( $name->asUnderscoreyProperty() eq "__LIKE_this", "underscorey property" );
    ok( $name->asConstantProperty()    eq "__LIKE_THIS", "constant format property" );
    ok( $name->asCamelCaseSetter()   eq "__setLIKEThis", "camel case setter" );
    ok( $name->asTitleCaseSetter()   eq "__setLIKEThis", "title case setter" );
    ok( $name->asUnderscoreySetter() eq "__set_LIKE_this", "underscorey setter" );
    ok( $name->asConstantSetter()    eq "__set_LIKE_THIS", "constant format setter" );

    $name = Object::KeyValueCoding::Key->new( "__LIKE_THIS__" );
    ok( $name->asCamelCaseProperty()   eq "__likeThis__", "camel case property" );
    ok( $name->asTitleCaseProperty()   eq "__LikeThis__", "title case property" );
    ok( $name->asUnderscoreyProperty() eq "__like_this__", "underscorey property" );
    ok( $name->asConstantProperty()    eq "__LIKE_THIS__", "constant format property" );
    ok( $name->asCamelCaseSetter()   eq "__setLikeThis__", "camel case setter" );
    ok( $name->asTitleCaseSetter()   eq "__setLikeThis__", "title case setter" );
    ok( $name->asUnderscoreySetter() eq "__set_like_this__", "underscorey setter" );
    ok( $name->asConstantSetter()    eq "__set_LIKE_THIS__", "constant format setter" );
}

my $keyPathToElementArrayMap = {
    # Commented out b/c whitespace is not stripped at the moment
    #' abc.def.ghi ' => [qw(abc def ghi)], # test stripping of whitespace
    'xyz.bbc.xyz' => [qw(xyz bbc xyz)],
    'nnn'  => [qw(nnn)],
    'ooo.' => [qw(ooo)],  # hmm, this one passes
};

my $keyPathsWithArguments = {
    q(abc.def("Arg With Spaces").yyy) => [{key => 'abc'},
                                         {key => 'def', arguments => [q("Arg With Spaces")]},
                                         {key => 'yyy'}, ],
};

sub test_parsing : Test(no_plan) {
    my ($self) = @_;
    foreach my $keyPath (keys %{$keyPathToElementArrayMap}) {
        my $reference = $keyPathToElementArrayMap->{$keyPath};
        my $test = Object::KeyValueCoding::keyPathElementsForPath($keyPath);
        ok(scalar @$reference == scalar @$test, "$keyPath has correct element count");
        foreach my $i (0..scalar @$reference -1) {
            ok ($reference->[$i] eq $test->[$i]->{key}, "element matches: ".$reference->[$i]." == ".$test->[$i]->{key});
        }
    }

    foreach my $keyPath (keys %{$keyPathsWithArguments}) {
        my $reference = $keyPathsWithArguments->{$keyPath};
        my $test = Object::KeyValueCoding::keyPathElementsForPath($keyPath);
        ok(scalar @$reference == scalar @$test, "$keyPath has correct element count");
        foreach my $i (0..scalar @$reference -1) {
            ok ($reference->[$i]->{key} eq $test->[$i]->{key}, "element matches: ".$reference->[$i]->{key}." == ".$test->[$i]->{key});
            ok (defined $reference->[$i]->{arguments} == defined $test->[$i]->{arguments}, "Both either do or don't have arguments");
            if (defined $reference->[$i]->{arguments}) {
                ok (scalar @{$reference->[$i]->{arguments}} == scalar @{$test->[$i]->{arguments}}, "element has correct argument count");
                my $refArgs = $reference->[$i]->{arguments};
                my $testArgs = $test->[$i]->{arguments};
                for my $j (0..scalar @$refArgs -1) {
                    ok($refArgs->[$j] eq $testArgs->[$j], "arg $j matches: ".$refArgs->[$j]." eq ".$testArgs->[$j]);
                }
            }
        }
    }

    #my $root = _Test::Entity::Root->new();
    #$root->setTitle("Banana");
    #ok($root->stringWithEvaluatedKeyPathsInLanguage('Title: ${title}') eq "Title: Banana", "key paths in interpolated string work");
}


1;