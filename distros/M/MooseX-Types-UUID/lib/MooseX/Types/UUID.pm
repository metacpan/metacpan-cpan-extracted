package MooseX::Types::UUID;
use strict;
use warnings;

our $VERSION = '0.03';
our $AUTHORITY = 'CPAN:JROCKWAY';

use MooseX::Types -declare => ['UUID'];
use MooseX::Types::Moose qw(Str);

sub _validate_uuid {
    my ($str) = @_;
    return $str =~ /^[[:xdigit:]]{8}-[[:xdigit:]]{4}-[[:xdigit:]]{4}-[[:xdigit:]]{4}-[[:xdigit:]]{12}$/;
}

subtype UUID,
  as Str, where { _validate_uuid($_) };

coerce UUID,
  # i've never seen lowercase UUIDs, but someone's bound to try it
  from Str, via { uc };

1;

__END__

=head1 NAME

MooseX::Types::UUID - UUID type for Moose classes

=head1 SYNOPSIS

  package Class;
  use Moose;
  use MooseX::Types::UUID qw(UUID);

  has 'uuid' => ( is => 'ro', isa => UUID );

  package main;
  Class->new( uuid => '77C71F92-0EC7-11DD-B986-DF138EE79F6F' );

=head1 DESCRIPTION

This module lets you constrain attributes to only contain UUIDs (in
their usual human-readable form).  No coercion is attempted.

=head1 EXPORT

None by default, you'll usually want to request C<UUID> explicitly.

=head1 AUTHOR

Jonathan Rockway C<< <jrockway@cpan.org> >>

Infinity Interactive (L<http://www.iinteractive.com/>)

=head1 COPYRIGHT

This program is Free software, you may redistribute it under the same
terms as Perl itself.
