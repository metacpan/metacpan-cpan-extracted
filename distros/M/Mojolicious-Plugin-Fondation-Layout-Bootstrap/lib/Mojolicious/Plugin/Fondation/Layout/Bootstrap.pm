package Mojolicious::Plugin::Fondation::Layout::Bootstrap;
use Mojo::Base 'Mojolicious::Plugin', -signatures;

# ABSTRACT: Simple layout plugin for Fondation

our $VERSION = '0.01';

sub fondation_meta {
    return {
        dependencies => ['Fondation::Asset'],
    };
}

sub register ($self, $app, $conf) {

    return $self;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mojolicious::Plugin::Fondation::Layout::Bootstrap - Simple layout plugin for Fondation

=head1 VERSION

version 0.03

=head1 AUTHOR

Daniel Brosseau <dab@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Daniel Brosseau.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
