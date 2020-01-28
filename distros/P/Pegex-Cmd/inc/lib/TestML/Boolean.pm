# Copied/modified from boolean.pm
use strict; use warnings;
package TestML::Boolean;
our $VERSION = '0.46';

my ($true, $false);

use overload
    '""' => sub { ${$_[0]} },
    '!' => sub { ${$_[0]} ? $false : $true },
    fallback => 1;

use base 'Exporter';
@TestML::Boolean::EXPORT = qw(true false isTrue isFalse isBoolean);

my ($true_val, $false_val, $bool_vals);

BEGIN {
    my $t = 1;
    my $f = 0;
    $true  = do {bless \$t, 'TestML::Boolean'};
    $false = do {bless \$f, 'TestML::Boolean'};

    $true_val  = overload::StrVal($true);
    $false_val = overload::StrVal($false);
    $bool_vals = {$true_val => 1, $false_val => 1};
}

# refaddrs change on thread spawn, so CLONE fixes them up
sub CLONE {
    $true_val  = overload::StrVal($true);
    $false_val = overload::StrVal($false);
    $bool_vals = {$true_val => 1, $false_val => 1};
}

sub true()  { $true }
sub false() { $false }
sub isTrue($)  {
    not(defined $_[0]) ? false :
    (overload::StrVal($_[0]) eq $true_val)  ? true : false;
}
sub isFalse($) {
    not(defined $_[0]) ? false :
    (overload::StrVal($_[0]) eq $false_val) ? true : false;
}
sub isBoolean($) {
    not(defined $_[0]) ? false :
    (exists $bool_vals->{overload::StrVal($_[0])}) ? true : false;
}

1;
