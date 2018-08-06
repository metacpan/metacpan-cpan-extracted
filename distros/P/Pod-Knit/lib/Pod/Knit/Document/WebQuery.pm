package Pod::Knit::Document::WebQuery;
our $AUTHORITY = 'cpan:YANICK';     
# ABSTRACT: manipulate Pod::Knit documents using Web::Query
$Pod::Knit::Document::WebQuery::VERSION = '0.0.1';
use strict;
use warnings;

use Web::Query::LibXML;

use Moose::Role;

use experimental qw/ signatures postderef /;

has dom => ( 
    is => 'ro',
    clearer => 'clear_dom',
    lazy => 1,
    default => sub ($self) {
        use DDP;
        my $x = $self->xml_pod;

        # https://github.com/tokuhirom/HTML-TreeBuilder-LibXML/pull/15
        HTML::TreeBuilder::LibXML::_parser->keep_blanks(1);
        Web::Query::LibXML->new_from_html(
            $x,
            { no_space_compacting => 1 },
        );
    },
);

sub find_or_create_section( $self, $name, $level = 1, $class = $name, @rest ) {

    $class //= $name;

    my $section = $self->dom->find( join '.', 'section', $name );

    return $section if $section->size;

    $self->dom->append(
        $self->xml_write( section => [
            ':class'        => lc($class),
            'head' . $level => $name,
            @rest,
        ])
    );

    return $self->dom->find( 'section.'. $name );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Pod::Knit::Document::WebQuery - manipulate Pod::Knit documents using
Web::Query

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

