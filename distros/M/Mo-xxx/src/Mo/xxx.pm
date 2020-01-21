package Mo::xxx;
my $MoPKG = "Mo::";
$VERSION = '0.13';

use constant XXX_skip => 1;
*{$MoPKG.'xxx::e'} = sub {
    my ($caller_pkg, $exports) = @_;
    $exports->{WWW} = sub {
        require XXX;
        XXX::WWW(@_);
    };
    $exports->{XXX} = sub {
        require XXX;
        XXX::XXX(@_);
    };
    $exports->{YYY} = sub {
        require XXX;
        XXX::YYY(@_);
    };
    $exports->{ZZZ} = sub {
        require XXX;
        XXX::ZZZ(@_);
    };
};
