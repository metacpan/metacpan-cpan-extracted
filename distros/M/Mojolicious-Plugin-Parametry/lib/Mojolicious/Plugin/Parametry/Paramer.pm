package Mojolicious::Plugin::Parametry::Paramer;

use strict;
use warnings;

our $VERSION = '1.001001'; # VERSION

sub __THIS_ISNT_THE_PARAM_YOU_SHOULD_BE_LOOKING_FOR_BLARGGRGTRKASDFHJKTRDHSYTSD
    { bless { _c => $_[1] }, $_[0] }

sub AUTOLOAD {
    ($_[0]->{_c}->param(
        $Mojolicious::Plugin::Parametry::Paramer::AUTOLOAD =~ s/.*:://r
    ) // '') =~ s/^\s+|\s+$//gr
}

1;

__END__