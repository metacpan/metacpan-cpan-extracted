package Pod::Knit::Plugin::Attributes;
our $AUTHORITY = 'cpan:YANICK';
# ABSTRACT: POD structure for attributes
$Pod::Knit::Plugin::Attributes::VERSION = '0.0.1';
use strict;
use warnings;

use XML::WriterX::Simple;

use Moose;

extends 'Pod::Knit::Plugin';
with 'Pod::Knit::DOM::WebQuery';

use experimental 'signatures';

sub setup_podparser {
    my( $self, $parser ) = @_;

    $parser->accept_directive_as_processed(  qw/
        attribute default
    /);

    $parser->commands->{attribute} = { alias => 'head3' };
    $parser->commands->{default} = { alias => 'head4' };
}

sub munge( $self, $doc ) {

    $doc->dom->find( 'section.attribute' )->each(sub{
        $_->detach;
        #$self->transform_attribute( $_, $doc );
        $self->attributes_section($doc)->append($_);
    });

}

sub attributes_section($self, $doc) {
    return $doc->find_or_create_section('attributes');
}

sub transform_attribute ($self,$doc) {
    $doc->dom->find( '.default' )->each(sub{
        $_->detach;
        $doc->dom->find('.')->filter('head3')->after($_);
    });
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Pod::Knit::Plugin::Attributes - POD structure for attributes

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

