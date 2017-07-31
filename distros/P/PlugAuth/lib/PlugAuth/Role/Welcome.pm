package PlugAuth::Role::Welcome;

use strict;
use warnings;
use Role::Tiny;

# ABSTRACT: Role for PlugAuth reload plugins
our $VERSION = '0.38'; # VERSION


requires qw( welcome );

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

PlugAuth::Role::Welcome - Role for PlugAuth reload plugins

=head1 VERSION

version 0.38

=head1 SYNOPSIS

 package PlugAuth::Plugin::MyRefresh;
 
 use Role::Tiny::With;
 
 with 'PlugAuth::Role::Plugin';
 with 'PlugAuth::Role::Welcome';
 
 sub welcome {
   my ($self, $c) = @_;
   # called on GET / requests
 }
 
 1;

=head1 DESCRIPTION

Use this role for PlugAuth plugins which provide alternate functionality
for the default GET / route.

=head1 REQUIRED ABSTRACT METHODS

=head2 $plugin-E<gt>welcome( $controller )

Called on GET / routes

=head1 SEE ALSO

L<PlugAuth>,
L<PlugAuth::Guide::Plugin>,

=cut

=head1 AUTHOR

Graham Ollis <gollis@sesda3.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by NASA GSFC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
