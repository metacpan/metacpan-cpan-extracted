#  !perl
#$Id: 09_ors.t 1215 2008-02-09 23:46:05Z jimk $
# 09_ors.t - test interaction with $\
use strict;
use warnings;
use Test::More tests =>  3;
use lib ( qq{./t/lib} );
BEGIN {
    use_ok('Perl6::Say');
    use_ok('Carp');
};

my $str = q{Hello World};
my $capture = q{};

SKIP: {
    my $skipped_tests = ( 3 - 2);
    eval { require 5.008 };
    my $reason =
      q{Writing to in-memory files (>\$string) not supported prior to Perl 5.8};
    skip $reason,
    $skipped_tests
    if $@;

    open my $fh, ">>", \$capture or croak "Couldn't open string for appending";
    my $oldfh = select $fh;
    {
        local $\ = q{X};
        print "$str\n";
        say $str;
        say;
    }
    close $fh or croak "Couldn't close string after appending";
    select $oldfh;
    
    is($capture,
        qq{Hello World\nXHello World\nX\nX}, 
        "say() functioned as predicted with \$\\ (Output Record Separator)"
    );

} # End SKIP block

