#  !perl
#$Id: 06_io.t 1213 2008-02-09 23:40:34Z jimk $
# 06_io.t - test say() when printing to FileHandle and IO::File objects
use strict;
use warnings;
use Test::More tests => 22;
use lib ( qq{./t/lib} );
BEGIN {
    use_ok('Perl6::Say');
    use_ok('File::Temp');
    use_ok('Carp');
    use_ok('FileHandle');
    use_ok('IO::File');
    use_ok('Perl6::Say::Auxiliary', qw| _validate capture_say_file |);
};

my ($say_sub, $msg, @list);

##### FileHandle:  Comma  #####

$say_sub = sub {
    my ($tmpfile, $arg) = @_;
    my $fh = FileHandle->new($tmpfile, q{w});
    if (defined $fh) {
        ref($arg eq q{ARRAY}) ? say $fh, @{$arg} : say $fh, $arg;
        $fh->close;
    } else {
        croak "Could not get FileHandle object";
    }
};
$msg= q{correctly printed to file via FileHandle object, comma syntax};

@list = ( 'Hello', ' ', 'World' );
capture_say_file( {
    data => \@list, pred => 1, eval => $say_sub, msg  => $msg,
} );

@list = ( 'Hello', ' ', 'World', "\n" );
capture_say_file( {
    data => \@list, pred => 2, eval => $say_sub, msg  => $msg,
} );

@list = ( 'Hello', ' ', 'World', "\n", 'Again!', "\n" );
capture_say_file( {
    data => \@list, pred => 3, eval => $say_sub, msg  => $msg,
} );

@list = (  );
capture_say_file( {
    data => \@list, pred => 1, eval => $say_sub, msg  => $msg,
} );

##### FileHandle:  Arrow  #####

$say_sub = sub {
    my ($tmpfile, $arg) = @_;
    my $fh = FileHandle->new($tmpfile, q{w});
    if (defined $fh) {
        ref($arg eq q{ARRAY}) ? $fh->say(@{$arg}) : $fh->say($arg);
        $fh->close;
    } else {
        croak "Could not get FileHandle object";
    }
};
$msg= q{correctly printed to file via FileHandle object, arrow syntax};

@list = ( 'Hello', ' ', 'World' );
capture_say_file( {
    data => \@list, pred => 1, eval => $say_sub, msg  => $msg,
} );

@list = ( 'Hello', ' ', 'World', "\n" );
capture_say_file( {
    data => \@list, pred => 2, eval => $say_sub, msg  => $msg,
} );

@list = ( 'Hello', ' ', 'World', "\n", 'Again!', "\n" );
capture_say_file( {
    data => \@list, pred => 3, eval => $say_sub, msg  => $msg,
} );

@list = (  );
capture_say_file( {
    data => \@list, pred => 1, eval => $say_sub, msg  => $msg,
} );

##### IO::File:  Comma  #####

$say_sub = sub {
    my ($tmpfile, $arg) = @_;
    my $fh = IO::File->new($tmpfile, q{w});
    if (defined $fh) {
        ref($arg eq q{ARRAY}) ? say $fh, @{$arg} : say $fh, $arg;
        $fh->close;
    } else {
        croak "Could not get IO::File object";
    }
};
$msg= q{correctly printed to file via IO::File object, comma syntax};

@list = ( 'Hello', ' ', 'World' );
capture_say_file( {
    data => \@list, pred => 1, eval => $say_sub, msg  => $msg,
} );

@list = ( 'Hello', ' ', 'World', "\n" );
capture_say_file( {
    data => \@list, pred => 2, eval => $say_sub, msg  => $msg,
} );

@list = ( 'Hello', ' ', 'World', "\n", 'Again!', "\n" );
capture_say_file( {
    data => \@list, pred => 3, eval => $say_sub, msg  => $msg,
} );

@list = (  );
capture_say_file( {
    data => \@list, pred => 1, eval => $say_sub, msg  => $msg,
} );

##### IO::File:  Arrow  #####

$say_sub = sub {
    my ($tmpfile, $arg) = @_;
    my $fh = IO::File->new($tmpfile, q{w});
    if (defined $fh) {
        ref($arg eq q{ARRAY}) ? $fh->say(@{$arg}) : $fh->say($arg);
        $fh->close;
    } else {
        croak "Could not get IO::File object";
    }
};
$msg= q{correctly printed to file via IO::File object, arrow syntax};

@list = ( 'Hello', ' ', 'World' );
capture_say_file( {
    data => \@list, pred => 1, eval => $say_sub, msg  => $msg,
} );

@list = ( 'Hello', ' ', 'World', "\n" );
capture_say_file( {
    data => \@list, pred => 2, eval => $say_sub, msg  => $msg,
} );

@list = ( 'Hello', ' ', 'World', "\n", 'Again!', "\n" );
capture_say_file( {
    data => \@list, pred => 3, eval => $say_sub, msg  => $msg,
} );

@list = (  );
capture_say_file( {
    data => \@list, pred => 1, eval => $say_sub, msg  => $msg,
} );

