package Perl::Critic::Policy::Bangs::ProhibitDebuggingModules;
use strict;
use warnings;

our $VERSION = '1.12';

use List::MoreUtils qw(any);
use Readonly;
use Perl::Critic::Utils qw( :severities );
use base qw(Perl::Critic::Policy);

=head1 NAME

Perl::Critic::Policy::Bangs::ProhibitDebuggingModules - Prohibit loading of debugging modules like Data::Dumper

=head1 DESCRIPTION

This policy prohibits loading common debugging modules like L<Data::Dumper>.

While such modules are incredibly useful during development and debugging,
they should probably not be loaded in production use. If this policy is
violated, it probably means you forgot to remove a C<use Data::Dumper;> line
that you had added when you were debugging.

=head1 CONFIGURATION

The current list of detected debugging modules is:

=over 4

=item * L<Data::Dumper>

=item * L<Data::Printer>

=back

To add more modules that shouldn't be loaded unless you're actively debugging
something, add them in F<.perlcriticrc> using the C<deubgging_modules> option.

=cut

Readonly::Scalar my $DESC => q/Debugging module loaded/;

sub supported_parameters    {
    return (
        {
            name            => 'debugging_modules',
            description     => 'Module names which are considered to be banned debugging modules',
            behavior        => 'string list',
            list_always_present_values => [qw(
                B::Stats

                Carp::Always.*
                Carp::Diagnostics
                Carp::REPL
                Carp::Source::Always
                Carp::Trace

                Data::Dump
                Data::Dump::Filtered
                Data::Dump::Streamer
                Data::Dump::Trace

                Data::Dumper.*

                Data::Printer
                Data::PrettyPrintObjects
                Data::Show
                Data::Skeleton
                Data::TreeDumper

                DDP
                DDS
                Devel::Ditto
                Devel::Dwarn
                Devel::Modlist
                Devel::Monitor
                Devel::StackTrace
                Devel::Trace
                Devel::Unplug
                ) ], # DDP and DDS are shorthand module names
        }
    );
}
sub default_severity        { return $SEVERITY_HIGH }
sub default_themes          { return qw/ bangs maintenance / }
sub applies_to              { return 'PPI::Statement::Include' }

sub violates {
    my ($self, $include, undef) = @_;
    return unless defined $include->type and ($include->type eq 'use' || $include->type eq 'require');
    my $included = $include->module or return;
    my $EXPL = "You've loaded $included, which probably shouldn't be loaded in production";

    my @banned = ( keys %{ $self->{_debugging_modules} } );
    return $self->violation($DESC, $EXPL, $include)
        if (any { $included =~ m/$_/xms } @banned);
    return;
}

=head1 AFFILIATION

This policy is part of L<Perl::Critic::Bangs>.

=head1 AUTHOR

Mike Doherty C<doherty@cpan.org>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2012 Mike Doherty

This library is free software; you can redistribute it and/or modify
it under the terms of the Artistic License 2.0.

=cut

1;
