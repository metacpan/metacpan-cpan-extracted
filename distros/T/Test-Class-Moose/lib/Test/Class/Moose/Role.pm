package Test::Class::Moose::Role;

# ABSTRACT: Test::Class::Moose for roles

use strict;
use warnings;
use namespace::autoclean;

use 5.10.0;

our $VERSION = '0.88';

use Carp;

use Sub::Attribute;
use Import::Into;
use Test::Class::Moose::AttributeRegistry;

BEGIN {
    require Test::Class::Moose;
    eval Test::Class::Moose->__sub_attr_declaration_code;
    croak($@) if $@;
}

sub import {
    shift;
    my %args = @_;

    my $caller = caller;

    my @imports = qw(
      Moose::Role
      Sub::Attribute
      strict
      warnings
    );

    unless ( $args{bare} ) {
        require Test::Most;
        push @imports, 'Test::Most';
    }

    $_->import::into($caller) for @imports;

    no strict "refs";
    *{"$caller\::Tags"}  = \&Tags;
    *{"$caller\::Test"}  = \&Test;
    *{"$caller\::Tests"} = \&Tests;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test::Class::Moose::Role - Test::Class::Moose for roles

=head1 VERSION

version 0.88

=head1 DESCRIPTION

If you need the functionality of L<Test::Class::Moose> to be available inside
of a role, this is the module to do that. This is how you can declare a TCM
role:

    package TestsFor::Basic::Role;

    use Test::Class::Moose::Role;

    sub test_in_a_role {
        my $test = shift;

        pass "This is picked up from role";
    }


    sub in_a_role_with_tags : Tags(first){
        fail "We should never see this test";
    }


    sub test_in_a_role_with_tags : Tags(second){
        pass "We should see this test";
    }

    1;

And to consume it:

    package TestsFor::Basic::WithRole;
    use Test::Class::Moose;

    with qw/TestsFor::Basic::Role/;

    sub test_in_withrole {
        pass "Got here";
    }

    1;

Note that this cannot be consumed into classes and magically make them into
test classes. You must still (at the present time) inherit from
C<Test::Class::Moose> to create a test suite.

=head2 Skipping Test::Most

By default, when you C<use Test::Class::Moose::Role> in your own test class, it
exports all the subs from L<Test::Most> into your class. If you'd prefer to
import a different set of test tools, you can pass C<< bare => 1 >> when using
C<Test::Class::Moose::Role>:

 use Test::Class::Moose::Role bare => 1;

 When you pass this, C<Test::Class::Moose::Role> will not export L<Test::Most>'s subs
 into your class. You will have to explicitly import something like
 L<Test::More> or L<Test2::Tools::Compare> in order to actually perform tests.

=for Pod::Coverage Tags Test Tests

=head1 SUPPORT

Bugs may be submitted at L<https://github.com/houseabsolute/test-class-moose/issues>.

I am also usually active on IRC as 'autarch' on C<irc://irc.perl.org>.

=head1 SOURCE

The source code repository for Test-Class-Moose can be found at L<https://github.com/houseabsolute/test-class-moose>.

=head1 AUTHORS

=over 4

=item *

Curtis "Ovid" Poe <ovid@cpan.org>

=item *

Dave Rolsky <autarch@urth.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 - 2017 by Curtis "Ovid" Poe.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

The full text of the license can be found in the
F<LICENSE> file included with this distribution.

=cut
