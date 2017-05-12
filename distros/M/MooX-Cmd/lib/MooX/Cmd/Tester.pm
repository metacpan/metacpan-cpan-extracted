package MooX::Cmd::Tester;

use strict;
use warnings;

our $VERSION = "0.015";

require Exporter;
use Test::More import => ['!pass'];
use Package::Stash;
use Capture::Tiny qw(:all);

use parent qw(Test::Builder::Module Exporter);

our @EXPORT    = qw(test_cmd test_cmd_ok);
our @EXPORT_OK = qw(test_cmd test_cmd_ok);

our $TEST_IN_PROGRESS;
my $CLASS = __PACKAGE__;

BEGIN
{
    *CORE::GLOBAL::exit = sub {
        return CORE::exit(@_) unless $TEST_IN_PROGRESS;
        MooX::Cmd::Tester::Exited->throw( $_[0] );
    };
}

sub result_class { 'MooX::Cmd::Tester::Result' }

sub test_cmd
{
    my ( $app, $argv ) = @_;

    my $result = _run_with_capture( $app, $argv );
    my $exit_code = defined $result->{error} ? ( ( 0 + $! ) || -1 ) : 0;

    $result->{error}
      and eval { $result->{error}->isa('MooX::Cmd::Tester::Exited') }
      and $exit_code = ${ $result->{error} };

    result_class->new(
        {
            exit_code => $exit_code,
            %$result,
        }
    );
}

sub test_cmd_ok
{
    my $rv = test_cmd(@_);

    my $test_ident = $rv->app . " => [ " . join( " ", @{ $_[1] } ) . " ]";
    ok( !$rv->error, "Everythink ok running cmd $test_ident" ) or diag( $rv->error );
    # no error and cmd means, we're reasonable successful so far
    $rv
      and !$rv->error
      and $rv->cmd
      and $rv->cmd->command_name
      and ok( $rv->cmd->command_commands->{ $rv->cmd->command_name }, "found command at $test_ident" );

    $rv;
}

sub _capture_merged(&)
{
    my $code = shift;
    my ( $stdout, $stderr, $merged, $ok );
    if ( $^O eq 'MSWin32' )
    {
        ( $stdout, $stderr, $ok ) = tee { $code->(); };
        $merged = $stdout . $stderr;
    }
    else
    {
        ($merged) = tee_merged
        {
            ( $stdout, $stderr, $ok ) = tee { $code->() };
        };
    }
    ( $stdout, $stderr, $merged, $ok );
}

sub _run_with_capture
{
    my ( $app, $argv ) = @_;

    my ( $execute_rv, $cmd, $cmd_name );

    my ( $stdout, $stderr, $merged, $ok ) = _capture_merged
    {
        eval {
            local $TEST_IN_PROGRESS = 1;
            local @ARGV             = @$argv;

            my $tb = $CLASS->builder();

            $cmd = ref $app ? $app : $app->new_with_cmd;
            ref $app and $app = ref $app;
            my $test_ident = "$app => [ " . join( " ", @$argv ) . " ]";
            ok( $cmd->isa($app), "got a '$app' from new_with_cmd" );
            @$argv
              and defined( $cmd_name = $cmd->command_name )
              and ok( ( grep { $_ =~ m/$cmd_name/ } @$argv ), "proper cmd name from $test_ident" );
            ok( scalar @{ $cmd->command_chain } <= 1 + scalar @$argv, "\$#argv vs. command chain length testing $test_ident" );
            @$argv and ok( $cmd->command_chain_end == $cmd->command_chain->[-1], "command_chain_end ok" );

            unless ( $execute_rv = $cmd->execute_return )
            {
                my ( $command_execute_from_new, $command_execute_method_name );
                my $cce = $cmd->can("command_chain_end");
                $cce                      and $cce                      = $cce->($cmd);
                $cce                      and $command_execute_from_new = $cce->can("command_execute_from_new");
                $command_execute_from_new and $command_execute_from_new = $command_execute_from_new->($cce);
                $command_execute_from_new or $command_execute_method_name = $cce->can('command_execute_method_name');
                $command_execute_method_name
                  and $execute_rv = [ $cce->can( $command_execute_method_name->($cce) )->($cce) ];
            }
            1;
        };
    };

    my $error = $ok ? undef : $@;

    return {
        app        => $app,
        cmd        => $cmd,
        stdout     => $stdout,
        stderr     => $stderr,
        output     => $merged,
        error      => $error,
        execute_rv => $execute_rv,
    };
}

{
    package    # no-index
      MooX::Cmd::Tester::Result;

    sub new
    {
        my ( $class, $arg ) = @_;
        bless $arg => $class;
    }
}

my $res = Package::Stash->new("MooX::Cmd::Tester::Result");
for my $attr (qw(app cmd stdout stderr output error execute_rv exit_code))
{
    $res->add_symbol( '&' . $attr, sub { $_[0]->{$attr} } );
}

{
    package    # no-index
      MooX::Cmd::Tester::Exited;

    sub throw
    {
        my ( $class, $code ) = @_;
        defined $code or $code = 0;
        my $self = ( bless \$code => $class );
        die $self;
    }
}

=head1 NAME

MooX::Cmd::Tester - MooX cli app commands tester

=head1 SYNOPSIS

  use MooX::Cmd::Tester;
  use Test::More;

  use MyFoo;

  # basic tests as instance check, initialization check etc. is done there
  my $rv = test_cmd( MyFoo => [ command(s) option(s) ] );

  like( $rv->stdout, qr/operation successful/, "Command performed" );
  like( $rv->stderr, qr/patient dead/, "Deal with expected command error" );

  is_deeply( $rv->execute_rv, \@expected_return_values, "got what I deserve?" );

  cmp_ok( $rv->exit_code, "==", 0, "Command successful" );

=head1 DESCRIPTION

The test coverage of most CLI apps is somewhere between poor and wretched.
With the same approach as L<App::Cmd::Tester> comes MooX::Cmd::Tester to
ease writing tests for CLI apps.

=head1 FUNCTIONS

=head2 test_cmd

  my $rv = test_cmd( MyApp => \@argv );

test_cmd invokes the app with given argv as if would be invoked from
command line and captures the output, the return values and exit code.

Some minor tests are done to prove whether class matches, execute succeeds,
command_name and command_chain are not totally scrambled.

It returns an object with following attributes/accessors:

=head3 app

Name of package of App

=head3 cmd

Name of executed (1st level) command

=head3 stdout

Content of stdout

=head3 stderr

Content of stderr

=head3 output

Content of merged stdout and stderr

=head3 error

the exception thrown by running the application (if any)

=head3 execute_rv

return values from execute

=head3 exit_code

0 on success, $! when error occurred and $! available, -1 otherwise

=head2 test_cmd_ok

  my $rv = test_cmd_ok( MyApp => \@argv );

Runs C<test_cmd> and expects it being successful - command_name must be in
command_commands, etc.

Returns the same object C<test_cmd> returns.

If an error occurred, no additional test is done (behavior as C<test_cmd>).

=head2 result_class

Builder for result class to use. Returns C<MooX::Cmd::Tester::Result> by
default.

=head1 ACKNOWLEDGEMENTS

MooX::Cmd::Tester is I<inspired> by L<App::Cmd::Tester> from Ricardo Signes.
In fact, I reused the entire design and adopt it to the requirements of
MooX::Cmd.

=head1 LICENSE AND COPYRIGHT

Copyright 2013-2015 Jens Rehsack.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.

=cut

1;
