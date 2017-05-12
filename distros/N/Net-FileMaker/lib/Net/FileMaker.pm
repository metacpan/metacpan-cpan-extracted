package Net::FileMaker;
{
  $Net::FileMaker::VERSION = '0.064';
}

use strict;
use warnings;
use Carp;
use 5.008;

use LWP::UserAgent;
use URI;

=encoding utf8

=head1 NAME

Net::FileMaker - Interact with FileMaker services

=head1 SYNOPSIS

    use Net::FileMaker;
    my $fms  = Net::FileMaker->new(host => $host, type => 'xml');

Net::FileMaker provides an interface to FileMaker's various HTTP-based
interfaces, at present only the XML API is supported, but further support to
include XSLT and other means is planned.

=head1 METHODS

=head2 new(host => $host, type => 'xml')

Creates a new object. Host names must be valid URI. The type key specifies the
type of database access - XML, XSLT etc. At present only C<xml> is valid. If
this is unspecified, XML is the default.

=cut

sub new
{
    my($class, %args) = @_;

    if($args{type} eq 'xml')
    {
        #TODO: Validate host is correct, must have http(s)? set first.
        require Net::FileMaker::XML;
        return  Net::FileMaker::XML->new(%args);
    }
    elsif(!$args{type} || $args{type} eq '')
    {
        # Assume no type specified - use XML.
        require Net::FileMaker::XML;
        return  Net::FileMaker::XML->new(%args);
    }
    # TODO: Add XSLT, PHP, etc.
    else
    {
        croak 'Unknown type specified.';
    }

}

=head1 DOCUMENTATION

As all of the current structure is confied to the XML base, see L<Net::FileMaker::XML>.

=head1 AUTHOR

Squeeks, C<< <squeek at cpan.org> >>

=head1 CONTRIBUTORS

Michele Ongaro, <<ongaro.michele at gmail.com>>
Simon Cozens, C<<simon at cpan.org>>
Marcel Grünauer, C<<marcel at cpan.org>>

=head1 BUGS

This distribution is now in maintainence mode as I (Squeeks) no longer have
access to a FileMaker Server to test functionality. If you are able to either
provide access to one or run the tests against one and provide feedback, please
get in touch so better support can be provided to this.

Please report any bugs or feature requests to C<bug-net::filemaker at
rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Net::FileMaker>.  I will be
notified, and then you'll automatically be notified of progress on your bug as I
make changes. Please ensure to include the version of FileMaker Server in your
report.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Net::FileMaker


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Net::FileMaker>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Net::FileMaker>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Net::FileMaker>

=item * Search CPAN

L<http://search.cpan.org/dist/Net::FileMaker/>

=back

=head1 DEVELOPMENT

Everyone is welcome to help towards the project with bugfixes, feature requests
or contributions.  You'll find the git repository for this project is located at
L<http://github.com/squeeks/Net-FileMaker>.

=head1 LICENSE AND COPYRIGHT

Copyright 2010 Squeeks.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Net::FileMaker
