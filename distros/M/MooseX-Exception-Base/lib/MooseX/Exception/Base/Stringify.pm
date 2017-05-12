package MooseX::Exception::Base::Stringify;

# Created on: 2012-07-11 11:07:06
# Create by:  Ivan Wills
# $Id$
# $Revision$, $HeadURL$, $Date$
# $Revision$, $Source$, $Date$

use Moose::Role;
use strict;
use warnings;
use version;

our $VERSION     = version->new('0.0.6');

Moose::Util::meta_attribute_alias('MooseX::Exception::Stringify');

has stringify_pre => (
    is        => 'rw',
    isa       => 'Str',
    predicate => 'has_stringify_pre',
);
has stringify_post => (
    is        => 'rw',
    isa       => 'Str',
    predicate => 'has_stringify_post',
);
has stringify => (
    is        => 'rw',
    isa       => 'CodeRef',
    predicate => 'has_stringify',
);

1;

__END__

=head1 NAME

MooseX::Exception::Base::Stringify - Traits class for attributes that are to be stringified.

=head1 VERSION

This documentation refers to MooseX::Exception::Base::Stringify version 0.0.6.


=head1 SYNOPSIS

   use Moose;
   use MooseX::Exception::Base::Stringify;

   # cause a MooseX::Exception::Base to output this value
   has my_attrib => (
       is     => 'rw',
       isa    => 'Str',
       traits => [qw{MooseX::Exception::Stringify}],
   );

   # custom stringification from an object
   has my_date => (
       is        => 'rw',
       isa       => 'DateTime',
       traits    => [qw{MooseX::Exception::Stringify}],
       stringify => sub {$_->ymd},
   );

   # causes the stringified object to show the my_message value
   # something like 'Message : ' . $obj->my_message
   has my_message => (
       is            => 'rw',
       isa           => 'Str',
       traits        => [qw{MooseX::Exception::Stringify}],
       stringify_pre => 'Message : ',
   );

   # like with stringify_pre the value has stringify_post appended
   # $obj->my_post . ' km/h'
   has my_post => (
       is             => 'rw',
       isa            => 'Num',
       traits         => [qw{MooseX::Exception::Stringify}],
       stringify_post => ' km/h',
   );

=head1 DESCRIPTION

Defines the trait (MooseX::Exception::Stringify) for L<MooseX::Exception::Base>
objects that want other parameters to be stringified along with the error
object.

=head1 INCOMPATIBILITIES

=head1 BUGS AND LIMITATIONS

There are no known bugs in this module.

Please report problems to Ivan Wills (ivan.wills@gmail.com).

Patches are welcome.

=head1 AUTHOR

Ivan Wills - (ivan.wills@gmail.com)

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2012 Ivan Wills (14 Mullion Close Hornsby Heights NSW Australia 2077).
All rights reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. See L<perlartistic>.  This program is
distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.

=cut
