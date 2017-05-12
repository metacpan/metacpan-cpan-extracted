package Object::Pluggable::Constants;
BEGIN {
  $Object::Pluggable::Constants::AUTHORITY = 'cpan:HINRIK';
}
BEGIN {
  $Object::Pluggable::Constants::VERSION = '1.29';
}

use strict;
use warnings;

require Exporter;
use base qw(Exporter);
our @EXPORT_OK = qw(
    PLUGIN_EAT_NONE PLUGIN_EAT_CLIENT PLUGIN_EAT_PLUGIN PLUGIN_EAT_ALL
);
our %EXPORT_TAGS = ( ALL => [@EXPORT_OK] );

use constant {
    PLUGIN_EAT_NONE   => 1,
    PLUGIN_EAT_CLIENT => 2,
    PLUGIN_EAT_PLUGIN => 3,
    PLUGIN_EAT_ALL    => 4,
};

1;
__END__

=encoding utf8

=head1 NAME

Object::Pluggable::Constants - Importable constants for Object::Pluggable

=head1 SYNOPSIS

 use Object::Pluggable::Constants qw(:ALL);

=head1 DESCRIPTION

Object::Pluggable::Constants defines a number of constants that are
required by the plugin system.

=head1 EXPORTS

=head2 C<PLUGIN_EAT_NONE>

Value: 1

This means the event will continue to be processed by remaining plugins and
finally, sent to interested sessions that registered for it.

=head2 C<PLUGIN_EAT_CLIENT>

Value: 2

This means the event will continue to be processed by remaining plugins but
it will not be sent to any sessions that registered for it.

=head2 C<PLUGIN_EAT_PLUGIN>

Value: 3

This means the event will not be processed by remaining plugins, it will go
straight to interested sessions.

=head2 C<PLUGIN_EAT_ALL>

Value: 4

This means the event will be completely discarded, no plugin or session will
see it.

=head1 MAINTAINER

Chris 'BinGOs' Williams <chris@bingosnet.co.uk>

=head1 SEE ALSO

L<Object::Pluggable|Object::Pluggable>

=cut
