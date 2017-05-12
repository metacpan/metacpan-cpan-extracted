use strict;

package Net::Delicious::Export;
use base qw (XML::SAX::Base);

# $Id: Export.pm,v 1.4 2005/09/29 13:22:57 asc Exp $

=head1 NAME

Net::Delicious::Export - base class for exporting Net::Delicious thingies

=head1 SYNOPSIS

 Ceci n'est pas une boite noire.

=head1 DESCRIPTION

Base class for exporting Net::Delicious thingies

This package subclasses I<XML::SAX::Base>.

=cut

$Net::Delicious::Export::VERSION = '1.2';

=head1 PACKAGE METHODS

=cut

=head2 __PACKAGE__->new(%args)

Valid arguments are anything you can pass a I<XML::SAX::Base>
constructor.

Returns a I<Net::Delicious::Export> object, Woot!

=cut

sub new {
    my $pkg = shift;
    return $pkg->SUPER::new(@_);
}

=head1 VERSION

1.2

=head1 DATE

$Date: 2005/09/29 13:22:57 $

=head1 AUTHOR

Aaron Straup Cope <ascope@cpan.org>

=head1 SEE ALSO

L<XML::SAX>

=head1 LICENSE

Copyright (c) 2004 Aaron Straup Cope. All Rights Reserved.

This is free software, you may use it and distribute it under the
same terms as Perl itself.

=cut

return 1;
