# Copyright (c) 2007 celmorlauren limited. All rights reserved. 
# This program is free software; you can redistribute it and/or modify it under
# the same terms as Perl itself.

package Sendmail::M4::Utils;
require Exporter;
use vars qw(@ISA @EXPORT $VERSION);
use strict;

@ISA    = qw(Exporter);
@EXPORT = ();
$VERSION= 0.27;

use IO::File;
use IO::Select;
use IPC::Open3;
use File::Copy;
use English;
#debug
use Data::Dumper;

=head1 NAME

Sendmail::M4::Utils - create and test sendmail M4 hack macro files

=head1 STATUS

Version 0.27 (Beta)

This compiles the M4 sendmail hack used by celmorlauren since version 0.23

HTML coding just STUBS at the moment.

=head1 SYNOPSIS

Sendmail is arguably the most powerfull and configurable e-mailing system in the world, however it does tend to be intimidating to System Adminstrators without a good foundation in programming. It is a very good idea to look at the "O'Reilly" publications "sendmail 3rd edition +" and their "Sendmail Cookbook", most tasks that need to be done can be solved by having a look at the "CookbooK".

Where a solution can not be found in the "Cookbook" or an existing "Hack" you will need to create your own.


Creating and testing B<sendmail hack macros> can be a tiresome and error prone business, this script has been developed to help, however you will still need to understand sendmail macros to use this. 
Testing methods are desgined to be used by both the commamd line and via HTML using a web browser.

Please note that you will have to hand edit your B<sendmail m4 #.mc> file, to include the reference to the B<hack> being generated, below is an example taken from our own B<linux.mc> file.
The line you must include, begins with B<HACK> the hack file follows, the current development version can be found as L<Sendmail::M4::Mail8> and L<Sendmail::M4::mail8>, B<mail8> is the program, B<Mail8> is its module, see their documetation for more.

    dnl  We use the generic m4 macro definition. This defines
    dnl  an extented .forward and redirect mechanism.
    dnl
    DOMAIN(`generic')dnl
    dnl
    HACK(`mail8-stop-fake-mx')dnl
    dnl  These mailers are available. per default only smtp is used. You have
    dnl  to add entries to /etc/mail/mailertable to enable one of the other
    dnl  mailers.
    dnl
    MAILER(`local')dnl
    MAILER(`smtp')dnl
    MAILER(`procmail')dnl
    MAILER(`uucp')dnl
    MAILER(`bsmtp')dnl
    MAILER(`fido')dnl
    dnl
    dnl  Just an other (open)ldap feature is the usage of maill500 as mailer
    dnl  for a given (open)ldap domain (see manual page mail500).
    dnl
    dnl MAILER(`mail500', `place_here_your_openldap_domain')dnl
    dnl
    dnl  This line is required for formating the /etc/sendmail.cf
    dnl
    LOCAL_CONFIG

The most notable help are.

=over 2

=over 2

=item MACRO{ 

When constructing "macros" is the ability to "nest" called macros within the text block of the calling "macro", below is an example of the development version of our ANTI-SPAM hack.

 rule <<RULE;
 SScreen_Local_check_rcpt_1
 R $*.FOUND      $@ MACRO{ $1 # checking for localusers and Trouble Tickets
     R $*.mail3      $@ MACRO{ $1 # Trouble Ticket user
         R $&{CheckRcpt}     $@ MACRO{ $&{CheckRcpt} # Valid TT?
             dnl TT must conform to minimal rules
             R $*                $: $>Screen_Local_check_mail_2 $&{CheckHelo} 
         }MACRO
         R $*                $@ $>ScreenMail8blocker ${mail3tt}
     }MACRO
 }MACRO
 RULE

Without the "nested" macro structure this could be difficult to keep track of, and indeed it was, thats why we have developed this.

=item Inline MACRO

The above B<MACRO{> also handles INLINE MACROS which enable much used logical statements to be included without the cost of another rule-set, this module includes a selection of these.

=item Packed Macro {MashFound#}

Most of the included INLINE MACROS use the packed macro {MashFound#}, which are designed to hold 9 long-names each, which of the {MashFound#} macros being refered to is invisable to the developer|user. And during testing the normal macro statement {####} where #### is a macro contained by {MashFound#} may be used, the testing program does all the required conversions.

This is required due to the limited number of free to use long-names, B<sendmail> assigns long-names for it-self at run-time. And so working OK during testing does not mean that sendmail will not fail at run-time. It is recommended to keep develeoper long-names to under 16.

=item TEST

Automated testing, the inclusion of test data within the source program, some of which is highly automated. It is very easy to generate 4000 lines of test results, the B<TEST> setup has expected replys, so will only stop on the unexpected, so any changes to a script can be checked with ease. 

=back

After using this to generate your HACK M4 files you will never want to it by hand again!

=back

This module is non OO, and exports the methods descriped under EXPORTS.

=head1 AUTHOR

Ian McNulty, celmorlauren limited (registered in England & Wales 5418604). 

email E<lt>development@celmorlauren.comE<gt>

=head1 USES

=over 16

=item IO::File

file creation

=item IPC::Open3 

to start "sendmail -bt -Ctest.cf"

=item File::Copy

to copy "tee" file to "file" in sendmails "hack" directory.

=item English

Data::Dumper   debuging this! used by our exported method "debug"

=back
    
=head1 EXPORTS

=cut

=head2 HASH REF = setup(@_)     returns HASH REF to internal hash %setup

=over 4

This configures this module, and is always required first.

The %setup hash is enclosed in a BEGIN block, to ensure that all programs and modules that use this get the same settings.

Expected/Allowed values allways as a (hash value pairing).

=over 16

=item hack_dir

SCALAR with default value of "/usr/share/sendmail/hack",

=item file

SCALAR "hack file name" to generate, with either full path or just the name, no default.

NOTE: "build" or "install" must also be specifed.

NOTE: if "install" is also defined a backup copy of "file" is made if it already exists!

=item sendmail

SCALAR with default value of "/usr/sbin/sendmail"

=item mc

SCALAR with default value of /etc/mail/linux.mc, this is the sendmail m4 source file to be used to build "cf", this is required for 'installation'

=item cf

SCALAR "test.cf file name" to build for testing purposes.

if "install" is specified and "cf" is not specified, will assume "test.cf" within current directory.

if "install" is specified and "cf" is is "sendmail.cf" will "die"!
    
otherwise will assume the main "sendmail.cf" is being tested. 

=item html

HASH REF, default is 0

=item build

SCALAR Generate|build "tee" file, this does not require root permissions.

Enables you to check the "tee", before installing it.

NOTE: ignored if also "html".

=item install

SCALAR

SU "root" permissions are required.
Copy "tee" file to "file", (sendmail hack directory file).  Create "cf" file.

NOTE: ignored if also "html".

=item test

SCALAR Will "build"|"install" before "test" if specified.

=item silent

SCALAR

STOPS all output! AND character translation!!  It is assumed that you are going to do something with the compiled rules.

=item error

ARRAY REF   only when also "silent" has contents of "moan", "whoops" will allways simply exit.
            
=item UNKNOWN

ARRAY REF remaining unknown arguments supplied.

=item tee

SCALAR automatic info, name optained from "file", this file does not need "root" SU permissions, and is placed in the current working directory.

Installation phase copies this to "file" which will need SU perms!

NOTE: if "build" is also defined a backup copy of "tee" is made if it already exists!

=item log

SCALAR automatic info, as "tee" but appended with ".log".

This file is generated during non "html" testing, contains all data entered by yourself and from "sendmail -bt".

If "file" is not also defined then this file will not be generated.

=item testing

SCALAR automatic info, set when "test" starts, changes the way both "ok" and "echo" operate.

=item SU

SCALAR automatic info, is user "root":"root".

=item time

SCALAR automatic info, "time" script started.

=item macro

SCALAR automatic variable, incremented on MACRO statements

=item rules

ARRAY REF automatic list of read in "S" macro rules

=item rule

HASH  REF automatic keyed by "rules" 

Format

=over 4

rule { 

=over 2

Stest_macro => { 

=over 2

=over 12

=item S => []

contains complete "S" macro coding

=item H => []

HINT's as to use

=item O => []

keys for "T" in order of specification

=item T => { 
    
TEST tests for coding

=over 2

=over 12

=item n => {
    
n = numeric count of test   

see L</rule::TEST> for details

=back

} 

=back

} 

=item M => []

contains list of SUB macros.  TOP Level S only!

=item F =>

SCALAR     only defined if FORCE is defined

=item N =>

SCALAR     only defined if NOTEST is defined

=item G => 

SCALAR     only defined if GLOBAL is defined

Top Level S only

1st line after S definition.

Reduces number of {macro_names} Limit of 96 !

=back

}

=back

}

=back

=back

=item inline

HASH REF automatic, where a rule is to be inlined, rule should start life as a standard rule above, when known to work OK, then inline. No other changes are needed. TEST lines etc are ignored.

Format is almost the the same as the the above rule, except most entrys are only here, so as not to break things.

Format

=over 4

inline { 

=over 2

Stest_macro => { 

=over 2

=over 12

=item S => []

contains complete "S" macro coding

=item G => SCALAR

only defined if GLOBAL is defined

=item I => []

contains list of sub inlines

=item H => []

exists only for compatability

=item O => []

exists only for compatability

=item T => {}

exists only for compatability
    
=item M => []

exists only for compatability

=item F => SCALAR

exists only for compatability

=item N => SCALAR

exists only for compatability

=back

}

=back

}

=back

=back

=item sane

HASH REF automatic, keyed normally by "rule", however anything may be used as a key.

Generated noramally by the method "sane" and refernced during testing by the MACRO TEST sub statement SANE "key".

Format

=over 4

sane { 

=over 2

=over 12

=item key => []

sendmail .D statements

=back

}

=back

=back

=item testing_domains

HASH REF automatic, generated by method "testing_domains", used during testing.

Format

=over 4

testing_domains {

=over 2

=over 12

=item OUR 

[ HELO, DOMAIN, IP, RESOLVE, FROM, RCPT \n ],
    
=item OK
    
[ HELO, DOMAIN, IP, RESOLVE, FROM, RCPT \n ],

=item BAD

[ HELO, DOMAIN, IP, RESOLVE, FROM, RCPT \n ],

=back

}

=back

testing_domains_keys {

=over 2

HELO    => 0,
    
DOMAIN  => 1,

IP      => 2,

RESOLVE => 3,

FROM    => 4,

RCPT    => 5,

=back

}

=back

Lists|lines of "," delimited values.

"OUR" is your domain,

"OK"  are legal domains and should be ok

"BAD" are faked|forged domains and should allways fail.


=item FOUND

HASH REF automatic, generated by MACRO statements such as FOUND, this uses just ONE "long name" to store as many FOUND statements as needed.

Format

=over 4

FOUND => {

=over 2

=over 12

=item LIST  => []

list of FOUND keys

=item KEY   => {}

key is {macro} value is FOUND key

=back

},

=back

=back

=item MASH_FOUND

HASH REF automatic, used during testing to keep current values for {MashFound} packed components.

Format

=over 4

MASH_FOUND => {

=over 2

macro   => value,

macro   => value,

macro   => value,

macro   => value,

=back

}

=back

=item magic

SCALAR  special value used by this program, do not use.

=item paranoid

SCALAR  value used by "Mail8" see its page for meaning.

=back

=back

=cut

=head2 debug @_

=over 4

debug prints out B<caller> info, and anything supplied to it, and asks for input, nothing and it will simply return, "n" or "no" and it B<exits>.

Note any refs supplied will parsed by B<Dumper> from package Data::Dumper

Included to help to debug this and modules that use it. Also when your code is OK it is easy to find and remove.

=back

=cut

push @EXPORT, "debug";
sub debug
{
    print "----STACK------------\n";
    my ($method,@stack) = &caller_ref();
    my @m_stack = map { print "  $_\n" } (@stack);
    print "----DUMPER-----------\n";
    map { print "$_\n" } map { (ref $_)?(Dumper $_):($_) } ( @_ );
    print "==================\nCarry on?>[Y|n]:>";
    my $d = &getline();
    scalar $d and $d=~/n/i and exit;
}

# debugging switch
my $DEBUG;

#global so all can see it
my %setup;

BEGIN {
# Need to know If this is being used by a SU root user
    my $gid = $GID;
    $gid =~ s/\s+.+//;
    my $root = (scalar $UID or scalar $gid )?(0):(1);
    my $time = localtime;


#configure it here
    %setup = (
        magic   => 0,
        paranoid=> 0,
        hack_dir=> "/usr/share/sendmail/hack",
        file    => 0,
        sendmail=> "/usr/sbin/sendmail",
        mc      => "/etc/mail/linux.mc",
        cf      => 0,
        html    => 0,
        build   => 0,
        install => 0,
        test    => 0,
        testing => 0,
        silent  => 0,
        tee     => 0,
        log     => 0,
        UNKNOWN => [],
        SU      => $root,
        time    => $time,
        macro   => 0,
        rule    => {},
        rules   => [],
        sane    => {},
        testing_domains => {
            OUR     => [],
            OK      => [],
            BAD     => [],
        },
        testing_domains_keys => {
            HELO    => 0,
            DOMAIN  => 1,
            IP      => 2,
            RESOLVE => 3,
            FROM    => 4,
            RCPT    => 5,
        },
        FOUND => {
            LIST    => [],
            KEY     => {},
        },
        MASH_FOUND => {},
    );
}
push @EXPORT, "setup";
sub setup
{
    while (scalar @_)
    {
        my $hash    = shift @_ or last;
        if ( exists $setup{$hash} )
        {
            $setup{$hash} = shift @_;
        }
        else
        {
            push @{$setup{'UNKNOWN'}}, $hash;
            last;
        }
    }
    push @{$setup{'UNKNOWN'}}, @_ if scalar @_;
    if ( $setup{'silent'} )
    {
        map { $setup{$_} = 0 } (qw(file tee log cf html build install test));
    }
    if ( $setup{'html'} )
    {
        map { $setup{$_} = 0 } (qw(file tee log build install));
        $setup{'test'} = 1;
    }
# can not install if not root
    $setup{'install'} = 0 unless $setup{'SU'};
    if ( $setup{'build'} or $setup{'install'} )
    {
        if ( my $file = $setup{'file'} )
        {
            my $tee;
# ok has file a path?
            if ( $file =~ /\// )
            {
                my @tee = split "/", $file;
                $tee    = pop @tee;
                $setup{"hack_dir"} = join "/", @tee;
            }
# ok place in std sendmail hack dir
            elsif ( my $hack_dir = $setup{'hack_dir'} )
            {
                $setup{'file'} = "$hack_dir/$file";
                $tee    = $file;
            }
# something wrong
            else
            {
                $tee = 0;
            }
# auto install on callback? magic is needed as otherwise build has precedence
            if ( $setup{'magic'} and $setup{'install'} and $tee and -f $tee )
            {
                $setup{'tee'} = $tee;
                &install();
                exit;
            }
            if ( $setup{'build'} and scalar $tee )
            {
                my $time= $setup{'time'};
                if ( -f $tee )
                {
                    unless ( rename $tee, "$tee.$time~" )
                    {
                        &moan("unable to archive existing $tee file");
                        undef $tee;
                        &ok("STOP RUN") and exit;
                    }
                }
            }
# auto install on callback?
            elsif ( $setup{'install'} and scalar $tee and -f $tee )
            {
                $setup{'tee'} = $tee;
                &install();
                exit;
            }
            unless ( scalar $tee )
            {
                map { $setup{$_} = 0 } (qw(file tee log build install));
                &moan( "err unable to obtain \"tee\" from \"file\"",
                     map { "$_ = $setup{$_}" } (qw(install build file)));
            }
            $setup{'tee'} = $tee;
        }
        else
        {
            map { $setup{$_} = 0 } (qw(file tee log build install));
        }
    }
    if ( $setup{"test"} and $setup{"tee"} )
    {
        my $log = $setup{"log"} = "$setup{'tee'}.log";
        my $time= $setup{'time'};
        if ( -f $log )
        {
            unless ( rename $log, "$log.$time~" )
            {
                &moan("unable to archive existing $log file");
                &ok("STOP RUN") and exit;
            }
        }
    }
    $setup{'cf'} = "test.cf" unless scalar $setup{'cf'};
    $setup{'cf'} =~ /sendmail\.cf/ and $setup{'install'} and die "install&cf=sendmail.cf";
    return \%setup;
}


=head2  0 = moan(@_)    allways returns 0

=over 4

Either prints out to STDERR or to a I<E<lt>tdE<gt>E<lt>tableE<gt>> HTML table depending on use.
Expects a list of moaning messages.

If setup{silent} places complaints in setup{error} instead of displaying

Perhaps this should be in Carp?

And just to let you know, our own comment module will be on CPAN soon, just as soon as the requested name space has been OKed, will be B<Carp::Comment>, not uploaded yet due to the module that depends on it not being ready.

=back

=cut

# this is the common code for both moan and whoops
sub caller_ref
{
#0 is ourselves!
    my $i = 1;
    my @stack;
    my $method = "moan";
    while((my($pack,$file,$line,$subname,@others) = caller($i++)))
    {
        my $stack;
#us our package
        if ( $pack =~ /^Sendmail::M4::Utils$/ )
        {
            $subname =~ /(show_moan|caller_ref)/ and next;
            $stack = "$subname ($line)";
            if ( $subname =~ /sendmail_(moan|whoops)/ )
            {
                pop @stack;
            }
            if ( $subname =~ /(moan|whoops)/ )
            {
                my $method = $subname;
                $method =~ s/^Sendmail::M4::Utils:://;
            }
        }
#someone using this package
        else
        {
            $stack = "$pack ($line) $subname";
        }
        push @stack, $stack;
    }
    return ($method,@stack);
}

sub show_moan
{
    my ($method,@stack) = caller_ref;
    my @m_stack = map { "$method  $_" } (@stack);
#display moan
    my @moan    = (
            @m_stack,
            map { "$method $_" } map { (ref $_)?(Dumper $_):($_) } ( @_ ),
            );
    if ( $setup{'silent'} )
    {
        my $e = $setup{'error'} = [];
        @$e   = @moan;
    }
    elsif ( scalar $setup{'html'} )
    {
        print "<td class = \"m4_error\">",
                "<table class = \"m4_error\">",
                    map { "<tr><td>$_</td></tr>" } (@moan),
                "</table>",
              "</td>";
    }
    else
    {
        my $moan = join "\n", @moan;
        no strict;
        print STDERR "$moan\n";
    }
    return 0;
}

push @EXPORT, "moan";
sub moan
{
    return show_moan @_;
}

=head2  whoops(@_)    allways exits

=over 4

Based on B<moan> and does much the same except it also exits.

Perhaps this should be in Carp?

=back

=cut
push @EXPORT, "whoops";
sub whoops
{
    show_moan @_;
    exit;
}

#getline explict readline from STDIN, as this uses strict
sub getline
{
    my $line;
    {
        no strict;
        $line = <STDIN>;
    }
    chomp $line;
    return $line;
}
    
=head2  $ok = ok("message")     message defaults to "OK" or "TRY: "

=cut
push @EXPORT, "ok";
sub ok
{

=pod

=over 4

=over 12

=item NOTE:

NOT for HTML! or when "silent"

ALLWAYS does nothing, just returns 1 or 0 if "testing".

=back

=cut
    ($setup{'html'} or $setup{'silent'}) and return ($setup{'testing'})?(0):(1);

=pod

print "message?"            allways apends a ?

=cut
    my ($package, $filename, $line) = caller;
    my $caller  = ($package=~/Sendmail::M4::Utils/)?("($line)"):("$package ($line)");

    my $def_msg= ($setup{'testing'})?("TRY: "):("OK");
    my $ok_msg = shift @_;
    scalar $ok_msg or $ok_msg = $def_msg;
    print "$caller, $ok_msg?";
    my $ok = getline;
    unless ($setup{'testing'})
    {

=pod

Normal usage, when not "testing".

=over 4

=over 32

=item <STDIN> "reply" "y" or "CR"

returns 1  OK!

=item anything else

returns 0  NOT OK!

=back

=back

=cut
        scalar $ok or return 1;
        return ($ok =~ /y/i)?(1):(0);
    }
    else
    {

=pod

During "testing"

=over 4

=over 32

=item E<lt>STDINE<gt> "CR"

returns 0

=item anything else

returned as is

=back

=back

=back

=cut
        return (scalar $ok)?($ok):(0);
    }
}

# tee, output to file, a bit like the shell command
sub tee
{
    my $file= ($setup{'testing'})?('log'):('tee');
    my $tee = $setup{$file};
    if (scalar $tee)
    {
        my $TEE;
        unless ( open $TEE, ">>$tee" )
        { 
            whoops "tee: cant open \"$file\" $tee","exit code $?"; 
            undef $setup{$file}; 
            return @_; 
        }
        if ( scalar @_ )
        {
            map { print $TEE "$_\n"; } (@_);
        }
        else
        {
            print $TEE "\n";
        }
        close $TEE;
    }
    return @_;
}

=head2 @_ = translate @_

=over 4

Does all the formating for B<echo> & B<build>.

Currently 

=over 4

UTF8 ("pound" UKP)|("euro" E) to $ conversion, also converts 3+ spaces to a tab.

EURO character works, but breaks Perldoc display for Perl 5.6! So for the B<pod> bits EURO character is shown either as B<EURO> or B<E>.

POUND character works, but looks bad on CPAN, will display correctly on Perldoc for 5.8.8, but not on earlier versions, so is shown for these pages as B<POUND> or B<UKP>

=back

=back

=cut
push @EXPORT, "translate";
sub translate
{
    return map { $_=~s/(£|€)/\$/g; $_=~s/\s{3,}/\t/g;$_ } map{ split "\n",$_ } (@_);
}

=head2  echo @_   

=over 4

This produces output, both to the screen and to the "tee" file, most functions use this to output, this does a simple echo with no other formating other than shown below.

During B<testing> no formating is done, text is output as is with just a "linefeed" appended.

Otherwise.

Sendmail expects tabed macro fields, however your "vi" session may be set to use spaces and colours etc, also "$" is used to signify a varity of things and this causes problems for Perl SCALARS. 

To get round these problems, and to allow for better looking text. 

=over 2

In your code use at least 3 spaces where sendmail expects a "tab", and use ("B<POUND>" or "B<EURO>") where sendmail expects a "$", however if you are not using a keyboard with either of these symbols then you will have to escape \$ as normal.

"echo" does UTF8 ("pound" B<UKP>)|("euro" B<E>) to $ conversion, also converts 3+ spaces to a tab, this is done via B<translate> above.

=back

=over 12

=item NOTE:

NOT for HTML! or when "silent"

ALLWAYS does nothing, just returns 1 or 0 if "testing".

=back

=back

=cut
push @EXPORT, "echo";
sub echo
{
    ($setup{'html'} or $setup{'silent'}) and return 1;
    if ( $setup{'testing'} )
    {
        scalar @_ and map { print "$_\n"; } tee map{ split "\n",$_} (@_);
    }
    elsif ( scalar @_ )
    {
        map { print "$_\n"; } tee translate(@_);
    }
    else
    {
        print "\n";
        tee;
    }
}
    
=head2 dnl @_

=over 4

For sendmail "dnl" comments, wraps supplied args in "dnl".

=over 12

=item NOTE:

NOT for HTML! or when "silent"

ALLWAYS does nothing, just returns 1 or 0 if "testing".

=back

=back

=cut
push @EXPORT, "dnl";
sub dnl 
{
    ($setup{'html'} or $setup{'silent'}) and return 1;
    echo map { "dnl $_ dnl" } map {split "\n",$_} (@_);
}

######################
# rule
#####################

=head2 define_MashFound @_

=over 4

It is safest to define {MashFound} before use, supply it with a list of {macro names} which will be stored within this packed macro, sets up %setup{FOUND} and %setup{MASH_FOUND}.

=back

=cut
push @EXPORT, "define_MashFound";
sub define_MashFound
{
    my $FOUND   = $setup{'FOUND'};
    my $L_KEY   = scalar @{$FOUND->{'LIST'}};
    my $FOUND_LIST;
    unless ( scalar $L_KEY )
    {
        $FOUND_LIST  = $FOUND->{'LIST'}->[0] = [];
    }
    else
    {
        $L_KEY--;
        $FOUND_LIST  = $FOUND->{'LIST'}->[$L_KEY];
    }
    my $KEY     = scalar @$FOUND_LIST;

    my $MASH_FOUND = $setup{'MASH_FOUND'};

    foreach my $load_macro (@_)
    {
        if ( $KEY > 8 )
        {
            $L_KEY++;
            $KEY = 0;
            $FOUND_LIST  = $FOUND->{'LIST'}->[$L_KEY] = [];
        }

        $KEY = push @$FOUND_LIST, $load_macro;
        $FOUND->{'KEY'}->{$load_macro} = [$L_KEY, $KEY ];
        $MASH_FOUND->{$load_macro} = "none";
    }
}

sub DEFINE_MASHFOUND
{
    my $L_KEY   = scalar @{$setup{'FOUND'}->{'LIST'}};
    $L_KEY--;
    my $inits   = " £| 0" x 9; 
    my $key = <<KEY;
    R £*    £:$inits
KEY
    foreach my $KEY (0..$L_KEY)
    {
        $key .= <<KEY;
    R £*    £: £(SelfMacro {MashFound$KEY} £@ £1 £) £1
KEY
    }
    return $key;
}

=head2 testing_domains @_

=over 4

"testing_domains" expects at least two arguments|lines, the first is the B<key> for the HASH setup{testing_domains}, remaining argument|lines are ("," delimeted (HELO, DOMAIN, IP, RESOLVE, FROM, RCPT) values, which are for use during testing. 

Referenced during testing by B<TEST AUTO(key KEY sub_key1 sub_key2,)>

=over 2

where B<key> is one of (E,F,O,V), B<KEY> is one of (OUR,OK,BAD), and B<sub_key#> is one of (HELO,DOMAIN,IP,RESOLVE,FROM,RCPT)

=back

Format

    OUR
    mail.celmorlauren.com, 0, 80.176.153.184, FAIL, development@celmorlauren.com, ian@daisymoo.com
    mail.celmorlauren.co.uk, 0, 80.176.153.184, FAIL, development@celmorlauren.co.uk, ian@daisymoo.com
    mail.daisymoo.com, 0, 80.176.153.184, FAIL, development@daisymoo.com, ian@daisymoo.com


    BAD
    this.is.bogus.bogus, 0, 10.0.3.4, FAIL, you@localhost, ian@daisymoo.com

So long as there is a blank line, between B<keys> then definitions for OUR,OK,BAD can be done together as the sample above shows. This also allows "#" comment lines to be included for clarity.

You may notice that our IP does not resolve to a domain, that is a common problem and so B<Mail8> does not care about that, it only cares that the B<HELO> resolves to the connected B<IP>, the B<RESOLVE> of OK stops a B<DNS> look-up.

=back

=cut
push @EXPORT, "testing_domains";
sub testing_domains
{
    my ($rule, $rule_set);
    my @macro_rule = map { split "\n", $_ } (@_);
    foreach my $in_line (@macro_rule)
    {
        unless ( scalar $in_line )
        {
            $rule = undef;
            next;
        }
        my $line = $in_line;
        $line =~ s/^\s+//;
        if ( $line =~ /^#/ )
        {
            next;
        }
        elsif ( $line =~ /^(OUR|OK|BAD)$/ )
        {
            $rule = $1;
            $rule_set = $setup{"testing_domains"}->{$rule};
            next;
        }
        scalar $rule or whoops "testing_domains requires a key of (OUR|OK|BAD)", \@macro_rule;
        $line =~ s/,\s+/,/g;
        push @$rule_set, $line;
    }
}

=head2 SCALAR inline SCALAR (optional)

=over 4

single argument must be either B<0> or <1> or someother B<scalar> quantity. Always returns current value for B<inline>.
Argument is purely optional,if not supplied just returns current value.

This switches B<ON> or B<OFF> the B<INLINE> statement for B<rule>s and B<MACRO>s contained within them, enabling inline cabable B<rule>s to be tested as seperate B<macros> and then inlined when known to be OK, it should be noted testing is required to ensure the inlining does not cause unwanted side effects.

Initial value is B<OFF>|B<0>

=back

=cut
push @EXPORT, "inline";
my $inline = 0;
sub inline
{
    scalar @_ and $inline = shift @_;
    return $inline;
}

=head2 sane @_

=over 4

"sane" expects at least two arguments|lines, the first is the B<key> for the HASH setup{sane}, remaining argument|lines are statements to be encoded as B<sendmail -bt .D> statments, statements are "," delimited.

Referenced during testing by B<TEST SANE(key)>

Format

    Local_check_mail
    {client_addr}127.0.0.1, {client_name}Localhost, {client_resolve}OK

=back

=cut
push @EXPORT, "sane";
sub sane
{
    my (@macro_rule);
    my $rule    = shift @_;
    if ( scalar @_ )
    {
        @macro_rule = map { split ",", $_ } map { $_ =~ s/,\s+/,/g; $_ } map { split "\n", $_ } (@_);
    }
    else
    {
        @macro_rule = map { split ",", $_ } map { $_ =~ s/,\s+/,/g; $_ } (split "\n", $rule);
        $rule  = shift @macro_rule;
    }
    my $rule_set = $setup{"sane"}->{$rule} = [];
    @$rule_set = @macro_rule;
}

=head2 rule @_

=over 4

"rule" is the main worker, sendmail macros are very powerfull and usefull, you will need to understand the "sendmail" macro programming syntax to use this.

=over 2

=over 4

=item 1

1st argument|line is the "S" macro rule, which must start with "S".

=item 2

2nd argument|line B<GLOBAL A> were B<A> is the letter to use. B<OPTIONAL>

=over 4

GLOBAL is a special argument that is used to reduce the number of B<sendmail {macro_names}>, as B<sendmail> has a limit of B<96>. It works by using the B<letter> specified (defaults to Z) to base its naming policy, sub macros are numbered from ZERO. Use it if you have the sendmail error message "B<too many long names>"

=back

=item 3

2nd or 3rd argument|line B<INLINE> code is intended to be (inlined)

=over 4

INLINE is a special argument that is used to reduce the number of B<sendmail "named rulesets"> as B<sendmail> has a standard limit of B<100>. Used with the method B<inline> this will inline code rather than define them as B<rule sets>, resulting in a lower count of B<rule sets> at the expense of larger file size. Use it if you have the sendmail error message "B<too many named rulesets>".

Best policy is to test small sections as "rule sets" and inline when noted to be OK. But remember to ensure all works OK when inlined.

=back

=back

Remaining argumentslines are the Macro, normally starting with "R", or something that make sense as a macro to sendmail.
The generated macro code returns the supplied arg by default, unless the code returns first.

=back

Extensions to the sendmail syntax are

=over 2

=cut
push @EXPORT, "rule";
sub rule
{
    my (@macro_rule,@macro_rules);
    my $rule    = shift @_;
    if ( scalar @_ )
    {
        @macro_rule = map { split "\n", $_ } (@_);
    }
    else
    {
        @macro_rule = split "\n", $rule;
        $rule  = shift @macro_rule;
    }
# init macro list with main S RULE, also only top level has a M list
    my $rule_set = { S => [], O => [], T => {}, M => [], H => [],};
    my $macros   = $rule_set->{"M"};
#GLOBAL
#sendmail has a limit of 96 {macro_names} including its own!
    my $global = $macro_rule[0];
    if ( $global =~ s/^\s*GLOBAL\s*// )
    {
        shift @macro_rule;
        $global = "Z" unless scalar $global;
        $global = uc $global;
        $rule_set->{'G'} = $global;
    }
#INLINE
#sendmail has a standard limit of 100 {named rulesets} including its own
    my $INLINE = $macro_rule[0];
    if ( $INLINE =~ s/^\s*INLINE\s*// )
    {
#inline also set global, for safty reasons
        my $use_inline = $inline;
        $INLINE =~ s/^ALLWAYS\s*// and $use_inline = 1;
        if ( $use_inline )
        {
            $setup{"inline"}->{$rule} = $rule_set;
            $macros = $rule_set->{"I"} = [];
            $global = "Z" unless scalar $global;
            $rule_set->{'G'} = $global;
            $INLINE = 1;
        }
        else
        {
            $setup{"rule"}->{$rule} = $rule_set;
            $INLINE = 0;
        }
    }
    else
    {
        $setup{"rule"}->{$rule} = $rule_set;
        $INLINE = 0;
    }
#keep backup copy for use later on
    @macro_rules = @macro_rule;
# main rule, and any sub macros have the same properties
    &macro($rule, $macros, \@macro_rules);
#only standard rulesets have sub macros
    $macros = $rule_set->{"M"};
# now for output? But not if silent!
    (scalar $setup{"silent"} or scalar $INLINE) and return;
#HTML layout
    if ( scalar $setup{"html"} )
    {
#TODO
    }
    else
#Standard Layout
    {
        echo @{$rule_set->{"S"}};
# have we macros? (inline does not, or should not)
        foreach ( @$macros )
        {
            $_ =~ /^NOSUCH\s+/ and next;
            echo;
            echo @{$setup{"rule"}->{$_}->{"S"}};
        }
        echo;
    }
}
# MACRO for use within rules
# usage where a sub macro is called as below, but we are only using it for IF ELSE reasons
#   R $*            $: $>Screen_bad_relay $&{RelayIP}           mail8 DB, spammer relay check
# use MACRO
#   R $*            $: MACRO{ $&{RelayIP} #mail8 DB, spammer relay check
#       R $*            $: $>Screen_bad_relay2 $1               mail8 DB, spammer relay check
#       R $*            $: $(SelfMacro {BadRelay} $@ $1 $) $1
#   }MACRO
#
# MACRO code may be nested as deeply as required, also can be indented to improve readability
#
#

# MashFound use a single "long name" instead of several
sub MashPack
{
#TODO
    my @sane_define;
#one day the packed macro {mash_found} may not be needed, but in the mean time to keep testing simple
#translate sane and define statemnts into packed form if they have been declared
    my (@pre_sane, %pre_sane);
    my $mash_found = 0;
    foreach my $pre_sane (@_)
    {
        if ( $pre_sane =~ /\{/ )
        {
            my $pre_mash = $pre_sane;
            $pre_mash =~ s/\{//;
            $pre_mash =~ s/\}.+$//;
            if ( exists $setup{'MASH_FOUND'}->{$pre_mash} )
            {
                $pre_sane =~ s/\{\w+\}//;
                $setup{'MASH_FOUND'}->{$pre_mash} = $pre_sane;
                my ($L_KEY,$KEY) = @{$setup{'FOUND'}->{'KEY'}->{$pre_mash}};
                $pre_sane{$L_KEY} = $KEY;
                $mash_found++;
            }
            else
            {
                push @sane_define, ".D$pre_sane";
            }
        }
        else
        {
            push @sane_define, ".D$pre_sane";
        }
    }
    if ( scalar $mash_found )
    {
        foreach my $L_KEY ( keys %pre_sane )
        {
            my $pre_sane = "Translate \$| $L_KEY \$| ".join ' $| ',(map "$setup{'MASH_FOUND'}->{$_}",@{$setup{'FOUND'}->{'LIST'}->[$L_KEY]});
            if ( $pre_sane{$L_KEY} < 9 )
            {
                my $diff = 9 - $pre_sane{$L_KEY};
                $pre_sane .= " \$| 0" x $diff;
            }
            push @sane_define, $pre_sane;
        }
    }
    return @sane_define;
}

sub MashCalcs
{
    my ($load_macro) = @_;
    my $FOUND = $setup{'FOUND'};
    scalar $FOUND->{'KEY'}->{$load_macro} or define_MashFound $load_macro;
    my ($L_KEY,$KEY) = @{$FOUND->{'KEY'}->{$load_macro}};
    my $FOUND_LIST  = @{$FOUND->{'LIST'}->[$L_KEY]};
    my $MashFound   = "£|£+" x $KEY;
    my $end_KEY     = $KEY - 1;
    my $MashRewrite = "";
    if ( $KEY > 1 )
    {
        $MashRewrite = "£|" . join "£|", (map "£$_", (1..$end_KEY)); 
    }
    $end_KEY += 2;
    my $wild_end = "";
    if ( $FOUND_LIST < 9 or $KEY < 9 )
    {
        $MashFound .= "£|£+";
        $wild_end   = "£|£$end_KEY";
    }
    return ( $L_KEY, $KEY, $MashFound, $MashRewrite, $wild_end );
}

sub MashStore
{
    my ( $L_KEY, $KEY, $MashFound, $MashRewrite, $wild_end ) = MashCalcs @_;
    my $key = <<KEY;
    R £*                    £: £(SelfMacro {MashTempB} £@ £1 £) £1
    R £*                    £: £&{MashFound$L_KEY}
    R $MashFound            £: $MashRewrite£|£&{MashTempB}$wild_end
    R £*                    £: £(SelfMacro {MashFound$L_KEY} £@ £1 £) £1
KEY
    return $key;
}

sub MashFound
{
    my ( $L_KEY, $KEY, $MashFound, $MashRewrite, $wild_end ) = MashCalcs @_;
    my $LOAD_MACRO = "SelfMacro$_[0]";
    my $key = <<KEY;
    R £+.FOUND              £: $LOAD_MACRO.£1.FOUND
    R $LOAD_MACRO.£+        £: £(SelfMacro {MashTempB} £@ £1 £) £1
    R £+.FOUND              £: £&{MashFound$L_KEY}
    R $MashFound            £: $LOAD_MACRO.$MashRewrite£|£&{MashTempB}$wild_end
    R $LOAD_MACRO.£+        £: £(SelfMacro {MashFound$L_KEY} £@ £1 £) £1
KEY
    return $key;
}

sub MashFind
{
    my ( $L_KEY, $KEY, $MashFound, $MashRewrite, $wild_end ) = MashCalcs @_;
    my $key = <<KEY;
    R £*                    £: £&{MashFound$L_KEY}
    R $MashFound            £: £$KEY
KEY
    return $key;
}

sub macro
{

    my ($rule, $macros, $macro_rules, $macro_inline) = @_;

    my $rule_hash   = $setup{"rule"};
    my $rule_list   = $setup{"rules"};
    my $rule_set    = $rule_hash->{$rule};

=pod

INLINE

=over 2

B<INLINE> must be the very first line, (after B<GLOBAL> if used), this B<inlines> this macro rule instead of producing a real B<named ruleset>, this statement only has effect if B<inline 1> has been used, otherwise it only modifies the generated maco not to return the original saved value (so as not to break things when inlined).

B<INLINE> supports sub arguments

=over 4

B<ALLWAYS> which overrides the global value of $inline, meaning that this code will allways be INLINED, also that this code is expected to allways work correctly and does not require any testing, please refrain from using this youself as it is intended for internal program use. Most if not all internal MACROS are coded this way.

Note: ALLWAYS is the 1st sub argument after INLINE, and other sub arguments may follow.

    Usage:
            INLINE ALLWAYS MASH
            INLINE ALLWAYS MASH TempA

B<NOMASH> which also stops the normal action of saving the original value.

    Usage:
            INLINE NOMASH

B<MASH> retores original saved value at the end of this macro rule, so for routines that are much used, they remain more like the original MACRO specification (without INLINE), also a over-ride value for MASH may follow, internal methods use B<TempA> which results in {MashTempA}

    Uasage:
            INLINE MASH
            INLINE MASH TempA

=back            

If a named B<rule seet> is inlined all its component B<MACRO>s B<must> also inlined! and so must also be compliant with B<INLINE> usage.

Also note it is advised that B<GLOBAL> has also been specified, otherwise this will assume the default GLOBAL of Z.

Note all code within the INLINED macro must be compliant with the usage, use of a RHS $@ will cause this to B<whoops> complaing about the infrigment of use.

Otherwise all the things that a normall macro use may be specified, however when B<inline> is in effect all B<TEST> lines are ignored.

May be used in explicitly named rulesets and MACROs, the entire line B<R $*   $: $>ruleset $1> is replaced with the B<inlined code> that the ruleset refers to.

=back

=cut    
    my $INLINE = $macro_rules->[0];
    my $use_inline = $inline;
    my $allways;
    my ($NOMASH,$MASH,$OPTION,$TEMP);
    if ( $INLINE =~ s/^\s*INLINE\s*// )
    {
        $INLINE =~ s/^ALLWAYS\s*// and $use_inline = $allways = 1;
        $INLINE =~ /^NOMASH\s*/ and $NOMASH = 1;
        $INLINE =~ s/^MASH\s*// and $MASH = 1 and $TEMP = $INLINE;
        shift @$macro_rules;
        if ( $use_inline )
        {
#are we using the parents macro settings?
            if ( $macro_inline and ref $macro_inline)
            {
                $rule_set = { 
                    S => $macro_inline->{'S'}, 
                    O => [], 
                    T => {}, 
                    H => [],
                    G => $macro_inline->{'G'},
                };
            }
            else
            {
                $rule_hash   = $setup{"inline"};
                $rule_set    = $rule_hash->{$rule};
            }
            $rule_list   = [];
        }
        $INLINE = 1;
    }

=pod

OPTION

=over 2

B<OPTION> must be the very first line, (after B<GLOBAL> if used), and can not be used with B<INLINE>, it supports sub arguments that alter the formatation of normal non INLINE macros.

B<OPTION> supports sub arguments

=over 4

B<NOMASH> which also stops the normal action of saving the original value.

    Usage:
            OPTION NOMASH

B<MASH> which forces the Macro to use a B<known> value for its mash

    Usage:
            OPTION MASH 1

    Which generates {MashA1} if GLOBAL is A            

=back            

=back

=cut    
    elsif ( $INLINE =~ s/^\s*OPTION\s*// )
    {
        $INLINE =~ /^NOMASH\s*/ and $NOMASH = 1;
        $INLINE =~ s/^MASH\s*// and $MASH = $OPTION = $INLINE;
        shift @$macro_rules;
        $INLINE = undef;
    }
    else
    {
        $INLINE = undef;
        $MASH   = 1;
    }
    my $macro       = $setup{'macro'};
#my $rule_hash   = $setup{"rule"};
#my $rule_list   = $setup{"rules"};
    my $rules       = $rule_set->{"S"};
    my $test_hash   = $rule_set->{"T"};
    my $test_list   = $rule_set->{"O"};
    my $hint_list   = $rule_set->{"H"};
    my $tests       = 0;

    my $mash = push @$rule_list, $rule;
#GLOBAL 
    my $global      = $rule_set->{'G'};
    if ( scalar $TEMP )
    {
        $mash = $TEMP;
    }
    elsif ( scalar $global and scalar $OPTION )
    {
        $mash = "$global$OPTION";
    }
    elsif ( scalar $OPTION )
    {
        $mash = $OPTION;
    }
    elsif ( scalar $global )
    {
        my $mashed = scalar @$macros;
        $mash = "$global$mashed";
    }
#save S argument to return if S does not return first
    push @$rules, $rule  unless ($INLINE and $use_inline);
    push @$rules, "R £*    £: £(SelfMacro {Mash$mash} £@ £1 £) £1"  unless $NOMASH;
#read through supplied S definition
    while ( my $line = shift @$macro_rules )
    {
#remove all leading space
        scalar $DEBUG and debug $line;
        $line =~ s/^\s+//;

=pod

# comment line within Rule to improve readability, otherwise ignored

=cut

        $line =~ /^#/ and next;

#=pod
#
#when code is INLINE B<$@> returns are a very bad idea, and will cause all sorts of strange problems, code may work as a MACRO but weird things happen when inlined!
#
#However if B<ALLWAYS> is defined then, the action of the macro will never vary, and so any return can be assumed to be OK
#
#=cut
        unless ( scalar $allways )
        {
            $INLINE and $line =~ /\s{3,}(€|£|\$)@\s*/ and whoops "CODE IS INLINE!", $line, $rule, $rule_set;
        }
#does line reference an inline coded "rule set" macro??
        my $call_line = $line;
        if ( $call_line =~ s/\s{3,}(€|£|\$):\s*(€|£|\$)>/\n/ )
        {
            my ($pre_line, $maybe_macro) = split "\n", $call_line;
            $maybe_macro =~ s/\s+/\n/;
            ($maybe_macro) = split "\n", $maybe_macro;
            if ( my $inline_macro = $setup{'inline'}->{"S$maybe_macro"} )
            {
                my $inline_code = $inline_macro->{'S'};
                if ( scalar $inline_code and scalar @$inline_code )
                {
                    push @$rules, @$inline_code;
                }
                else
                {
                    whoops "INLINE $maybe_macro has an empty 'S'?", $inline_macro, $line, $rule, $rule_set;
                }
                next;
            }
        }
        elsif ( $call_line =~ s/\s{1}MACRO\{// and $use_inline )
        {
#peek ahead for inlined MACRO code
            my $peek_is_GLOBAL = $macro_rules->[0];
            my $peek_is_INLINE = $macro_rules->[1];
            if ( scalar $peek_is_GLOBAL  and $peek_is_GLOBAL =~ /(GLOBAL|INLINE)/ )
            {
                if ( $1 =~ /GLOBAL/ )
                {
                    unless ( scalar $peek_is_INLINE  and $peek_is_INLINE =~ /INLINE/ )
                    {
                        $peek_is_INLINE = 0;
                    }
                }
                else
                {
                    $peek_is_INLINE = 1;
                }
#OK looks like an INLINE call
                if ( $peek_is_INLINE )
                {
                    $call_line =~ s/\s+#/    /;
                    push @$rules, $call_line;
                    $macro = $setup{'macro'}++;
                    push @$macros, "NOSUCH $rule $macro";
# nested call to process sub macro, and tell it to use the same rule_set as this
                    &macro($rule, $macros, $macro_rules, $rule_set);
                    next;
                }

            }
        }

=pod

MACRO   MACRO{  }MACRO

=over 2

$: MACRO{ $1 # comment    ==  $: $>Sub_something $1     comment

MACRO{ opens a block, }MACRO terminates the block.
    
Enables a sub macro that is used only once to be contained within the calling macro stament block, it is however coded in the normal way in the hack file. MACROs may be nested as deeply as required, enabling easy to code and read complex IF|ELSE statment blocks. Example below.

 rule <<RULE;
 SSome_macro
 R $*.FOUND      $@ MACRO{ $1 # something.FOUND
     R $*.mail3      $@ MACRO{ $1 # something.mail3.FOUND
         R $&{CheckRcpt}     $@ MACRO{ $&{CheckRcpt} # Valid TT?
             dnl TT must conform to minimal rules
             R $*                $: $>Standard_TT_mail $1
         }MACRO
         R $*                $@ $>SBad_mail $1
     }MACRO
 }MACRO
 RULE


Please do not use the macro named B<SScreen_macro> yourself as it is used by this method appended with numerics

=back

=cut
        if ( $line =~ s/MACRO\{\s*/£>Screen_macro_\n/ )
        {
            $macro = $setup{'macro'}++;
            my ($start, $arg_comment) = split "\n", $line;
# get rid of leading space from nested macro?
            $start       =~ s/^\s+//;
# comment follows HASH, helps keep code readable
            if ( scalar $arg_comment )
            {
#has been noted that some macros are not supplied with anything
                $arg_comment =~ s/\s+#/\t/; 
                my ($arg,$comment) = split "\t", $arg_comment;
                if ( scalar $comment )
                {
                    push @$rules, "$start$macro $arg    $comment\n";
                }
                else
                {
                    push @$rules, "$start$macro $arg\n";
                }
            }
            else
            {
                push @$rules, "$start$macro\n";
            }
# sub macro rule, note $start has other bits
            $rule = "SScreen_macro_$macro";
# record this new S rule
            $rule_hash->{$rule} = { S => [], O => [], T => {}, H => [] };
# also note Global scheme being used if any
            $global and $rule_hash->{$rule}->{'G'} = $global;
            push @$macros, $rule;
# nested call to process sub macro
            &macro($rule, $macros, $macro_rules);
        }
        elsif ( $line =~ /\}MACRO/ )
        {
            last;
        }

=pod

DEFINE_MASHFOUND

=over 2

Must be used after the Perl statement B<define_MashFound> and before any M4 macro statements that refer to the packed macro {MashFound}.

This should be placed in the first B<rule> that is used, and before any other capatalised macros, such as B<FIND> B<IS> etc. Failure to do so will cause unpredictable errors elsewhere when running the M4 hack file.

=back

=cut
        elsif ( $line =~ s/^DEFINE_MASHFOUND\s*// )
        {
            my $key = DEFINE_MASHFOUND;
            my $found_macro = <<FOUND;
    INLINE ALLWAYS MASH TempA
    NOTEST AUTO        
    $key
}MACRO
FOUND
            my @found_macro = split "\n", $found_macro;
            $macro = $setup{'macro'}++;
            push @$macros, "NOSUCH $rule $macro";
# nested call to process sub macro, and tell it to use the same rule_set as this
            &macro($rule, $macros, \@found_macro, $rule_set);
        }

=pod

FOUND

=over 2

expects a single argument, which is the B<{macro}> to be loaded with the $+.FOUND if that is the case,
this is a an inbuilt B<INLINE ALLWAYS> MACRO which generates code to be included in m4 source.

Usage:

    FOUND BadRelay

BadRelay will be loaded with $+.FOUND only if B<R $+.FOUND>, current work space is saved and restored.

comments may be used, this will be included as a "dnl" line within the macro

It should be noted that only {MashFound} is used, the {macro} is now a key to an internal array kept by {MashFound}, this compexity is required due to the limited number of "long names" available to the developer, testing does not show up these limitations, it requires sendmail to be run for real and observed while talking to other servers.

=back

=cut
        elsif ( $line =~ s/^FOUND\s+// )
        {
            $line =~ s/\s+/\t/;
            my ($load_macro,$comments) = split "\t", $line;
            my $comment = (scalar $comments)?($comments):("if FOUND save into $load_macro");
            my $LOAD_MACRO = "SelfMacro$load_macro";
            my $key = MashFound $load_macro;
            my $found_macro = <<FOUND;
    INLINE ALLWAYS MASH TempA
    NOTEST AUTO        
    dnl $comment dnl
    $key
}MACRO
FOUND
            my @found_macro = split "\n", $found_macro;
            $macro = $setup{'macro'}++;
            push @$macros, "NOSUCH $rule $macro";
# nested call to process sub macro, and tell it to use the same rule_set as this
            &macro($rule, $macros, \@found_macro, $rule_set);
        }

=pod

FIND

=over 2

expects a single argument, which is the B<{MashFound}->{macro}> to be accessed and have its contents placed in the workspace, this is now the only way to access items saved by B<FOUND>.

this is a an inbuilt B<INLINE ALLWAYS> MACRO which generates code to be included in m4 source.

Usage:

    FIND BadRelay

=back

=cut
        elsif ( $line =~ s/^FIND\s+// )
        {
            $line =~ s/\s+/\t/;
            my ($load_macro,$comments) = split "\t", $line;
            my $key = MashFind $load_macro;
            my $found_macro = <<FOUND;
    INLINE ALLWAYS NOMASH
    NOTEST AUTO        
    $key
}MACRO
FOUND
            my @found_macro = split "\n", $found_macro;
            $macro = $setup{'macro'}++;
            push @$macros, "NOSUCH $rule $macro";
# nested call to process sub macro, and tell it to use the same rule_set as this
            &macro($rule, $macros, \@found_macro, $rule_set);
        }

=pod

STORE

=over 2

expects a single argument, works like FOUND excecpt allways loads value with current work space.

this is a an inbuilt B<INLINE ALLWAYS> MACRO which generates code to be included in m4 source.

Usage:

    STORE BadRelay

=back

=cut
        elsif ( $line =~ s/^STORE\s+// )
        {
            $line =~ s/\s+/\t/;
            my ($load_macro,$comments) = split "\t", $line;
            my $key = MashStore $load_macro;
            my $found_macro = <<FOUND;
    INLINE ALLWAYS MASH TempA
    NOTEST AUTO        
    $key
}MACRO
FOUND
            my @found_macro = split "\n", $found_macro;
            $macro = $setup{'macro'}++;
            push @$macros, "NOSUCH $rule $macro";
# nested call to process sub macro, and tell it to use the same rule_set as this
            &macro($rule, $macros, \@found_macro, $rule_set);
        }

=pod

IS

=over 2

Expects upto 3 arguments. Number expected depends on the first argument.

=over 4

=cut
        elsif ( $line =~ s/^IS\s+// )
        {

=pod            

B<FOUND> expects 2 sub arguments.

=over 2

=over 4

=item 1

is the B<{macro}> to check for B<.FOUND>, just the name, do not enclose in brackets.

    IS FOUND Bounce

=item 2

is the B<action> to do if B<.FOUND>, since the nature of this INLINE ALLWAYS MASH macro never varys the normal form would be
    $@ $>SomethingOrOther $1
alternativly if you do not care about the returned value    
    $: $>SomethingOrOther $1
or even
    $#err something

    IS FOUND Bounce $# "Bounce not wanted here"

=back

=back

B<THISFOUND> expects 1 argument, the B<action> as B<FOUND>

=over 2

checks current B<work space> for B<.FOUND>

    IS THISFOUND $@ $1.FOUND

=back

B<REFUSED> and B<ALREADYREFUSED> expects 1 argument, the B<action> as B<FOUND>

=over 2

Normally the action should be B<#err somthing>

B<REFUSED> and B<ALREADYREFUSED> the checked B<{macro}> is either {Refused} or {AlreadyRefused}, these macro's are used by B<Mail8>, however we feel that these are usefull to other scripts.

=back

AND (REFUSED|ALREADYREFUSED) $#err somthing

=over 4

B<AND> is a special sub macro statement that allows the actions that REFUSED|ALREADYREFUSED does to be enacted also without the cost of another B<rule set>. See below, we are not refering to the "IS REFUSED"!

    IS FOUND Bounce AND REFUSED  $#err somthing

=back

=back

=back

=cut
            if ( $line =~ s/^(THISFOUND|FOUND|REFUSED|ALREADYREFUSED)\s+// )
            {
                my $load_macro = $line;
                my $this_found;
                if ( $1 eq "THISFOUND" )
                {
                    $this_found = 1;
                    $load_macro = "This";
                }
                elsif ( $1 eq "FOUND" )
                {
                    $load_macro =~ s/\s+.*$//;
                    $line =~ s/^\w+\s+//;
                }
                elsif ( $1 eq "REFUSED" )
                {
                    $load_macro = "Refused";
                }
                else
                {
                    $load_macro = "AlreadyRefused";
                }
                my $LOAD_MACRO = "SelfMacro$load_macro";
                my $found_macro = <<FOUND;
    INLINE ALLWAYS MASH TempA
    NOTEST AUTO        
FOUND
                if ( scalar $this_found )
                {
                    $found_macro .= <<FOUND;
    R £+.FOUND          £: $LOAD_MACRO.£1.FOUND
FOUND
                }
                else
                {
                    $found_macro .= MashFind $load_macro;
                    $found_macro .= <<KEY;
    R £+.FOUND          £: $LOAD_MACRO.£1.FOUND
KEY
                }
                if ( $line =~ s/^AND\s+//)
                {
                    if ( $line =~ s/^(REFUSED|ALREADYREFUSED)\s*// )
                    {
                        if ( $1 eq "REFUSED" )
                        {
                            $load_macro = "Refused";
                        }
                        else
                        {
                            $load_macro = "AlreadyRefused";
                        }
                        $found_macro .= MashFound $load_macro;
                        if ( scalar $line )
                        {
                            $found_macro .= <<FOUND;
    R £*                £: £&{MashSelf}            
    R £+.FOUND          £: $LOAD_MACRO.£1.FOUND
    R $LOAD_MACRO.£+    $line
}MACRO
FOUND
                        }
                        else
                        {
                            $found_macro .= <<FOUND;
}MACRO
FOUND
                        }
                    }
                    else
                    {
                        whoops "IS $load_macro, uexpected AND $line";
                    }
                }
                else
                {
                    $found_macro .= <<FOUND;
    R $LOAD_MACRO.£+    $line
}MACRO
FOUND
                }
                my @found_macro = split "\n", $found_macro;
                $macro = $setup{'macro'}++;
                push @$macros, "NOSUCH $rule $macro";
# nested call to process sub macro, and tell it to use the same rule_set as this
                &macro($rule, $macros, \@found_macro, $rule_set);
            }
        }

=pod

B<REFUSED> and B<ALREADYREFUSED>

=over 2

These INLINE ALLWAYS MASH macros, load the {client_addr}.FOUND into the {macro} which is either {Refused} or {AlreadyRefused}, a single sub argument is expected, which is the action to do, however if the sub argument is ommited, this will simply store and do nothing else.

Normally
    REFUSED $#err something

=back

=cut
        elsif ( $line =~ s/^(REFUSED|ALREADYREFUSED)\s*// )
        {
            my $load_macro = $line;
            if ( $1 eq "REFUSED" )
            {
                $load_macro = "Refused";
            }
            else
            {
                $load_macro = "AlreadyRefused";
            }
            my $LOAD_MACRO = "SelfMacro$load_macro";
            my $found_macro = <<FOUND;
    INLINE ALLWAYS MASH TempA
    NOTEST AUTO        
    R £*                £: £&{client_addr}.FOUND
FOUND
            $found_macro .= MashStore $load_macro;
            if ( scalar $line )
            {
                $found_macro .= <<FOUND;
    R £*                $line
}MACRO
FOUND
            }
            else
            {
                $found_macro .= <<FOUND;
}MACRO
FOUND
            }
            my @found_macro = split "\n", $found_macro;
            $macro = $setup{'macro'}++;
            push @$macros, "NOSUCH $rule $macro";
# nested call to process sub macro, and tell it to use the same rule_set as this
            &macro($rule, $macros, \@found_macro, $rule_set);
        }

=pod

{MashSelf}

=over 2

{MashSelf} provides access to the autosaved argument for this rule.

Usage
    R $*    £: &${MashSelf}

=back

=cut
        elsif ( $line =~ s/\{MashSelf\}/\{MashSelf\}\n/g )
        {
            my @MashStack = split "\n", $line;
            $NOMASH and whoops "attempt at using {MashSelf}", @MashStack;
            $line = "";
            while ( my $next = shift @MashStack )
            {
                if ( $next =~ s/\{MashSelf\}$// )
                {
                    $line .= "$next"."{Mash$mash}";
                }
                else
                {
                    $line .= $next;
                }
            }
            push @$rules, $line;
        }

=pod

{MashStack}

=over 2

{MashStack} provides a lasy way to keep data, without polluting other data.
Allways append something to the "MashStack", such as "A" as shown in the example.

Usage
    R $*    $: &${MashStackA}
    R $*    $: &${MashStackB}

=back

=cut
        elsif ( $line =~ s/\{MashStack/\{MashStack\n/g )
        {
            my @MashStack = split "\n", $line;
            $NOMASH and whoops "attempt at using {MashStack}", @MashStack;
            $line = "";
            while ( my $next = shift @MashStack )
            {
                if ( $next =~ /\{MashStack$/ )
                {
                    $line .= "$next$mash"."D";
                }
                else
                {
                    $line .= $next;
                }
            }
            push @$rules, $line;
        }

=pod

{MashTemp}

=over 2

{MashTemp} provides a lasy way to keep very temporary data, these values are only dependable within the current Macro, and may be clobbered by contained Macro's. This method exits to reduce further the number of B<sendmail {macro names}>.
Allways append something to the "MashTemp", such as "A" as shown in the example. Remember to use a consistant sub naming policy to minimise the generated names, we recomend using the sequence (A,B,C,D ..) but use as few as possible.

Usage
    R $*    $: &${MashTempA}
    R $*    $: &${MashTempB}

=back

=cut
        elsif ( $line =~ /\{MashTemp\}/ )
        {
            push @$rules, $line;
        }

=pod

DEBUG           switchs on|off debug info during read-in                        

=over 2

Errors in the macro TEST coding can be difficult to track, so this will display helpfull debuging info, remove when the problem has been sorted.

Usage
    DEBUG 1         To switch on
    DEBUG 0         To switch off
    DEBUG           To switch off, however its best to be explicit.

=back        

=cut
        elsif ( $line =~ s/^DEBUG\s*//)
        {
            $DEBUG = $line;
        }

=pod

TEST

=over 2

TEST macro code, is for testing of the macro, this code does not enter the output file.

TEST lines are converted into a simple HASH as follows

=over 4

{   

=over 2

=over 16

=item D   => []

list of B<.D> define a Macro statements

=item T   => SCALAR

translation macro, to be used before values below are supplied to the B<macro> under test

=item V   => []

values to try with B<macro>

=item E   => []

values as "V" but must result in "ERR"

=item O   => []

values as "V" but must result in "OK"

=item F   => []

values as "V" but must result in "FOUND"

=item I#  => []

values as "V" but must result in "#" 

where "#" is the expected reply.

eg 

IREPLY

=item SANE => []

list of $setup{sane} keys that define lists of B<.D> define a Macro statements

=item AUTO

does not have a HASH, but instead creates (V,E,O,F) as required.

=back

=back

}

=back

Encoded with leading definition letter and opening bracket, values "," delimited.
    D()    D( {client_addr}198.168.2.1, {client_name}dog.bone.com )
    T()    T(Translate)
    V()    V(frodo\@hobit.com, frog\@pond.com)

Not all definitions are required, you may use all or just one, in the case where no enclosing "()" brackets are used, this assumes you mean "V()".
B<E> and B<O> will stop|interrupt testing if returned result is unexpected.
B<V> will stop|interrupt testing if result is either "ERR" or "OK"!

Examples below

    TEST SANE(std) D({client_addr}198.168.2.1, sdog.bone.com) V(frodo\@hobit.com) 

Assumed "V()" values for macro

    TEST frodo\@hobit.com, frog\@pond.com 

Testing "Local_check_relay" requires "host.name"$|"ip_address", which requires our build "Translate" macro or your own for other uses.

    TEST T(Translate) E(bogus.host.domain 12.5.7.89, n.n.bogus 1.2.3.4)

TEST methods are used in order of specification, and effects persist during testing, so things defined for a preceding "Macro" will effect all "Macros" that follow

=over 2

=cut
        elsif ( $line =~ s/^TEST\s+// )
        {
            push @$test_list, $tests;
            my $th = $test_hash->{$tests} = {};
#line may have ", " where we only want ","
            $line =~ s/,\s*/,/g;
#braketed definintions?
            if ( $line =~ s/\s*\)\s*/\n/g )
            {
                foreach ( split "\n", $line )
                {
                    my $part = $_;
                    if ( $part =~ s/^T\(\s*// )
                    {
                        $th->{'T'} = $part;
                    }
                    elsif ( $part =~ s/^(SANE|D|V|E|O|F|I\w+)\(\s*// )
                    {
                        my $D = $th->{$1} = [];
                        @$D   = split ",", $part;
                    }

=pod

AUTO

=over 2

AUTO enables local site checking, without the need to hack the module, or expect module methods to modify the TESTS from their command line, set this up with the method B<testing_domains>, do not use other TEST methods with this apart from B<SANE>, B<T> and (B<D> where B<AUTO D> is not used). 

General format for this is (except for D)

=over 2

AUTO(key KEY sub_key1 sub_key2, key KEY sub_key1 sub_key2, ...

=over 2

Where key is one of (E,F,O,V), KEY is one of (OUR,OK,BAD) and sub_key# is one of (HELO,DOMAIN,IP,RESOLVE,FROM,RCPT).

Foreach setup{testing_domains}->{KEY}->[] line, the relevent field is used for testing, and so has the effect of specifying 
TEST E(...........) where each "." is the relevent field referenced by sub_key#.

=back

=back

B<D>

=over 2

AUTO(D; KEY; M sub_key1; M sub_key1; M sub_key1, ...

=over 2

Where KEY is one of (OUR,OK,BAD), M is a B<sendmail macro name>, enclosed in {} if that would normally be required, and may be anything that can be defined, sub_key1 as already defined.

Please note the use of ";" to delimit fields, do not forget to place a ";" after the B<D> and the KEY even if you are only defining a single macro.

This is not of any use without other TEST options, being specified. If used B<D> generates a TEST line based on the other TEST options for each setup{testing_domains}->{KEY}->[] line.
And so has the effect of specifying.

    TEST D({macro}value,{macro}value) E(...........) V(.......)
    TEST D({macro}value,{macro}value) E(...........) V(.......)
    TEST D({macro}value,{macro}value) E(...........) V(.......)
    TEST D({macro}value,{macro}value) E(...........) V(.......)
    ......


=cut

                    elsif ( $part =~ s/^AUTO\(\s*// )
                    {
                        my $tdk = $setup{'testing_domains_keys'};
                        $part =~ s/\s+/ /g;
                        my %D;
                        my @P = split ",", $part;
                        foreach my $P ( @P )
                        {
                            if ( $P =~ /^D\s*/i )
                            {
                                $P =~ s/;\s*/;/g;
                                my ($key, $KEY, @D) = split ";", $P;
                                $D{$KEY} = {};
                                scalar $key and $key =~ /^D$/ or whoops "TEST AUTO (D \"key\" error, $part";
                                scalar $KEY and $KEY =~ /^(OUR|OK|BAD)$/ or whoops "TEST AUTO (D \"KEY\" error, $part";
                                foreach my $D ( @D )
                                {
                                    my ($M, $sub_key1) = split " ",$D;
                                    scalar $M or whoops "TEST AUTO D \"M\" error, $part";
                                    scalar $sub_key1 and exists $tdk->{$sub_key1} or whoops "TEST AUTO D \"sub_key1\" error, $part";
                                    $D{$KEY}->{$M} = $sub_key1;
                                }
                            }
                            else
                            {
                                my ($key,$KEY,$sub_key1,$sub_key2) = split " ", $P;
                                scalar $key and $key =~ /^(E|F|O|V)$/ or whoops "TEST AUTO \"key\" error, $part";
                                scalar $KEY and $KEY =~ /^(OUR|OK|BAD)$/ or whoops "TEST AUTO \"KEY\" error, $part";
                                scalar $sub_key1 and exists $tdk->{$sub_key1} or whoops "TEST AUTO \"sub_key1\" error, $part";
                                if ( scalar $sub_key2 )
                                {
                                    exists $tdk->{$sub_key2} or whoops "TEST AUTO \"sub_key2\" error, $part";
                                }
                                my $KEYED = $setup{'testing_domains'}->{$KEY};
                                unless ( scalar @$KEYED )
                                {
                                    moan "TEST AUTO KEY $KEY is empty";
                                    next;
                                }
                                my $D = $th->{$key} = [];
#this can generate a lot of test lines, try to ensure each test is unique
                                my %tested;
                                foreach ( @$KEYED )
                                {
                                    my @keyed = split ",", $_;
                                    my $keyed;
                                    if ( scalar $sub_key1 and scalar $sub_key2 )
                                    {
                                        $keyed = "$keyed[$tdk->{$sub_key1}] $keyed[$tdk->{$sub_key2}]";
                                    }
                                    else
                                    {
                                        $keyed = $keyed[$tdk->{$sub_key1}];
                                    }
                                    if ( scalar $tested{$keyed} )
                                    {
                                        next;
                                    }
                                    else
                                    {
                                        $tested{$keyed} = 1;
                                    }
                                    push @$D, $keyed;
                                }
                            }
                        }
                        my @D_keys = keys %D;
#have we got AUTO(D specified? D HASH can have 3 keys, OUR,OK,BAD
                        if ( scalar @D_keys )
                        {
                            my $keyed;
                            my $d_th = $th;
                            my $tested_lines = 0;
                            AUTO_D_KEY: foreach my $KEY ( @D_keys )
                            {
                                my $KEYED = $setup{'testing_domains'}->{$KEY};
                                unless ( scalar @$KEYED )
                                {
                                    moan "TEST AUTO D KEY $KEY is empty";
                                    next AUTO_D_KEY;
                                }
#this can generate a lot of test lines, try to ensure each test is unique
                                my %tested;
                                AUTO_KEYED: foreach my $keyed_line ( @$KEYED )
                                {
#each will need testing with the D values
                                    my @keyed = split ",", $keyed_line;
                                    my %keyed;
                                    map { $keyed{$_} = "$keyed[$tdk->{$D{$KEY}->{$_}}]" } (keys %{$D{$KEY}});
#but check it has not already been used
                                    my @define = map { "$_$keyed{$_}" } (keys %keyed);
                                    my $define = join ",", @define;
                                    if ( scalar $tested{$define} )
                                    {
                                        next AUTO_KEYED;
                                    }
                                    else
                                    {
                                        $tested{$define} = 1;
                                    }
#ok completly new test? well at least for this KEY
                                    if ( scalar $tested_lines )
                                    {
                                        $tests++;
                                        push @$test_list, $tests;
                                        $th = $test_hash->{$tests} = {};
#copy original test hash to new duplicate
                                        %$th = %$d_th;
                                    }
                                    $tested_lines++;
                                    my $D = $th->{"D"} = [];
                                    @$D = @define;
                                }
                            }
                        }
#TODO

=pod

=back

=back

=back

=cut
                    }
                    else
                    {
                        moan "unexpected TEST definition $part";
                    }
                }
            }
#values for macro without brackets
            else
            {
                my $V = $th->{'V'} = [];
                @$V   = split ",", $line;
            }
            $tests++;
        }

=pod

HINT

=over 2

HINT is used to supply hints during testing, examples as to expected format etc, use as many as required, or none at all, but it will make your life easier to use them if you do not include TEST code or want to enter data on the fly.

All HINT are stored in the B<H=E<gt>[] ARRAY> for the B<rule>

Example below

    TEST D({client_addr}198.168.2.1, sdog.bone.com) V(frodo\@hobit.com) 
    HINT email address expected, valid or invalid

=back

=cut
        elsif ( $line =~ s/^HINT\s+// )
        {
            push @$hint_list, $line;
        }

=pod

FORCE

=over 2

FORCE if specified will allways pause testing and ask you for test data, regardless of wether B<TEST> has been used, has no meaning for "HTML", and omitting B<TEST>s has the same effect. Some sort of hint should follow, which will be shown before asking you for data.

FORCE is stored in the B<F=E<gt>SCALAR> for the B<rule>

Example below

    TEST D({client_addr}198.168.2.1, sdog.bone.com) V(frodo\@hobit.com) 
    FORCE email address expected, valid or invalid

=back

=cut
        elsif ( $line =~ s/^FORCE(\s+|$)// )
        {
            $rule_set->{"F"} = (scalar $line)?($line):("?");
        }

=pod

NOTEST

=over 2

NOTEST if specified is the reverse of FORCE, meaning if no B<TEST>s have been defined, this will allways skip testing, and continue. Some sort of hint should follow, explaining why testing is not required.

If B<NOTEST AUTO> is specified then it is assumed that the code is program generated and is tested by a controlling macro, so this will stay quite about it, otherwise this will B<moan> about the lack of testing.

Note if both FORCE and NOTEST are defined, NOTEST takes precedence.

NOTEST is stored in the B<N=E<gt>SCALAR> for the B<rule>

Example below

    NOTEST containing rule tests this.

=back

=cut
        elsif ( $line =~ s/^NOTEST\s+// )
        {
            $rule_set->{"N"} = (scalar $line)?($line):("!NOT TESTED!?");
        }
# normal line
        else
        {
            push @$rules, $line;
        }
    }
# restore saved value from begining, BUT do not clobber if inline!
    push @$rules, "R £*    £: £&{Mash$mash}"  if $MASH;
}
     

=back

=back

=back

=back

=head2  inbuilt_rule @_

=over 4

Enables this to test B<sendmails> own internal rules, instruction format is the same as for the above B<rule>, indeed this uses the same B<%setup HASHs>.

NOTE: This only supports the B<test> methods, even though it uses the same B<macro> parser to its work, nothing is output, and the "B<S>", "B<M>" and"B<N>" componants are removed for safty reasons, and a "B<I>" with the value B<1> is added.

=back

=cut
push @EXPORT, "inbuilt_rule";
sub inbuilt_rule
{
    my (@macro_rule,@macro_rules);
    my $rule    = shift @_;
    if ( scalar @_ )
    {
        @macro_rule = map { split "\n", $_ } (@_);
    }
    else
    {
        @macro_rule = split "\n", $rule;
        $rule  = shift @macro_rule;
    }
# init macro list with main S RULE, also only top level has a M list
    my $rule_set = { S => [], O => [], T => {}, M => [], H => [],};
    my $macros   = $rule_set->{"M"};
    $setup{"rule"}->{$rule} = $rule_set;
#keep backup copy for use later on
    @macro_rules = @macro_rule;
# main rule, and any sub macros have the same properties
    &macro($rule, $macros, \@macro_rules);
    map { delete $rule_set->{$_} } (qw(S M N));
    $rule_set->{'I'} = 1;
}

=head2 VERSIONID $title

=over 4

Only argument expected is the title|name for this hack to insert in the B<VERSIONID> statement. Output format is.

    # version
    my ($title) = @_;
    my $time = localtime();
    echo "VERSIONID(`@(#)$title for Sendmail 8.12 or better $time')";

=back

=cut
push @EXPORT, "VERSIONID";
sub VERSIONID
{
    # version
    my ($title) = @_;
    my $time = localtime();
    echo "VERSIONID(`@(#)$title for Sendmail 8.12 or better $time')";
}

=head2 LOCAL_CONFIG

=over 4

Required statement, this inserts required statments into the hack file.

    echo <<ECHO;
    LOCAL_CONFIG
    KSelfMacro macro
    ECHO

Currently only the B<SelfMacro macro>, which is used by many of the above methods, feel free to use it yourself but do not use names starting with B<Mash> other than those stated in B<rule> above.

Add your own definitions after this.

=back

=cut
push @EXPORT, "LOCAL_CONFIG";
sub LOCAL_CONFIG
{
    echo <<ECHO;
LOCAL_CONFIG
KSelfMacro macro
ECHO
}

=head2 LOCAL_RULESETS

=over 4

Required statement, this inserts required statments into the hack file.
Currently only a B<Translate> macro, which is based on the example in the B<Sendmail 3rd edition> book, section 7.1.1, page 290, however we will assume only 2 tokens are going to be supplied (the program inserts the seperator), this is for the standard macro B<Local_check_relay> 

Due to the limited number of "long names", some have had to be recoded as an $| delimited array {MashFound}, which of course makes testing difficult, so as we already have a problem with "rule sets", "Translate" will now also pack {MashFound}, which is re-writen each time this is used.

    echo <<ECHO;
    LOCAL_RULESETS

    STranslate
    R $* $$| $*     $: $1 $| $2     fake for -bt mode
    ECHO

Add your own definitions after this.

=back

=cut
push @EXPORT, "LOCAL_RULESETS";
sub LOCAL_RULESETS
{
    my $echo = <<ECHO;
LOCAL_RULESETS

STranslate
R ££| £+        £: £| £1
R £* ££| £*     £1 £| £2     fake for -bt mode
R £| £+         £: £| £| £1
ECHO
    my $L_KEY   = scalar @{$setup{'FOUND'}->{'LIST'}};
    $L_KEY = 1 unless scalar $L_KEY;
    $L_KEY--;
    foreach my $KEY (0..$L_KEY)
    {
        $echo .= <<ECHO;
R £| £| $KEY £+       £: £(SelfMacro {MashFound$KEY} £@ £1 £) £1
ECHO
    }
    $echo .= <<ECHO;
ECHO
    echo $echo;
}

=head2 build

=over 4

No arguments, this may included in the script after the B<rule>s and just before B<install>, this has no effect unless B<setup{silent}> is in effect, meaning that preceeding B<rule>s have not produced output, or you have built the required B<setup> HASH yourself.

=back

=cut
push @EXPORT, "build";
sub build
{
#is this just a comment?
    $setup{'silent'} or return;
#check we have something to do
    my @rules_list  = @{$setup{'rules'}};
    scalar @rules_list or return moan "nothing to test? setup{rules} empty?";
    my $rule_hash   = $setup{'rule'};
    foreach ( @rules_list )
    {
        tee translate @{$setup{"rule"}->{$_}->{"S"}};
    }
}

=head2 install

=over 4

No arguments, this may be included in the script after the B<rule>s or B<build> and just before B<test>, if you are not root this will attempt to B<su -c '"program" install 1'>

Note you may call your program with "install 1" so long as B<setup> processes the program arguments, or at least gets 1st pick. You will have to ensure that B<setup> gets all its requires.

=back

=cut
push @EXPORT, "install";
sub install
{
#normal users will not have "install" rights
    map { $setup{$_} or return moan "setup{$_} not defined" } (qw(file hack_dir tee cf mc));
#if not root, try to su to do the install
    unless ($setup{"SU"})
    {
        ok "Next is 'su' login password, this enable us to intall the generated code.\nContinue" or exit;
        my $self = ($0 =~ /\//) ? ($0):("./$0");
        $setup{"install"} = 1;
#need to install, build takes precedence stopping the install from happening!
        $setup{'magic'} = 1;
#essential args for installation
        my $args = join " ", map { "$_ \'$setup{$_}\'" } ( qw(
                    magic
                    hack_dir 
                    file 
                    sendmail
                    mc 
                    cf
                    install 
                    ));
        system "su -c \'$self $args\'" and exit moan "can not su -c \'$self $args\'";
#clear these to prevent mishaps?
        $setup{"install"} = 0;
        $setup{'magic'} = 0;
        return 1;
    }
    map { $setup{$_} or return moan "setup{$_} not defined" } (qw(file hack_dir tee cf mc install));
    my $tee = $setup{'tee'};
    my $file= $setup{'file'};
    my $time= $setup{'time'};
    my $cf  = $setup{'cf'};
    my $mc  = $setup{'mc'};

#archive existing installation files
    foreach (qw(file cf))
    { 
        if ( -f $setup{$_} )
        {
            rename $setup{$_}, "$setup{$_}.$time~" or 
                whoops "$!. install \"$_\" \"$setup{$_}\" rename failed";
        }
    }
#copy hack to its destination
    copy($tee, $file)  or whoops "$!. install, copy failed";
#compile CF file for testing
    system "m4 $mc > $cf" and whoops "\"m4 $mc > $cf\" resulted in $?";
    return 1;
}

=head1 Testing methods ============================


Sendmail intialization and chit chat methods, usable directly. But normally used by B<test> specified further down this document.

=cut

=head2 REF HASH setup{senddmail_hash} = sendmail_hash

=over 4

Setup script for B<sendmail> below, call it yourself to get the "setup" that will be used by B<sendmail>, mostly of use to initialize the B<output> methods with something more suitable for your needs, this currently defaults to methods suitable for command line usage.

If used place before B<test> to enable your alternative setup, otherwise omit and use the default settings.
If you use this directly be sure to also use B<sendmail> with no arguments to intialise the connection, sendmail -bt gives a greating message on starting.

NOTE calling it replaces the existing HASH with the default.

B<sendmail> calls this itself if the required HASH does not exist!

    sendmail_hash => {
        IO  =>  {   IO::File objects used by IPC::Open3 open3 
            r    => IO::File object
            w    => IO::FIle object
            e    => IO::File object
            pid  => IPC::Open3 open3 object 'sendmail'
        }
        select  {   IO:Select objects which refer to above IO::File objects
            r   =>  IO::Select object
            w   =>  IO::Select object   timeout has 30 seconds added to it
            e   =>  IO::Select object
            t   =>  SCALAR = 3  timeout seconds for select statment
            l   =>  SCALAR      last action that caused this to return 
                                one of 
                                r=(read),w=(write),e=(error),t=(timeout)
        }
        buffer  {   [] REFs containing data for|from above IO::File objects
            r   =>  [] REF  contains read in data (push)
            w   =>  [] REF  contains data waiting to be written (shift)
            e   =>  [] REF  contains errors (push)
            l   =>  [] REF  contains last read in data or error
        }
        error   =>  [] REF  general errors, undef if OK
        output  {   what is this supposed to do with 'display' infomation?
            silent  => SCALAR = 0   1 suppresses all output
            echo    => SUB REF default is &echo (command line only)
            moan    => SUB REF default is &moan 
                                       (which already understands HTML)
            whoops  => SEB REF default is &whoops 
                                        (based on moan, but also exits)
        }

=back

=cut
push @EXPORT, "sendmail_hash";
sub sendmail_hash
{
#   main hash, if called clear down existing, and start again
    my $s = $setup{'sendmail_hash'} = {
        IO      => {},
        "select"=> {
            t   => 3,
            l   => 0,
        },
        buffer  => {
            l   => [],
        },
        output  => {
            silent  => 0,
            echo    => \&echo,
            moan    => \&moan,
            whoops  => \&whoops,
        },
    };
#IO::Select has to be done after a file has been opened for it
    foreach (qw(r w e))
    {
        $s->{"IO"}->{$_}     = new IO::File;
        $s->{"buffer"}->{$_} = [];
    }
#init pipe to sendmail
    my $sendmail = "$setup{'sendmail'} -bt";
    $setup{'cf'} and $sendmail .= " -C$setup{'cf'}";
#simple refs reguired for open3
    my $rh = $s->{'IO'}->{'r'};
    my $wh = $s->{'IO'}->{'w'};
    my $eh = $s->{'IO'}->{'e'};
    $s->{'pid'} = open3($wh, $rh, $eh, $sendmail);
    unless ( $s->{'pid'} )
    {
#this is the first call to 'sendmail' so do not know for sure what to do
        $s->{'error'} = "open3 \"$sendmail\" call failed with: $!";
        whoops $s->{'error'};
        return undef;
    }
#creat select object now we have open file handles
    foreach (qw(r w e))
    {
        $s->{"select"}->{$_} = new IO::Select($s->{"IO"}->{$_});
        unless ( $s->{'select'}->{$_}->count() )
        { 
            $s->{'error'} = "unable to create IO::Select object for $_"; 
            whoops $s->{'error'};
            return undef;
        }
    }
    return $s;
}

=head2 undef sendmail_whoops @_

=over 4

B<sendmail> methods use this to complain and exit, will be silent if B<sendmail_hash->output->silent>, alternativly uses the relevant B<whoops> method to complain and exit. NOTE will allways B<exit>.

=back

=cut
push @EXPORT, "sendmail_whoops";
sub sendmail_whoops
{
    my $s = $setup{'sendmail_hash'};
    my $whoops = \&whoops;
    if ( scalar $s )
    {
        if ( scalar $s->{'object'} )
        {
            if ( scalar $s->{'object'}->{'whoops'} )
            {
                $whoops = $s->{'object'}->{'whoops'};
            }
            $s->{'object'}->{'silent'} and exit;
        }
    }
    $whoops->(@_);
    exit;
}

=head2 undef sendmail_moan @_

=over 4

B<sendmail> methods use this to complain and to fill out its own sendmail_hash{error}, will be silent if B<sendmail_hash->output->silent>, alternativly uses the relevant B<moan> method to complain.

=back

=cut
push @EXPORT, "sendmail_moan";
sub sendmail_moan
{
    my $s = $setup{'sendmail_hash'};
    my $moan = \&moan;
    if ( scalar $s )
    {
        my $e = $s->{'error'} = [];
        @$e   = @_;
        if ( scalar $s->{'object'} )
        {
            if ( scalar $s->{'object'}->{'moan'} )
            {
                $moan = $s->{'object'}->{'moan'};
            }
            $s->{'object'}->{'silent'} and return undef;
        }
    }
    return $moan->(@_);
}

=head2 undef sendmail_echo @_

=over 4

B<sendmail> methods use this to display the output of "sendmail -bt" interprocess pipe, will be silent if B<sendmail_hash->output->silent>, alternativly uses the relevant B<echo> method to display.

=back

=cut
push @EXPORT, "sendmail_echo";
sub sendmail_echo
{
    my $s = $setup{'sendmail_hash'};
    my $echo = \&echo;
    if ( scalar $s )
    {
        if ( scalar $s->{'object'} )
        {
            if ( scalar $s->{'object'}->{'echo'} )
            {
                $echo = $s->{'object'}->{'echo'};
            }
            $s->{'object'}->{'silent'} and return 1;
        }
    }
    return $echo->(@_);
}


=head2 ($code,@buffer) = sendmail(@_)

=over 4

Interface for talking to "sendmail -bt", on first call will set it self up using B<sendmail_hash> if the required HASH does not already exist.

Any arguments are "sendmail instructions" this will allways append newlines.

Returns recieved @buffer, does not return on writes as sendmail will allways reply, however returns B<undef> on timeouts or on read and write fails!

B<sendmail> has its own "sendmail_hash" HASH in setup, which will be setup on first use if not already defined, and enougth other information exists to enable this.

USES

=over 4

B<sendmail_whoops>  to complain about errors and exit!
B<sendmail_moan>    to complain about errors!
B<sendmail_echo>    to display received data

=back

=back

=cut
push @EXPORT, "sendmail";
sub sendmail
{
    my $s = $setup{'sendmail_hash'};
    unless ( scalar $s )
    {
        unless ( $s = sendmail_hash())
        {
            my $e = $setup{'sendmail_hash'}->{'error'};
            my $error = ($e)?($e):("sendmail setup failed?");
            sendmail_whoops $error;
        }
        my @ok = &sendmail();
        if ( my $ok = scalar @ok )
        {
            if ( $ok > 4 )
            {
                ok "Sendmail reported errors, STOP RUN [Y|n]" or exit;
            }
            return @ok;
        }
        else
        {
            return sendmail_whoops "initial sendmail communication failed?";
        }
    }
#sendmail allways replys, this may have been given a list of work to do
#But we must wait for sendmail to reply before continuing, or we can end up
#in a mess!

# write buffer, should be empty
    my $w_buff = $s->{'buffer'}->{'w'};
    scalar @_ and push @$w_buff, @_;
    if ( scalar @$w_buff )
    {
        my @ok;
        while ( my $write = shift @$w_buff )
        {
            @ok = &sendmail_comms($write);
            scalar @ok or return;
        }
#return last recieved block;
        return @ok;
    }
    else
    {
        return &sendmail_comms();
    }
}

sub sendmail_comms
{
#sendmail connection must be open
    my $s = $setup{'sendmail_hash'};
    scalar $s->{"pid"} or sendmail_whoops "IO connection with sendmail is closed!";
    my $timeout = $s->{"select"}->{'t'};
#buffers
    my $bufs = $s->{'buffer'};
    my $sels = $s->{'select'};
#have we stuff to write?
    my $delay = 0;
    my $last_write = scalar @_;
    $last_write > 1 and sendmail_whoops <<WHOOPS;
This must be supplied with one \"write\" at a time!
supplied with $last_write arguments
WHOOPS
#sendmail may have quite a lot to do, so need a longer timeout
    $last_write and $timeout += 30;
    while ( 1 )
    {
        my @selects = (
            $sels->{'r'},
#do we still have stuff to write?
            ((scalar @_)?($sels->{'w'}):(undef)),
            $sels->{'e'},
            );
        my $start_time = time;
        my ( $read,$write,$error ) = IO::Select->select(@selects,$timeout);
        my $end_time   = time;
        my $waited     = $end_time - $start_time;
        $delay += $waited;
#increment buffer and return just read in
        if ( (scalar $read and scalar @$read) or (scalar $error and scalar @$error) )
        {
            my ($HDL,$hdl);
            if ( scalar $read )
            {
                $HDL = shift @$read;
                $hdl = "r";
            }
            else
            {
                $HDL = shift @$error;
                $hdl = "e";
            }
            $sels->{'l'} = $hdl;
            my $buffer = $bufs->{"l"} = [];
            my $string;
            my $recv = sysread $HDL,$string,1024;
            if ( $recv )
            {
#normal read operation
                if ( $hdl =~ /r/i )
                {
                    if ( scalar $bufs->{"long_string"} )
                    {
                        $bufs->{'long_string'} .= $string;
                    }
                    else
                    {
                        $bufs->{'long_string'} = $string;
                    }
                    if ( $string =~ /(^|\n)>\s+$/ )
                    {
                        @$buffer = grep {scalar $_} (split "\n", $bufs->{'long_string'});
#clear down read buffer 
                        $bufs->{'long_string'} = undef;
                        push @{$bufs->{$hdl}}, @$buffer;
                        sendmail_echo @$buffer;
#dont return if still have something to write
                        scalar @_ or return @$buffer;
                        $delay = 0;
                    }
                }
#errors need to be reported, normally we can not continue
                else
                {
                    @$buffer = split "\n", $string;
                    push @{$bufs->{$hdl}}, @$buffer;
                    return sendmail_moan @$buffer;
                }
            }
            else
            {
                $s->{"pid"} = 0;
                return sendmail_moan "(Read|Write|Error) handle $hdl connection with \"sendmail -bt\" has been closed";
            }
        }
#writes expect some reply in all cases to sendmail
        elsif ( scalar $write and scalar @$write )
        {
            my $line = shift @_;
            my $HDL  = shift @$write;
            sendmail_echo $line;
            my $ok   = print $HDL "$line\n";
            unless ($ok)
            {
                $s->{"pid"} = 0;
                $sels->{'l'} = "w";
                return sendmail_whoops "$! failed to talk to sendmail pipe";
            }
            $delay = 0;
        }
#timeout, however as sendmail may be busy with a slow operating external program
        else
        {
            $sels->{'l'} = "t";
            if ( $last_write )
            {
                sendmail_moan "Timeout waiting \"$delay\" for sendmail to reply";
                next if ok "Try again? [n|y] :";
                next if $delay < 360 and $setup{"silent"};
            }
            else
            {
                sendmail_moan "Timeout waiting \"$delay\" for sendmail";
            }
            return undef;
        }
    }
}


=head2 test @_

=over 4

Expects either 

=over 4

nothing, in which case all defined rules are tested in turn, if any "rule" does not have "TEST"s defined for it, this will halt on and ask you for a test value, or simply press return to continue, HTML format is still in development.

rule=>test, rule=>test, rule=>test  hash value pairs, which are the rule to test and the TEST number to do, or alternativly the word "ALL" to do all "TESTS" for this rule.

=back

This will only "TEST" rules that have been defined, so it is best to place this last in your code.
This uses B<sendmail> to talk to "sendmail -bt" via open3. 

sets B<setup{testing}> to inform other methods that are common to both B<build> and B<test> to use B<setup{log}> instead of B<setup{tee}>.

=back

=cut
push @EXPORT, "test";
sub test
{
#flag for methods to understand testing is in progress
    $setup{'testing'} = 1;
#if first time this has been used, init sendmail so that we can use its methods
    $setup{'sendmail_hash'} or 
        sendmail() or 
        sendmail_whoops "test failed to init sendmail!";
#check we have something to do
    my @rules_list = @{$setup{'rules'}};
    scalar @rules_list or return sendmail_moan "nothing to test? setup{rules} empty?";
    my $rule_hash  = $setup{'rule'};
# have arguments been supplied?
    my $cmd_line  = scalar @_;
    my @test_list = ($cmd_line)?(@_):(map{ ($_,"ALL") } (@rules_list));
    RULE:while ( my $rule = shift @test_list )
    {
#although written to file with a leading S, testing requires it to be removed
        my $use_rule = $rule;
        $use_rule =~ s/^S//;
        my $test_ind = shift @test_list or last;
        my $rule_def = $rule_hash->{$rule} or 
            return sendmail_moan "rule{$rule} does not exist!";
#any hints? better show them now
        my $hints = $rule_def->{'H'};
        scalar $hints and scalar @$hints and sendmail_echo @$hints;
#not all rule's will have tests
        my @tests = @{$rule_def->{'O'}};
        my $force = $rule_def->{'F'};
        my $notest= $rule_def->{'N'};
        my ($code,$ok);
#command line is likly to be explicit value to try
        if ( $cmd_line )
        {
#so long as the word is not all
            if ( $test_ind =~/\D+/ and $test_ind !~ /^ALL$/i )
            {
                sendmail "$use_rule $test_ind" or next RULE;
            }
#numeric must exist
            elsif ( $test_ind =~ /^\d+$/ )
            {
                if ( $rule_def->{'T'}->{$test_ind})
                {
                    @tests = ($test_ind);
                }
                else
                {
                    sendmail_moan "no such $test_ind for $rule";
                    next RULE;
                }
            }
        }
#no tests for this rule?
        elsif ( $notest and not scalar @tests )
        {
            $notest =~ /AUTO/ or sendmail_moan "$notest for $rule";
            next RULE;
        }
        elsif ( $force or not scalar @tests )
        {
            my $msg  = ($force)?($force):("Rule=:\"$rule\", Enter TEST value to try:> ");
            while ( my $test = ok $msg )
            {
                sendmail "$use_rule $test";
            }
        }
        my $SANE = $setup{'sane'};
        foreach ( @tests )
        {
            my $tests = $rule_def->{'T'}->{$_} or next RULE;
#sane define statements required? remember these persit
            my $sane_define;
            if ( scalar $tests->{'SANE'} and scalar @{$tests->{'SANE'}})
            {
#TODO
#one day the packed macro {mash_found} may not be needed, but in the mean time to keep testing simple
#translate sane and define statemnts into packed form if they have been declared
                $sane_define = [];
                my @pre_sane;
                my $mash_found = 0;
                @$sane_define = MashPack ( map { @{$SANE->{$_}} } grep { $SANE->{$_} } (@{$tests->{'SANE'}}));
#@$sane_define = (map { ".D$_" } map { @{$SANE->{$_}} } grep { $SANE->{$_} } (@{$tests->{'SANE'}})); 
#set sane here, as there may be no tests defined, and preserves original action
                sendmail @$sane_define;
            }
#define statements required? remember these persit
            if ( scalar $tests->{'D'} and scalar @{$tests->{'D'}})
            {
                sendmail MashPack (@{$tests->{'D'}}); 
            }
#translation macro?
            my $T = $tests->{'T'};
            foreach ( grep /^(V|E|O|F|I\w+)$/, (keys %$tests))
            {
                scalar $tests->{$_} and scalar @{$tests->{$_}} or next;
                my $v = $_;
                my @V = @{$tests->{$v}};
                foreach ( @V )
                {
                    my $t = $_;
#sane settings reguired for test run?
                    if ( scalar $sane_define )
                    {
                        sendmail @$sane_define;
                    }
#spaces should not be included in values, but if there is one assume $| magic
                    $t =~ s/\s/ \$| / if $T;
                    my $a = ($T)?("$T,$use_rule $t"):("$use_rule $t");
                    my @R = sendmail $a;
                    scalar @R or next;
                    my @Un = grep /^Undefined ruleset/, @R; 
                    if ( scalar @Un )
                    {
                        sendmail_moan @Un;
                        ok "stop run? [y|n]" or exit;
                        next RULE;
                    }
                    my @err   = grep /returns:\s+\$#\s*err/i,@R;
                    my @ok    = grep /returns:\s+\$#\s*ok/i, @R;
                    my @found = grep /\.\s*FOUND/, @R;
                    my $stop  = 0;
#with returns such as #ok and #err, it is very likly to get .FOUND replys also
#1st pop ">" prompt off, last reply may alter things
                    pop @R;
                    my $last_return = pop @R;
                    if ( scalar $last_return )
                    {
                        if ( $last_return =~ /returns:\s+\$#\s*err/i )
                        {
                            $last_return = "err";
                        }
                        elsif ( $last_return =~ /returns:\s+\$#\s*ok/i )
                        {
                            $last_return = "ok";
                        }
                        else
                        {
                            $last_return = "NA";
                        }
                    }
                    else
                    {
                        sendmail_moan "expected replys for ($rule,$v,$a)";
                        $stop = 1;
                    }
                    if ( scalar @err and $v =~/(v|o|f)/i )
                    {
                        sendmail_moan "unexpected \$# err, for ($rule,$v,$a)", @err;
                        $stop = 1;
                    }
                    elsif ( scalar @ok and $v =~ /(v|e|f)/i )
                    {
                        sendmail_moan "unexpected \$# OK, for ($rule,$v,$a)", @ok;
                        $stop = 1;
                    }
                    elsif ( scalar @found and $v =~ /(v|e|o)/i )
                    {
                        if ( $v =~ /e/i and $last_return =~ /err/i )
                        {
                            sendmail_moan "warning (last=<$last_return>), unexpected .FOUND, for ($rule,$v,$a)", @found;
                        }
                        elsif ( $v =~ /o/i and $last_return =~ /ok/i )
                        {
                            sendmail_moan "warning (last=<$last_return>), unexpected .FOUND, for ($rule,$v,$a)", @found;
                        }
                        else
                        {
                            sendmail_moan "unexpected .FOUND, for ($rule,$v,$a)", @found;
                            $stop = 1;
                        }
                    }
                    elsif ( not scalar @err and $v =~ /e/i )
                    {
                        sendmail_moan "expected \$# err, for ($rule,$v,$a)";
                        $stop = 1;
                    }
                    elsif ( not scalar @ok and $v =~ /o/i )
                    {
                        sendmail_moan "expected \$# OK, for ($rule,$v,$a)";
                        $stop = 1;
                    }
                    elsif ( not scalar @found and $v =~ /f/i )
                    {
                        sendmail_moan "expected .FOUND, for ($rule,$v,$a)";
                        $stop = 1;
                    }
                    elsif ( $v =~ /i\w+/i )
                    {
                        sendmail_echo <<SENDMAIL_ECHO;
------TEST results can not be AUTO checked-----
$rule, $v, $a
------VERIFY RESULT BEFORE CONTINUING----------
SENDMAIL_ECHO
                        ok "Results as expected? [Y|n]" and $stop = 1;
                    }
                    else
                    {
                        unless ( $v =~ /(v|o|e|f)/i )
                        {
                            sendmail_moan "? unmatched $v, program error?";
                            $stop = 1;
                        }
                    }
                    if ( $stop )
                    {
                        ok "stop run? [y|n]" or exit;
                    }
                }
            }
        }
    }
}

#OK end of main program documentation, next is usage

=head1 Example USAGE  from a command line driven program


Note this also contains a cut down snippet of the ANTI SPAM hack that caused this to come into existance.


    #! /usr/bin/perl -w
    use Sendmail::M4::Utils;

    setup @ARGV;

    # copyright message
    dnl <<DNL;
    Copyright (c) 2007 celmorlauren Limited England
    Author: Ian McNulty       <development\@celmorlauren.com>

    this should live in /usr/share/sendmail/hack/mail8-stop-fake-mx.m4

    some settings that are advised
    FEATURE(`access_db',	`hash -T<TMPF> -o /etc/mail/access.db')
    FEATURE(`greet_pause',	`2000')
    define(`confPRIVACY_FLAGS', `goaway')
    DNL

    # version
    VERSIONID "ANTI SPAM";

    # 
    dnl <<DNL;

    SPAM checking additions --------------------------
    '-' added to trap DSL faked domain names

    DNL
    echo <<ECHO;
    define(`confOPERATORS',`.:@!^/[]-')
    ECHO

    LOCAL_CONFIG

    echo <<ECHO;
    KRlookup dns -RA -a.FOUND -d5s -r4

    ECHO

    # we can do some checking with HEADER lines
    echo "HReceived: $>+ScreenReceived";


    ################################################################
    ################################################################
    # end of snippet, this would of course contain your own code
    ################################################################
    ################################################################

    # this is the start of the real code
    LOCAL_RULESETS

    echo <<ECHO;
    dnl this bit is for mail8, intial contact and flood checking?
    dnl bit below checked, see p288
    ECHO

    #######################################
    # CONTACT
    # This bit arrived at on first contact, and so permissions based on IP can be set
    rule <<RULE;
    SLocal_check_relay
    TEST T(Translate) V(local 192.168.0.1, bogus.host 1.2.3.4)
    R $* $| $*      $: $(SelfMacro {RelayName} $@ $1 $) $1 $| $2
    R $* $| $*      $: $(SelfMacro {RelayIP} $@ $2 $) $1 $| $2
    R $*            $: $>Screen_bad_relay $&{RelayIP} 
    RULE

    intstall;

    test;
    
    ################################################################
    ################################################################
    # end of snippet, this would of course contain your own code
    ################################################################
    ################################################################

=cut


=head1 HISTORY

B<Versions>

=over 5

=item 0.1

Nov 2006  1st version, pure sendmail M4 hack, using plug-in Perl programs.

=item 0.2

25 Aug 2007, B<this> 1st CPAN test module, developed to test M4 hack scripts, original script split into B<Utils> for creation and testing, and B<Mail8> the B<ANTI SPAM> engine.

B<Amendments to release version>

=over 3

=item 30 Aug 2007

TEST, HINT & FORCE did not nest.

=item 3 Sept 2007

cf file backup now has a tilde ending "~".
%setup{paranoid} added for mail8.

=item 5 Sept 2007

NOTEST, for nested MACROS that are already tested by a containing level, or where additional testing makes no sense.

=item 8 Sept 2007

Testing of a Mail8 component with bugs caused files with wrong permisions to be created, meaning the standard user could not re-create them, and some confusion as to what was happening. Utils will now B<whoops> on these problems giving a clear indication as to the real problem.

{MashStack} failed to work when more than one instance was used on a single line.

NOTEST AUTO will not B<moan> meaning auto generated lines that not be meaningfully tested do not complain about it.

FORCE and absence of TEST's now will continue to ask for input for a rule, until nothing is entered

=item 10 Sept 2007

Testing of Reintergrated Mail8 showed that NESTing still did not work, reason found and fixed, also somethings that where expected were not allways supplied.

GLOBAL added to reduce the number of {macro_names} as Mail8 managed to go over B<sendmail>s limit of B<96>, used at the top level S rule to reset counters.

=item 11 Sept 2007

INLINE added, Mail8 managed to go over the standard B<sendmail> limit of B<100> B<named rulesets>, counted a total of 123 in the test.cf, we know we could re-compile sendmail with a bigger limit. But that is something we can not expect of anyone else.

=item 13 Sept 2007

UTF8 EURO currency "character" added can now be used in rule definitions, where $ would have to be escaped.

=item 14 Sept 2007

FOUND inbuilt MACRO added to load B<SelfMacro {macro}> with "$+.FOUND", intention is to remove another B<rule set> as this B<MACRO> will be coded B<INLINE>.

=item 15 Sept 2007

method B<inbuilt_rule> added to enable testing of B<sendmail>s own rule sets, these use the same methods and control HASHs as B<rule> except generates no code.

=item 16 Sept 2007

B<MACRO{> statements (REFUSED, ALREADYREFUSED, IS (REFUSED, ALREADYREFUSED, FOUND), INLINE ALLWAYS) added to both help with reducing the number of generated B<rule sets> and to improve the layout of B<Mail8>.

=item 17 Sept 2007
    
B<MACRO{ TEST> sub statement SANE and the method "sane" added to simplify reseting B<sendmail -bt> test session to sensible values.

=item 19 Sept 2007

B<MACRO{ TEST> sub statement AUTO and method "testing_domains" added to enable customers vary the test data to reflect their setup, testing B<Sendmail::M4::Mail8> via B<Sendmail::M4::mail8> with just celmorlauren email setup is not sufficient.    

=item 21 Sept 2007

Documentation clean up, noted that EURO character causes problems with Perldoc for version 5.6 Perl, POUND does not work either (but at least does mess up display)

=back

=item 0.21 

21 Sept 2007 CPAN Amended version

B<Amendments to release version>

=over 3

=item 22 Sept 2007

Documentation clean up, noted that POUND character does not display correctly on CPAN, hum it would be better if CPAN coped with UTF8 characters!

B<MACRO{> DEBUG statement added to switch on debuging within the TEST line read in phase, to track difficult to see errors.

{MashSelf} failed to work when more than one instance was used on a single line.

=back

=item 0.22 

22 Sept 2007 CPAN Amended version

B<Amendments to release version>

=over 3

=item 22 Sept 2007

installed on a test system, started to run ("too many long names" again) AAARGH! 

{MashTemp} added a variant of {MashStack}, differnce being the reduced number of names generated, the names only being safe only in the current macro, and can be clobbered by contained macros, that use this. You have been warned!

=item 23 Sept 2007

B<Macro{> OPTION added, this is to enable such things 

OPTION NO MASH    

OPTION MASH 1       mash nameing policy uses {Mash1}   

Also added sub option to INLINE ALLWAYS MASH, which overides the normal macro nameing policy, internal methods now use the mash name {MashTempA} for purposes of saving and returning a value.

=back

=item 0.23 

23 Sept 2007 CPAN Amended version

B<Amendments to release version>

=over 3

=item 01 Oct 2007

Live on primary, secondary and test systems. When sending mail to "sendmail.org" (via test), sendmail tried and failed to allocate more names for itself ("too many long names" again) AAARGH! However the send did still work (without md5) 

Currently the Sendmail::M4::Mail8.pm version uses 21 "long names", OK for normall sending. But md5 needs more.

=over 4

=item *

MACRO{ statement FOUND & IS FOUND modified, new statements FIND & STORE, now a single {MashFound} macro can be loaded with as many sub names as required.


=item *

Translate rule set modified to pack {MashFound}    

=item *

define_MashFoud added, to declare packed components of {MashFound}

Modifications made so that {macro} maybe used for TEST D & SANE statments, but will be packed into {MashFound} if they have been defined. 

=back

=back

=item 0.24 

22 September 2007 CPAN Amended version

B<Amendments to release version>

=over 3

=item 08 Oct 2007

Error in B<pod> line 960 space between =head 2, as B<Mail8> has been updated with B<Reply-to> header line checking, this little thing can be fixed and uploaded.

=back

=item 0.25 

08 October 2007 CPAN Amended version

B<Amendments to release version>

=over 3

=item 12 Oct 2007

FIND did not have NOMASH stated, so used a long-name when it should not have had done.

Mail8 development, dealing with hotmail & yahoo mail addresses and domains, showed that sendmail has a problem with wild-cards higher than $9, use a $10 and sendmail will complain ( too many wildcards ).

define_MashFound ammended along with others that use the packed form of {MashFound}, although sendmail has a limit of 9 wildcards, {MashFound#} where # is numeric, each containing upto 9 elements, the presence of these makes no other difference to the macro coding, FIND STORE etc all work as before.

=item 13 Oct 2007

POD clean up, HISTORY moved to end of document, layout of POD improved, but some bits will be left for later.
Code check. Should not touching again until the socks method is ready.

=back

=item 0.26 

13 October 2007 CPAN Amended version

B<Amendments to release version>

=over 3

=item 14 Oct 2007

Mail8 added another component to MashFound# making 9 in one, causing M4 statement not to formated correctly, failure in logic fixed.

=back

=item 0.27 

14 October 2007 CPAN Amended version

B<Amendments to release version>

=over 3


=back

=cut

1;
