use strict;
use warnings;
package MooseX::Daemonize::Pid;
# ABSTRACT: PID management for MooseX::Daemonize

our $VERSION = '0.21';

use Moose;
use Moose::Util::TypeConstraints qw(coerce from via);
use namespace::autoclean;

coerce 'MooseX::Daemonize::Pid'
    => from 'Int'
        => via { MooseX::Daemonize::Pid->new( pid => $_ ) };


has 'pid' => (
    is        => 'rw',
    isa       => 'Int',
    lazy      => 1,
    clearer   => 'clear_pid',
    predicate => 'has_pid',
    default   => sub { $$ }
);

sub is_running { kill(0, (shift)->pid) ? 1 : 0 }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MooseX::Daemonize::Pid - PID management for MooseX::Daemonize

=head1 VERSION

version 0.21

=head1 DESCRIPTION

This is a very basic Pid management object, it doesn't do all that
much, and mostly just serves as a base class for L<MooseX::Daemonize::Pid::File>.

=head1 ATTRIBUTES

=over 4

=item I<pid Int>

=back

=head1 METHODS

=over 4

=item B<clear_pid>

This will clear the value of the I<pid> attribute. It is useful for making sure
that the parent process does not have a bad value stored in it.

=item B<has_pid>

This is a predicate method to tell you if your I<pid> attribute has
been initialized yet.

=item B<is_running>

This checks to see if the I<pid> is running.

=item meta()

The C<meta()> method from L<Class::MOP::Class>

=back

=head1 SUPPORT

Bugs may be submitted through L<the RT bug tracker|https://rt.cpan.org/Public/Dist/Display.html?Name=MooseX-Daemonize>
(or L<bug-MooseX-Daemonize@rt.cpan.org|mailto:bug-MooseX-Daemonize@rt.cpan.org>).

There is also a mailing list available for users of this distribution, at
L<http://lists.perl.org/list/moose.html>.

There is also an irc channel available for users of this distribution, at
L<C<#moose> on C<irc.perl.org>|irc://irc.perl.org/#moose>.

=head1 AUTHORS

=over 4

=item *

Stevan Little <stevan.little@iinteractive.com>

=item *

Chris Prather <chris@prather.org>

=back

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2007 by Chris Prather.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
