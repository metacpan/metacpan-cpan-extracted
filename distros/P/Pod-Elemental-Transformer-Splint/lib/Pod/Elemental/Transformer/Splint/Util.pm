use 5.10.1;
use strict;
use warnings;

package Pod::Elemental::Transformer::Splint::Util;

# ABSTRACT: Role for attribute renderers
our $AUTHORITY = 'cpan:CSSON'; # AUTHORITY
our $VERSION = '0.1202';

use Moose::Role;
use Pod::Simple::XHTML;
use Safe::Isa;

sub parse_pod {
    my $self = shift;
    my $pod = shift;

    my $podder = Pod::Simple::XHTML->new;
    $podder->html_header('');
    $podder->html_footer('');
    my $results = '';
    $podder->output_string(\$results);
    $podder->parse_string_document("=pod\n\n$pod");

    $results =~ s{</?p>}{}g;
    $results =~ s{https?://search\.cpan\.org/perldoc\?}{https://metacpan.org/pod/}g;
    $results =~ s{[\v\h]*$}{};
    return $results;
}

sub determine_type_library {
    my $self = shift;
    my $type_constraint = shift;

    return $self->get_library_for_type($type_constraint) if $self->get_library_for_type($type_constraint);
    return $self->default_type_library if $self->has_default_type_library;
    return $type_constraint;
}

sub make_type_string {
    my $self = shift;
    my $type_constraint = shift;
    return '' if !defined $type_constraint;

    # The type knows its own library
    return $self->parse_pod(sprintf 'L<%s|%s/"%s>', $type_constraint, $type_constraint->library, $type_constraint) if $type_constraint->$_can('library') && defined $type_constraint->library;

    # We don't deal with InstanceOf
    if($type_constraint =~ m{InstanceOf}) {
        if($self->has_default_type_library) {
            $type_constraint =~ s{InstanceOf}{$self->type_string_helper('InstanceOf', $self->default_type_library, 'InstanceOf')}egi;
            $type_constraint =~ s{"}{'}g;
        }
        return $type_constraint
    }

    # If there are multiple types we deal with them individually
    if($type_constraint =~ m{[^a-z0-9_]}i) {

        $type_constraint =~ s{\b([a-z0-9_]+)\b}{$self->type_string_helper($1, $self->determine_type_library($1), $1)}egi;

        # cleanup and ensure some whitespace
        $type_constraint =~ s{\v}{}g;
        $type_constraint =~ s{\|}{ | }g;
        $type_constraint =~ s{\[}{ [ }g;
        $type_constraint =~ s{]}{ ]}g;
        return $type_constraint;
    }


    # it can't do library, but it can do name?
    if($self->$_can('name')) {
        my $name = $type_constraint->name;

        if($self->get_library_for_type($name)) {
            return $self->parse_pod(sprintf 'L<%s|%s/"%s>', $name, $self->get_library_for_type($name), $name);
        }
        return $self->parse_pod(sprintf 'L<%s|%s/"%s>', $name, $self->has_default_type_library, $name);
    }

    if($self->get_library_for_type($type_constraint)) {
        return $self->parse_pod(sprintf 'L<%s|%s/"%s>', $type_constraint, $self->get_library_for_type($type_constraint), $type_constraint);
    }

    return $self->parse_pod(sprintf 'L<%s|%s/"%s>', $type_constraint, $self->has_default_type_library, $type_constraint);
}

sub type_string_helper {
    my $self = shift;
    my $text = shift;
    my $type_library = shift;
    my $anchor = shift;

    return $self->parse_pod(sprintf 'L<%s|%s/"%s>', $text, $type_library, $anchor);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Pod::Elemental::Transformer::Splint::Util - Role for attribute renderers

=head1 VERSION

Version 0.1202, released 2020-12-26.

=head1 SOURCE

L<https://github.com/Csson/p5-Pod-Elemental-Transformer-Splint>

=head1 HOMEPAGE

L<https://metacpan.org/release/Pod-Elemental-Transformer-Splint>

=head1 AUTHOR

Erik Carlsson <info@code301.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Erik Carlsson.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
