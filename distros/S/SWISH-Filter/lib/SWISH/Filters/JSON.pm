package SWISH::Filters::JSON;
use strict;
use vars qw( $VERSION @ISA );
$VERSION = '0.191';
@ISA     = ('SWISH::Filters::Base');
use Data::Dump qw( dump );

sub new {
    my ($class) = @_;
    my $self = bless { mimetypes => [qr!application/json!], }, $class;
    return $self->use_modules( 'JSON', ['Search::Tools::XML' => '0.88'], );
}

sub filter {
    my ( $self, $doc ) = @_;

    # get the raw content
    my $json = $doc->fetch_doc_reference;

    # convert to perl
    my $perl = JSON::decode_json($$json);

    # convert to XML
    my $xml = Search::Tools::XML->perl_to_xml(
        $perl,
        {   root       => 'doc',
            wrap_array => 0,
        },
    );

    #warn sprintf("xml: %s\n", Search::Tools::XML->tidy($xml));

    # update the document's content type
    $doc->set_content_type('application/xml');

    # If filtered must return either a reference to the doc or a pathname.
    return ( \$xml );
}

1;

__END__

=head1 NAME

SWISH::Filters::JSON - JSON to XML filter module

=head1 DESCRIPTION

SWISH::Filters::JSON converts JSON-encoded text to valid XML.

Requires CPAN modules L<JSON> and L<Search::Tools::XML>.

=head1 AUTHOR

Peter Karman << karman at cpan dot org >>

=head1 COPYRIGHT

This library is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<SWISH::Filter>

=cut

