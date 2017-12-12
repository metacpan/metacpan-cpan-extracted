use strict;
use utf8;

use Test::More;

BEGIN{ 
    BAIL_OUT
        "A bug in Perl 5.20 regex compilation prevents the use of PPR under that release"
        if $] > 5.020 && $] < 5.022;
    plan skip_all => "Perl 5.16 or later required for Acme::LookOfDisapproval"
        if $] < 5.016;
    plan skip_all => "Acme::LookOfDisapproval not installed"
        if !eval { require Acme::LookOfDisapproval };
}

plan tests => 2;

use PPR;
use Acme::LookOfDisapproval;

local $SIG{__WARN__} = sub {
    like shift, qr{ಠ_ಠ} => "Got the look of disapproval!";
};

ಠ_ಠ 'ಠ_ಠ';


open my $own_file, '<:encoding(utf8)', $0 or die $!;
my $own_code = do { local $/; readline($own_file); };

ok $own_code =~ m{ ^ (?&PerlOWS) (?&PerlStatement) (?&PerlOWS) $  $PPR::GRAMMAR }xm
    => 'Matched code with the look of disapproval!';


done_testing();

