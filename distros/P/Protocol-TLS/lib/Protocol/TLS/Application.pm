package Protocol::TLS::Application;
use strict;
use warnings;
use Carp;
use Protocol::TLS::Trace qw(tracer);
use Protocol::TLS::Constants qw(const_name :versions :alert_desc :c_types);

sub decode {
    my $ctx = shift;
    $ctx->state_machine( 'recv', CTYPE_APPLICATION_DATA );
    return $ctx->application_data(@_);
}

sub encode {
    $_[1];
}

1
