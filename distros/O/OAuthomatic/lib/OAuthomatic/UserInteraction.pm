package OAuthomatic::UserInteraction;
# ABSTRACT: Wrapping communication with user


use Moose::Role;
use OAuthomatic::Types;
use namespace::sweep;


requires 'prompt_client_credentials';


requires 'visit_oauth_authorize_page';


requires 'prepare_to_work';


requires 'cleanup_after_work';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

OAuthomatic::UserInteraction - Wrapping communication with user

=head1 VERSION

version 0.0201

=head1 DESCRIPTION

Role defining methods related to communication with end user.

=head1 METHODS

=head2 prompt_client_credentials() => ClientCred(...)

Asks the user to visit appropriate remote page and provide application
(or developer) keys. Should return L<OAuthomatic::Types::ClientCred>.

Implementation can either prompt user interactively (on the terminal,
in browser, in GUI window...), hinting her or him which place to
visit, or have those values hardcoded/loaded from elsewhere.

Note that while methods below are (mostly) parameterless, this object
will work in context of specific site and application, and should
likely require information about those in the constructor.

See L<OAuthomatic::UserInteraction::ViaMicroWeb> and L<OAuthomatic::UserInteraction::ConsolePrompts>
for example implementations.

=head2 visit_oauth_authorize_page($app_auth_url)

Send user to the page of given url (which points to I<grant access to
application ...> page and already contains all necessary parameters).

=head2 prepare_to_work()

Prepare anything necessary to handle other calls.

=head2 cleanup_after_work()

Called once object is no longer needed, may cleanup whatever
prepare_to_work initialized or started.

=head1 AUTHOR

Marcin Kasperski <Marcin.Kasperski@mekk.waw.pl>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Marcin Kasperski.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
