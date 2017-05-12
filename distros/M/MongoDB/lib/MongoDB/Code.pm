#
#  Copyright 2009-2013 MongoDB, Inc.
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
#

use strict;
use warnings;
package MongoDB::Code;


# ABSTRACT: JavaScript Code

use version;
our $VERSION = 'v1.8.0';

#pod =head1 NAME
#pod
#pod MongoDB::Code - JavaScript code
#pod
#pod =cut

use Moo;
use Types::Standard qw(
    HashRef
    Str
);
use namespace::clean -except => 'meta';

#pod =head1 ATTRIBUTES
#pod
#pod =head2 code
#pod
#pod A string of JavaScript code.
#pod
#pod =cut

has code => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

#pod =head2 scope
#pod
#pod An optional hash of variables to pass as the scope.
#pod
#pod =cut

has scope => (
    is       => 'ro',
    isa      => HashRef,
    required => 0,
);


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MongoDB::Code - JavaScript Code

=head1 VERSION

version v1.8.0

=head1 NAME

MongoDB::Code - JavaScript code

=head1 ATTRIBUTES

=head2 code

A string of JavaScript code.

=head2 scope

An optional hash of variables to pass as the scope.

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

This software is Copyright (c) 2017 by MongoDB, Inc.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
