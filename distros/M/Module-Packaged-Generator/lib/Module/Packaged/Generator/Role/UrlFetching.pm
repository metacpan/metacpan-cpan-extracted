#
# This file is part of Module-Packaged-Generator
#
# This software is copyright (c) 2010 by Jerome Quelin.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
use 5.010;
use strict;
use warnings;

package Module::Packaged::Generator::Role::UrlFetching;
BEGIN {
  $Module::Packaged::Generator::Role::UrlFetching::VERSION = '1.111930';
}
# ABSTRACT: role to provide easy url fetching

use LWP::Simple;
use Moose::Role;

use Module::Packaged::Generator::Utils qw{ $DATADIR };

with 'Module::Packaged::Generator::Role::Logging';


# -- public methods


sub fetch_url {
    my ($self, $url, $basename) = @_;

    my $file = $DATADIR->file( $basename );
    $self->log_debug( "downloading $url" );
    my $rc = mirror($url, $file);
    return $file if $rc == 304; # file is up to date
    return $file if is_success($rc);
    $self->log_fatal( status_message($rc) . "$rc $url " );
}

no Moose::Role;

1;


=pod

=head1 NAME

Module::Packaged::Generator::Role::UrlFetching - role to provide easy url fetching

=head1 VERSION

version 1.111930

=head1 DESCRIPTION

This L<Moose> role provides the consuming class with an easy way to
mirror files from the internet.

=head1 METHODS

=head2 fetch_url

    my $file = $self->fetch_url( $url, $basename );

Try to fetch C<$url>, and store it as C<$basename> in a private data
directory (cf L<Module::Packaged::Generator::Utils>). Return the full
path if successful (a L<Path::Class> object), throws an error if
download ended up as an error.

=head1 AUTHOR

Jerome Quelin

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Jerome Quelin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

