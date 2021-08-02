# File automatically generated from BurntSushi/toml-test
use utf8;
use Test2::V0;
use TOML::Tiny;

binmode STDIN,  ':encoding(UTF-8)';
binmode STDOUT, ':encoding(UTF-8)';

open my $fh, '<', "./t/toml-test/invalid/bool/wrong-case-false.toml" or die $!;
binmode $fh, ':raw';
my $toml = do{ local $/; <$fh>; };
close $fh;

ok dies(sub{ scalar from_toml($toml, strict => 1) }), 'strict_mode dies on bool/wrong-case-false';

done_testing;