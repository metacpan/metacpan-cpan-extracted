#!/usr/bin/perl -c

package MooseX::GlobRef::Object;

=head1 NAME

MooseX::GlobRef::Object - Store a Moose object in glob reference

=head1 SYNOPSIS

  package My::IO::File;

  use Moose;

  extends 'MooseX::GlobRef::Object', 'IO::File';

=head1 DESCRIPTION

This class extends L<Moose::Object> with L<MooseX::GlobRef::Role::Object>.

This class is obsoleted by L<MooseX::GlobRef::Role::Object> and left for
backward compatibility reason. The L<MooseX::GlobRef> package should be used
instead.

=cut

use 5.006;
use strict;
use warnings;

our $VERSION = '0.0701';

use Moose;

use MooseX::GlobRef;


=head1 INHERITANCE

=over 2

=item *

extends L<Moose::Object>

=cut

extends 'Moose::Object';

=item *

with L<MooseX::GlobRef::Role::Object>

=back

=cut

with 'MooseX::GlobRef::Role::Object';


1;


=head1 SEE ALSO

L<MooseX::GlobRef>, L<Moose::Object>.

=head1 AUTHOR

Piotr Roszatycki <dexter@cpan.org>

=head1 LICENSE

Copyright (c) 2007, 2008, 2009, 2010 Piotr Roszatycki <dexter@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as perl itself.

See L<http://dev.perl.org/licenses/artistic.html>
