package Test::Siebel::Srvrmgr::Daemon::Action::Serializable;

use base qw(Test::Class Class::Data::Inheritable);
use Test::Most;
use Test::Moose;
use Siebel::Srvrmgr::ListParser;
use Storable;
use Test::TempDir::Tiny;
use File::Spec;
use Test::Siebel::Srvrmgr::Fixtures qw(data_from_file);

# :WORKAROUND:25/06/2013 16:34:40::
# This package was created because it seems impossible to use Test::Class with two superclasses being inherited, being one of them a role.
# Because of that, this superclass will not be a subclass of Test::Siebel::Srvrmgr::Daemon::Action and all tests will focus on test the
# usage of Siebel::Srvrmgr::Daemon::Action::Serializable Moose role
# the scheme of defining automatically the class to be tested does not seems to work if it is desired to override Test::Siebel::Srvrmgr startup
# method

BEGIN {
    __PACKAGE__->mk_classdata('class');
    __PACKAGE__->mk_classdata('role');
    __PACKAGE__->mk_classdata('temp_dir');
}

__PACKAGE__->SKIP_CLASS(1);

# just to avoid "use Storable" in subclasses
sub recover {
    my ( $test, $file ) = @_;
    return Storable::retrieve($file);
}

sub startup : Test( startup => 1 ) {
    my ( $test ) = @_;

# removes the Test:: from the child class package name, so it is expected that the resulting package name exists in @INC
    ( my $class = ref $test ) =~ s/^Test:://;
    return 1, "$class loaded" if $class eq __PACKAGE__;
    $class =~ s/::Serializable//;
    use_ok $class or die;
    $test->class($class);
    $test->role('Siebel::Srvrmgr::Daemon::Action::Serializable');
    $test->temp_dir( tempdir() );
    $test->{action} = $test->class()->new(
        {
            parser => Siebel::Srvrmgr::ListParser->new(),
            params => [ $test->get_dump() ]
        }
    );
}

sub get_my_data {
    my $test = shift;

    if ( exists( $test->{data} ) ) {
        return $test->{data};
    }
    else {
        return $test->{data} = data_from_file( $test->{data_file} );
    }

}

sub get_dump {
    my $test = shift;
    my $name = __PACKAGE__;
    $name =~ s/\:{2}/_/g;
    return File::Spec->catfile( $test->temp_dir(), ( $name . '_storable' ) );
}

sub role_usage : Test(1) {
    my $test = shift;
    does_ok( $test->{action}, $test->role() );
}

sub class_methods : Tests(3) {
    my $test = shift;
    can_ok( $test->{action}, qw(get_dump_file set_dump_file store) );
    is( $test->{action}->get_dump_file(),
        $test->get_dump(), 'get_dump_file returns the correct string' );
    ok( $test->{action}->set_dump_file( $test->get_dump ),
        'set_dump_file works' );
}

sub DESTROY {
    my $test = shift;

# :WORKAROUND:07/06/2013 16:39:28:: this class does not generate any file, just the subclasses
    unless ( ref($test) eq 'Test::Siebel::Srvrmgr::Action::Serializable' ) {

        if ( -e $test->get_dump() ) {
            unlink( $test->get_dump() )
              or diag( 'Cannot remove ' . $test->get_dump() . ': ' . $! );
        }
    }
}

sub recover_me : Test {
    my $test = shift;

# :WARNING   :07/06/2013 16:58:13:: this tests does not verifies the Siebel::Srvrmgr API, but it will help to
# detect that a subclass of Serializable was not finished correctly
    ok(
        (
            ( ( $test->isa(__PACKAGE__) ) and ( ref($test) ne __PACKAGE__ ) )
            ? 1
            : 0
        ),
        'method recover_me needs to be overrided by subclasses of '
          . __PACKAGE__
    );

# :WORKAROUND:25/06/2013 16:45:31:: recover a serialized data requires that the do method is invoked to call the appropriate subclass of
# Siebel::Srvrmgr::Daemon::Action that applies Siebel::Srvrmgr::Daemon::Action::Serializable Moose role
    $test->{action}->do( $test->get_my_data() );
}

1;
