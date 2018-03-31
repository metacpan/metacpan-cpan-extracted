package Statocles::Deploy;
our $VERSION = '0.092';
# ABSTRACT: Base role for ways to deploy a site

use Statocles::Base 'Role';

#pod =attr base_url
#pod
#pod The base URL for this deploy. Site URLs will be automatically rewritten to be
#pod based on this URL.
#pod
#pod This allows you to have different versions of the site deployed to different
#pod URLs.
#pod
#pod =cut

has base_url => (
    is => 'ro',
    isa => Str,
);

#pod =attr site
#pod
#pod The site this deploy is deploying for. This will be set before the site calls
#pod L<the deploy method|/deploy>.
#pod
#pod =cut

has site => (
    is => 'rw',
    isa => InstanceOf['Statocles::Site'],
);

#pod =method deploy
#pod
#pod     my @paths = $deploy->deploy( $from_store, $message );
#pod
#pod Deploy the site, copying from the given L<store object|Statocles::Store>, optionally
#pod committing with the given message. Returns a list of file paths deployed.
#pod
#pod This must be implemented by the composing class.
#pod
#pod =cut

requires qw( deploy );

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Statocles::Deploy - Base role for ways to deploy a site

=head1 VERSION

version 0.092

=head1 DESCRIPTION

A Statocles::Deploy deploys a site to a destination, like Git, SFTP, or
otherwise.

=head1 ATTRIBUTES

=head2 base_url

The base URL for this deploy. Site URLs will be automatically rewritten to be
based on this URL.

This allows you to have different versions of the site deployed to different
URLs.

=head2 site

The site this deploy is deploying for. This will be set before the site calls
L<the deploy method|/deploy>.

=head1 METHODS

=head2 deploy

    my @paths = $deploy->deploy( $from_store, $message );

Deploy the site, copying from the given L<store object|Statocles::Store>, optionally
committing with the given message. Returns a list of file paths deployed.

This must be implemented by the composing class.

=head1 SEE ALSO

=over 4

=item L<Statocles::Deploy::File>

=item L<Statocles::Deploy::Git>

=back

=head1 AUTHOR

Doug Bell <preaction@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Doug Bell.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
