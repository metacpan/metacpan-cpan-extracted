use 5.008008;
use strict;
use warnings;

package MooX::Press::Keywords;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.063';

use Type::Library -base;
use Type::Utils ();

BEGIN {
	Type::Utils::extends(qw/
		Types::Standard
		Types::Common::Numeric
		Types::Common::String
	/);
};

our (%EXPORT_TAGS, @EXPORT_OK);

sub true  ()   { !!1 }
sub false ()   { !!0 }

$EXPORT_TAGS{ 'booleans' } = [qw/ true false /];

sub ro   ()    { 'ro'      }
sub rw   ()    { 'rw'      }
sub rwp  ()    { 'rwp'     }
sub lazy ()    { 'lazy'    }
sub bare ()    { 'bare'    }
sub private () { 'private' }

$EXPORT_TAGS{ 'privacy' } = [qw/ ro rw rwp lazy bare private /];

use Scalar::Util qw( blessed );
sub confess {
	@_ = sprintf(shift, @_) if @_ > 1;
	require Carp;
	goto \&Carp::confess;
}

$EXPORT_TAGS{ 'util' } = [qw/ blessed confess /];

push @EXPORT_OK, map @{$EXPORT_TAGS{$_}}, keys(%EXPORT_TAGS);

my $orig = 'Type::Library'->can('import');
sub import {
	'strict'->import;
	'warnings'->import;
	push @_, -all if @_ == 1;
	goto $orig;
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

MooX::Press::Keywords - handy keywords for MooX::Press

=head1 SYNOPSIS

  use MooX::Press::Keywords;
  use MooX::Press (
    class => [
      'Leaf' => {
        has => {
          'colour' => {
            is       => rwp,
            enum     => [qw/ green red brown /],
            default  => 'green',
          },
        },
      },
      'Tree' => {
        has => {
          'species' => {
            is       => ro,
            isa      => Str,
            required => true,
          },
          'foliage' => {
            is       => lazy,
            isa      => '@Leaf',
            builder  => sub { [] },
          },
        },
      },
    ],
  );
  no MooX::Press::Keywords;

=head1 DESCRIPTION

This is just a quick way of importing:

=over

=item *

L<strict> and L<warnings>.
(C<< no MooX::Press::Keywords >> won't unimport these!)

=item *

L<Types::Standard>, L<Types::Common::Numeric>, and L<Types::Common::String>.

=item *

C<true> and C<false> boolean constants.

=item *

C<ro>, C<rw>, C<rwp>, C<lazy>, C<private>, and C<bare> string constants.

=item *

C<blessed> from L<Scalar::Util>.

=item *

C<confess> from L<Carp>.

=back

You don't need to use it, but it might save a few lines of boilerplate
code, and allow you to use some meaningful barewords instead of quoted
strings and numbers.

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=MooX-Press>.

=head1 SEE ALSO

L<MooX::Press>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2020 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

