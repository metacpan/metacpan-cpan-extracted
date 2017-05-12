#
#  Copyright 2009 10gen, Inc.
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

package MongoDB::Async::Code;
{
  $MongoDB::Async::Code::VERSION = '0.702.3';
}


# ABSTRACT: JavaScript Code


use Moose;


has code => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);


has scope => (
    is       => 'ro',
    required => 0,
	default => undef,
);

1;

__END__

=pod

=head1 NAME

MongoDB::Async::Code - JavaScript Code

=head1 VERSION

version 0.702.3

=head1 NAME

MongoDB::Async::Code - JavaScript code

=head1 ATTRIBUTES

=head2 code

A string of JavaScript code.

=head2 scope

An optional hash of variables to pass as the scope.

=head1 AUTHORS

=over 4

=item *

Florian Ragwitz <rafl@debian.org>

=item *

Kristina Chodorow <kristina@mongodb.org>

=item *

Mike Friedman <mike.friedman@10gen.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2012 by 10gen, Inc..

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
