package SmokeRunner::Multi;
our $AUTHORITY = 'cpan:YANICK';
#ABSTRACT: Manage smoke tests across multiple branches/checkouts/projects
$SmokeRunner::Multi::VERSION = '0.21';
use strict;
use warnings;

use SmokeRunner::Multi::Config;
use SmokeRunner::Multi::TestSet;


sub new
{
    my $class = shift;

    return bless {}, $class;
}

sub next_set
{
    return ( SmokeRunner::Multi::TestSet->All() )[0];
}

sub run_and_report_next_set
{
    my $self = shift;

    my $set = $self->next_set()
        or return;

    my $runner = $self->make_runner( set => $set );

    $set->update_files();

    # Running the tests could take a while, during which time the set
    # might change in version control.
    my $time = time;
    $runner->run_tests();

    my $reporter = $self->make_reporter( runner => $runner );

    $reporter->report();

    $set->update_last_run_time($time);
    $set->unprioritize();

    return $reporter;
}

sub make_runner
{
    my $self = shift;

    return
        $self->_class_for
            ( 'Runner',
              SmokeRunner::Multi::Config->instance()->runner() )
                ->new(@_);
}

sub make_reporter
{
    my $self = shift;

    return
        $self->_class_for
            ( 'Reporter',
              SmokeRunner::Multi::Config->instance()->reporter() )
                ->new(@_);
}

sub _class_for
{
    my $self = shift;
    my $type = shift;
    my $name = shift;

    die "No config for \L$type\n"
        unless defined $name;

    my $full_class = $name =~ /::/ ? $name : join '::', __PACKAGE__, $type, $name;

    return $full_class if $full_class->can('new');

    eval "use $full_class";
    die $@ if $@;

    return $full_class;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SmokeRunner::Multi - Manage smoke tests across multiple branches/checkouts/projects

=head1 VERSION

version 0.21

=head1 SYNOPSIS

  use SmokeRunner::Multi;

  my $runner = SmokeRunner::Multi->new();

  $runner->run_and_report_next_set();

=head1 DESCRIPTION

This distribution was created to help manage the running of automated
tests across multiple branches or checkouts.

Each branch is called a "test set", and sets are ordered based on
various criteria.  This class provide a high-level interface for
getting the next set, running its tests, and reporting on them.

Also see the F<smokerunner-multi> script that comes with this
distribution.

=head1 METHODS/FUNCTIONS

This class provides the following methods:

=head2 SmokeRunner::Multi->new()

Creates a new object.

=head2 $smoker->next_set()

Returns the next test set to be run.

=head2 $smoker->run_and_report_next_set()

This is a convenience method that can be used to run and report on the
next test set in a single step.

As a convenience (mostly for testing), it returns the reporter object
it creates internally.

=head2 $smoker->make_runner( ... )

This is a convenience method for making a
C<SmokeRunner::Multi::Runner> object of the class specified in the
config file. Any parameters passed to this method will be passed on to
the Runner class's constructor.

=head2 $smoker->make_reporter( ... )

This is a convenience method for making a
C<SmokeReporter::Multi::Reporter> object of the class specified in the
config file. Any parameters passed to this method will be passed on to
the Reporter class's constructor.

=head1 CONFIGURATION

See L<SmokeRunner::Multi::Config> for details on configuring the smoke
runner. You need to create a minimal config file to do much of
anything.

=head1 SEE ALSO

See the other classes in this distribution for more information:
L<SmokeRunner::Multi::TestSet>, L<SmokeRunner::Multi::Runner>,
L<SmokeRunner::Multi::Reporter>, and L<SmokeRunner::Multi::Config>.

=head1 AUTHORS

=over 4

=item *

Dave Rolsky <autarch@urth.org>

=item *

Yanick Champoux <yanick@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2007 by LiveText, Inc..

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
