use strict;
use warnings;

package MooseX::Role::Logger;
# ABSTRACT: Provide logging via Log::Any (DEPRECATED)
our $VERSION = '0.005'; # VERSION

use Moo::Role;
with 'MooX::Role::Logger';

1;


# vim: ts=4 sts=4 sw=4 et:

__END__

=pod

=encoding UTF-8

=head1 NAME

MooseX::Role::Logger - Provide logging via Log::Any (DEPRECATED)

=head1 VERSION

version 0.005

=head1 DESCRIPTION

L<MooseX::Role::Logger> has been renamed to L<MooX::Role::Logger> to clarify
that it works with both L<Moo> and L<Moose>.  This role just wraps that one and
is provided for backwards compatibility.

See L<MooX::Role::Logger> for usage details.

=head1 AUTHOR

David Golden <dagolden@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by David Golden.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
