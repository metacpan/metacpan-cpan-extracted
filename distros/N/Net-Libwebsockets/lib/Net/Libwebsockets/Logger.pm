package Net::Libwebsockets::Logger;

use strict;
use warnings;

=encoding utf-8

=head1 NAME

Net::Libwebsockets::Logger - Contextual logging

=head1 SYNOPSIS

    my $logger = Net::Libwebsockets::Logger->new(
        level => Net::Libwebsockets::LLL_ERR | Net::Libwebsockets::LLL_WARN,

        callback => sub ($level, $message) {
            # $level is one of LLL_ERR et al.
        },
    );

=head1 DESCRIPTION

This class implements a LWS contextual logger, as L<Net::Libwebsockets>’s
main documentation describes.

=cut

#----------------------------------------------------------------------

use Carp;

#----------------------------------------------------------------------

=head1 METHODS

=head2 $obj = I<CLASS>->new( %OPTS )

Instantiates I<CLASS>. %OPTS are all optional:

=over

=item * C<level> - A bitwise-OR of various C<LLL_*> constants
from L<Net::Libwebsockets>. Defaults to LWS’s global log level at
instantiation time.

=item * C<callback> - A coderef that receives 2 arguments: the message’s
log level (should match a C<LLL_*> constant), and the message itself.
Defaults to LWS’s own default behavior.

=back

=cut

sub new {
    my ($class, %opts) = @_;

    for my $key (keys %opts) {
        if ($key eq 'level') {
            # validate? XS will handle it anyway
        }
        elsif ($key eq 'callback') {
            if ($opts{$key} && !UNIVERSAL::isa($opts{$key}, 'CODE')) {
                Carp::confess("“callback” must be a coderef, not “$opts{$key}”");
            }
        }
        else {
            Carp::confess(__PACKAGE__ . ": unknown argument: $key");
        }
    }

    return $class->_new(@opts{'level', 'callback'});
}

1;
