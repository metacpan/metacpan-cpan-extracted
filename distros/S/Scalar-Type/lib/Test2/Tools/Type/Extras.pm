package Test2::Tools::Type::Extras;

use strict;
use warnings;

use base qw(Exporter);

use Carp qw(croak);

use Scalar::Util qw(blessed reftype);

our $VERSION = '1.0.1';

our @EXPORT = ('regex_supported');

my @targets = map { $_.'::' } @_;

{
    no strict 'refs';
    while(my($k, $v) = each(%{__PACKAGE__.'::'})) {
        push @EXPORT, $k if(
            $k =~ /^is_/ &&
            ref($v) ne 'SCALAR' &&
            defined(&{$v})
        );
    }
}

*_checker = \&Test2::Tools::Type::_checker;

sub is_positive { _checker(sub { $_[0] > 0   }, @_); }
sub is_negative { _checker(sub { $_[0] < 0   }, @_); }
sub is_zero     { _checker(sub { $_[0] == 0; }, @_); }

# There are tests that is_ref, is_object and is_hashref don't screw with
# the argument's type. That covers the implementations that use
# ref/blessed/reftype. If you add more checks with different innards,
# add tests for that as well as that they return what you expect.
sub is_ref       { _checker(sub { ref($_[0]);     }, @_); }
sub is_object    { _checker(sub { blessed($_[0]); }, @_); }
sub is_hashref   { _checker(sub { reftype($_[0]) && reftype($_[0]) eq 'HASH'   }, @_); }
sub is_arrayref  { _checker(sub { reftype($_[0]) && reftype($_[0]) eq 'ARRAY'  }, @_); }
sub is_scalarref { _checker(sub { reftype($_[0]) && reftype($_[0]) eq 'SCALAR' }, @_); }
sub is_coderef   { _checker(sub { reftype($_[0]) && reftype($_[0]) eq 'CODE'   }, @_); }
sub is_globref   { _checker(sub { reftype($_[0]) && reftype($_[0]) eq 'GLOB'   }, @_); }
sub is_refref    { _checker(sub { reftype($_[0]) && reftype($_[0]) eq 'REF'    }, @_); }

sub is_regex {
    croak("You need perl 5.12 or higher to use is_regex")
        unless(regex_supported());
    _checker(sub { reftype($_[0]) && reftype($_[0]) eq 'REGEXP' }, @_);
}

sub regex_supported { $] >= 5.012 }

1;

=head1 NAME

Test2::Tools::Type::Extras - Extra tools for checking data types

=head1 SYNOPSIS

    use Test2::V0;
    use Test2::Tools::Type qw(:extras);

=head1 DESCRIPTION

This provides extra testing functions for Test2::Tools::Type. They
can all be used stand-alone or with Test2::Tools::Type's C<type> method.

This module is not intended for you to use it directly.

=head1 BUGS

If you find any bugs please report them on Github, preferably with a test case.

=head1 FEEDBACK

I welcome feedback about my code, especially constructive criticism.

=head1 AUTHOR, COPYRIGHT and LICENCE

Copyright 2024 David Cantrell E<lt>F<david@cantrell.org.uk>E<gt>

This software is free-as-in-speech software, and may be used,
distributed, and modified under the terms of either the GNU
General Public Licence version 2 or the Artistic Licence. It's
up to you which one you use. The full text of the licences can
be found in the files GPL2.txt and ARTISTIC.txt, respectively.

=head1 CONSPIRACY

This module is also free-as-in-mason software.

=cut
