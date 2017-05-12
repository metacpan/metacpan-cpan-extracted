#  !perl
#$Id: 05_scalar_ref.t 1215 2008-02-09 23:46:05Z jimk $
# 05_scalar_ref.t - test say() when printing to string via reference to scalar
use strict;
use warnings;
use Test::More tests => 27;
use lib ( qq{./t/lib} );
BEGIN {
    use_ok('Perl6::Say');
    use_ok('Carp');
    use_ok('Perl6::Say::Auxiliary', qw| _validate capture_say_scalar |);
};

my %diagnostics = (
    open    => qq{Cannot open filehandle to scalar ref for writing},
    close   => qq{Cannot close filehandle to scalar ref after writing},
);

my ($say_sub, $msg, @list);

##### Global Filehandle:  Direct #####


SKIP: {
    my $skipped_tests = (27 - 3);
    eval { require 5.008 };
    my $reason =
      q{Writing to in-memory files (>\$string) not supported prior to Perl 5.8};
    skip $reason,
    $skipped_tests
    if $@;
    
    $say_sub = sub {
        my $arg = shift;
        my $string = q{};
        open FH, ">", \$string or croak $diagnostics{open};
        ref($arg eq q{ARRAY}) ? say FH @{$arg} : say FH $arg;
        close FH or croak $diagnostics{close};
        return $string;
    };
    $msg= q{correctly printed to string via global filehandle};
    
    @list = ( 'Hello', ' ', 'World' );
    capture_say_scalar( {
        data => \@list, pred => 1, eval => $say_sub, msg  => $msg,
    } );
    
    @list = ( 'Hello', ' ', 'World', "\n" );
    capture_say_scalar( {
        data => \@list, pred => 2, eval => $say_sub, msg  => $msg,
    } );
    
    @list = ( 'Hello', ' ', 'World', "\n", 'Again!', "\n" );
    capture_say_scalar( {
        data => \@list, pred => 3, eval => $say_sub, msg  => $msg,
    } );
    
    @list = (  );
    capture_say_scalar( {
        data => \@list, pred => 1, eval => $say_sub, msg  => $msg,
    } );
    
    ##### Global Filehandle: Arrow  #####
    
    $say_sub = sub {
        my $arg = shift;
        my $string = q{};
        open FH, ">", \$string or croak $diagnostics{open};
        ref($arg eq q{ARRAY}) ? FH->say(@{$arg}) : FH->say($arg);
        close FH or croak $diagnostics{close};
        return $string;
    };
    $msg= q{correctly printed to string via global filehandle, arrow syntax};
    
    @list = ( 'Hello', ' ', 'World' );
    capture_say_scalar( {
        data => \@list, pred => 1, eval => $say_sub, msg  => $msg,
    } );
    
    @list = ( 'Hello', ' ', 'World', "\n" );
    capture_say_scalar( {
        data => \@list, pred => 2, eval => $say_sub, msg  => $msg,
    } );
    
    @list = ( 'Hello', ' ', 'World', "\n", 'Again!', "\n" );
    capture_say_scalar( {
        data => \@list, pred => 3, eval => $say_sub, msg  => $msg,
    } );
    
    @list = (  );
    capture_say_scalar( {
        data => \@list, pred => 1, eval => $say_sub, msg  => $msg,
    } );
    
    ##### Global Filehandle: Typeglob  #####
    
    $say_sub = sub {
        my $arg = shift;
        my $string = q{};
        open FH, ">", \$string or croak $diagnostics{open};
        ref($arg eq q{ARRAY}) ? *FH->say(@{$arg}) : *FH->say($arg);
        close FH or croak $diagnostics{close};
        return $string;
    };
    $msg= q{correctly printed to string via global filehandle, typeglob syntax};
    
    @list = ( 'Hello', ' ', 'World' );
    capture_say_scalar( {
        data => \@list, pred => 1, eval => $say_sub, msg  => $msg,
    } );
    
    @list = ( 'Hello', ' ', 'World', "\n" );
    capture_say_scalar( {
        data => \@list, pred => 2, eval => $say_sub, msg  => $msg,
    } );
    
    @list = ( 'Hello', ' ', 'World', "\n", 'Again!', "\n" );
    capture_say_scalar( {
        data => \@list, pred => 3, eval => $say_sub, msg  => $msg,
    } );
    
    @list = (  );
    capture_say_scalar( {
        data => \@list, pred => 1, eval => $say_sub, msg  => $msg,
    } );
    
    ##### Global Filehandle: Reference to Typeglob  #####
    
    $say_sub = sub {
        my $arg = shift;
        my $string = q{};
        open FH, ">", \$string or croak $diagnostics{open};
        ref($arg eq q{ARRAY}) ? (*FH)->say(@{$arg}) : (*FH)->say($arg);
        close FH or croak $diagnostics{close};
        return $string;
    };
    $msg= q{correctly printed to string via global filehandle, ref to typeglob syntax};
    
    @list = ( 'Hello', ' ', 'World' );
    capture_say_scalar( {
        data => \@list, pred => 1, eval => $say_sub, msg  => $msg,
    } );
    
    @list = ( 'Hello', ' ', 'World', "\n" );
    capture_say_scalar( {
        data => \@list, pred => 2, eval => $say_sub, msg  => $msg,
    } );
    
    @list = ( 'Hello', ' ', 'World', "\n", 'Again!', "\n" );
    capture_say_scalar( {
        data => \@list, pred => 3, eval => $say_sub, msg  => $msg,
    } );
    
    @list = (  );
    capture_say_scalar( {
        data => \@list, pred => 1, eval => $say_sub, msg  => $msg,
    } );
    
    
    ##### Lexical Filehandle:  Comma  #####
    
    $say_sub = sub {
        my $arg = shift;
        my $string = q{};
        open my $fh, ">", \$string or croak $diagnostics{open};
        ref($arg eq q{ARRAY}) ? say $fh, @{$arg} : say $fh, $arg;
        close $fh or croak $diagnostics{close};
        return $string;
    };
    $msg= q{correctly printed to string via lexical filehandle, comma syntax};
    
    @list = ( 'Hello', ' ', 'World' );
    capture_say_scalar( {
        data => \@list, pred => 1, eval => $say_sub, msg  => $msg,
    } );
    
    @list = ( 'Hello', ' ', 'World', "\n" );
    capture_say_scalar( {
        data => \@list, pred => 2, eval => $say_sub, msg  => $msg,
    } );
    
    @list = ( 'Hello', ' ', 'World', "\n", 'Again!', "\n" );
    capture_say_scalar( {
        data => \@list, pred => 3, eval => $say_sub, msg  => $msg,
    } );
    
    @list = (  );
    capture_say_scalar( {
        data => \@list, pred => 1, eval => $say_sub, msg  => $msg,
    } );
    
    ##### Lexical Filehandle:  Arrow #####
    
    $say_sub = sub {
        my $arg = shift;
        my $string = q{};
        open my $fh, ">", \$string or croak $diagnostics{open};
        ref($arg eq q{ARRAY}) ? $fh->say(@{$arg}) : $fh->say($arg);
        close $fh or croak $diagnostics{close};
        return $string;
    };
    $msg= q{correctly printed to string via lexical filehandle, arrow syntax};
    
    @list = ( 'Hello', ' ', 'World' );
    capture_say_scalar( {
        data => \@list, pred => 1, eval => $say_sub, msg  => $msg,
    } );
    
    @list = ( 'Hello', ' ', 'World', "\n" );
    capture_say_scalar( {
        data => \@list, pred => 2, eval => $say_sub, msg  => $msg,
    } );
    
    @list = ( 'Hello', ' ', 'World', "\n", 'Again!', "\n" );
    capture_say_scalar( {
        data => \@list, pred => 3, eval => $say_sub, msg  => $msg,
    } );
    
    @list = (  );
    capture_say_scalar( {
        data => \@list, pred => 1, eval => $say_sub, msg  => $msg,
    } );

} # End SKIP block

