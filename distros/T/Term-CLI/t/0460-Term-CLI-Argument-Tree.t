#
#!/usr/bin/perl -T
#
# Copyright (c) 2018-2022, Steven Bakker.
# Copyright (c) 2022, Diab Jerius, Smithsonian Astrophysical Observatory
#
# This program is free software; you can redistribute it and/or modify it
# under the same terms as Perl 5.14.0. For more details, see the full text
# of the licenses in the directory LICENSES.
#

use 5.014_001;
use warnings;

use Test::More;

my $TEST_NAME = 'ARGUMENT';

sub Main() {
    if ( ( $::ENV{SKIP_ALL} || $::ENV{"SKIP_$TEST_NAME"} )
        && !$::ENV{"TEST_$TEST_NAME"} )
    {
        plan skip_all => 'skipped because of environment';
    }
    Term_CLI_Argument_Tree_test->runtests();
    exit 0;
}

package Term_CLI_Argument_Tree_test {

    use parent 0.225 qw( Test::Class );

    use Test::More 1.001002;
    use Test::Exception 0.35;
    use FindBin 1.50;
    use Term::CLI::Argument::Tree;
    use Term::CLI::Command;
    use Term::CLI;
    use Term::CLI::L10N;

    my $ARG_NAME = 'test_tree';

    # Untaint the PATH.
    $::ENV{PATH} =
        '/usr/local/bin:/usr/local/sbin:/usr/bin:/bin:/usr/sbin:/sbin';

    sub startup : Test(startup => 1) {
        my $self = shift;

        Term::CLI::L10N->set_language('en');

        $self->{arg} = Term::CLI::Argument::Tree->new(
            name   => $ARG_NAME,
            values => {
                a0 => {
                    b00 => 'c000',
                    b01 => { c010 => 'd' },
                },
                a1 => { b10 => 'c100' },
                a2 => undef,
                a3 => {},
            },
        );

        isa_ok( $self->{arg}, 'Term::CLI::Argument::Tree',
            'Term::CLI::Argument::Tree->new' );

        $self->{cmd} = Term::CLI::Command->new(
            name      => 'test',
            arguments =>
                [ Term::CLI::Argument->new( name => 'first' ), $self->{arg} ],
            callback => sub {
                my ( $self, %attr ) = @_;
                return %attr;
            },
        );
        $self->{cli} = Term::CLI->new(
            commands => [ $self->{cmd} ],

            # do nothing call back. default callback emits
            # errors which messes up our output.
            callback => sub { shift; return @_ }
        );

        return;
    }

    sub check_constructor : Test(1) {
        my $self = shift;

        throws_ok { Term::CLI::Argument::Tree->new( name => $ARG_NAME ) }
        qr/Missing required arguments: values/, 'error on missing value_list';
        return;
    }

    sub check_attributes : Test(2) {
        my $self = shift;
        my $arg  = $self->{arg};
        is( $arg->name, $ARG_NAME, "name attribute is $ARG_NAME" );
        is( $arg->type, 'Tree',    "type attribute is Tree" );
        return;
    }

    sub check_complete : Test(4) {
        my $self = shift;
        my $cli  = $self->{cli};

        my $mkline = sub { 'test first' . $_[0], index( $_[1], '^' ) + 10 };

        subtest '1st element' => sub {

            subtest 'empty' => sub {
                my ( $line, $idx ) = $mkline->(
                    ' ',    #
                    '^'
                );
                is_deeply( [ $cli->complete_line( '', $line, $idx ) ],
                    [ 'a0', 'a1', 'a2', 'a3' ], qq/"$line"/, );
            };

            subtest 'partial' => sub {
                my ( $line, $idx ) = $mkline->(
                    ' a',    #
                    '^'
                );
                is_deeply( [ $cli->complete_line( 'a', $line, $idx ) ],
                    [ 'a0', 'a1', 'a2', 'a3' ], qq/"$line"/, );
            };

            subtest 'full' => sub {
                my ( $line, $idx ) = $mkline->(
                    ' a0',    #
                    '^'
                );
                is_deeply( [ $cli->complete_line( 'a0', $line, $idx ) ],
                    ['a0'], qq/"$line"/, );
            };

            subtest 'invalid' => sub {
                my ( $line, $idx ) = $mkline->(
                    ' b',     #
                    '^'
                );
                is_deeply( [ $cli->complete_line( 'b', $line, $idx ) ],
                    [], qq/"$line"/, );
            };
        };

        subtest '2nd element' => sub {

            subtest 'empty' => sub {
                my ( $line, $idx ) = $mkline->(
                    ' a0 ',    #
                    '    ^'
                );
                is_deeply( [ $cli->complete_line( '', $line, $idx ) ],
                    [ 'b00', 'b01' ], qq/"$line"/, );
            };

            subtest 'partial' => sub {
                my ( $line, $idx ) = $mkline->(
                    ' a0 b',    #
                    '    ^'
                );
                is_deeply( [ $cli->complete_line( 'b', $line, $idx ) ],
                    [ 'b00', 'b01' ], qq/"$line"/, );
            };

            subtest 'full' => sub {
                my ( $line, $idx ) = $mkline->(
                    ' a0 b00',    #
                    '    ^'
                );
                is_deeply( [ $cli->complete_line( 'b00', $line, $idx ) ],
                    ['b00'], qq/"$line"/, );
            };

            subtest 'invalid' => sub {
                my ( $line, $idx ) = $mkline->(
                    ' a0 c',      #
                    '    ^'
                );
                is_deeply( [ $cli->complete_line( 'c', $line, $idx ) ],
                    [], qq/"$line"/, );
            };

        };

        subtest '3rd element' => sub {

            subtest 'empty' => sub {
                my ( $line, $idx ) = $mkline->(
                    ' a0 b01',    #
                    '       ^'
                );
                is_deeply( [ $cli->complete_line( '', $line, $idx ) ],
                    ['c010'], qq/"$line"/, );
            };

            subtest 'partial' => sub {
                my ( $line, $idx ) = $mkline->(
                    ' a0 b01 c',    #
                    '        ^'
                );
                is_deeply( [ $cli->complete_line( 'c', $line, $idx ) ],
                    ['c010'], qq/"$line"/, );
            };

            subtest 'full' => sub {
                my ( $line, $idx ) = $mkline->(
                    ' a0 b01 c010',    #
                    '        ^'
                );
                is_deeply( [ $cli->complete_line( 'c010', $line, $idx ) ],
                    ['c010'], qq/"$line"/, );
            };

            subtest 'invalid' => sub {
                my ( $line, $idx ) = $mkline->(
                    ' a0 b01 d',       #
                    '        ^'
                );
                is_deeply( [ $cli->complete_line( 'd', $line, $idx ) ],
                    [], qq/"$line"/, );
            };

        };

        subtest 'terminal leaf' => sub {

            subtest 'leaf is undef' => sub {
                my ( $line, $idx ) = $mkline->(
                    ' a2',    #
                    '   ^'
                );
                is_deeply( [ $cli->complete_line( '', $line, $idx ) ],
                    [], qq/"$line"/, );
            };

            subtest 'leaf is string' => sub {
                my ( $line, $idx ) = $mkline->(
                    ' a0 b01 c010 ',    #
                    '             ^'
                );
                is_deeply( [ $cli->complete_line( '', $line, $idx ) ],
                    ['d'], qq/"$line"/, );
            };

            subtest 'leaf is empty hash' => sub {
                my ( $line, $idx ) = $mkline->(
                    ' a3 ',             #
                    '    ^'
                );
                is_deeply( [ $cli->complete_line( '', $line, $idx ) ],
                    [], qq/"$line"/, );
            };

        };

        return;
    }

    sub check_validate : Test(10) {
        my $self = shift;
        my $cli  = $self->{cli};

        my $mkline = sub { 'test first' . $_[0] };

        subtest '1st element' => sub {

            subtest 'empty' => sub {
                my $command_line = $mkline->('');
                my %args         = $cli->execute_line($command_line);
                is( $args{status}, -1, "execute failed" );
                like( $args{error}, qr/need at least .*test_tree/, 'error' );
            };

            subtest 'partial/invalid' => sub {
                my $command_line = $mkline->(' a');
                my %args         = $cli->execute_line($command_line);
                is( $args{status}, -1, "execute failed" );
                like( $args{error}, qr/not in hierarchy/, 'error' );
            };

            subtest 'full' => sub {
                my $command_line = $mkline->(' a0');
                my %args         = $cli->execute_line($command_line);
                is( $args{status}, 0, "execute succeeded" )
                    or diag("got error: $args{error}");
            };
        };

        subtest '2nd element' => sub {

            subtest 'partial/invalid' => sub {
                my $command_line = $mkline->(' a0 b');
                my %args         = $cli->execute_line($command_line);
                is( $args{status}, -1, "execute failed" );
                like( $args{error}, qr/not in hierarchy/, 'error' );
            };

            subtest 'full' => sub {
                my $command_line = $mkline->(' a0 b00');
                my %args         = $cli->execute_line($command_line);
                is( $args{status}, 0, "execute succeeded" )
                    or diag("got error: $args{error}");
            };

        };

        subtest '3rd element' => sub {

            subtest 'partial/invalid' => sub {
                my $command_line = $mkline->(' a0 b01 c');
                my %args         = $cli->execute_line($command_line);
                is( $args{status}, -1, "execute failed" );
                like( $args{error}, qr/not in hierarchy/, 'error' );
            };

            subtest 'full' => sub {
                my $command_line = $mkline->(' a0 b01 c010');
                my %args         = $cli->execute_line($command_line);
                is( $args{status}, 0, "execute succeeded" )
                    or diag("got error: $args{error}");
            };

        };

        subtest 'terminal leaf' => sub {

            subtest 'leaf is undef' => sub {
                my $command_line = $mkline->(' a2');
                my %args         = $cli->execute_line($command_line);
                is( $args{status}, 0, "execute succeeded" )
                    or diag("got error: $args{error}");
            };

            subtest 'leaf is empty hash' => sub {
                my $command_line = $mkline->(' a3');
                my %args         = $cli->execute_line($command_line);
                is( $args{status}, 0, "execute succeeded" )
                    or diag("got error: $args{error}");
            };
        };

        return;
    }
}

Main();
