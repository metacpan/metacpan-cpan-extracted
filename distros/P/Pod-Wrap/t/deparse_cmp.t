#!/usr/bin/perl
# $Id: deparse_cmp.t,v 1.1 2004/01/08 01:41:42 nothingmuch Exp $

use strict;
use warnings;

use Test::More;
use Fcntl qw(SEEK_SET);
eval { require IPC::Open3 } or skip_all("Need pipes for B::Deparse. I don't know of another way yet.");
use B::Deparse;
use IO::Select;

if ($ENV{TEST_MANY_MODULES}){
    # lots of dependancies # thanks to the wonderful perl monks
    eval { require CPAN };
    eval { require CPANPLUS };
    eval { require LWP::Simple };
    eval { require Crypt::OpenPGP };
    eval { require WWW::Mechanize::Shell };
    eval { require Class::DBI };
    eval { require Net::LDAP };
    eval { require Net::SSH::Perl };
    eval { require Petal }; 
    
    # quite big
    eval { require CGI };
    eval { require Mail::SpamAssassin };
    eval { require Mail::Box };
    eval { require Mail::Box::Manager };
    
    # lots of pod
    eval { require diagnostics };
    
    # core modules are likely to be there
    eval { require Scalar::Util };
    eval { require File::Temp };
    eval { require IO::Handle };
    eval { require Memoize };
    eval { require Test };
    eval { require Test::Simple };
}

eval { require Pod::Stripper }; # interesting as a test suite.
my $diff = eval { require Text::Diff }; # more to test, and nicer output with large string comparisons

use Pod::Wrap;

$|=1;

$SIG{CHLD} = 'IGNORE'; #sub { wait until wait + 1 }; # damn lazy. Looks good with keyword highlighting.
$SIG{PIPE} = 'IGNORE'; # __END__s will cause perl to stop reading.

my @modules = values %INC;
plan tests => @modules + 1;

ok(Pod::Wrap->new(), "Create wrapper obj");

$Text::Wrap::columns = 90; # Opcode && Net::LDAP::Constant have __DATA__ section. It shouldn't be wrapped because B::Deparse keeps it (as it should).

foreach $_ (@modules){
    testFile($_); # test a filename
};

exit;

sub testFile {
    my $file = shift;
    
    my ($wrapped, $orig);
    
    
    SKIP:{
        eval {
            my $f = '';
            open FH, "+>", \$f;
            open IN, "<", $file;
            Pod::Wrap->new->parse_from_filehandle(\*IN,\*FH);
            close IN;
            seek FH, 0, SEEK_SET;
            $wrapped = deparse(\*FH);
            close FH;
            
            
            open IN, "<", $file;
            $f = '';
            1 while(sysread IN, $f, 4096, length($f));
            open FH, "<", \$f;
            $orig = deparse(\*FH);
            close FH;
        };
        
        if ($@){
            my $msg = $@;
            $msg =~ s/\n//s;
            skip ("Couldn't deparse ($@)",1);
        }
        
        local $TODO = "Decide if we want to do this one." if $file =~ /Stripper\.pm$/;
        
        if ($diff){ # if we have Text::Diff we make a nicer output on error
            if ($wrapped eq $orig){
                pass($file);
            } else {
                fail($file);
                my $diff = Text::Diff::diff(\$wrapped, \$orig);#, { STYLE => "Table" });
                foreach my $line (split($/, $diff)){
                    diag($line);
                }
            }
        } else { is ($wrapped, $orig, $file) }
    }
}

sub deparse {
    my $fh = shift;
    
    local $ENV{PERL_HASH_SEED} = 0; # GRRR!!!! otherwise deparse output will not be consistent
    IPC::Open3::open3(\*WRITE, \*READ, \*ERR, "perl", "-MO=Deparse") or die $!; # should be fatal (if it fails, or just because it's plain wrong).
    
    # out various handles
    my $w = IO::Select->new(\*WRITE);
    my $r = IO::Select->new(\*READ, \*ERR);
    
    my $output = '';
    my $buf = '';
    
    # write, reading if needed
    WRITE: while(my @h = map { @$_ } IO::Select->select($r,$w)){
        foreach my $h (@h){
            if ($h == \*READ){
                sysread READ, $output, 512, length($output);
            } elsif ($h == \*ERR){
                sysread ERR, $buf, 512;
            } elsif ($h == \*WRITE and not $w->has_exception(0)){
                if (read $fh, $buf, 512){
                    syswrite WRITE, $buf;
                } else {
                    close WRITE;
                    last WRITE;
                }
            }
        }
    }
    
    # just read
    READ: { while(my @h = map { @$_ } IO::Select->select($r, undef, undef, 10)){ foreach my $h (@h){
        if ($h == \*READ){
            sysread READ, $output, 512, length($output) or last READ;
        } elsif ($h == \*ERR) {
            sysread ERR, $buf, 512;
        } else {
            die "WTF?!\n";
        }
    }} die "$!" };
    
    close READ;
    close ERR;
    
    return $output;
}
