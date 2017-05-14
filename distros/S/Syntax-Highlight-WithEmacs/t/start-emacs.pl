use strict;
use warnings;
sub test_start_emacs {
    my $emacs = shift;
    my $out;
    local $@;
    eval { run [$emacs, '--version'], \undef, \$out };
    plan skip_all => "Failed to start Emacs, cannot test module" if $@;
    $out
}
sub test_start_client {
    my $emacsclient = shift;
    my ($fail, $err);
    local $@;
    eval { my $out; run [$emacsclient, '-batch', -eval => '()'], \undef, \$out, \$err };
    $fail = $@;
    ($fail, $err)
}
1
