use 5.008;
use strict;
use warnings;

package Test::Class::GetoptControl;
our $VERSION = '1.100860';
# ABSTRACT: Command-line control of test class execution
use List::Util 'shuffle';
use Test::More;
use Test::Class;
use parent 'Getopt::Inherited';
use constant GETOPT => qw(
  include|i=s@ shuffle reverse
);

sub runtests {
    my $self    = shift;
    my @classes = $self->get_classes;
    if (@classes) {
        Test::Class->runtests(@classes);
    } else {
        diag 'No class meets the specification';
    }
}

sub get_classes {
    my $self      = shift;
    my $test_info = Test::Class->_test_info;
    my @classes   = keys %$test_info;

    # first, if --include is given, filter out classes that aren't included
    my @include = @{ $self->opt('include') || [] };
    if (@include) {
        my %keep;
        for my $class (@classes) {
            for (@include) {
                $keep{$class}++ if index($class, $_) != -1;
            }
        }
        @classes = keys %keep;
    }

    # now determine test class order
    if ($self->opt('shuffle')) {
        note '--shuffle takes precedence over --reverse'
          if $self->opt('reverse');
        note 'test order: shuffle';
        @classes = shuffle @classes;
    } elsif ($self->opt('reverse')) {
        note 'test order: reverse';
        @classes = reverse sort @classes;
    } else {
        note 'test order: sort';
        @classes = sort @classes;

        # Perl::Critic complains about "return sort ... "
    }
    @classes;
}
1;


__END__
=pod

=for stopwords GETOPT runtests

=for test_synopsis 1;
__END__

=head1 NAME

Test::Class::GetoptControl - Command-line control of test class execution

=head1 VERSION

version 1.100860

=head1 SYNOPSIS

    package MyApp;
    use base qw(Test::Class::GetoptControl);

    package main;
    my $app = MyApp->new;
    $app->runtests;

on the command-line:

    $ myapp --include FooTests --shuffle
    # test order: shuffle
    ok 1 - foobar

=head1 DESCRIPTION

When inheriting from this class, your application gets the ability to control
the execution of test classes using command-line options.

=head1 METHODS

=head2 runtests

Calls C<get_classes()> to determine which test classes to run and in which
order, then runs them.

=head2 get_classes

Asks L<Test::Class> for information on all registered test classes, then
filters and sorts them by the criteria set in the command-line options.

=head2 GETOPT

Defines the specific command-line options for this class; see
L<Getopt::Inherited>.

=head1 COMMAND-LINE OPTIONS

=over 4

=item C<--include>

This option takes a string and can be given several times. It says that only
classes whose package name contains the string should be run. C<-i> is an
alias for this option. If no C<include> option is given, all test classes are
run.

Examples:

    $ myapp --include Foo
    $ myapp -i Foo
    $ myapp --include Foo --include Bar

=item C<--shuffle>

This options causes the test classes to be run in a random order. A note
saying so is printed as well.

=item C<--reverse>

This options causes the test classes to be run in reverse alphabetical package
name order. If neither C<--reverse> nor C<--shuffle> are given, tests are run
in alphabetical package name order. If both C<--reverse> and C<--shuffle> are
given, C<--shuffle> takes precedence and a note saying so is printed.

In any case, a note specifying the sort order is printed.

=back

=head1 INSTALLATION

See perlmodinstall for information and options on installing Perl modules.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests through the web interface at
L<http://rt.cpan.org/Public/Dist/Display.html?Name=Test-Class-GetoptControl>.

=head1 AVAILABILITY

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit L<http://www.perl.com/CPAN/> to find a CPAN
site near you, or see
L<http://search.cpan.org/dist/Test-Class-GetoptControl/>.

The development version lives at
L<http://github.com/hanekomu/Test-Class-GetoptControl/>.
Instead of sending patches, please fork this project using the standard git
and github infrastructure.

=head1 AUTHOR

  Marcel Gruenauer <marcel@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2009 by Marcel Gruenauer.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

