package Moose::Test;

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:STEVAN';

__END__

=pod

=head1 NAME

Moose::Test - A Test Runner for the Moose test suite

=head1 SYNOPSIS

    # t/001-attr--nohook.t -- test bare class
    use Test::More tests => 1;
    use Moose::Test::Case;
    Moose::Test::Case->new->run_tests;

    # t/001-attr--immutable.t -- munge class before tests run
    use Test::More tests => 1;
    use Moose::Test::Case;
    Moose::Test::Case->new->run_tests(
        after_last_pm => sub {
            Class->meta->make_immutable;
        },
    )

    # t/001-attr/Class.pm
    package Class;
    use Moose;
    has name => (isa => 'Str');

    # t/001-attr/string.t
    my $obj = Class->new(name => "Lloyd");
    ok($obj, "Constructor works when validating a string");

=head1 DESCRIPTION

This module provides an abstraction over the Moose test
cases such that it makes it easier for them to be re-used
in different contexts. 

=head1 BUGS

All complex software has bugs lurking in it, and this module is no 
exception. If you find a bug please either email me, or add the bug
to cpan-RT.

=head1 AUTHOR

Stevan Little E<lt>stevan.little@iinteractive.comE<gt>

Shawn M Moore E<lt>sartak@bestpractical.comE<gt>

Yuval Kogman E<lt>nothingmuch@woobling.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2008 Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

