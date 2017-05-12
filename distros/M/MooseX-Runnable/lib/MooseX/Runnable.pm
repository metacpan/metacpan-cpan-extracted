package MooseX::Runnable; # git description: v0.09-13-gb2ccf60
# ABSTRACT: Tag a class as a runnable application
# KEYWORDS: moose extension executable execute script binary run modulino

our $VERSION = '0.10';

use Moose::Role;
use namespace::autoclean;

requires 'run';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MooseX::Runnable - Tag a class as a runnable application

=head1 VERSION

version 0.10

=head1 SYNOPSIS

Create a class, tag it runnable, and provide a C<run> method:

    package App::HelloWorld;
    use feature 'say';
    use Moose;

    with 'MooseX::Runnable';

    sub run {
       my ($self,$name) = @_;
       say "Hello, $name.";
       return 0; # success
    }

Then you can run this class as an application with the included
C<mx-run> script:

    $ mx-run App::HelloWorld jrockway
    Hello, jrockway.
    $

C<MooseX::Runnable> supports L<MooseX::Getopt|MooseX::Getopt>, and
other similar systems (and is extensible, in case you have written
such a system).

=head1 DESCRIPTION

MooseX::Runnable is a framework for making classes runnable
applications.  This role doesn't do anything other than tell the rest
of the framework that your class is a runnable application that has a
C<run> method which accepts arguments and returns the process' exit
code.

This is a convention that the community has been using for a while.
This role tells the computer that your class uses this convention, and
let's the computer abstract away some of the tedium this entails.

=head1 REQUIRED METHODS

=head2 run

Your class must implement C<run>.  It accepts the command-line args
(that were not consumed by another parser, if applicable) and returns
an integer representing the UNIX exit value.  C<return 0> means
success.

=head1 THINGS YOU GET

=head2 C<mx-run>

This is a script that accepts a C<MooseX::Runnable> class and tries to
run it, using C<MooseX::Runnable::Run>.

The syntax is:

  mx-run Class::Name

  mx-run <args for mx-run> -- Class::Name <args for Class::Name>

for example:

  mx-run -Ilib App::HelloWorld --args --go --here

or:

  mx-run -Ilib +Persistent --port 8080 -- App::HelloWorld --args --go --here

=head2 C<MooseX::Runnable::Run>

If you don't want to invoke your app with C<mx-run>, you can write a
custom version using L<MooseX::Runnable::Run|MooseX::Runnable::Run>.

=head1 ARCHITECTURE

C<MX::Runnable> is designed to be extensible; users can run plugins
from the command-line, and application developers can add roles to
their class to control behavior.

For example, if you consume L<MooseX::Getopt|MooseX::Getopt>, the
command-line will be parsed with C<MooseX::Getopt>.  Any recognized
args will be used to instantiate your class, and any extra args will
be passed to C<run>.

=head1 CAVEATS

Many of the plugins shipped are unstable; they may go away, change,
break, etc.  If there is no documentation for a plugin, it is probably
just a prototype.

=head1 SUPPORT

Bugs may be submitted through L<the RT bug tracker|https://rt.cpan.org/Public/Dist/Display.html?Name=MooseX-Runnable>
(or L<bug-MooseX-Runnable@rt.cpan.org|mailto:bug-MooseX-Runnable@rt.cpan.org>).

There is also a mailing list available for users of this distribution, at
L<http://lists.perl.org/list/moose.html>.

There is also an irc channel available for users of this distribution, at
L<C<#moose> on C<irc.perl.org>|irc://irc.perl.org/#moose>.

=head1 AUTHOR

Jonathan Rockway <jrockway@cpan.org>

=head1 CONTRIBUTORS

=for stopwords Jonathan Rockway Karen Etheridge Doug Bell Duke Leto

=over 4

=item *

Jonathan Rockway <jon@jrock.us>

=item *

Karen Etheridge <ether@cpan.org>

=item *

Doug Bell <doug.bell@baml.com>

=item *

Duke Leto <jonathan@leto.net>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2009 by Jonathan Rockway.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
