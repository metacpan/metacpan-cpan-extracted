package System::Wrapper::Parallel;

use warnings;
use strict;
use constant MAX_RAND => System::Wrapper::MAX_RAND;

use Carp;
use File::Spec;
use Moose;
use System::Wrapper;

our $VERSION = '0.0.2';

has 'commands' => ( is => 'rw', isa => 'ArrayRef[System::Wrapper]', required => 1 );
has 'pipeline' => ( is => 'rw', isa => 'Bool' );

sub run {
    my ( $self ) = @_;

    my ($previous, @commands) = @{$self->commands};

    System::Wrapper::_err( "parallel execution requires more than one command" ) 
      unless @commands;

    System::Wrapper::_err( "pipeline execution requires POSIX::mkfifo() to be implemented" )
      if $self->pipeline and not _mkfifo_works();

    my @results = ();
  COMMAND:
    for my $command ( @commands, 'DUMMY' ) {

        if ( $self->pipeline and ref $command ) {
            $previous->_fifo( _connect( $previous, $command ) );
        }

        if ( ref $command ) {
            unless (my $pid = fork) {
                push @results, $previous->run;
                exit if ref $command;
            }
        }
        else {
            push @results, $previous->run;
        }
        $previous = $command;
    }
    return @results;
}

sub _connect {
    my ( $upstream, $downstream ) = @_;
    my $class = ref $downstream;

    my $named_pipe = File::Spec->catfile( File::Spec->tmpdir(),
        qq{$class:} . int rand MAX_RAND );

    POSIX::mkfifo( $named_pipe, 0777 )
        or _err( "couldn't create named pipe %s: %s", $named_pipe, $! );

    my %output_spec = $upstream->output;

    _err(
        "can't install fifo %s as output because there are multiple output specifications (%s):\n%s",
        $named_pipe,
        join( q{, }, map {qq{'$_' }} sort keys %output_spec ),
        $upstream->description || "$upstream"
    ) if keys %output_spec > 1;

    $upstream->output( { scalar each %output_spec || q{>} => $named_pipe } );
    $downstream->input($named_pipe);

    return $named_pipe;
}

sub _mkfifo_works {
    eval {
        require POSIX;
        POSIX->import();
        my $test_named_pipe = File::Spec->catfile( File::Spec->tmpdir(),
            'test.' . int rand MAX_RAND );

        POSIX::mkfifo( $test_named_pipe, 0777 )
            or _err( "couldn't create test named pipe %s: %s",
            $test_named_pipe, $! );

        unlink $test_named_pipe;
    };
    _err( "requires POSIX::mkfifo:\n%s", $@ )
        if $@;

    return 1;
}

1;
