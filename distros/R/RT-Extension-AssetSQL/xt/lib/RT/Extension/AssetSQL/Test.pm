use strict;
use warnings;

### after: use lib qw(@RT_LIB_PATH@);
use lib qw(/opt/rt4/local/lib /opt/rt4/lib);

package RT::Extension::AssetSQL::Test;
use base 'RT::Test::Assets';

our @EXPORT = (@RT::Test::Assets::EXPORT, 'assetsql');

sub import {
    my $class = shift;
    my %args  = @_;

    $args{'requires'} ||= [];
    if ( $args{'testing'} ) {
        unshift @{ $args{'requires'} }, 'RT::Extension::AssetSQL';
    } else {
        $args{'testing'} = 'RT::Extension::AssetSQL';
    }

    $class->SUPER::import( %args );

    require RT::Extension::AssetSQL;
    __PACKAGE__->export_to_level(1);
}

sub assetsql {
    local $Test::Builder::Level = $Test::Builder::Level + 1;

    my $options = shift;
    my @expected = @_;
    my $currentuser = RT->SystemUser;

    my $sql;
    if (ref($options)) {
        $sql = delete $options->{sql};
        $currentuser = delete $options->{CurrentUser} if $options->{CurrentUser};
        die "Unexpected options: " . join ', ', keys %$options if keys %$options;
    }
    else {
        $sql = $options;
    }

    my $count = scalar @expected;

    my $assets = RT::Assets->new($currentuser);
    $assets->FromSQL($sql);
    $assets->OrderBy( FIELD => 'Name', ORDER => 'ASC' );

    Test::More::is($assets->Count, $count, "number of assets from [$sql]");
    my $i = 0;
    while (my $asset = $assets->Next) {
        my $expected = shift @expected;
        if (!$expected) {
            Test::More::fail("got more assets (" . $asset->Name . ") than expected from [$sql]");
            next;
        }
        ++$i;
        Test::More::is($asset->Name, $expected->Name, "asset ($i/$count) from [$sql]");
    }
    while (my $expected = shift @expected) {
        Test::More::fail("got fewer assets than expected (" . $expected->Name . ") from [$sql]");
    }
}

1;
