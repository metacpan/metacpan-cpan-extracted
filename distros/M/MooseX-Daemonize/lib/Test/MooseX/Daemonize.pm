use strict;
use warnings;
package Test::MooseX::Daemonize;
# ABSTRACT: Tool to help test MooseX::Daemonize applications

our $VERSION = '0.21';

# BEGIN CARGO CULTING
use Sub::Exporter -setup => {
    exports => [ qw(daemonize_ok check_test_output) ],
    groups  => { default => [ qw(daemonize_ok check_test_output) ] },
};

use Test::Builder;

our $Test = Test::Builder->new;

sub daemonize_ok {
    my ( $daemon, $msg ) = @_;
    unless ( my $pid = fork ) {
        $daemon->start();
        exit;
    }
    else {
        sleep(1);    # Punt on sleep time, 1 seconds should be enough
        $Test->ok( $daemon->pidfile->does_file_exist, $msg )
          || $Test->diag(
            'Pidfile (' . $daemon->pidfile->file . ') not found.' );
    }
}

sub check_test_output {
    my ($app) = @_;
    open( my $stdout_in, '<', $app->test_output )
      or die "can't open test output: $!";
    while ( my $line = <$stdout_in> ) {
        $line =~ s/\s+\z//;
        my $label;
        if ( $line =~ /\A(?:(not\s+)?ok)(?:\s+-)(?:\s+(.*))\z/ ) {
            my ( $not, $text ) = ( $1, $2, $3 );
            $text ||= '';

           # We don't just call ok(!$not), because that generates diagnostics of
           # its own for failures. We only want the diagnostics from the child.
            my $orig_no_diag = $Test->no_diag;
            $Test->no_diag(1);
            $Test->ok(!$not, $text);
            $Test->no_diag($orig_no_diag);
        }
        elsif ( $line =~ s/\A#\s?// ) {
            $Test->diag($line);
        }
        else {
            $Test->diag("$label: $line (unrecognised)\n");
        }
    }
}

package # hide from PAUSE
    Test::MooseX::Daemonize::Testable;

use Moose::Role;

has test_output => (
    isa      => 'Str',
    is       => 'ro',
    required => 1,
);

after daemonize => sub {
    $Test->use_numbers(0);
    $Test->no_ending(1);
    open my $out, '>', $_[0]->test_output or die "Cannot open test output: $!";
    my $fileno = fileno $out;
    open STDERR, ">&=", $fileno
      or die "Can't redirect STDERR";

    open STDOUT, ">&=", $fileno
      or die "Can't redirect STDOUT";

    $Test->output($out);
    $Test->failure_output($out);
    $Test->todo_output($out);
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test::MooseX::Daemonize - Tool to help test MooseX::Daemonize applications

=head1 VERSION

version 0.21

=head1 SYNOPSIS

    use File::Spec::Functions;
    use File::Temp qw(tempdir);

    my $dir = tempdir( CLEANUP => 1 );

    ## Try to make sure we are in the test directory

    my $file = catfile( $dir, "im_alive" );
    my $daemon = FileMaker->new( pidbase => $dir, filename => $file );

    daemonize_ok( $daemon, 'child forked okay' );
    ok( -e $file, "$file exists" );

=head1 DESCRIPTION

This module provides some basic L<Test::Builder>-compatible test methods to
use when writing tests for your L<MooseX::Daemonize>-based modules.

=head1 EXPORTED FUNCTIONS

=over 4

=item B<daemonize_ok ( $daemon, ?$msg )>

This will attempt to daemonize your C<$daemon> returning ok on
success and not ok on failure.

=item B<check_test_output ( $daemon )>

This is expected to be used with a C<$daemon> which does the
B<Test::MooseX::Daemonize::Testable> role (included in this package --
see the source for more info). It will collect the test output
from your daemon and apply it in the parent process by mucking
around with L<Test::Builder> stuff, again, read the source for
more info. If we get time we will document this more thoroughly.

=back

=head1 SEE ALSO

L<MooseX::Daemonize>

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
