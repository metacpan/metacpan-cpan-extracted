package OAuthomatic::OAuthInteraction;
# ABSTRACT: handle browser redirects happening during OAuth initial exchange

use Moose::Role;
use OAuthomatic::Types;
use namespace::sweep;




requires 'callback_url';


requires 'wait_for_oauth_grant';


requires 'prepare_to_work';


requires 'cleanup_after_work';



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

OAuthomatic::OAuthInteraction - handle browser redirects happening during OAuth initial exchange

=head1 VERSION

version 0.0201

=head1 SYNOPSIS

    $oauth_interaction->prepare_to_work();
    say "Please, spawn browser on ", $oauth_interaction->callback_url;
    my $app_cred = $oauth_interaction->wait_for_oauth_grant();
    $oauth_interaction->cleanup_after_work();

=head1 DESCRIPTION

APIs required from module responsible for receiving completion of
access-granting interaction with the OAuth-protected site.

Main problem resolved here is that OAuth authorization is completed by
browser redirect, with tokens crucial for the process provided in
URL. This module is about receiving this redirect and extracting this
info.

Default implementation - L<OAuthomatic::OAuthInteraction::ViaMicroWeb>
- spawns embedded temporary webserver on local address.

=head1 METHODS

=head2 callback_url()

Which url should be given to access-granting website as URL
for final callback.

It may be localhost address (it suffices that it works in local
browser, need not be reachable from internet).

In extreme case some fake address can be used and user instructed to
copy and paste it to the application when prompted.

=head2 wait_for_oauth_grant() => Verifier(...)

Wait until callback is received, extract and return obtained
tokens. Return undef in case obtained results are invalid.

=head2 prepare_to_work()

Prepare and start anything necessary to handle other calls (in
particular, to receive call to L</callback url>).

Example implementation starts separate thread with temporary webserver.

=head2 cleanup_after_work()

Called once object is no longer needed, may cleanup whatever
L</prepare_to_work> initialized or started.

=for test_synopsis use feature 'say';  my ($oauth_interaction);

=head1 AUTHOR

Marcin Kasperski <Marcin.Kasperski@mekk.waw.pl>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Marcin Kasperski.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
