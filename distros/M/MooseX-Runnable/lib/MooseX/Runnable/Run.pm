use strict;
use warnings;
package MooseX::Runnable::Run;
# ABSTRACT: Run a MooseX::Runnable class as an application

our $VERSION = '0.10';

use MooseX::Runnable::Invocation;
use namespace::autoclean;

sub run_application($;@) {
    my ($app, @args) = @_;

    exit MooseX::Runnable::Invocation->new(
        class => $app,
    )->run(@args);
}

sub run_application_with_plugins($$;@){
    my ($app, $plugins, @args) = @_;
    exit MooseX::Runnable::Invocation->new(
        class => $app,
        plugins => $plugins,
    )->run(@args);
}

sub import {
    my ($class, $app) = @_;

    if($app){
        run_application $app, @ARGV;
    }
    else {
        my $c = caller;
        no strict 'refs';
        *{ $c. '::run_application' } = \&run_application;
        *{ $c. '::run_application_with_plugins' } = \&run_application_with_plugins;
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MooseX::Runnable::Run - Run a MooseX::Runnable class as an application

=head1 VERSION

version 0.10

=head1 SYNOPSIS

Write an app:

   package MyApp;
   use Moose; with 'MooseX::Runnable';
   sub run { say 'Hello, world.'; return 0 } # (UNIX exit code)

Write a wrapper script, C<myapp.pl>.  With sugar:

   #!/usr/bin/env perl
   use MooseX::Runnable::Run 'MyApp';

Or without:

   #!/usr/bin/env perl
   use MooseX::Runnable::Run;

   run_application 'MyApp', @ARGV;

Then, run your app:

   $ ./myapp.pl
   Hello, world.
   $ echo $?
   0

=head1 DESCRIPTION

This is a utility module that runs a L<MooseX::Runnable|MooseX::Runnable> class with
L<MooseX::Runnable::Invocation|MooseX::Runnable::Invocation>.

=head1 SEE ALSO

L<mx-run>, a script that will run MooseX::Runnable apps, saving you
valuable seconds!

L<MooseX::Runnable>

=head1 SUPPORT

Bugs may be submitted through L<the RT bug tracker|https://rt.cpan.org/Public/Dist/Display.html?Name=MooseX-Runnable>
(or L<bug-MooseX-Runnable@rt.cpan.org|mailto:bug-MooseX-Runnable@rt.cpan.org>).

There is also a mailing list available for users of this distribution, at
L<http://lists.perl.org/list/moose.html>.

There is also an irc channel available for users of this distribution, at
L<C<#moose> on C<irc.perl.org>|irc://irc.perl.org/#moose>.

=head1 AUTHOR

Jonathan Rockway <jrockway@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2009 by Jonathan Rockway.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
