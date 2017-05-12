package MooseX::Types::PerlVersion;

# ABSTRACT: L<Perl::Version> type for Moose classes

use strict;
use warnings;

our $VERSION = '0.002';

use MooseX::Types -declare => [qw(PerlVersion)];
use MooseX::Types::Moose qw(Num Str);
use Perl::Version;
use namespace::clean;

class_type 'Perl::Version';

subtype PerlVersion,
    as 'Perl::Version',
    where { $_ =~ Perl::Version::REGEX },
    message { 'Must be a valid Perl version' };

coerce PerlVersion,
    from Num, via { Perl::Version->new($_) },
    from Str, via { Perl::Version->new($_) };

1; # eof



=pod

=head1 NAME

MooseX::Types::PerlVersion - L<Perl::Version> type for Moose classes

=head1 VERSION

version 0.002

=head1 SYNOPSIS

  use MooseX::Types::PerlVersion qw(PerlVersion);

  has version => (
      is     => 'ro',
      isa    => PerlVersion,
      coerce => 1,
  );

=head1 DESCRIPTION

This package provides Moose types for L<Perl::Version>. It also provides
coercion from C<Str> and C<Num> Moose types.

=head1 EXPORT

None by default, you'll usually want to request C<PerlVersion> explicitly.

=head1 SEE ALSO

=over 4

=item L<Perl::Version>

=item L<Moose::Util::TypeConstraints>

=item L<Moose>

=back

=cut

=head1 AUTHOR

Roman F. <romanf@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Roman F..

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__
