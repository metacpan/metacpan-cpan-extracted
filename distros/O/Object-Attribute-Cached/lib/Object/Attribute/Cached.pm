package Object::Attribute::Cached;

our $VERSION = '1.00';

use strict;
use warnings;

=head1 NAME

Object::Attribute::Cached - cache complex object attributes

=head1 SYNOPSIS

	use Object::Attribute::Cached
		attribute1 => sub { shift->some_complex_task },
		squared => sub { shift->{num} ** 2 },
		uptosquare => sub { 1 .. shift->squared },
		squaredsquared => sub { map $_ ** 2, shift->uptosquare };

=head1 DESCRIPTION

This provides a simple interface to writing simple caching attribute methods.

It avoids having to write code like:

	sub parsed_query { 
		my $self = shift;
		$self->{_cached_parsed_query} ||= $self->parse_the_query;
		return $self->{_cached_parsed_query};
	}

Instead you can just declare:

	use Object::Attribute::Cached
		parsed_query => sub { shift->parse_the_query };


=head1 CAVEATS

We try to allow an attribute to be a lists or hash and examine caller()
to try to do the right thing. This will work for simple cases, but if
you're running into problems, or trying to do something more complex,
it's always safer to use references instead.

=cut

sub import {
  my ($self, @pairs) = @_;
  no strict 'refs';
  my $caller = caller();
  while (my ($method, $code) = splice (@pairs, 0,2)) {
    my $cache = "__cache_$method";
    *{"$caller\::$method"} = sub {
      my $self = shift;
      $self->{$cache} ||= [ $code->($self, @_) ];
      return @{ $self->{$cache} } if wantarray;
			return $self->{$cache}->[0];
    };
  };
}

=head1 AUTHOR

Tony Bowden

=head1 BUGS and QUERIES

Please direct all correspondence regarding this module to:
  bug-Object-Attribute-Cached@rt.cpan.org

=head1 COPYRIGHT AND LICENSE

  Copyright (C) 2003-2005 Kasei

  This program is free software; you can redistribute it and/or modify it under
  the terms of the GNU General Public License; either version 2 of the License,
  or (at your option) any later version.

  This program is distributed in the hope that it will be useful, but WITHOUT
  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
  FOR A PARTICULAR PURPOSE.

=cut

1;

