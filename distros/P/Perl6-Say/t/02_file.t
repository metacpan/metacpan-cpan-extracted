#  !perl
#$Id: 02_file.t 1213 2008-02-09 23:40:34Z jimk $
# 02_file.t - test say() when printing via filehandle to file
use strict;
use warnings;
use Test::More tests => 28;
use lib ( qq{./t/lib} );
BEGIN {
    use_ok('Perl6::Say');
    use_ok('File::Temp');
    use_ok('Carp');
    use_ok('Perl6::Say::Auxiliary', qw| _validate capture_say_file |);
};

my ($say_sub, $msg);

##### Global Filehandle: Direct  #####

$say_sub = sub {
    my ($tmpfile, $arg) = @_;
    open FH, ">$tmpfile" or croak "Cannot open tempfile for writing";
    ref($arg eq q{ARRAY}) ? say FH @{$arg} : say FH $arg;
    close FH or croak "Cannot close tempfile after writing";
};
$msg= q{correctly printed to file via global filehandle};

capture_say_file( {
    data => qq{Hello World},            pred => 1,
    eval => $say_sub,                   msg  => $msg,
} );

capture_say_file( {
    data => qq{Hello World\n},          pred => 2,
    eval => $say_sub,                   msg  => $msg,
} );

capture_say_file( {
    data => qq{Hello World\nAgain!\n},  pred => 3,
    eval => $say_sub,                   msg  => $msg,
} );

capture_say_file( {
    data => qq{},                       pred => 1,
    eval => $say_sub,                   msg  => $msg,
} );

##### Global Filehandle: Arrow  #####

$say_sub = sub {
    my ($tmpfile, $arg) = @_;
    open FH, ">$tmpfile" or croak "Cannot open tempfile for writing";
    ref($arg eq q{ARRAY}) ? FH->say(@{$arg}) : FH->say($arg);
    close FH or croak "Cannot close tempfile after writing";
};
$msg= q{correctly printed to file via global filehandle, arrow syntax};

capture_say_file( {
    data => qq{Hello World},            pred => 1,
    eval => $say_sub,                   msg  => $msg,
} );

capture_say_file( {
    data => qq{Hello World\n},          pred => 2,
    eval => $say_sub,                   msg  => $msg,
} );

capture_say_file( {
    data => qq{Hello World\nAgain!\n},  pred => 3,
    eval => $say_sub,                   msg  => $msg,
} );

capture_say_file( {
    data => qq{},                       pred => 1,
    eval => $say_sub,                   msg  => $msg,
} );

##### Global Filehandle: Typeglob  #####

$say_sub = sub {
    my ($tmpfile, $arg) = @_;
    open FH, ">$tmpfile" or croak "Cannot open tempfile for writing";
    ref($arg eq q{ARRAY}) ? *FH->say(@{$arg}) : *FH->say($arg);
    close FH or croak "Cannot close tempfile after writing";
};
$msg= q{correctly printed to file via global filehandle, typeglob syntax};

capture_say_file( {
    data => qq{Hello World},            pred => 1,
    eval => $say_sub,                   msg  => $msg,
} );

capture_say_file( {
    data => qq{Hello World\n},          pred => 2,
    eval => $say_sub,                   msg  => $msg,
} );

capture_say_file( {
    data => qq{Hello World\nAgain!\n},  pred => 3,
    eval => $say_sub,                   msg  => $msg,
} );

capture_say_file( {
    data => qq{},                       pred => 1,
    eval => $say_sub,                   msg  => $msg,
} );

##### Global Filehandle: Reference to Typeglob  #####

$say_sub = sub {
    my ($tmpfile, $arg) = @_;
    open FH, ">$tmpfile" or croak "Cannot open tempfile for writing";
    ref($arg eq q{ARRAY}) ? (*FH)->say(@{$arg}) : (*FH)->say($arg);
    close FH or croak "Cannot close tempfile after writing";
};
$msg= q{correctly printed to file via global filehandle, ref to typeglob syntax};

capture_say_file( {
    data => qq{Hello World},            pred => 1,
    eval => $say_sub,                   msg  => $msg,
} );

capture_say_file( {
    data => qq{Hello World\n},          pred => 2,
    eval => $say_sub,                   msg  => $msg,
} );

capture_say_file( {
    data => qq{Hello World\nAgain!\n},  pred => 3,
    eval => $say_sub,                   msg  => $msg,
} );

capture_say_file( {
    data => qq{},                       pred => 1,
    eval => $say_sub,                   msg  => $msg,
} );

##### Lexical Filehandle:  Comma  #####

$say_sub = sub {
    my ($tmpfile, $arg) = @_;
    open my $fh, ">$tmpfile" or croak "Cannot open tempfile for writing";
    ref($arg eq q{ARRAY}) ? say $fh, @{$arg} : say $fh, $arg;
    close $fh or croak "Cannot close tempfile after writing";
};
$msg= q{correctly printed to file via lexical filehandle, comma syntax};

capture_say_file( {
    data => qq{Hello World},            pred => 1,
    eval => $say_sub,                   msg  => $msg,
} );

capture_say_file( {
    data => qq{Hello World\n},          pred => 2,
    eval => $say_sub,                   msg  => $msg,
} );

capture_say_file( {
    data => qq{Hello World\nAgain!\n},  pred => 3,
    eval => $say_sub,                   msg  => $msg,
} );

capture_say_file( {
    data => qq{},                       pred => 1,
    eval => $say_sub,                   msg  => $msg,
} );

##### Lexical Filehandle:  Arrow  #####

$say_sub = sub {
    my ($tmpfile, $arg) = @_;
    open my $fh, ">$tmpfile" or croak "Cannot open tempfile for writing";
    ref($arg eq q{ARRAY}) ? $fh->say(@{$arg}) : $fh->say($arg);
    close $fh or croak "Cannot close tempfile after writing";
};
$msg= q{correctly printed to file via lexical filehandle, arrow syntax};

capture_say_file( {
    data => qq{Hello World},            pred => 1,
    eval => $say_sub,                   msg  => $msg,
} );

capture_say_file( {
    data => qq{Hello World\n},          pred => 2,
    eval => $say_sub,                   msg  => $msg,
} );

capture_say_file( {
    data => qq{Hello World\nAgain!\n},  pred => 3,
    eval => $say_sub,                   msg  => $msg,
} );

capture_say_file( {
    data => qq{},                       pred => 1,
    eval => $say_sub,                   msg  => $msg,
} );

