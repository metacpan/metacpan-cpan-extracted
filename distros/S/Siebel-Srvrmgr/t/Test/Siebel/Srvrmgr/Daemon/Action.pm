package Test::Siebel::Srvrmgr::Daemon::Action;

use Test::Most;
use Siebel::Srvrmgr::ListParser;
use Test::Moose 'has_attribute_ok';
use Test::TempDir::Tiny;
use File::Spec;
use Config;
use parent qw(Test::Siebel::Srvrmgr);

sub get_parser {
    my $test = shift;
    return $test->{parser};
}

sub set_parser {
    my $test = shift;
    $test->{parser} = shift;
}

sub get_action {
    my $test = shift;
    return $test->{action};
}

sub set_action {
    my $test = shift;
    $test->{action} = shift;
}

sub get_struct {
    my $self = shift;
    return $self->{structure_type};
}

sub get_col_sep {
    my $test = shift;
    return $test->{col_sep};
}

sub get_temp_dir {
    my $test = shift;
    return $test->{temp_dir};
}

sub before : Tests(setup) {
    my ( $test, $params_ref ) = @_;
    $test->{temp_dir} = tempdir();

    if (    ( $test->get_struct() eq 'delimited' )
        and ( defined( $test->get_col_sep() ) ) )
    {
        $test->set_parser(
            Siebel::Srvrmgr::ListParser->new(
                { field_delimiter => $test->get_col_sep() }
            )
        );
    }
    else {
        $test->set_parser( Siebel::Srvrmgr::ListParser->new() );
    }

    if ( defined($params_ref) ) {
        $test->set_action(
            $test->class()->new(
                {
                    parser => $test->get_parser(),
                    params => $params_ref
                }
            )
        );

    }
    else {
        $test->set_action(
            $test->class()->new(
                {
                    parser => $test->get_parser(),
                    params =>
                      [ File::Spec->catfile( $test->{temp_dir}, 'foobar' ) ]
                }
            )
        );
    }
}

sub constructor : Tests(2) {
    my $test = shift;
    ok( $test->get_action(), 'the constructor works' );
    isa_ok( $test->get_action(), $test->class() );
}

sub class_attributes : Tests(3) {
    my $test = shift;

    foreach my $attrib (qw(parser params expected_output)) {
        has_attribute_ok( $test->{action}, $attrib );
    }
}

sub class_methods : Tests(8) {
    my $test         = shift;
    my $parser_class = 'Siebel::Srvrmgr::ListParser';
    isa_ok( $test->get_action()->get_parser(),
        $parser_class, "get_parser returns a $parser_class instance" );
    can_ok( $test->get_action(), qw(new get_params get_parser do do_parsed) );

  SKIP: {
        skip 'superclass does not returns data with get_my_data', 1
          if (
            ref( $test->get_action() ) eq 'Siebel::Srvrmgr::Daemon::Action' );
        ok( $test->get_action()->do( $test->get_my_data() ),
            'do method works with get_my_data()' );
        lives_ok(
            sub {
                $test->get_action()->get_exp_output(),
                  'get_exp_output does not raise an exception';
            }
        );
    }

  SKIP: {

        skip 'tests just for superclass', 2
          if (
            ref( $test->get_action() ) ne 'Siebel::Srvrmgr::Daemon::Action' );
        dies_ok(
            sub { $test->get_action()->do('simple string') },
            'do method raises an exception with wrong type of parameter'
        );
        dies_ok(
            sub { $test->get_action()->do_parsed() },
            'do_parsed of superclass causes an exception'
        );
        like(
            $@,
            qr/do_parsed must be overrided by subclasses/,
            'the exception test is the expected'
        );

    }
    ok( $test->get_action()->get_params(), 'get_params works returns data' );

}

sub clean_up : Test(shutdown) {
    my $test = shift;

    # removes the dump files
    my $dir = $test->get_temp_dir();
    opendir( DIR, $dir ) or die "Cannot read $dir: $!\n";
    my @files = readdir(DIR);
    close(DIR);

    # :TODO :08/07/2013 12:50:22:: change for a proper interface instead hoping for data structure be the expected
    my $filename = '^' . ( @{ $test->get_action()->get_params() } )[0];

    # to avoid warnings with matching regular expression due the backslash used
    # by Windows
    if ( $Config{osname} eq 'MSWin32' ) {
        $filename =~ s/\\/\\\\/g;
    }

    my $regex = qr/$filename/;

    foreach my $file (@files) {

        if ( $file =~ /$regex/ ) {
            my $path = File::Spec->catfile( $dir, $file );
            unlink $path or diag("Cannot remove $path: $!");
        }
    }

    rmdir($dir) or diag("Cannot remove $dir: $!");
}

1;
