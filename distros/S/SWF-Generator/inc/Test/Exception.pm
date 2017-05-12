#line 1
use strict;
use warnings;

package Test::Exception;
use Test::Builder;
use Sub::Uplevel qw( uplevel );
use base qw( Exporter );
use Carp;

our $VERSION = '0.27';
our @EXPORT = qw(dies_ok lives_ok throws_ok lives_and);

my $Tester = Test::Builder->new;

sub import {
    my $self = shift;
    if ( @_ ) {
        my $package = caller;
        $Tester->exported_to( $package );
        $Tester->plan( @_ );
    };
    $self->export_to_level( 1, $self, $_ ) foreach @EXPORT;
}

#line 84

sub _quiet_caller (;$) { ## no critic Prototypes
    my $height = $_[0];
    $height++;
    if( wantarray and !@_ ) {
        return (CORE::caller($height))[0..2];
    }
    else {
        return CORE::caller($height);
    }
}

sub _try_as_caller {
    my $coderef = shift;

    # local works here because Sub::Uplevel has already overridden caller
    local *CORE::GLOBAL::caller;
    { no warnings 'redefine'; *CORE::GLOBAL::caller = \&_quiet_caller; }

    eval { uplevel 3, $coderef };
    return $@;
};


sub _is_exception {
    my $exception = shift;
    return ref $exception || $exception ne '';
};


sub _exception_as_string {
    my ( $prefix, $exception ) = @_;
    return "$prefix normal exit" unless _is_exception( $exception );
    my $class = ref $exception;
    $exception = "$class ($exception)" 
            if $class && "$exception" !~ m/^\Q$class/;
    chomp $exception;
    return "$prefix $exception";
};


#line 169


sub throws_ok (&$;$) {
    my ( $coderef, $expecting, $description ) = @_;
    croak "throws_ok: must pass exception class/object or regex" 
        unless defined $expecting;
    $description = _exception_as_string( "threw", $expecting )
    	unless defined $description;
    my $exception = _try_as_caller( $coderef );
    my $regex = $Tester->maybe_regex( $expecting );
    my $ok = $regex 
        ? ( $exception =~ m/$regex/ ) 
        : eval { 
            $exception->isa( ref $expecting ? ref $expecting : $expecting ) 
        };
    $Tester->ok( $ok, $description );
    unless ( $ok ) {
        $Tester->diag( _exception_as_string( "expecting:", $expecting ) );
        $Tester->diag( _exception_as_string( "found:", $exception ) );
    };
    $@ = $exception;
    return $ok;
};


#line 215

sub dies_ok (&;$) {
    my ( $coderef, $description ) = @_;
    my $exception = _try_as_caller( $coderef );
    my $ok = $Tester->ok( _is_exception($exception), $description );
    $@ = $exception;
    return $ok;
}


#line 254

sub lives_ok (&;$) {
    my ( $coderef, $description ) = @_;
    my $exception = _try_as_caller( $coderef );
    my $ok = $Tester->ok( ! _is_exception( $exception ), $description );
	$Tester->diag( _exception_as_string( "died:", $exception ) ) unless $ok;
    $@ = $exception;
    return $ok;
}


#line 294

sub lives_and (&;$) {
    my ( $test, $description ) = @_;
    {
        local $Test::Builder::Level = $Test::Builder::Level + 1;
        my $ok = \&Test::Builder::ok;
        no warnings;
        local *Test::Builder::ok = sub {
            $_[2] = $description unless defined $_[2];
            $ok->(@_);
        };
        use warnings;
        eval { $test->() } and return 1;
    };
    my $exception = $@;
    if ( _is_exception( $exception ) ) {
        $Tester->ok( 0, $description );
        $Tester->diag( _exception_as_string( "died:", $exception ) );
    };
    $@ = $exception;
    return;
}

#line 460

1;
