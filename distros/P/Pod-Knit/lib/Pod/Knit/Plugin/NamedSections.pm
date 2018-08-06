package Pod::Knit::Plugin::NamedSections;
our $AUTHORITY = 'cpan:YANICK';
# ABSTRACT: Create directive shortcuts for sections
$Pod::Knit::Plugin::NamedSections::VERSION = '0.0.1';

use 5.10.0;
use strict;
use warnings;

use Moose;

extends 'Pod::Knit::Plugin';
with 'Pod::Knit::DOM::WebQuery';

use experimental 'signatures', 'postderef';

has sections => (
    isa => 'ArrayRef',
    is => 'ro',
    lazy => 1,
    default => sub {
        []
    },
    traits => [ 'Array' ],
    handles => { all_sections => 'elements' },
);

sub setup_podparser {
    my( $self, $parser ) = @_;

    $parser->accept_directive_as_processed( @{ $self->sections } );

    $parser->commands->{$_} = { alias => 'head1' }
        for $self->all_sections;
}

sub munge( $self, $doc ) {

    for my $section ( $self->all_sections ) {
        $doc->dom->find( ".$section > head1" )->each(sub {
            return if $_->text;
            $_->text( uc $section );
        });
    }

}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Pod::Knit::Plugin::NamedSections - Create directive shortcuts for sections

=head1 VERSION

version 0.0.1

=head1 SYNOPSIS

in F<knit.yml>

    plugins:
        NamedSections:
            sections:
                - synopsis
                - description

in POD:

    =synopsis
    
        ...
    
    =description
    
    Blah blah
    
    =head1 Normal section

Knitted POD:

    =head1 SYNOPSIS
    
    ...
    
    =head1  DESCRIPTION
    
    ...

=head1 DESCRIPTION

Declares custom sections that will act like C<=head1>s.

In the XML representation of the document, the C<section> tag will be given
the name of the section as a class. E.g.

    =synopsis

turns into

    <section class="synopsis">...</section>

=head1 AUTHOR

Yanick Champoux <yanick@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Yanick Champoux.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

Full text of the license can be found in the F<LICENSE> file included in
this distribution.

=cut

