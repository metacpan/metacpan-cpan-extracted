package PlugAuth::Role::Refresh;

use strict;
use warnings;
use Role::Tiny;

# ABSTRACT: Role for PlugAuth reload plugins
our $VERSION = '0.38'; # VERSION


requires qw( refresh );

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

PlugAuth::Role::Refresh - Role for PlugAuth reload plugins

=head1 VERSION

version 0.38

=head1 SYNOPSIS

 package PlugAuth::Plugin::MyRefresh;
 
 use Role::Tiny::With;
 
 with 'PlugAuth::Role::Plugin';
 with 'PlugAuth::Role::Refresh';
 
 sub refresh {
   my ($self) = @_;
   # called on every request
 }
 
 1;

=head1 DESCRIPTION

Use this role for PlugAuth plugins which need to be refreshed
on every call.  You will likely want to mix this role in with either
or both L<PlugAuth::Role::Auth> and L<PlugAuth::Role::Authz>.

=head1 REQUIRED ABSTRACT METHODS

=head2 $plugin-E<gt>refresh

Called on every request.

=head1 SEE ALSO

L<PlugAuth>,
L<PlugAuth::Guide::Plugin>,
L<Test::PlugAuth::Plugin::Refresh>

=cut

=head1 AUTHOR

Graham Ollis <gollis@sesda3.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by NASA GSFC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
