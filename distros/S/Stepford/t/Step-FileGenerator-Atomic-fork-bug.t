## no critic (Moose::RequireCleanNamespace, Moose::RequireMakeImmutable)
use strict;
use warnings;

use Log::Dispatch;
use Log::Dispatch::Null;
use Parallel::ForkManager;
use Path::Class qw( tempdir );
use Test::Fatal;
use Test::More;
use Try::Tiny;

my $tempdir = tempdir( CLEANUP => 1 );
my $logger
    = Log::Dispatch->new( outputs => [ [ Null => min_level => 'emerg' ] ] );

{
    package Atomic;

    use autodie;
    use Moose;
    use Stepford::Types qw( File );

    with 'Stepford::Role::Step::FileGenerator::Atomic';

    has final_file => (
        traits => ['StepProduction'],
        is     => 'ro',
        isa    => File,
    );

    sub run {
        my $self = shift;
        my $file = $self->pre_commit_file;
        open my $fh, '>', $file;
        print {$fh} 'foo' or die $!;
        close $fh;
    }
}

{
    my $file = $tempdir->file('final-file');
    my $step = Atomic->new(
        logger     => $logger,
        final_file => $file,
    );

    my $pm = Parallel::ForkManager->new(1);

    my ( $exit_code, $message );
    $pm->run_on_finish(
        sub {
            ( $exit_code, $message ) = @_[ 1, 5 ];
        }
    );

    my $signal_file = $tempdir->file('signal');
    if ( my $pid = $pm->start ) {
        undef $step;
        touch $signal_file;
    }
    else {
        _run_child( $pm, $signal_file, $step );
    }

    $pm->wait_all_children;

    is( $exit_code, 0, 'child process exited without error' );
    is_deeply(
        $message,
        { error => q{} },
        'no error message from child process'
    );

    if ( -f $file ) {
        is( $file->slurp, 'foo', 'step wrote expected contents to file' );
    }
}

done_testing();

sub _run_child {
    my $pm          = shift;
    my $signal_file = shift;
    my $step        = shift;

    my $x = 0;
    until ( -f $signal_file || $x == 10 ) {
        sleep 1;
        $x++;
    }
    unless ( -f $signal_file ) {
        $pm->finish( 1, { error => 'parent never created the signal file' } );
    }

    my $error;
    try {
        $step->run;
    }
    catch {
        $error = "$_";
    };

    $pm->finish( ( $error ? 2 : 0 ), { error => $error // q{} } );
}
