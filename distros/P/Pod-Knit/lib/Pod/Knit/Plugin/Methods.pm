package Pod::Knit::Plugin::Methods;
our $AUTHORITY = 'cpan:YANICK';
# ABSTRACT: POD structure for methods
$Pod::Knit::Plugin::Methods::VERSION = '0.0.1';
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
        method signature
    /);

    $parser->commands->{method} = { alias => 'head3' };
    $parser->commands->{signature} = { alias => 'verbatim' };
}

sub methods_section($self,$doc) {
    return $doc->find_or_create_section('methods');
}

sub munge( $self, $doc ) {

    $doc->dom->find( 'section.method' )->each(sub{
        $self->transform_method($_);
        $_->detach;
        $self->methods_section($doc)->append($_);
    });

}

sub transform_method ($self,$section) {
    $section->find( 'verbatim.signature' )->each(sub{
        $_->detach;
        $section->find('head3')->after($_);
    });
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Pod::Knit::Plugin::Methods - POD structure for methods

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

