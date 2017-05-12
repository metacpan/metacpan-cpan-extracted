use strict; use warnings;
package Module::Install::AckXXX;
our $VERSION = '0.27';

use base 'Module::Install::Base';
our $AUTHOR_ONLY = 1;

sub ack_xxx {
    my $self = shift;
    return unless $self->is_admin;

    require Capture::Tiny;
    sub ack { system "find lib t Makefile.PL -type f | ack -x '^\\s*use XXX\\b(?!\\s*\\d)'"; }

    my $output = Capture::Tiny::capture_merged(\&ack);
    $self->_report($output) if $output;
}

sub _report {
    my $self = shift;
    my $output = shift;
    chomp ($output);
    print <<"...";

*** AUTHOR WARNING ***
*** Found usage of XXX.pm in this code:
$output

...
}

1;
