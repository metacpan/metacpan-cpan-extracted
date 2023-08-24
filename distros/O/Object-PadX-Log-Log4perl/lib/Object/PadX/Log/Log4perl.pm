package Object::PadX::Log::Log4perl;
our $VERSION = '0.001';
use v5.26;
use Object::Pad;

# ABSTRACT: A logger role for Object::Pad based classes based on Log::Log4perl

role Object::PadX::Log::Log4perl;
use Log::Log4perl;

field $logger;

method logger {
  return $logger if $logger;
  $logger = Log::Log4perl->get_logger(ref($self));
  return $logger;
}

method log {
  my $cat = shift;
  if ($cat && $cat =~ m/^(\.|::)/) {
    return Log::Log4perl->get_logger(ref($self) . $cat);
  }
  elsif ($cat) {
    return Log::Log4perl->get_logger($cat);
  }
  else {
    return $self->logger;
  }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Object::PadX::Log::Log4perl - A logger role for Object::Pad based classes based on Log::Log4perl

=head1 VERSION

version 0.001

=head1 SYNOPSIS

    package MyClass;
    use v5.26;
    use Object::Pad;

    class MyClass :does(Object::PadX::Log::Log4perl)

    method foo {
        $self->log->info("Foo called");
    }

=head1 DESCRIPTION

A logging role building a very lightweight wrapper to L<Log::Log4perl> for use
with your L<Object::Pad> classes. The initialization of the Log4perl instance
must be performed prior to logging the first log message.  Otherwise the
default initialization will happen, probably not doing the things you expect.

The logger needs to be setup before using the logger, which could happen in the
main application:

    package main;
    use Log::Log4perl qw(:easy);
    use MyClass;

    BEGIN { Log::Log4perl->easy_init() }

    my $myclass = MyClass->new();
    $myclass->log->info("In my class");    # Access the log of the object
    $myclass->dummy;                       # Will log "Dummy log entry"

Using the logger within a class is as simple as consuming a role:

=head1 METHODS

=head2 logger

The C<logger> attribute holds the L<Log::Log4perl> object that implements all
logging methods for the defined log levels, such as C<debug> or C<error>.

=head2 log

Basically the same as logger, but also allowing to change the log category for
this log message.

    if ($myapp->log->is_debug()) {
      $myapp->log->debug("Woot");            # category is class myapp
    }

    $myapp->log("FooBar")->info("Foobar");   # category FooBar
    $myapp->log->info("Yihaa");              # category class again myapp
    $myapp->log(".FooBar")->info("Foobar");  # category myapp.FooBar
    $myapp->log("::FooBar")->info("Foobar"); # category myapp.FooBar

=head1 PRIOR ART

This code has been mostly ported/inspired from L<MooseX::Log::Log4perl>.
Copyright (c) 2008-2016, Roland Lammel <lammel@cpan.org>, http://www.quikit.at

=head1 AUTHOR

Wesley Schwengle <waterkip@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by Wesley Schwengle.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
