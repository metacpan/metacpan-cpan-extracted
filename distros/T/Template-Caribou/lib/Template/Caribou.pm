package Template::Caribou;
our $AUTHORITY = 'cpan:YANICK';
# ABSTRACT: class-based HTML-centric templating system
$Template::Caribou::VERSION = '1.2.2';
use Carp;

use Moose::Exporter;

use Template::Caribou::Role;
use Template::Caribou::Tags qw/ attr /;

Moose::Exporter->setup_import_methods(
    with_meta => [ 'template' ],
    as_is     => [ 'attr', 'show' ],
    also      => [ 'Template::Caribou::Role' ],
);

use Moose::Util qw/ apply_all_roles /;

use 5.10.0;

sub show {
    state $shown_warning = 0;

    carp 'show() is deprecated, use $bou->my_template instead'
        unless $shown_warning++;

    $Template::Caribou::TEMPLATE->render(@_);
}

sub init_meta {
    my $class = shift;
    my %args = @_;

    my $meta = eval { $args{for_class}->meta };

    unless ( $meta ) {
        $meta = Moose->init_meta(@_);
        eval "package $args{for_class}; use Moose;";
    }

    apply_all_roles( $args{for_class}, 'Template::Caribou::Role' );

    return $meta;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Template::Caribou - class-based HTML-centric templating system

=head1 VERSION

version 1.2.2

=head1 SYNOPSIS

    package MyTemplate;

    use Template::Caribou;

    use Template::Caribou::Tags::HTML qw/ :all /;

    has name => ( is => 'ro' );

    template page => sub {
        my $self = shift;

        html { 
            head { 
                title { 'Example' } 
            };
            
            $self->my_body;
        }
    };

    template my_body => sub {
        my $self = shift;

        body { 
            h1 { 'howdie ' . $self->name } 
        }
    };

    package main;

    my $template = MyTemplate->new( name => 'Yanick' );
    print $template->page;

=head1 DESCRIPTION

WARNING: Codebase is alpha with extreme prejudice. Assume that bugs are
teeming and that the API is subject to change.

L<Template::Caribou> is a L<Moose>-based, class-centric templating system
mostly aimed at producing sgml-like outputs, mostly HTML, but also XML, SVG, etc. It is
heavily inspired by L<Template::Declare>.

For a manual on how to use C<Template::Caribou>, have a peek at
L<Template::Caribou::Manual>.

When C<use>d within a namespace, C<Template::Caribou> will apply the role L<Template::Caribou::Role>
to it (and auto-turn the namespace into Moose class if it wasn't a Moose class or role already),
as well as import the keywords C<template> and C<attr> (the latter from
L<Template::Caribou::Tags>), as well as load L<Template::Caribou::Utils>.

=head1 AUTHOR

Yanick Champoux <yanick@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by Yanick Champoux.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
