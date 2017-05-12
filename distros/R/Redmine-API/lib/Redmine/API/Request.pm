#
# This file is part of Redmine-API
#
# This software is copyright (c) 2014 by celogeek <me@celogeek.com>.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
package Redmine::API::Request;

# ABSTRACT: handle request to the Redmine API
use strict;
use warnings;
our $VERSION = '0.04';    # VERSION
use Carp;

use Moo;
use Redmine::API::Action;

use vars qw/$AUTOLOAD/;

sub AUTOLOAD {
    my $self = shift;
    my $route = substr( $AUTOLOAD, length(__PACKAGE__) + 2 );
    return if $route eq 'DESTROY';
    return Redmine::API::Action->new( request => $self, action => $route );
}

has 'api' => (
    is       => 'ro',
    required => 1,
    isa      => sub {
        croak "api should be a Redmine::API object"
            if ref $_[0] ne 'Redmine::API';
    }
);

has 'route' => (
    is       => 'ro',
    required => 1,
);

1;

__END__

=pod

=head1 NAME

Redmine::API::Request - handle request to the Redmine API

=head1 VERSION

version 0.04

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
https://github.com/celogeek/Redmine-API/issues

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

celogeek <me@celogeek.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by celogeek <me@celogeek.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
