package OpusVL::AppKit::View::SimpleXML;



use Moose;

use strict;
BEGIN 
{
    extends 'Catalyst::View';
}
use XML::Simple;

sub process 
{
    my ( $self, $c ) = @_;
    $c->response->headers->content_type($c->stash->{content_type} || 'text/xml');
    # FIXME: really ought to make the XML options optional too.
    $c->response->output( XMLout $c->stash->{xml}, 
                            NoAttr => 1, 
                            RootName => $c->stash->{root_element} || 'root_element', 
                            XMLDecl => 1 );
    return 1;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

OpusVL::AppKit::View::SimpleXML

=head1 VERSION

version 2.29

=head1 DESCRIPTION

    XML view using XML::Simple based on Catalyst::View::REST::XML
    Place an xml payload in $c->stash->{xml}.
    The content type will be set to 'text/xml' or $c->stash->{content_type}
    $c->stash->{root_element} should contain the name of the root element
    for the XML.

    The XMLout call is made with the NoAttr => 1 and XMLDecl => 1 settings.

    Included is the 'AppKit' ShareDir path to include distributed files.

=head1 NAME

    OpusVL::AppKit::View::SimpleXML - Simple XML view for OpusVL::AppKit

=head1 SEE ALSO

    L<OpusVL::AppKit>

=head1 AUTHOR

OpusVL - www.opusvl.com

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by OpusVL - www.opusvl.com.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
