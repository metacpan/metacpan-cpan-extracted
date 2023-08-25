package Pithub::Repos::Actions;
our $AUTHORITY = 'cpan:PLU';

# ABSTRACT: Github v3 Repo Actions API

use Moo;

our $VERSION = '0.01041';

use Pithub::Repos::Actions::Workflows ();

extends 'Pithub::Base';


sub workflows {
    return shift->_create_instance( Pithub::Repos::Actions::Workflows::, @_ );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Pithub::Repos::Actions - Github v3 Repo Actions API

=head1 VERSION

version 0.01041

=head1 DESCRIPTION

This class is incomplete. Please send patches for any additional functionality
you may require.

=head1 METHODS

=head2 workflows

Provides access to L<Pithub::Repos::Actions::Worfklows>.

=head1 AUTHOR

Johannes Plunien <plu@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Johannes Plunien.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
