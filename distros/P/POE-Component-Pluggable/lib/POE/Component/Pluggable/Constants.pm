package POE::Component::Pluggable::Constants;
$POE::Component::Pluggable::Constants::VERSION = '1.28';
#ABSTRACT: importable constants for POE::Component::Pluggable

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

qq[Constantly plugging];

__END__

=pod

=encoding UTF-8

=head1 NAME

POE::Component::Pluggable::Constants - importable constants for POE::Component::Pluggable

=head1 VERSION

version 1.28

=head1 SYNOPSIS

 use POE::Component::Pluggable::Constants qw(:ALL);

=head1 DESCRIPTION

POE::Component::Pluggable::Constants defines a number of constants that are
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

=head1 SEE ALSO

L<POE::Component::Pluggable|POE::Component::Pluggable>

=head1 AUTHORS

=over 4

=item *

Chris Williams <chris@bingosnet.co.uk>

=item *

Apocalypse <perl@0ne.us>

=item *

Hinrik Örn Sigurðsson

=item *

Jeff Pinyan

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Chris Williams.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
