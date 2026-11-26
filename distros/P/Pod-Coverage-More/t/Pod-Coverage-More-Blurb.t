#!perl

use 5.036;
use warnings FATAL => q{all};

use Test2::V1 -i;    ## no critic (ProhibitUnusedImports) -i imports every tool, which the policy cannot see
use Test2::Plugin::NoWarnings;

use Pod::Coverage::More::Blurb;

# The blurbs of the source that LINES make.
sub blurbs_of {
    my (@lines) = @_;
    return Pod::Coverage::More::Blurb->read_string( join( "\n", @lines ) . "\n" );
}

# The name of a constraint, or a dash when there is none.
sub name_of {
    my ($type) = @_;
    return defined $type ? $type->display_name : q{-};
}

subtest tags => sub {
    my $blurb = blurbs_of(
        '# Resize the image',
        '# to fit the box.',
        '#',
        '# Keeps the ratio.',
        '# @param   $width   Int  in pixels',
        '# @param   height  ArrayRef[Int] - the',
        '#     heights',
        '# @param   label   what to call it',
        '# @returns Image::Thing  the resized copy',
        '# @throws  when either size',
        '#   is not positive',
        '# @example my $small = $image->resize( 100, 50 );',
        '# @example print $small;',
        'sub resize {',
        '}',
    )->{resize};
    is( $blurb->{description},                                   [ 'Resize the image to fit the box.', 'Keeps the ratio.' ],        "the text before the first tag, in paragraphs" );
    is( [ map { $_->{name} } @{ $blurb->{params} } ],            [qw{$width height label}],                                         "each \@param, with its name as written" );
    is( [ map { name_of( $_->{type} ) } @{ $blurb->{params} } ], [qw{Int ArrayRef[Int] -}],                                         "a type word or expression is the type, and a plain word is no type" );
    is( [ map { $_->{description} } @{ $blurb->{params} } ],     [ 'in pixels', 'the heights', 'what to call it' ],                 "the rest is the description, continued on the lines below" );
    is( name_of( $blurb->{returns}{type} ),                      'InstanceOf["Image::Thing"]',                                      "a package name is an instance of the package" );
    is( $blurb->{throws},                                        ['when either size is not positive'],                              "a \@throws, continued" );
    is( $blurb->{examples},                                      [ [ 'my $small = $image->resize( 100, 50 );', 'print $small;' ] ], "consecutive \@example lines make one example" );
    is( $blurb->{line},                                          14,                                                                "the line of the sub" );
};

subtest example_indentation => sub {
    my $blurbs = blurbs_of(
        '# @example my $widget = make(',
        '# @example     size   => 3,',
        '# @example     colour => q{red},',
        '# @example );',
        'sub make {',
        '}',
        '# @example   if ($ready) {',
        '# @example       go();',
        '# @example   }',
        'sub go {',
        '}',
        '# @example my $widget = make(',
        '#     size => 3,',
        '# );',
        'sub continued {',
        '}',
    );
    is( $blurbs->{make}{examples},      [ [ 'my $widget = make(', '    size   => 3,', '    colour => q{red},', ');' ] ], "consecutive \@example lines keep their indentation relative to the first" );
    is( $blurbs->{go}{examples},        [ [ 'if ($ready) {',      '    go();',      '}' ] ],  "under the indentation of the first" );
    is( $blurbs->{continued}{examples}, [ [ 'my $widget = make(', '    size => 3,', ');' ] ], "and lines without the tag keep theirs" );
};

subtest returns_text => sub {
    my $blurbs = blurbs_of( '# @returns 443 when nothing else is set', 'sub port {', '}', '# @returns 0 on success', 'sub status {', '}' );
    is( [ map { name_of( $blurbs->{$_}{returns}{type} ) } qw{port status} ], [qw{- -}],                      "a number at the start of a \@returns names no type" );
    is( $blurbs->{port}{returns}{description},                               '443 when nothing else is set', "and starts its text" );
};

subtest where_a_blurb_is => sub {
    my $blurbs = blurbs_of(
        '# Not a blurb: a blank line follows.',
        q{},
        'sub separated { }',
        '# A blurb of a method.',
        'method kept { }',
        '=head2 in_pod',
        '',
        '# A comment inside POD.',
        'sub in_pod { }',
        '',
        '=cut',
        '',
        'sub undocumented { }',
        '# A blurb of a fun.',
        'fun keyword_sub ($x) { }',
        '__END__',
        '# After the end.',
        'sub after_end { }',
    );
    is( [ sort keys %$blurbs ], [qw{kept keyword_sub}], "only comments directly above a sub, outside POD and before __END__, are blurbs" );
};

done_testing;
