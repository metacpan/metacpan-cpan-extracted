#line 1
##
# name:      Module::Install::AckXXX
# abstract:  Warn Author About XXX.pm
# author:    Ingy döt Net <ingy@cpan.org>
# license:   perl
# copyright: 2010, 2011

package Module::Install::AckXXX;
use 5.008003;
use strict;
use warnings;

my $requires = "
use App::Ack 1.94 ();
use Capture::Tiny 0.10 ();
";

use base 'Module::Install::Base';
our $VERSION = '0.16';
our $AUTHOR_ONLY = 1;

sub ack_xxx {
    my $self = shift;
    return unless $self->is_admin;

    require Capture::Tiny;
    sub ack { system "ack -G '\\.(pm|t|PL)\$' '^\\s*use XXX\\b'"; }
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

