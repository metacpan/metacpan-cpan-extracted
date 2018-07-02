use Test::Most;

use OpenOffice::OODoc::HeadingStyles;

use Test::MockObject;

subtest "Default Heading Styles" => sub {

    my $mocked_styles = _mock_obj__styles(
        {
            styles => {
                'Heading_20_1' => "One",
                'Heading_20_2' => "Two"
            }
        }
    );

    ok $mocked_styles->establishHeadingStyle( 1 ) eq "One" ,
        "get heading from already exisitng style";

    ok $mocked_styles->establishHeadingStyle( 2, "Nope" ) ne "Nope",
        "does not return something else when there is already an existing style";

    ok $mocked_styles->establishHeadingStyle( 3, "Three" ) eq "Three",
        "does return a custom style if it did not exist";

    cmp_deeply(
        $mocked_styles->{styles} => {
            Heading_20_1 => "One",
            Heading_20_2 => "Two",   # not "Nope"
            Heading_20_3 => "Three", # did create
        },
        "did not messup exisitng styles, but created a custom style"
    );
};

done_testing();

# _mock_obj__styles
#
# creates a mocked object that handles:
# - OpenOffice::OODoc::HeadingStyles::establishHeadingStyle
# - createHeadingStyle
# - getStyleElement
#
# accepts a hash with predefined styles, 'truthness' of the value is sufficient
#
sub _mock_obj__styles {
    my $mock_obj = Test::MockObject->new( shift );
    $mock_obj->mock(
        'establishHeadingStyle' =>
            \&OpenOffice::OODoc::HeadingStyles::establishHeadingStyle
    );
    $mock_obj->mock(
        'createHeadingStyle' => sub {
            my $self             = shift;
            my $level            = shift;
            my $style_definition = shift;
            my $style_name       = "Heading_20_$level";
            $self->{styles}{$style_name} = $style_definition;
            return $self->getStyleElement($style_name)
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
