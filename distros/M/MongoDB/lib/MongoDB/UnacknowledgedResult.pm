#  Copyright 2015 - present MongoDB, Inc.
#
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#
#  http://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.

use strict;
use warnings;
package MongoDB::UnacknowledgedResult;

# ABSTRACT: MongoDB unacknowledged result object

use version;
our $VERSION = 'v2.2.2';

use Moo;
use MongoDB::_Constants;
use namespace::clean;

with $_ for qw(
  MongoDB::Role::_PrivateConstructor
  MongoDB::Role::_WriteResult
);

#pod =method acknowledged
#pod
#pod Indicates whether this write result was acknowledged.  Always false for
#pod this class.
#pod
#pod =cut

sub acknowledged() { 0 };

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MongoDB::UnacknowledgedResult - MongoDB unacknowledged result object

=head1 VERSION

version v2.2.2

=head1 SYNOPSIS

    if ( $result->acknowledged ) {
        ...
    }

=head1 DESCRIPTION

This class represents an unacknowledged result, i.e. with write concern
of C<< w => 0 >>.  No additional information is available and no other
methods should be called on it.

=head1 METHODS

=head2 acknowledged

Indicates whether this write result was acknowledged.  Always false for
this class.

=head1 AUTHORS

=over 4

=item *

David Golden <david@mongodb.com>

=item *

Rassi <rassi@mongodb.com>

=item *

Mike Friedman <friedo@friedo.com>

=item *

Kristina Chodorow <k.chodorow@gmail.com>

=item *

Florian Ragwitz <rafl@debian.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2020 by MongoDB, Inc.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
