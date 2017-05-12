package OpenTok::API::Exceptions;

use strict;
use warnings;

use vars qw($VERSION);

our $VERSION = 0.02;

my %e;

BEGIN
{
    %e = (  'OpenTok::API::Exception' => {
                description => 'Generic OpenTok exception. Read the message to get more details'
            },
    
            'OpenTok::API::Exception::Auth' => {
                isa         => 'OpenTok::API::Exception',
                description => 'OpenTok exception related to authentication. Most likely an issue with your API key or secret'
            },

            'OpenTok::API::Exception::Request' => {
                isa         => 'OpenTok::API::Exception',
                description => 'OpenTok exception related to the HTTP request. Most likely due to a server error. (HTTP 500 error)'
            },

    );
    
}    
    

use Exception::Class (%e);

1;

=head1 NAME

OpenTok::API::Exceptions - Exceptions for the Mail::Log::* modules.

=head1 SYNOPSIS

  use OpenTok::API::Exceptions;

  OpenTok::API::Exception->throw(q{Error description});

=head1 DESCRIPTION

This is a generic Exceptions module, supporting exceptions for the OpenTok::API::*
modules.  At the moment it's just a thin wrapper around L<Exception::Class>, 
Current exceptions in this module:

=head1 AUTHOR

Maxim Nikolenko, C<< <root at zbsd.ru> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-opentok-api at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=OpenTok::API>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc OpenTok::API

You can also look for information at:

http://www.tokbox.com/opentok/api/tools/as3/documentation/overview/index.html

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=OpenTok::API>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/OpenTok-API>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/OpenTok-API>

=item * Search CPAN

L<http://search.cpan.org/dist/OpenTok-API/>

=back


=head1 LICENSE AND COPYRIGHT

Copyright 2011 Maxim Nikolenko.

This module is released under the following license: BSD
