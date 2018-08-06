package Pod::Knit::Document::Mojo;
our $AUTHORITY = 'cpan:YANICK';
# ABSTRACT: manipulate a Pod::Knit::Document using Mojo::DOM58
$Pod::Knit::Document::Mojo::VERSION = '0.0.1';
use strict;
use warnings;

use Mojo::DOM58;

use Moose::Role;

use MooseX::MungeHas { has_ro => [ 'is_ro' ] };

use experimental qw/ signatures /;

has_ro dom => sub ($self) {
    Mojo::DOM58->new( $self->xml_pod )
};

sub find_or_create_section( $self, $name, $level = 1, $class = $name, @rest ) {

    $class //= $name;

    my $section = $self->dom->find( join '.', 'section', $name );

    return $section if $section->size;

    $self->dom->find('document')->first->append_content(
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

Pod::Knit::Document::Mojo - manipulate a Pod::Knit::Document using
Mojo::DOM58

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

