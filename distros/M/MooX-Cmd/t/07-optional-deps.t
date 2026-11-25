#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

# hide the recommended dependencies, whether they are installed or not
my @hidden = qw(Text/Abbrev.pm MooX/ConfigFromFile.pm MooX/ConfigFromFile/Role.pm);
unshift @INC, sub {
    my (undef, $file) = @_;
    grep { $_ eq $file } @hidden and die "Can't locate $file in \@INC (hidden by test)\n";
    return;
};

require Moo;
require MooX::Cmd;

eval { require MooX::Cmd::Role::AbbrevCmds; 1 } or diag($@);
ok(!$INC{'Text/Abbrev.pm'}, "AbbrevCmds does not load Text::Abbrev at compile time");

eval q{
    package PlainApp;
    use Moo;
    sub execute { 1 }
    use MooX::Cmd;
    1;
} or diag($@);
my $app = eval { PlainApp->new_with_cmd };
ok($app,                                 "app without optional roles works without the recommended modules") or diag($@);
ok(!$INC{'Text/Abbrev.pm'},              "app without AbbrevCmds does not load Text::Abbrev");
ok(!$INC{'MooX/ConfigFromFile/Role.pm'}, "app without ConfigFromFile does not load MooX::ConfigFromFile::Role");

eval q{
    package AbbrevMissingApp;
    use Moo;
    sub execute { 1 }
    use MooX::Cmd with_abbrev_cmds => 1;
    1;
} or diag($@);
$app = eval { AbbrevMissingApp->new_with_cmd };
like($@, qr/AbbrevCmds requires Text::Abbrev/, "with_abbrev_cmds names the missing Text::Abbrev on use");

my $ok = eval q{
    package ConfigMissingApp;
    use Moo;
    sub execute { 1 }
    use MooX::Cmd with_config_from_file => 1;
    1;
};
ok(!$ok, "with_config_from_file without MooX::ConfigFromFile fails on import");
like($@, qr/with_config_from_file requires MooX::ConfigFromFile/, "the error names the missing MooX::ConfigFromFile");

done_testing;
