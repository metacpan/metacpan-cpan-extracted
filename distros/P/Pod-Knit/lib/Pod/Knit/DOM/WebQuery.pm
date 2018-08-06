package Pod::Knit::DOM::WebQuery;
our $AUTHORITY = 'cpan:YANICK';
$Pod::Knit::DOM::WebQuery::VERSION = '0.0.1';
use Moose::Util qw/ apply_all_roles /;

use HTML::TreeBuilder::LibXML;

use Moose::Role;

use experimental qw/
    signatures
    postderef
/;

requires 'munge';

around munge => sub($orig, $self,$doc) {
    apply_all_roles( $doc, 'Pod::Knit::Document::WebQuery' );

    $orig->($self,$doc);

    $doc->xml_pod( $doc->dom->as_html );

    return $doc;
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Pod::Knit::DOM::WebQuery

=head1 VERSION

version 0.0.1

=head1 AUTHOR

Yanick Champoux <yanick@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Yanick Champoux.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

Full text of the license can be found in the F<LICENSE> file included in
this distribution.

=cut

