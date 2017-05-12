#!/usr/bin/env perl 
# Copyright (C) 2012 Rocky Bernstein <rocky@cpan.org>
# Documentation is at the __END__
package Perl::Syntax;
our $VERSION = '1.00';
use B qw(minus_c save_BEGINs);
sub import {
    my ($class, @options) = @_;
    my $filename = $options[0] if @options;
    open (SAVE_ERR, '>&STDERR');
    eval q[
        BEGIN {
            minus_c;
            save_BEGINs;
            close STDERR;
            if (defined($filename)) {
               open (STDERR, ">", $filename);
            } else {
               open (STDERR, ">", \$Perl::Syntax::stderr);
            }
        }
    ];
    die $@ if $@
}

unless (caller) {
    # Demo code
    printf "Demoing %s ...\n", __FILE__;
    require File::Basename;
    my $dirname = File::Basename::dirname(__FILE__);
    my $basename = File::Basename::basename(__FILE__);
    chdir $dirname;
    my @prefix = ("$^X", '-I..', "-MPerl::Syntax");
    system("$^X -I.. -MPerl::Syntax $basename");
    system(@prefix, $basename);
    printf("Perl file $basename does %ssyntax check okay.\n", 
	   $?>>8 ? 'not ' : '');
    system(@prefix, '-e', '1+');
    printf "1+ does %ssyntax check okay.\n", $?>>8 ? 'not ' : ' ';
    require File::Temp;
    my ($fh, $tempfile) = File::Temp::tempfile('SyntaxXXXX', SUFFIX=>'.log',
					       UNLINK => 1,
					       TMPDIR => 1);
    @prefix = ("$^X", '-I..', "-MPerl::Syntax=$tempfile");
    system(@prefix, $basename);
    print "Syntax checking $basename gives message:\n";
    seek($fh, 0, 0);
    print $_ while <$fh> ;

    seek($fh, 0, 0);
    system(@prefix, '-e', 'not(perl');
    print "Syntax checking 'not(perl' gives message:\n";
    seek($fh, 0, 0);
    print $_ while <$fh> ;
    close $fh;
}
1;
__END__
=pod

=head1 Name

Perl::Syntax -- Syntax Check Perl files and strings 

=head1 Summary

This module syntax checks Perl files and strings. It is identical
to running C<perl -c ...>, but output doesn't go by default to STDOUT.

You run his like this from a command line:

    $ perl -MPerl::Syntax perl-program.pl
    $ perl -MPerl::Syntax -e 'your perl code' 

which is like: 

    $ perl -c perl-program.pl 2>/dev/null
    $ perl -MPerl::Syntax -e 'your perl code' 2>/dev/null

Or from inside Perl: 

     system($^X, '-M', 'Perl::Syntax', $perl_program);
     system("$^X -M Perl::Syntax $perl_program");
     # check $? 

By default, no output is produced. You will get a zero return code if
everything checks out or nonzero if there was a syntax error. 

To capture output to a file, you can specify a file name by adding an
equal sign after "Perl::Syntax" like this:

    perl -MPerl::Syntax=/tmp/output-file.txt perl-program.pl 

or inside PerL:

     system($^X, '-M', 'Perl::Syntax=/tmp/outfile-file.txt', $perl_program);

File I</tmp/output-file.txt> will have either the messages Perl
normally produces on C<STDERR>:

    XXXX syntax OK

or

    syntax error at XXXX line DDDD ...
    ...

=head1 Examples

     use English;
     my @prefix = ($EXECUTABLE_NAME, '-MPerl::Syntax');

     # test this Perl code to see if it is syntactically correct;
     system(@prefix, __FILE__); 
     print "Yep, we're good" unless $? >> 8;

     # test of invalid Perl code: 
     system(@prefix, '-e', '$Incomplete + $Expression +'; 
     print "Try again" if $? >> 8;

     # Show capturing output
     system($EXECUTABLE_NAME, '-MPerl::Syntax=/tmp/Syntax.log', __FILE__);
     # results are in /tmp/Syntax.log

=head1 Bugs/Caveats

There doesn't seem to be much benefit here over using C<perl -c> with
C<STDERR> redirected. What I really want is a kind of eval that just
does the syntax checking.

=head1 Author

Rocky Bernstein

=head1 See Also 

C<-c> switch from L<perlrun#Command-Switches>

=head1 Copyright

Copyright (C) 2012 Rocky Bernstein <rocky@cpan.org>

This program is distributed WITHOUT ANY WARRANTY, including but not
limited to the implied warranties of merchantability or fitness for a
particular purpose.

The program is free software. You may distribute it and/or modify it
under the terms of the GNU General Public License as published by the
Free Software Foundation (either version 2 or any later version) and
the Perl Artistic License as published by O'Reilly Media, Inc. Please
open the files named gpl-2.0.txt and Artistic for a copy of these
licenses.

=cut
