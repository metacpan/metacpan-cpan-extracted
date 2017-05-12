use t::boilerplate;

use Test::More;
use Cwd qw( getcwd );
use File::DataClass::IO;
use File::Spec::Functions qw( catdir catfile );

use_ok 'Module::Provision';

my $owd = getcwd; my $prog;

sub test_mp {
   my ($builder, $method) = @_; $method ||= 'dist';

   return Module::Provision->new_with_options
      ( appclass  => 'Module::Provision',
        base      => 't',
        builder   => $builder,
        config    => { tempdir => 't', },
        method    => $method,
        nodebug   => 1,
        quiet     => 1,
        project   => 'Foo::Bar',
        templates => catdir( 't', 'code_templates' ),
        vcs       => 'none', );
}

sub test_cleanup {
   my $owd = shift; chdir $owd;

   io( catdir( qw( t Foo-Bar )        ) )->rmtree();
   io( catdir( qw( t code_templates ) ) )->rmtree();
   return;
}

$prog = test_mp( 'MB', 'init_templates' ); $prog->run;

ok -f catfile( qw( t code_templates index.json ) ), 'Creates template index';

SKIP: {
   $ENV{AUTHOR_TESTING} or skip 'extended testing', 1;

   $prog = test_mp( 'MB', 'dist' ); $prog->run;

   like $prog->appbase->name, qr{ Foo-Bar \z }mx, 'Sets appbase';
   ok -d catdir( $prog->appbase->name, qw( lib Foo ) ), 'Creates lib/Foo dir';
   ok -d catdir( $prog->appbase->name, 'inc' ), 'Creates inc dir';
   ok -d catdir( $prog->appbase->name, 't' ), 'Creates t dir';
   ok -f catfile( $prog->appbase->name, qw( lib Foo Bar.pm ) ),
      'Creates lib/Foo/Bar.pm';
   ok -f catfile( $prog->appbase->name, 'Build.PL' ), 'Creates Build.PL';

   test_cleanup( $owd );

   $prog = test_mp( 'DZ' );

   is $prog->run, 0, 'Dist DZ returns zero';

   test_cleanup( $owd );

   $prog = test_mp( 'MB' );

   is $prog->run, 0, 'Dist MB returns zero';

   test_cleanup( $owd );
};

done_testing;

unlink catfile( qw( t .foo-bar.rev ) );
unlink catfile( qw( t ipc_srlock.lck ) );
unlink catfile( qw( t ipc_srlock.shm ) );

# Local Variables:
# mode: perl
# tab-width: 3
# End:
