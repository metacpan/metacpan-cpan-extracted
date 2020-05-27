use Test::Most;

use OpenOffice::OODoc::HeadingStyles;

use Test::MockObject;

subtest "Default Heading Styles" => sub {

    my $mocked_styles = _mock_obj__styles( { styles => {} } );

    $mocked_styles->createHeadingStyle($_) for 1 .. 6;

    cmp_deeply(
        $mocked_styles->{styles} => {
                'Heading_20_1' => ignore(),
                'Heading_20_2' => ignore(),
                'Heading_20_3' => ignore(),
                'Heading_20_4' => ignore(),
                'Heading_20_5' => ignore(),
                'Heading_20_6' => ignore(),
        },
        "Created 6 default heading styles"
    );

    cmp_deeply(
        $mocked_styles->{styles}{'Heading_20_6'} => {
            'class'                 => "text",
            'display-name'          => "Heading 6",
            'family'                => "paragraph",
            'next'                  => "Text_20_body",
            'parent'                => "Heading",

            'paragraph'             => {
                'fo:margin-bottom'      => "0.0417in",
                'fo:margin-top'         => "0.0417in",
            },

            'text'                  => {
                'fo:font-size'          => "85%",
                'fo:font-style'         => "italic",
                'fo:font-weight'        => "bold",
            },
        },
        "Created 'Heading 6' with the right settings"
    );

};

subtest "Custom Heading" => sub {

    my $mocked_styles = _mock_obj__styles( { styles => {} } );



    my @warnings;
    $SIG{__WARN__} = sub { push(@warnings, @_) };

    $mocked_styles->createHeadingStyle(
        9.99 => { # yup, decimal number here
            paragraph => {
                top        => '9.9999in',
                bottom     => '9.9999mm',
            },
            text      => {
                size       => 'huge',
                weight     => 'super-heavy',
                style      => 'strike-through',
                family     => 'fantasy',
                name       => 'Noteworthy',
                font_style => 'Condensed',
            },
        }
    );

    cmp_deeply(
        $mocked_styles->{styles} => {
                'Heading_20_9' => ignore(),
        },
        "Created style '9', using whole number only"
    );

    is(@warnings, 1, ".. and emits warnings as expected");
    like(
        $warnings[0],
        qr/^Changed level '9.99' to '9' at/,
        ".. with the correct message"
    );

    cmp_deeply(
        $mocked_styles->{styles}{'Heading_20_9'} => {
            'class'                 => "text",
            'display-name'          => "Heading 9",
            'family'                => "paragraph",
            'next'                  => "Text_20_body",
            'parent'                => "Heading",

            'paragraph'             => {
                'fo:margin-bottom'      => "9.9999mm",
                'fo:margin-top'         => "9.9999in",
            },

            'text'                  => {
                'fo:font-family'        => "fantasy",
                'fo:font-size'          => "huge",
                'fo:font-style'         => "strike-through",
                'fo:font-weight'        => "super-heavy",
                'style:font-name'       => "Noteworthy",
                'style:font-style-name' => "Condensed",
            },
        },
        "Created 'Heading 9' with the right settings"
    );

};

subtest "Override \$HEADING_DEFINITIONS" => sub {

    # keep a copy of the default headings
    my $HEADING_DEFINITIONS_original =
    $OpenOffice::OODoc::HeadingStyles::HEADING_DEFINITIONS;

    $OpenOffice::OODoc::HeadingStyles::HEADING_DEFINITIONS = {
        'Heading 1' => {
            text        => { font_style => 'Ultra-Thin' },
        },
    };

    my $mocked_styles = _mock_obj__styles( { styles => {} } );

    $mocked_styles->createHeadingStyle( 1 ) ;

    cmp_deeply(
        $mocked_styles->{styles}{'Heading_20_1'} => {
            'class'                 => "text",
            'display-name'          => "Heading 1",
            'family'                => "paragraph",
            'next'                  => "Text_20_body",
            'parent'                => "Heading",

            'text'                  => {
                'style:font-style-name' => "Ultra-Thin",
            },
        },
        "Created 'Heading 1' with custom settings"
    );

    # reset default headings
    $OpenOffice::OODoc::HeadingStyles::HEADING_DEFINITIONS =
        $HEADING_DEFINITIONS_original;

};

done_testing();

# _mock_obj__styles
#
# creates a mocked object that handles:
# - createHeadingStyle
#   references OpenOffice::OODoc::HeadingStyles::createHeadingStyle
# - createStyle
# - updateStyle
# - getStyleElement
#
# accepts a hash with predefined styles, 'truthness' of the value is sufficient
#
sub _mock_obj__styles {
    my $mock_obj = Test::MockObject->new( shift );
    $mock_obj->mock(
        'createHeadingStyle' =>
            \&OpenOffice::OODoc::HeadingStyles::createHeadingStyle
    );
    $mock_obj->mock(
        'createStyle' => sub {
            my $self = shift;
            my $name = shift;
            my %args = @_;
            return if exists $self->{styles}{$name};
            $self->{styles}{$name} = \%args;
        }
    );
    $mock_obj->mock(
        'updateStyle' => sub {
            my $self = shift;
            my $name = shift;
            my %args = @_;
            return unless exists $self->{styles}{$name};
            my $area = delete $args{properties}{'-area'};
            $self->{styles}{$name}{$area}{$_} = $args{properties}{$_}
                for keys %{ $args{properties} };
        }
    );
    $mock_obj->mock(
        'getStyleElement' => sub {
            my $self = shift;
            my $name = shift;
            return $self->{styles}{$name}
        }
    );
    return $mock_obj
}
