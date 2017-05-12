package Mozilla::ObserverService;

use 5.008007;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Mozilla::ObserverService ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '0.04';

require XSLoader;
XSLoader::load('Mozilla::ObserverService', $VERSION);

# Preloaded methods go here.

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Mozilla::ObserverService - Perl interface to the Mozilla nsIObserverService

=head1 SYNOPSIS

    use Mozilla::ObserverService;

    my $cookie = Mozilla::PromptService::Register({
        'http-on-examine-response' => sub {
            my $http_channel = shift;
            print $http_channel->responseStatus . " at " . $http_channel->uri . "\n";
        },
    });

    # We don't need it anymore...
    Mozilla::PromptService::Unregister($cookie);

=head1 DESCRIPTION

Mozilla::ObserverService uses Mozilla nsIObserverService to allow perl functions
register for notifications.

For more detailed information see Mozilla's nsIObserverService documentation.

=head1 FUNCTIONS

=head2 Register($callbacks_hash)

Registers callbacks (values of the C<$callbacks_hash>) to the notifications
specified by corresponding keys of the C<$callbacks_hash>.

Note that all of those callbacks receive various mozilla's objects as
parameters.

Returns opaque cookie which can be used to unregister callbacks later.

=head2 Unregister($cookie)

Uses cookie obtained by C<Register> to unregister callbacks from observer
service.

=head1 CAVEAT

At present only nsIHttpChannel::responseStatus and uri methods are wrapped
around in perl code (as shown in SYNOPSIS).

=head1 SEE ALSO

Mozilla nsIObserverService documentation,
L<Gtk2::MozEmbed|Gtk2::MozEmbed>,
L<Mozilla::DOM|Mozilla::DOM>,
L<Mozilla::Mechanize|Mozilla::Mechanize>,
L<Mozilla::PromptService|Mozilla::PromptService>.

=head1 AUTHOR

Boris Sukholitko, E<lt>boriss@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Boris Sukholitko

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.7 or,
at your option, any later version of Perl 5 you may have available.


=cut
