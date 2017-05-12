package Mo::xxx;
my $MoPKG = "Mo::";
$VERSION = '0.12';

use constant XXX_skip => 1;
my $dm = 'YAML::XS';
*{$MoPKG.'xxx::e'} = sub {
    my ($caller_pkg, $exports) = @_;
    $exports->{WWW} = sub {
        require XXX;
        local $XXX::DumpModule = $dm;
        XXX::WWW(@_);
    };
    $exports->{XXX} = sub {
        require XXX;
        local $XXX::DumpModule = $dm;
        XXX::XXX(@_);
    };
    $exports->{YYY} = sub {
        require XXX;
        local $XXX::DumpModule = $dm;
        XXX::YYY(@_);
    };
    $exports->{ZZZ} = sub {
        require XXX;
        local $XXX::DumpModule = $dm;
    };
};
