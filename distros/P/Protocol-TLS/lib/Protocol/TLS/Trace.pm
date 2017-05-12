package Protocol::TLS::Trace;
use strict;
use warnings;
use Time::HiRes qw(time);

use Exporter qw(import);
our @EXPORT_OK = qw(tracer bin2hex);

my %levels = (
    debug     => 0,
    info      => 1,
    notice    => 2,
    warning   => 3,
    error     => 4,
    critical  => 5,
    alert     => 6,
    emergency => 7,
);

my $tracer_sngl = Protocol::TLS::Trace->_new(
    min_level => ( exists $ENV{TLS_DEBUG} && exists $levels{ $ENV{TLS_DEBUG} } )
    ? $levels{ $ENV{TLS_DEBUG} }
    : $levels{error}
);
my $start_time = 0;

sub tracer {
    $tracer_sngl;
}

sub _new {
    my ( $class, %opts ) = @_;
    bless {%opts}, $class;
}

sub _log {
    my ( $self, $level, $message ) = @_;
    if ( $level >= $self->{min_level} ) {
        chomp($message);
        my @caller = map { s/Protocol::TLS:://; $_ }
          ( ( caller(2) )[3], ( caller(1) )[2] );
        my $now = time;
        if ( $now - $start_time < 60 ) {
            $message =~ s/\n/\n           /g;
            printf "[%05.3f] [%s:%s] %s\n", $now - $start_time, @caller,
              $message;
        }
        else {
            my @t = ( localtime() )[ 5, 4, 3, 2, 1, 0 ];
            $t[0] += 1900;
            $t[1]++;
            $message =~ s/\n/\n                      /g;
            printf "[%4d-%02d-%02d %02d:%02d:%02d] [%s:%s] %s\n", @t,
              @caller, $message;
            $start_time = $now;
        }
    }
}

sub debug {
    shift->_log( 0, @_ );
}

sub info {
    shift->_log( 1, @_ );
}

sub notice {
    shift->_log( 2, @_ );
}

sub warning {
    shift->_log( 3, @_ );
}

sub error {
    shift->_log( 4, @_ );
}

sub critical {
    shift->_log( 5, @_ );
}

sub alert {
    shift->_log( 6, @_ );
}

sub emergency {
    shift->_log( 7, @_ );
}

sub bin2hex {
    my $bin = shift;
    my $c   = 0;
    my $s;

    join "", map {
        $c++;
        $s = !( $c % 16 ) ? "\n" : ( $c % 2 ) ? "" : " ";
        $_ . $s
    } unpack( "(H2)*", $bin );
}

1
