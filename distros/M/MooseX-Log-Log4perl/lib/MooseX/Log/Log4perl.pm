package MooseX::Log::Log4perl;

use 5.008;
use Moo::Role;
use Log::Log4perl;

our $VERSION = '0.47';

has 'logger' => (
    is      => 'rw',
    lazy    => 1,
    default => sub { return Log::Log4perl->get_logger(ref($_[0])) }
);

sub log {
    my $self = shift;
    my $cat = shift;
    if ($cat && $cat =~ m/^(\.|::)/) {
        return Log::Log4perl->get_logger(ref($self) . $cat);
    } elsif($cat)  {
        return Log::Log4perl->get_logger($cat);
    } else {
        return $self->logger;
    }
}

1;

__END__

=head1 NAME

MooseX::Log::Log4perl - A Logging Role for Moose based on Log::Log4perl

=head1 SYNOPSIS

    package MyApp;
    use Moose;

    with 'MooseX::Log::Log4perl';

    sub something {
        my ($self) = @_;
        $self->log->debug("started bar");    ### logs with default class catergory "MyApp"
        ...
        $self->log('special')->info('bar');  ### logs with category "special"
        ...
        $self->log('.special')->info('bar'); ### logs with category "MyApp.special"
        $self->log('::special')->info('bar');### logs with category "MyApp.special"
    }

=head1 DESCRIPTION

A logging role building a very lightweight wrapper to L<Log::Log4perl> for use with your L<Moose> or L<Moo> classes.
The initialization of the Log4perl instance must be performed prior to logging the first log message.
Otherwise the default initialization will happen, probably not doing the things you expect.

For compatibility the C<logger> attribute can be accessed to use a common interface for application logging.

Using the logger within a class is as simple as consuming a role:

    package MyClass;
    use Moose;
    with 'MooseX::Log::Log4perl';

    sub dummy {
        my $self = shift;
        $self->log->info("Dummy log entry");
    }

The logger needs to be setup before using the logger, which could happen in the main application:

    package main;
    use Log::Log4perl qw(:easy);
    use MyClass;

    BEGIN { Log::Log4perl->easy_init() };

    my $myclass = MyClass->new();
    $myclass->log->info("In my class"); # Access the log of the object
    $myclass->dummy;                    # Will log "Dummy log entry"

=head1 EVEN SIMPLER USE

For simple logging needs use L<MooseX::Log::Log4perl::Easy> to directly add log_<level> methods to your class
instance.

    $self->log_info("Dummy");


=head1 USING WITH MOO INSTEAD OF MOOSE

As this module is using L<Moo>, you can use it with Moo instead of Moose too.

This will allow to simple use it as documented above in a Moo based application, like shown in the example below:

This is your class consuming the MooseX::Log::Log4perl role.

    package MyCat;
    use Moo;

    with 'MooseX::Log::Log4perl';

    sub catch_it {
        my $self = shift;
        $self->log->debug("Say Miau");
    }

Which can be simply used in your main application then.

    package main;
    use MyCat;
    use Log::Log4perl qw(:easy);
    BEGIN { Log::Log4perl->easy_init() };

    my $log = Log::Log4perl->get_logger();
    $log->info("Application startup...");
    MyCat->new()->catch_it();   ### Will log "Dummy dodo"


=head1 ACCESSORS

=head2 logger

The C<logger> attribute holds the L<Log::Log4perl> object that implements all logging methods for the
defined log levels, such as C<debug> or C<error>. As this method is defined also in other logging
roles/systems like L<MooseX::Log::LogDispatch> this can be thought of as a common logging interface.

  package MyApp::View::JSON;

  extends 'MyApp::View';
  with 'MooseX:Log::Log4perl';

  sub bar {
    $self->logger->info("Everything fine so far");    # logs a info message
    $self->logger->debug("Something is fishy here");  # logs a debug message
  }


=head2 log([$category])

Basically the same as logger, but also allowing to change the log category
for this log message. If the category starts with a C<+>, we pre-pend the current
class (what would have been the category if you didn't specify one).

 if ($myapp->log->is_debug()) {
     $myapp->log->debug("Woot"); # category is class myapp
 }
 $myapp->log("TempCat")->info("Foobar"); # category TempCat
 $myapp->log->info("Grumble"); # category class again myapp
 $myapp->log(".TempCat")->info("Foobar"); # category myapp.TempCat
 $myapp->log("::TempCat")->info("Foobar"); # category myapp.TempCat

=head1 SEE ALSO

L<Log::Log4perl>, L<Moose>, L<Moo>, L<MooX::Log::Any>, L<MooX::Role::Logger>

=head1 BUGS AND LIMITATIONS

Please report any issues at L<https://github.com/lammel/moosex-log-log4perl>

Or come bother us in C<#moose> on C<irc.perl.org>.

=head1 AUTHOR

Roland Lammel L<< <lammel@cpan.org> >>

Inspired by the work by Chris Prather L<< <perigrin@cpan.org> >> and Ash
Berlin L<< <ash@cpan.org> >> on L<MooseX::LogDispatch>

=head1 CONTRIBUTORS

In alphabetical order:

=over 2

=item * abraxxa for Any::Moose deprectation

=item * Michael Schilli <m@perlmeister.com> for L<Log::Log4perl> and interface suggestions

=item * omega for catgory prefix support

=item * Tim Bunce <TIMB@cpan.org> for corrections in the L<MooseX::Log::Log4perl::Easy> module.

=back

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2008-2016, Roland Lammel L<< <lammel@cpan.org> >>, L<http://www.quikit.at>

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.
