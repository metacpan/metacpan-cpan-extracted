package RDF::Server::Interface;

use Moose::Role;

requires 'handle_request';

no Moose::Role;

1;

__END__

=pod

=head1 NAME

RDF::Server::Interface - defines how the server speaks over the protocol

=head1 SYNOPSIS

 package My::Interface;

 use Moose::Role;
 with 'RDF::Server::Interface';

=head1 DESCRIPTION

=head1 CONFIGURATION

=over 4

=item handlers : ArrayRef[Handler]

This is a list of objects that implement the RDF::Server::Role::Handler role.
These are searched by C<find_handler> to find the handler that will handle the
given path.

=back

=head1 METHODS

=over 4

=item find_handler($)

Given a path, this will return the handler object that should be used to handle
the request.  If no such object can be found, this will return C<undef>.

N.B.: Regardless of how the request URL is constructed, C<find_handler> 
expects a REST-style path to find the proper handler.  This does not apply 
to determining what operation is done through the handler once the handler 
is identified.

=item handle_request ($$)  (required)

This method is given an HTTP::Request and HTTP::Response object (in that order)
representing the current request and prepared response.

=back

=head1 SEE ALSO

L<RDF::Server::Interface::REST>

=head1 AUTHOR

James Smith, C<< <jsmith@cpan.org> >>

=head1 LICENSE

Copyright (c) 2008  Texas A&M University.

This library is free software.  You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

