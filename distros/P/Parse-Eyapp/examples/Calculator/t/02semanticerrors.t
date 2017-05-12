use warnings;
use strict;
use Test::More tests => 3;
BEGIN { use_ok('Math::Calc') };

#########################

my $warnings = '';

local $SIG{__WARN__} = sub { $warnings .= shift };
my $input = q{
a = 2*3
c = b -1 # error: b is undef
};
my $parser = Math::Calc->new();
$parser->input(\$input);
my %s = %{$parser->Run()};

like($warnings, qr{Accesing undefined variable b at line 3\.}, 'undefined variable');

$warnings = '';
$input = q{
a = 2*3
d = a-6
f = a/d  # error: division by zero
};
$parser->input(\$input);
$parser->Run();
like($warnings, qr{Illegal division by zero at line 4\.}, 'division by zero');

