package t::TestProfile;
use strict;
use warnings;

sub load {
    my $class = shift;
    $class->_add_test_prof;
}

sub _add_test_prof {
    my $class = shift;

    Devel::KYTProf->add_prof(
        "t::TestPerson",
        "name",
        sub {
            my ( $orig, $self, $args ) = @_;
            return [
                '%s',
                ["name"],
                {  
                    "name" => "tarou",
                },
            ];
        }
    );
}

1;
