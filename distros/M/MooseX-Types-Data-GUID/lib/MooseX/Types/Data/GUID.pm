package MooseX::Types::Data::GUID;

use strict;
use warnings;

our $VERSION = '0.001000';

use Data::GUID;
use MooseX::Types -declare => [qw/ GUID /];
use Moose::Util::TypeConstraints;

class_type 'Data::GUID';
subtype GUID, as 'Data::GUID';

coerce 'Data::GUID' =>
  from Str => via { Data::GUID->from_any_string($_) };

coerce GUID,
  from Str => via { Data::GUID->from_any_string($_) };

1;

__END__;

=head1 NAME

MooseX::Types::Data::GUID - L<Data::GUID> related constraints and coercions for
Moose

=head1 SYNOPSIS

Export Example:

    use MooseX::Types::Data::GUID qw(TimeZone);

    has guid => (
        isa => GUID,
        is => "rw",
        coerce => 1,
    );

    Class->new( guid => "C6A9FE9A-72FE-11DD-B3B4-B2EC1DADD46B");

Namespaced Example:

    use MooseX::Types::Data::GUID;

    has guid => (
        isa => 'Data::GUID',
        is => "rw",
        coerce => 1,
    );

    Class->new( guid => "C6A9FE9A-72FE-11DD-B3B4-B2EC1DADD46B");

=head1 DESCRIPTION

This module packages several L<Moose::Util::TypeConstraints> with coercions,
designed to work with L<Data::GUID>.

=head1 AUTHOR

Guillermo Roditi (groditi) E<lt>groditi@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (c) 2008 Guillermo Roditi. This program is free software; you can 
redistribute it and/or modify it under the same terms as Perl itself.

=cut
