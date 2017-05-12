use strict;
use warnings;

package MooX::Role::Logger;
# ABSTRACT: Provide logging via Log::Any
our $VERSION = '0.005'; # VERSION

use Moo::Role;

use Log::Any ();

#pod =method _logger
#pod
#pod Returns a logging object.  See L<Log::Any> for a list of logging methods it accepts.
#pod
#pod =cut

has _logger => (
    is       => 'lazy',
    isa      => sub { ref( $_[0] ) =~ /^Log::Any/ }, # XXX too many options
    init_arg => undef,
);

sub _build__logger {
    my ($self) = @_;
    return Log::Any->get_logger( category => "" . $self->_logger_category );
}

has _logger_category => ( is => 'lazy', );

#pod =method _build__logger_category
#pod
#pod Override to set the category used for logging.  Defaults to the class name of
#pod the object (which could be a subclass).  You can override to lock it to a
#pod particular name:
#pod
#pod     sub _build__logger_category { __PACKAGE__ }
#pod
#pod =cut

sub _build__logger_category { return ref $_[0] }

1;


# vim: ts=4 sts=4 sw=4 et:

__END__

=pod

=encoding UTF-8

=head1 NAME

MooX::Role::Logger - Provide logging via Log::Any

=head1 VERSION

version 0.005

=head1 SYNOPSIS

In your modules:

    package MyModule;
    use Moose;
    with 'MooX::Role::Logger';

    sub run {
        my ($self) = @_;
        $self->cry;
    }

    sub cry {
        my ($self) = @_;
        $self->_logger->info("I'm sad");
    }

In your application:

    use MyModule;
    use Log::Any::Adapter ('File', '/path/to/file.log');

    MyModule->run;

=head1 DESCRIPTION

This role provides universal logging via L<Log::Any>.  The class using this
role doesn't need to know or care about the details of log configuration,
implementation or destination.

Use it when you want your module to offer logging capabilities, but don't know
who is going to use your module or what kind of logging they will implement.
This role lets you do your part and leaves actual log setup and routing to
someone else.

The application that ultimately uses your module can then choose to direct log
messages somewhere based on its own needs and configuration with
L<Log::Any::Adapter>.

This role is based on L<Moo> so it should work with either L<Moo> or L<Moose>
based classes.

=head1 USAGE

=head2 Testing

Testing with L<Log::Any> is pretty easy, thanks to L<Log::Any::Test>.
Just load that before L<Log::Any> loads and your log messages get
sent to a test adapter that includes testing methods:

    use Test::More 0.96;
    use Log::Any::Test;
    use Log::Any qw/$log/;

    use lib 't/lib';
    use MyModule;

    MyModule->new->cry;
    $log->contains_ok( qr/I'm sad/, "got log message" );

    done_testing;

=head2 Customizing

If you have a whole set of classes that should log with a single category,
create your own role and set the C<_build__logger_category> there:

    package MyLibrary::Role::Logger;
    use Moo::Role;
    with 'MooX::Role::Logger';

    sub _build__logger_category { "MyLibrary" }

Then in your other classes, use your custom role:

    package MyLibrary::Foo;
    use Moo;
    with 'MyLibrary::Role::Logger'

=head1 METHODS

=head2 _logger

Returns a logging object.  See L<Log::Any> for a list of logging methods it accepts.

=head2 _build__logger_category

Override to set the category used for logging.  Defaults to the class name of
the object (which could be a subclass).  You can override to lock it to a
particular name:

    sub _build__logger_category { __PACKAGE__ }

=head1 SEE ALSO

Since MooX::Role::Logger is universal, you have to use it with one of
several L<Log::Any::Adapter> classes:

=over 4

=item *

L<Log::Any::Adapter::File>

=item *

L<Log::Any::Adapter::Stderr>

=item *

L<Log::Any::Adapter::Stdout>

=item *

L<Log::Any::Adapter::ScreenColoredLevel>

=item *

L<Log::Any::Adapter::Dispatch>

=item *

L<Log::Any::Adapter::Syslog>

=item *

L<Log::Any::Adapter::Log4perl>

=back

These other logging roles are specific to particular logging packages, rather
than being universal:

=over 4

=item *

L<MooseX::LazyLogDispatch>

=item *

L<MooseX::Log::Log4perl>

=item *

L<MooseX::LogDispatch>

=item *

L<MooseX::Role::LogHandler>

=item *

L<MooseX::Role::Loggable> (uses L<Log::Dispatchouli>)

=item *

L<Role::Log::Syslog::Fast>

=back

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/dagolden/MooX-Role-Logger/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/dagolden/MooX-Role-Logger>

  git clone https://github.com/dagolden/MooX-Role-Logger.git

=head1 AUTHOR

David Golden <dagolden@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by David Golden.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
