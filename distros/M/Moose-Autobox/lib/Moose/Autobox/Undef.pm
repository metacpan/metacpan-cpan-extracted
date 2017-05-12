package Moose::Autobox::Undef;
# ABSTRACT: the Undef role
use Moose::Role 'with';
use namespace::autoclean;

our $VERSION = '0.16';

with 'Moose::Autobox::Item';

sub defined { 0 }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Moose::Autobox::Undef - the Undef role

=head1 VERSION

version 0.16

=head1 SYNOPSIS

  use Moose::Autobox;

  my $x;
  $x->defined; # false

=head1 DESCRIPTION

This is a role to describes a undefined value.

=head1 METHODS

=over 4

=item C<defined>

=back

=over 4

=item C<meta>

=back

=head1 SUPPORT

Bugs may be submitted through L<the RT bug tracker|https://rt.cpan.org/Public/Dist/Display.html?Name=Moose-Autobox>
(or L<bug-Moose-Autobox@rt.cpan.org|mailto:bug-Moose-Autobox@rt.cpan.org>).

There is also a mailing list available for users of this distribution, at
L<http://lists.perl.org/list/moose.html>.

There is also an irc channel available for users of this distribution, at
L<C<#moose> on C<irc.perl.org>|irc://irc.perl.org/#moose>.

=head1 AUTHOR

Stevan Little <stevan.little@iinteractive.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2006 by Infinity Interactive, Inc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
