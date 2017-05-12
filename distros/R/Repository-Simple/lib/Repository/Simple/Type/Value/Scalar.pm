package Repository::Simple::Type::Value::Scalar;

use strict;
use warnings;

our $VERSION = '0.01';

use base 'Repository::Simple::Type::Value';

=head1 NAME

Repository::Simple::Type::Value::Scalar - Simple "rs:scalar" value type

=head1 SYNOPSIS

  my $value_type = Repository::Simple::Type::Value::Scalar->new;

=head1 DESCRIPTION

This represents the simplest of all value types. It only holds any scalar and does nothing to check or inflate or deflate a given value.

=cut

sub new {
    return bless {}, __PACKAGE__;
}

sub name {
    return 'rs:scalar';
}

=head1 AUTHOR

Andrew Sterling Hanenkamp, E<lt>hanenkamp@cpan.orgE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright 2006 Andrew Sterling Hanenkamp E<lt>hanenkamp@cpan.orgE<gt>.  All 
Rights Reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. See L<perlartistic>.

This program is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE.

=cut

1
