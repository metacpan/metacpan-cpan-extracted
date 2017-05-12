package MooX::Types::MooseLike::Numeric;
use strict;
use warnings FATAL => 'all';
use MooX::Types::MooseLike qw(exception_message);
use MooX::Types::MooseLike::Base;
use Exporter 5.57 'import';
our @EXPORT_OK = ();

our $VERSION = '1.03';

my $type_definitions = [
  {
    name       => 'PositiveNum',
    subtype_of => 'Num',
    from       => 'MooX::Types::MooseLike::Base',
    test       => sub { $_[0] > 0 },
    message    => sub { return exception_message($_[0], 'a positive number') },
  },
  {
    name       => 'PositiveOrZeroNum',
    subtype_of => 'Num',
    from       => 'MooX::Types::MooseLike::Base',
    test       => sub { $_[0] >= 0 },
    message    => sub { return exception_message($_[0], 'a positive number or zero') },
  },
  {
    name       => 'PositiveInt',
    subtype_of => 'Int',
    from       => 'MooX::Types::MooseLike::Base',
    test       => sub { $_[0] > 0 },
    message    => sub { return exception_message($_[0], 'a positive integer') },
  },
  {
    name       => 'PositiveOrZeroInt',
    subtype_of => 'Int',
    from       => 'MooX::Types::MooseLike::Base',
    test       => sub { $_[0] >= 0 },
    message    => sub { return exception_message($_[0], 'a positive integer or zero') },
  },
  {
    name       => 'NegativeNum',
    subtype_of => 'Num',
    from       => 'MooX::Types::MooseLike::Base',
    test       => sub { $_[0] < 0 },
    message    => sub { return exception_message($_[0], 'a negative number') },
  },
  {
    name       => 'NegativeOrZeroNum',
    subtype_of => 'Num',
    from       => 'MooX::Types::MooseLike::Base',
    test       => sub { $_[0] <= 0 },
    message    => sub { return exception_message($_[0], 'a negative number or zero') },
  },
  {
    name       => 'NegativeInt',
    subtype_of => 'Int',
    from       => 'MooX::Types::MooseLike::Base',
    test       => sub { $_[0] < 0 },
    message    => sub { return exception_message($_[0], 'a negative integer') },
  },
  {
    name       => 'NegativeOrZeroInt',
    subtype_of => 'Int',
    from       => 'MooX::Types::MooseLike::Base',
    test       => sub { $_[0] <= 0 },
    message    => sub { return exception_message($_[0], 'a negative integer or zero') },
  },
  {
    name       => 'SingleDigit',
    subtype_of => 'PositiveOrZeroInt',
    from       => 'MooX::Types::MooseLike::Numeric',
    test       => sub { $_[0] < 10 },
    message    => sub { return exception_message($_[0], 'a single digit') },
  },
  ];

MooX::Types::MooseLike::register_types($type_definitions, __PACKAGE__,
  'MooseX::Types::Common::Numeric');
our %EXPORT_TAGS = ('all' => \@EXPORT_OK);

1;

__END__

=head1 NAME

MooX::Types::MooseLike::Numeric - Moo types for numbers

=head1 SYNOPSIS

  package MyPackage;
  use Moo;
  use MooX::Types::MooseLike::Numeric qw(PositiveInt);

  has "daily_breathes" => (
    is  => 'rw',
    isa => PositiveInt
  );

=head1 DESCRIPTION

A set of numeric types to be used in Moo-based classes. Adapted from MooseX::Types::Common::Numeric

=head1 TYPES (subroutines)

Available types are listed below.

=over

=item PositiveNum

=item PositiveOrZeroNum

=item PositiveInt

=item PositiveOrZeroInt

=item NegativeNum

=item NegativeOrZeroNum

=item NegativeInt

=item NegativeOrZeroInt

=item SingleDigit

=back

=head1 SEE ALSO

L<MooX::Types::MooseLike> - a type builder.

L<MooX::Types::MooseLike::Base> - a set of basic types.

L<MooX::Types::MooseLike::Email>, L<MooX::Types::MooseLike::DateTime>

=head1 AUTHOR

mateu - Mateu X. Hunter (cpan:MATEU) <hunter@missoula.org>

=head1 CONTRIBUTORS

amidos - Dmitry Matrosov (cpan:AMIDOS) <amidos@amidos.ru>

=head1 COPYRIGHT

Copyright (c) 2011-2015 the MooX::Types::MooseLike::Numeric L</AUTHOR>

=head1 LICENSE

This library is free software and may be distributed under the same terms
as perl itself.

=cut
