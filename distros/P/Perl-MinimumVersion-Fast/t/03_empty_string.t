use strict;
use warnings;
use utf8;
use Test::More;
use Perl::MinimumVersion::Fast;

{
    my $warn;
    $SIG{__WARN__} = sub { $warn = shift };
    my $p = Perl::MinimumVersion::Fast->new(\'');
    is($warn, undef);
};

done_testing;

