package Mojolicious::Plugin::Fondation::Action::Base;
$Mojolicious::Plugin::Fondation::Action::Base::VERSION = '0.03';
# ABSTRACT: Base class for Fondation post-load actions

use Mojo::Base -base, -signatures;

has 'manager';
has 'log';

sub after_load ($self, $long_name, $conf, $share_dir) {
    # to be overridden
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mojolicious::Plugin::Fondation::Action::Base - Base class for Fondation post-load actions

=head1 VERSION

version 0.03

=head1 AUTHOR

Daniel Brosseau <dab@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Daniel Brosseau.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
