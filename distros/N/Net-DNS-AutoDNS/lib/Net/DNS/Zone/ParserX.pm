package Net::DNS::Zone::ParserX;

use strict;
use warnings;
use vars qw (
    $VERSION
    $REVISION
    @ISA
    @EXPORT_OK
    $ZONE_RR_REGEX
    $NAMED_COMPILEZONE
    $DUMP
);

use File::Basename;
use Carp;
use File::Temp;
use IO::File;
use IO::Handle;
use Net::DNS;
use Net::DNS::RR;

# ABSTRACT: A Zone Pre-Parser (slightly altered fork in cpanel2autodns)


BEGIN {
    require Exporter;

    @ISA      = qw(Exporter);
    $VERSION  = '0.02';
    $REVISION = (qw$LastChangedRevision: 788 $)[1];

    @EXPORT_OK = qw (
        processGENERATEarg
    );
}

# Debugging during code development ... Anything greater than 0 will
# cause debugging output.
use constant DEBUG => 0;    ## no critic

my $debug = DEBUG;

my $MaxIncludeDepth = 20;    # maximum time $INCLUDE recursion.

############
#
#  The ZONE_RR_REGEX all classes and types known by Net::DNS::RR and creates
#  a regexp to match input against.
#
#  This way we match against all know RRs at least those known to
#  Net::DNS
#

# the classes regexp component we need elsewhere in the code as well
my $classes = join('|', keys %Net::DNS::classesbyname, 'CLASS\\d+');

build_regex() unless $ZONE_RR_REGEX;


sub new {
    my ($class, $argument) = @_;

    $class = ref($class) || $class;
    my $self = {};
    bless($self, $class);

    if ($argument) {
        print "new called with an argument\n" if $debug;
        if ($argument->isa("IO::Handle")) {
            $self->{"fh"} = $argument;
        }
        else {
            die
                'Failure: supplied argument is not an instance of IO::File, IO::Handle or related i.o.w. isa( IO::Handle) failed';
        }
    }
    else {
        $self->{"fh"} = IO::File->new_tmpfile;
    }

    return $self;
}


sub get_io {
    my $self = shift;
    return $self->{"fh"};
}


sub read {    ## no critic (ProhibitBuiltinHomonyms)
    my ($self, $possible_filename, $arghash) = @_;

    my $origin = $arghash->{"ORIGIN"};

    if ($arghash->{"CREATE_RR"}) {
        $self->{create_rr} = [];
    }

    if ($arghash->{"STRIP_SEC"}) {
        $self->{strip_dnskey} = 1;
        $self->{strip_nsec}   = 1;
        $self->{strip_rrsig}  = 1;
    }

    if ($arghash->{"STRIP_DNSKEY"}) {
        $self->{strip_dnskey} = 1;
    }

    if ($arghash->{"STRIP_NSEC"}) {
        $self->{strip_nsec} = 1;
    }

    if ($arghash->{"STRIP_RRSIG"}) {
        $self->{strip_rrsig} = 1;
    }

    if ($arghash->{"STRIP_OLD"}) {
        $self->{strip_old} = 1;
    }

    $self->{bump_soa} = 0;
    if ($arghash->{"BUMP_SOA"}) {
        $self->{bump_soa} = 1;
    }

    my $fh = $self->{"fh"};

    my @filename = glob($possible_filename);
    return "READ FAILURE: ambigueous input: " . join " ", @filename . "\n"
        if (@filename > 1);
    $self->{'filename'} = $filename[0];

    if (defined($origin) && $origin =~ /\S+/o) {

        # Strip spaces from begin and end of string.
        $origin =~ s/\s//og;
        $self->{'_origin'} = $origin;
    }
    else {
        $self->{'_origin'} = basename($filename[0]);
    }

    $self->{'IncludeRecursionDetector'} = 0;
    $self->{'DefaultTTLDirectiveFound'} = 0;
    $self->{'_origin'} .= "." if $self->{'_origin'} !~ /\.$/o;
    my $returnval = $self->_read($fh, $filename[0], $self->get_origin, '', 0);
    return $returnval if $returnval =~ /^READ FAILURE:/o;

    return 0;
}


sub get_array {
    my $self = shift;

    return [] unless $self->{create_rr};
    return $self->{create_rr};
}


sub get_origin {
    my $self = shift;
    return $self->{'_origin'};
}


sub build_regex {

    # Longest ones go first, so the regex engine will match AAAA before A.
    my $types =
        join('|', sort { length $b <=> length $a } keys %Net::DNS::typesbyname);

    $types .= '|TYPE\\d+';

    $ZONE_RR_REGEX = " ^ 
                                        \\s*
                    (\\S+)+     # name anything non-space will do 
                    \\s*                
                    (\\d+)?           
                    \\s*
                    ($classes)?
                    \\s*
                    ($types)    # There must be a type specified.
                    \\s*
                    (.*)
                    \$";

    print STDERR "Regex: $ZONE_RR_REGEX\n" if DEBUG;

    return;
}

sub _read {

    my $self           = shift;
    my $fh_out         = shift;    # Filehandle to print parsed output to
    my $filename       = shift;    # Filename of file to be read
    my $lastseenORIGIN = shift;    # Relevant to relative domains
    my $previousdname  = shift;    # Relevant during $INCLUDE
    my $lastseenTTL    = shift;
    print ";; _read method called on $filename with origin $lastseenORIGIN\n"
        if $debug;

    my $namedcomp_return;
    $namedcomp_return =
        $self->_read_namedcomp($fh_out, $filename, $lastseenORIGIN)
        if ($NAMED_COMPILEZONE);
    print "namedcomp_return returned:  $namedcomp_return\n" if $debug;
    if (defined($namedcomp_return)) {
        if ($namedcomp_return eq "success") {
            return "success";
        }
        else {
            # Only if the command failed to execute we'll continue with the "perl code";
            return ("READ FAILURE: from named-compilezone: $namedcomp_return")
                unless $namedcomp_return =~ /Failed to execute/;
        }
    }

    $self->{"IncludeRecursionDetector"}++;    # Used for testing INCLUDE LOOPS
    my $fh_in = IO::File->new;
    $fh_in->open("< $filename")
        || return "READ FAILURE: Could not open $filename\n";

    $lastseenORIGIN .= "." if $lastseenORIGIN !~ /\.$/o;

    my $TTL        = 0;
    my $defaultTTL = 0;

    #  The following loop parses the zone file. At the end of the
    #  paring logic the $_ contains "name TTL CLASS RTYPE RDATA" whith
    #  all variables set and all names expanded to FQDN.
    #
    #  During the loop the APEX keyset and it's signatures are removed.
    # Check RFC1035 section 5 for details on how to handle INCLUDES
    # and how the lastseenORIGIN propagates

    my $buffer              = '';
    my $openingbracketfound = 0;

    READLINE: while (<$fh_in>) {
        next READLINE                      if /^\s*$/o;    # All spaces
        print "LINE: >" . $_               if DEBUG > 1;
        print "BUFF: >" . $buffer . "\n\n" if DEBUG > 9;
        my $i = 0;    # i is a counter to prevent overruns in multiline RRs

        # Start parsing the line 'token' by 'token'.
        # As long as there are non whitespace tokens on the
        # end of the line then (.*)$ matches those.
        #
        # $1 either contains a single whitespace or
        # the longest nonwhitespace collection of characters

        # Only go through char-by-char lineparsing if there
        # are parenthesis, quotes or comments or if we are parsing multilines
        if (
               $openingbracketfound
            || /\(/o
            ||          # Opening bracket
            /\;/o ||    # Comment at end of line
            /\"/o ||    # Quote
            /\)/o       # Closing bracket
            )
        {

            LINEPARSE:
            while (s/^(.)(.*)$/$2/o && $i < 200) {    # no more than 200
                                                      # lines for multi-
                                                      # line RRs
                print "LINE: " . $_ if DEBUG > 10;
                print "BUFF: " . $buffer . "\n\n" if DEBUG > 10;

                my $char = $1;
                if ($char eq ';') {

                    # rest of line is a comment...
                    if ($openingbracketfound) {
                        next READLINE;
                    }
                    else {
                        next READLINE
                            if $buffer =~ s/^\s*$//o;    # buffer only
                                                         # contains spaces
                        last LINEPARSE;
                    }
                }
                elsif ($char eq '(') {

                    # Maybe we are to strict here and we should just ignore this
                    return
                        "READ FAILURE: Multiple enclosing opening brackets around "
                        . $_
                        if $openingbracketfound == 1;
                    $openingbracketfound = 1;
                }
                elsif ($char eq ')') {
                    return
                        "READ FAILURE: Multiple enclosing closing brackets around "
                        . $_
                        if $openingbracketfound == 0;
                    $openingbracketfound = 0;
                }
                elsif ($char eq '"') {

                    # We entered a 'character string'
                    # collect everything upto the closing quote
                    $buffer .= '"';
                    my $k = 0;
                    CHRSTR: while (s/(.)(.*)/$2/o) {
                        $buffer .= $1;
                        $k++;
                        if ($k > 256) {
                            print
                                "Character strings should not be longer than 256 chars\n";
                            print "See RFC1035 section 3.3\n";
                            exit;
                        }

                        # Note that end of line will also terminate character
                        # strings.
                        # This may not be RFC complient so we print a warning.
                        last CHRSTR if $1 eq '"';
                    }
                    print "WARNING: Unmatched quotes at end of line\n"
                        if $buffer !~ /\"$/o;
                }
                else {
                    # Single spaces between the tokens.. we depend on this later
                    if ($char =~ /^\s+$/o) {
                        $buffer .= " " unless $buffer =~ /\s$/o;
                    }
                    else {
                        $buffer .= $char;
                    }
                }
                $i++;

                # Next line if we are at end of line and there is still a open bracket
                # not matched.
                next READLINE if $openingbracketfound && /^\s*$/o;
            }    # END LINEPARSE

            # LINE HAS NOW BEEN PARSED.. ALL MULTILINES ARE ON ONE LINE AND
            #
            $buffer =~ s/\s*$//go;    # remove possible trailing spce
            $_      = $buffer;
            $buffer = '';
        }
        else {                        # when not parsing the line char by char
            s/\s+/ /go;               # Remove extra spaces
            s/\s*$//go;               # Remove extra spaces
        }

        print "READLINE:>>" . $_ . "<<\n" if DEBUG > 2;

        if (/^\s*\$TTL\s+(\d+)/o) {    #FOUND a $TTL directive
            $lastseenTTL = $1;
            $defaultTTL = $lastseenTTL if (!$defaultTTL);
            print ";; DEFAULT TTL found : " . $lastseenTTL . "\n"
                if DEBUG > 1;
            $self->{'default_ttl'} = $defaultTTL;
            next READLINE;
        }

        # replace the @ by the ORIGIN.. as given by the argument.
        s/@/$lastseenORIGIN/;

        # Set the current originin. This is the one from the $ORIGIN value from
        # the zone file. It will be used to complete dnames  below.
        if (/^\s*\$ORIGIN\s+(\S+)\s*$/o) {
            $lastseenORIGIN = $1;
            print ";; lastseenORIGIN set to : " . $lastseenORIGIN . "\n"
                if DEBUG > 1;
            next READLINE;
        }

        if (/^\s*\$INCLUDE\s+(\S+)\s*(\S*)?$/io) {
            my $newfilename = $1;
            $lastseenORIGIN = $2 if $2;
            if ($newfilename =~ /\//o) {

                # absolute pathname
            }
            else {
                #relative pathname
                $newfilename =
                    dirname($self->{'filename'}) . "/" . $1;  # Relative path...
            }

            # Deep recursion is still possible....
            return
                "READ FAILURE: Including $filename from itself would cause deep recursion\n"
                if ($filename eq $newfilename);

            # Other recursion check

            return "READ FAILURE: Nested INCLUDE more than 20 levels deep... \n"
                . "check if the  files are not including in loops..."
                if $self->{"IncludeRecursionDetector"} > $MaxIncludeDepth;

            # RFC 1035 section 5 specifies that the lastseenORIGIN does not traverse
            # INCLUDES but is unclear on the last seen TTL. We use the lastseen TTL
            # from the included file
            $lastseenTTL =
                $self->_read($fh_out, $newfilename, $lastseenORIGIN,
                $previousdname, $lastseenTTL);

            return $lastseenTTL if $lastseenTTL =~ /^READ FAILURE:/o;
            next READLINE;
        }

        # Use the previous dname if no dname was qualified (line starts with blanks)
        if (/^(\S+)\s+/o) {
            $previousdname = $1;

            # below is a uggly bug fix.
            $previousdname = $lastseenORIGIN
                if ($previousdname eq '$GENERATE');
            $previousdname = $lastseenORIGIN
                if ($previousdname eq '$INCLUDE');
        }
        else {
            $_ = $previousdname . $_;
        }

        # $_ now either contains a GENERATE statement or a line with not
        # fully qualified domain names in both owner name as RDATA and
        # with possibly unqualified TTL and CLASS.

        if (
            m{^\s*\$GENERATE       #Generate directive
	    \s+((\d+)-(\d+)(/(\d+))?)    #Range start-stop or start-stop/step.
	    \s+(\S+)               #The LHS
	    \s+(\S+)               #The TYPE
	    \s+(\S+)               #The RHS
	   }xo
            )
        {
            print "Range: $2-$3 "                         if DEBUG;
            print "/$5 "                                  if DEBUG && $5;
            print "LHS: $6 " . "TYPE: $7 " . "RHS: $8 \n" if DEBUG;
            my $RANGE = $1;
            my $LOW   = $2;
            my $HIGH  = $3;
            my $STEP  = $5 ? $5 : 1;
            my $LHS   = $6;
            my $TYPE  = $7;
            my $RHS   = $8;

            if ($TYPE !~ /PTR|CNAME|DNAME|A|AAAA|NS/o) {
                print
                    "Generate only supports PTR, CNAME, DNAME, A, AAAA and NS.\n";
                next READLINE;
            }
            if ($LOW > $HIGH) {
                print "Range should be increasing.\n";
                print "Skipping the following \$GENERATE directive:\n" . $_;
                next READLINE;
            }
            if ($LOW < 0 || $STEP < 0) {
                print "Sorry all vallues in the range need to be positive";
                print "Skipping the following \$GENERATE directive:\n" . $_;
                next READLINE;
            }
            my $i = $LOW;
            while ($i <= $HIGH) {

                my $ownername = processGENERATEarg($LHS, $i, $lastseenORIGIN);

                my $my_generated_record =
                    $ownername . " " . $lastseenTTL . " IN " . $TYPE . " ";
                if ($TYPE =~ /CNAME|PTR|DNAME|NS/o) {

                    # These types have expansion of the RDATA to FQDN
                    my $rdatastr =
                        processGENERATEarg($RHS, $i, $lastseenORIGIN);
                    $my_generated_record .= $rdatastr;
                    if (   ($TYPE =~ /CNAME|DNAME/)
                        && ($ownername eq $rdatastr))
                    {
                        $i += $STEP;
                        next;
                    }

                }
                else {
                    # A and AAAA are left alone
                    $my_generated_record .= processGENERATEarg($RHS, $i, "");
                }
                print ";; GENERATE: " . $my_generated_record . "\n"
                    if DEBUG;

                print $fh_out $my_generated_record . "\n";

                if (defined $self->{"create_rr"}) {
                    my $rr = Net::DNS::RR->new($my_generated_record);

                    push @{ $self->{"create_rr"} }, $rr;
                }
                $i += $STEP;
            }

        }
        else {
            my $returnval =
                $self->_parseline($_, $lastseenORIGIN, $lastseenTTL);
            next READLINE if $returnval =~ /^__SKIPPED__$/o;
            return $returnval if $returnval =~ /^READ FAILURE:/o;
            $_ = $returnval;
            print ";;    " . $_ . "\n" if DEBUG > 2;

            print $fh_out $_ . "\n";
            if (defined $self->{"create_rr"}) {
                my $rr = Net::DNS::RR->new($_);
                push @{ $self->{"create_rr"} }, $rr;
            }
        }
    }

    # Done parsing this file.
    $fh_in->close;
    $self->{"IncludeRecursionDetector"}--;
    print ";;   returning from _read\n" if DEBUG > 2;
    return $lastseenTTL;
}

#
# Internal functions.

#####################################
# complete_dname will append the origin to the input string if needed.
# Does a sanity check on escaped \.

sub _complete_dname {
    my $self   = shift;
    my $dname  = shift;
    my $origin = shift;
    if ($dname !~ /\.$/o && $dname !~ /\\\.$/o)
    {    # Hmmmm what if a label ends in an escapped \.

        $dname .= "." . $origin;

        # This fixes a bug, If the origin equals the root the above line
        # caused two trailing dots to be added.
        chop $dname if $origin eq ".";
    }

    return $dname;
}


####################################################
#  processGENERATEarg
#
# this function is used to expand lhs or rhs variables in
# a generate statment.
# it takes the lhs or rhs string and and the current vallue of
# the itterator as input and returns the beast fully expanded according
# to the following rules.

#lhs describes the owner name of the resource records to be
#created. Any single $ symbols within the lhs side are replaced by the
#iterator value. To get a $ in the output you need to escape the $
#using a backslash \, e.g. \$. The $ may optionally be followed by
#modifiers which change the offset from the interator, field width and
#base. Modifiers are introduced by a { immediately following the $ as
#${offset[,width[,base]]}. e.g. ${-20,3,d} which subtracts 20 from the
#current value, prints the result as a decimal in a zero padded field
#of with 3. Available output forms are decimal (d), octal (o) and
#hexadecimal (x or X for uppercase). The default modifier is
#${0,0,d}. If the lhs is not absolute, the current $ORIGIN is appended
#to the name.

sub processGENERATEarg {
    my $lhs    = shift;
    my $i      = shift;
    my $origin = shift;

    my $expanded = "";
    while ($lhs) {
        my $remaining = "";
        if (
            $lhs =~ s/^(\S*?)
	    ((?<!\\)\$.*)$               # The first non escaped $ character and anything beyond to end of sring
	    /$2/x
            )
        {
            $expanded .= $1 if $1;
            $lhs =~ s/^\$(\{(\d+)(,(\d+))?(,(\w+))?\})?(.*)\s?$/$7/;

            #	$lhs=~ s/\$//;
            my $offset = $2 ? $2 : 0;
            my $width  = $4 ? $4 : 0;
            my $format = $6 ? $6 : "d";
            if ($format !~ /d|o|x|X/o) {
                die
                    "Fatal error in parsing the format in a \$GENERATE statement.\n Should be d,o,x or X\n";
            }
            $expanded .= sprintf("%0$width$format", $i + $offset);
        }
        else {
            $expanded .= $lhs;
            $lhs = "";

        }
    }
    $expanded =~ s/\\\$/\$/og;    #finally substitute '$' for the escaped \$

    # Only expand to FQDN if the last char is a "." and if the
    # the $origin argument is not empty.

    $expanded .= "." . $origin if $expanded !~ /\.$/o && $origin ne "";

    return $expanded;
}

###################################
#
#  parseline will complete an inputline of the form <dname> [<TTL>]
#  [<CLASS>] <type> <RDATA> to a line with fully qualified names in
#  the dname and the RDATA, it will insert the CLASS and TTL if not
#  specified.  The arguments are the lastseenORIGIN and lastseenTTL
#  that are used to complete the domain names with, and to add to fill
#  in the unqualified TTLs.
#

# returns 0 on success
# returns string starting with "READ FAILURE:" on error.

# returns the string "__SKIPPED__" if a line was skipped (see the
# argumens to the read method such as STRIP_SEC &c).

sub _parseline {
    my $self = shift;
    $_ = shift;
    my $lastseenORIGIN = shift;    # vallue of the last seen $ORIGIN directive
    my $lastseenTTL    = shift;

    my $ttl;

    my $rtype  = '';
    my $rdata  = '';
    my $prefix = '';

    ($_ =~ m/$ZONE_RR_REGEX/xso)
        || return "READ FAILURE: \""
        . $_
        . "\" did not match RR pattern.\nPlease clean your zonefile!\n";

    my $dname = $1;

    s/^\s*(\S+) / /o;    # remove the dname to put it back fully qualified
                         # If there is a match it could still be matching the
                         # string 0, so just testing on $1 will now work....
    if ($1 || $1 eq "0") {
        $dname = $1;

        $dname = $self->_complete_dname($dname, $lastseenORIGIN);
        $_ = $dname . $_;
        print ";;    read DNAME: " . $dname . "\n" if DEBUG > 2;
    }
    else {
        return
            "READ FAILURE: Couldn't match dname in read method while reading\n"
            . $_
            . " \nthis Should not happen\n";
    }

    # See if there is a TTL value, if not insert one
    if (/^\S+ (\d+)/o) {
        print ";;    TTL   : " . $1 . "\n" if $debug > 2;
        $ttl = $1;
    }
    else {

        # RFC 1035
        # 'Omitted class and TTL values are default to the
        # last explicitly stated values"

        # I take that to mean last explicitly stated in a $TTL
        # statement. (Purerely because of bind9 compatibility)

        # instert last seen TTL

        s/^(\S+) (.*)$/$1 $lastseenTTL $2/;

    }

    # See if there is the CLASS is defined, if not insert one.
    if (!/^\S+ \d+ ($classes)/) {

        #insert IN
        s/^(\S+ \d+ )(.*)$/$1IN $2/o;
    }

    # We have everything specified.. We now get the RTYPE AND RDATA...
    /^\S+ \d+ ($classes) (\S+) (.*)$/;
    if ($1) {
        print ";;    rtype: " . $2 . "\n" if DEBUG > 2;
        $rtype = $2;
    }
    else {
        return "READ FAILURE: We expected to match an RTYPE\n" . $_
            . " \nthis Should not happen\n";
    }
    if ($3) {
        $rdata = $3;
        print ";;    rdata:-->" . $rdata . "<---\n" if DEBUG > 2;

    }
    else {
        return
            "READ FAILURE: We expected to find RDATA in the following record\n"
            . $_
            . " \ncheck your zonefile\n";
    }

    if (defined $ttl) {
        $prefix = $dname . " " . $ttl . " IN " . $rtype . " ";
    }
    else {
        $prefix = $dname . " " . $lastseenTTL . " IN " . $rtype . " ";
    }

    # Expand to FQDN in the RDATA.
    #
    # We apply a regular expression to the rdata and expand dnames in there
    # to fully qualified dnames using the complete_dname function.

    if (uc $rtype eq "NS") {

        #"NS"   		 RFC 1035, Section 3.3.11
        # the pattern below is appropriate if the rdata only contains a dname
        # or the dname is the last item in the RDATA string
        $_ = $prefix . $self->_complete_dname($rdata, $lastseenORIGIN);

        # skipping
        #	"MD"	RFC 1035, Section 3.3.4 (obsolete)
        #	"MF"  	RFC 1035, Section 3.3.5 (obsolete)
    }
    elsif (uc $rtype eq "CNAME") {

        #	"CNAME"  RFC 1035, Section 3.3.1
        $_ = $prefix . $self->_complete_dname($rdata, $lastseenORIGIN);
    }
    elsif (uc $rtype eq "SOA") {

        #	"SOA"	RFC 1035, Section 3.3.13
        # first two strings in the SOA rdata are dnames
        $rdata =~ /(\S+)\s+(\S+)\s+(\d+)\s+(.*)$/o;
        return "READ FAILURE: Soa serial not found in\n $_\n"
            if (!$3 && $3 ne "0");

        my $soaserial = $3;
        $soaserial++ if $self->{"bump_soa"};
        $_ =
              $prefix
            . $self->_complete_dname($1, $lastseenORIGIN) . " "
            . $self->_complete_dname($2, $lastseenORIGIN) . " "
            . $soaserial . " "
            . $4;    #

        # Additional sanity check.
        if (lc($dname) ne lc($self->{'_origin'})) {
            print
                "WARNING: ORIGIN as specified or determined from the file name\n";
            print
                "     does not match the SOA ownername. I'll be using the ownername!\n";
            print "     origin set from "
                . $self->{'_origin'} . " to: "
                . $dname . "\n";
            $self->{'_origin'} = $dname;
        }

    }
    elsif (uc $rtype eq "MB") {

        #	"MB"	RFC 1035, Section 3.3.3

        $_ = $prefix . $self->_complete_dname($rdata, $lastseenORIGIN);
    }
    elsif (uc $rtype eq "PTR") {
        $_ = $prefix . $self->_complete_dname($rdata, $lastseenORIGIN);
    }
    elsif (uc $rtype eq "MG") {

        #	"MG"	RFC 1035, Section 3.3.6
        $_ = $prefix . $self->_complete_dname($rdata, $lastseenORIGIN);
    }
    elsif (uc $rtype eq "MR") {

        #	"MR"	RFC 1035, Section 3.3.8
        $_ = $prefix . $self->_complete_dname($rdata, $lastseenORIGIN);

        # skipping
        #	"NULL"	RFC 1035, Section 3.3.10
        #	"WKS"	RFC 1035, Section 3.4.2 (deprecated, and no dname)
    }
    elsif (uc $rtype eq "PTR") {

        #	"PTR"	RFC 1035, Section 3.3.12
        $_ = $prefix . $self->_complete_dname($rdata, $lastseenORIGIN);

        #skipping
        #	"HINFO"	RFC 1035, Section 3.3.2
    }
    elsif (uc $rtype eq "MINFO") {

        #	"MINFO"	RFC 1035, Section 3.3.7
        $rdata =~ /(\S+) (\S+)$/o;
        $_ =
              $prefix
            . $self->_complete_dname($1, $lastseenORIGIN) . " "
            . $self->_complete_dname($2, $lastseenORIGIN);
    }
    elsif (uc $rtype eq "MX") {

        #	"MX"	RFC 1035, Section 3.3.9
        $_ = $prefix . $self->_complete_dname($rdata, $lastseenORIGIN);

        # skipping
        #	"TXT"	RFC 1035, Section 3.3.14
    }
    elsif (uc $rtype eq "RP") {

        #	"RP"	RFC 1183, Section 2.2
        $rdata =~ /(\S+) (\S+)$/o;
        $_ =
              $prefix
            . $self->_complete_dname($1, $lastseenORIGIN) . " "
            . $self->_complete_dname($2, $lastseenORIGIN);
    }
    elsif (uc $rtype eq "AFSDB") {

        #	"AFSDB"	RFC 1183, Section 1
        $_ = $prefix . $self->_complete_dname($rdata, $lastseenORIGIN);

        # skipped
        #	"X25"	RFC 1183, Section 3.1
        #	"ISDN"	RFC 1183, Section 3.2
    }
    elsif (uc $rtype eq "RT") {

        #	"RT"	RFC 1183, Section 3.3
        $_ = $prefix . $self->_complete_dname($rdata, $lastseenORIGIN);

        # skipped
        #	"NSAP"	RFC 1706, Section 5
    }
    elsif (uc $rtype eq "SIG") {

        #	"SIG"	RFC 2555, Section 4.1
        return "__SKIPPED__" if $self->{'strip_old'};
        my (
            $typecovered, $algoritm,      $type,
            $orgttl,      $sigexpiration, $siginception,
            $keytag,      $signame,       $sig
            )
            = $rdata =~
            /^\s*(\S+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\S+)\s+(.*)/o;
        $_ =
              $prefix
            . " $typecovered $algoritm $type $orgttl $sigexpiration $siginception $keytag "
            . $self->_complete_dname($signame, $lastseenORIGIN) . " $sig";

    }
    elsif (uc $rtype eq "PX") {

        #	"PX"	RFC 2163,
        my ($preference, $map822, $mapx400) = $rdata =~ /(\d+) (\S+) (\S+)$/o;
        $_ =
              $prefix . " "
            . $preference . " "
            . $self->_complete_dname($map822,  $lastseenORIGIN) . " "
            . $self->_complete_dname($mapx400, $lastseenORIGIN);
    }
    elsif (uc $rtype eq "KEY") {

        # NOTHING

        # skipped
        #	"GPOS"	RFC 1712 (obsolete)
        #	"AAAA"	RFC 1886, Section 2.1
        #	"LOC"	RFC 1876

    }
    elsif (uc $rtype eq "NXT") {
        return "__SKIPPED__" if $self->{'strip_old'};

        #	"NXT"	RFC 2535
        $rdata =~ /(\S+) (.*)$/o;
        $_ = $prefix . $self->_complete_dname($1, $lastseenORIGIN) . " " . $2;

        #	"EID"   draft-ietf-nimrod-dns-xx.txt
        #	"NIMLOC"   draft-ietf-nimrod-dns-xx.txt
    }
    elsif (uc $rtype eq "SRV") {

        #	"SRV"	RFC 2782
        $_ = $prefix . $self->_complete_dname($rdata, $lastseenORIGIN);

        # skipped

        #	"ATMA"   [Dobrowski]
        # skipped... hmmmmm...

    }
    elsif (uc $rtype eq "NAPTR") {

        #	"NAPTR"	RFC 2168, 2915
        $rdata =~ /(.*) (\S+)$/o;
        $_ = $prefix . $1 . " " . $self->_complete_dname($2, $lastseenORIGIN);
    }
    elsif (uc $rtype eq "KX") {

        #	"KX"	RFC 2230
        $_ = $prefix . $self->_complete_dname($rdata, $lastseenORIGIN);

        # skipped
        #	"CERT"	RFC 2358
        #	"A6"	RFC 2874
    }
    elsif (uc $rtype eq "DNAME") {

        #	"DNAME"	RFC 2672
        $_ = $prefix . $self->_complete_dname($rdata, $lastseenORIGIN);

        #skipped
        #	"SINK"   [Eastlake]   # I don't know about this RR
        #	"OPT"	RFC 2671

        #       "APL"    RFC 3123   NO dname in RDATA
        #      "DS"          NO dname in RDATA
        #      "SSHFP        NO dname in RDATA

    }
    elsif (uc $rtype eq "NSEC") {

        #	"NSEC"
        return "__SKIPPED__" if $self->{'strip_nsec'};
        $rdata =~ /(\S+) (.*)$/o;
        $_ = $prefix . $self->_complete_dname($1, $lastseenORIGIN) . " " . $2;
    }
    elsif (uc $rtype eq "DNSKEY") {

        #	"DNSKEY"
        return "__SKIPPED__" if $self->{'strip_dnskey'};

    }
    elsif (uc $rtype eq "RRSIG") {

        #	"RRSIG"
        return "__SKIPPED__" if $self->{'strip_rrsig'};
        my (
            $typecovered, $algoritm,      $type,
            $orgttl,      $sigexpiration, $siginception,
            $keytag,      $signame,       $sig
            )
            = $rdata =~
            /^\s*(\S+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\S+)\s+(.*)/o;
        return "__SKIPPED__"
            if $self->{'strip_dnskey'} && uc($typecovered) eq "DNSKEY";
        return "__SKIPPED__"
            if $self->{'strip_nsec'} && uc($typecovered) eq "NSEC";
        return "__SKIPPED__"
            if $self->{'bump_soa'} && uc($typecovered) eq "SOA";
        $_ =
              $prefix
            . " $typecovered $algoritm $type $orgttl $sigexpiration $siginception $keytag "
            . $self->_complete_dname($signame, $lastseenORIGIN) . " $sig";

    }
    elsif (uc $rtype =~ /TYPE\d+/o) {

        # Unknown RR.
    }

    return $_;

}

# Use named-compilezone -D to do the processing;

sub _read_namedcomp {
    my ($self, $fh_out, $filename, $origin) = @_;

    my $tmpfh    = File::Temp->new();
    my $tmpfname = $tmpfh->filename;

    print ";; Tempfilename: $tmpfname\n" if $debug;

    print ";; _read_namedcomp: $filename $origin\n" if $debug;
    my $cmd = "named-compilezone  -i none -o $tmpfname $origin $filename";
    print ";; Running: " . join(" ", $cmd) . "\n" if $debug;

    my @result = `$cmd`;
    if ($debug) {
        foreach my $i (@result) {
            print ";;; $i\n";
        }
    }
    my $lastresult = pop(@result);

    if ($? == -1) {
        return "command failed: $!\n";
    }
    elsif ($lastresult =~ /failed/) {
        return $lastresult;
    }

    $origin =~ s/\.$// unless ($origin eq ".");

    my $loadzone_result = "";
    my $ProcessedApex;

    open($DUMP, "<", $tmpfname)    ## no critic
        || return ("Could not execute " . join(" ", $cmd))
        ;                          # This should cause classic parsing

    CONTENT: while (<$DUMP>) {
        if (/^\S+\s+\d+\s+IN\s+(SOA|RRSIG\s+\w+|DNSKEY|NSEC|SOA|NXT|SIG)\s+/o) {
            my $type = $1;
            $self->{strip_dnskey} && ($type eq "DNSKEY") && next CONTENT;

            # Also strip the sig over DNSKEY if we are stripping DNSKEYS
            if ($type =~ /RRSIG\s+(\w+)/) {
                $self->{strip_rrsig}  && next CONTENT;
                $self->{strip_dnskey} && ($1 eq "DNSKEY") && next CONTENT;
                $self->{strip_nsec}   && ($1 eq "NSEC") && next CONTENT;
                $self->{bump_soa}     && ($1 eq "SOA") && next CONTENT;
            }

            $self->{strip_rrsig} && ($type eq "RRSIG") && next CONTENT;
            $self->{strip_nsec}  && ($type eq "NSEC")  && next CONTENT;
            $self->{strip_old}
                && (($type eq "NXT") || ($type eq "SIG"))
                && next CONTENT;
            if ($self->{bump_soa} && ($type eq "SOA")) {
                my $soa = Net::DNS::RR->new($_);
                $soa->serial($soa->serial() + 1);
                $_ =
                    $soa->string . "\n"; # The newline is FITAL, the next record
                                         # would otherwise disapear behind a
                                         # comment.
            }
        }

        print $fh_out $_;
        if (defined $self->{"create_rr"}) {
            my $rr = Net::DNS::RR->new($_);
            push @{ $self->{"create_rr"} }, $rr;
        }
    }

    close($DUMP);

    print $fh_out "\n";    # Make sure file ends with newline

    return ("success");

}

sub DESTROY {
    close($DUMP);
    return;
}


1;

__END__

=pod

=head1 NAME

Net::DNS::Zone::ParserX - A Zone Pre-Parser (slightly altered fork in cpanel2autodns)

=head1 VERSION

version 0.1

=head1 SYNOPSIS

OO package that implements an RFC complient zone file (pre)parser.
perldoc L<Net::DNS::Zone::Parser> for details.

=head1 DESCRIPTION

The Net::DNS::Zone::Parser should be considered a preprocessor that
"normalizes" a zonefile. 

It will read a zonefile in a format conforming to the relevant RFCs
with the addition of BIND's GENERATE directive from disk and will
write fully specified resource records (RRs) to a filehandle. Whereby:

=over

=item - all comments are stripped;

=item - there is one RR per line;

=item - each RR is fully expanded i.e. all domain names are fully qualified
(canonicalised) and the CLASS and TTLs are specified.

=item - Some RRs may be 'stripped' from the source or otherwise
processed. For details see the 'read' method.

=back

Note that this module does not have a notion of what constitutes a
valid zone; it only parses. For example, the parser will happilly
parse RRs with ownernames that are below in another zone because a NS
RR elsewhere in the zone.

=head1 FORK

Requirement for Net::DNS::SEC blocked adoption.

=head1 METHODS

=head2 new

   my $parser=Net::DNS::Zone::Parser->new($io);

Creates the a parser instance.

The optional argument should be a IO::File or IO::Handle type of
object. If not specified a temporary IO::File type object will be
created to which the lines will be printed. This object can be
obtained using the get_io method

=head2 get_io

   my $io=$parser->get_io;
   $io->seek(0,0);
   print while (< $io >);

Returns the filehandle to which the zone file has been written. This
is either the filehandle specified as argument to the new() method or
one that points to a temporary file.

=head2 read

    my $parser=Net::DNS::Zone::Parser->new;
    $parser->read("/tmp/example.foo");
    $parser->read("/tmp/foo.db",
		{ ORIGIN => "example.db",
		  };

# alternatively

    $returnval=$parser->read("/tmp/foo.db",
		{ ORIGIN => "example.db",
                  CREATE_RR => 1,
		  STRIP_SEC => 1,
		  };
    if ($returnval) {
         die $returnval;
    }else{
         $RRarrayref=$parser->get_array();
    }

'read' reads a zonefile from disk to 'pre-processes' it.  The first
argument is a path to the zonefile. The second parameter is a hash
with optional arguments to tweak the reading.

The read method returns 0 on success and a string starting with "READ
FAILURE:" and a description on why the error occurred, on error.

The zone file is written (streamed) to a filehandle, also see the
get_io method.

The HASH may contain 1 or more of the following arguments.

=over

=item ORIGIN   

the origin of the zone being parsed. if ommited the origin is taken to
be the same as the name of the file.

=item CREATE_RR 

if the value evaluates to TRUE an array of Net::DNS::RR objects is
build that can be returned using the get_array method. When CREATE_RR
is true the read module will fail if Net::DNS::RR->new() cannot parse
the input i.e. when the RDATA of a RR is not correctly specified.
Since the instance maintains the RR array in core setting this
variable may be problematic for large zones.

=item STRIP_RRSIG 

if the value evaluates to TRUE all RRSIG RRs in the zone are ignored
i.e. stripped from the output

=item STRIP_NSEC 

if the value evaluates to TRUE all NSEC RRs in the zone are ignored
i.e. stripped from the output

=item STRIP_DNSKEY 

if the value evaluates to TRUE all DNSKEY RRs and their related RRSIGs
in the zone are ignored i.e. stripped from the output

=item STRIP_SEC 

if the value evaluates to TRUE all DNSKEY, RRSIG and NSEC RRs in the
zone are ignored i.e. stripped from the output

=item STRIP_OLD 

if this value evaluates to TRUE all NXT and SIG RRs are ignored (the
KEY RRs are _not_ ignored).

=item BUMP_SOA

if this value evaluates to TRUE the SOA serial will be increased by 1 
when written to the filehandle.

=back

=head2 get_array

Returns a reference to the array that is created if CREATE_RR is set
to true during the read method.

=head2 get_origin

    my $origin=$parser->get_origin;

Returns the origin of the zone that was parsed.

=head2 build_regex

This code is simalar but not equal to the Net::DNS::RR function.
The resulting regexp is just slightly different.

=head1 FUNCTIONS

=head2 processGENERATEarg

  use Net::DNS::Zone::Parser (processGENERATEarg)
  $generated=processGENERATEarg(0.0.${1,3},5,"inaddr.arpa."

This exported function parses the "LHS" and "RHS" from a BIND generate
directive.  The first argument contains the "LHS" or "RHS", the second
argument the iterator vallue and the last argument contains the value
of the "origin" that is to be added if the result of the generate is
not a FQDN (it is the vallue that is stupidly appended if the synthesized
name does not end with a ".").

From the BIND documentation:

lhs describes the owner name of the resource records to be
created. Any single $ symbols within the lhs side are replaced by the
iterator value. To get a $ in the output you need to escape the $
using a backslash \, e.g. \$. The $ may optionally be followed by
modifiers which change the offset from the iterator, field width and
base. Modifiers are introduced by a { immediately following the $ as
${offset[,width[,base]]}. e.g. ${-20,3,d} which subtracts 20 from the
current value, prints the result as a decimal in a zero padded field
of with 3. Available output forms are decimal (d), octal (o) and
hexadecimal (x or X for uppercase). The default modifier is
${0,0,d}. If the lhs is not absolute, the current $ORIGIN is appended
to the name.

=head1 Supported DIRECTIVEs

=head2 INCLUDE

$INCLUDE <path> [<origin>]

will read the file as specified by 'path'. If 'path' is absolute it
will be interpreted as such. If it is relative it will be taken
relative to the path of the zonefile that includes it. 

Optionally $INCLUDE will take a 2nd argument that sets the current
origin for relative domains. 

The parser only accept IN class zone files.

=head2 TTL

Specifying the default TTL

=head2 ORIGIN

Specifying the origin used to complete non fully qualified domain
names.

=head2 GENERATE

See the BIND documentation.

=head1 Related packages.

There are other packages with likewise functionality; they where not
suitable for my purposes. But maybe they are suitable for you. So
before you start using this module you may want to look at these.

DNS::Zone::File will parse a zonefile but will not expand domain names
that are not fully qualified since it has no logic to interpret the
RDATA of each individual RR. You can use this module to pre-process
the file and then feed it to DNS::Zone::File (Default) to create a
DNS::Zone instance.

DNS::ZoneFile has almost the same functionality as this code it the
canonicalises RR records it is aware off. It also has an INCLUDE
function. Being an abstraction of a zonefile it has an interface to
add and delete RRs from the zonefile and print it. The code does not 
support a GENERATE feature.

Net::DNS::ZoneFile also almost has the same functionality, it supports
the GENERATE, INCLUDE and ORIGIN primitives. It also supports more
classes than just the IN class. However, this module first loads the
complete zone in memory; which may be problematic for very large
zones.  It only seems to support a subset of the available RR types.

All of these classes are abstractions of zonefiles, not of zones
i.e. there is no notion of where the zonecuts are and what data is out
of zone.

=head1 TODO, BUGS and FEATURES.

=over

=item FEATURE

This code only supports zones in the Zone files in the IN class.

=item FEATURE

More sanity checking on the RDATA for each RR. 

The pre-processor it will only look for 'dnames' in the RDATA that
need expansion and not check or validate other entries in the RDATA.

=item FEATURE

The zonefile formating rules allow the CLASS to be specified
before the TTL. This code does not parse such lines.

=item FEATURE

The KX RR (RFC 2230) will have its RDATA expanded but since
there is no implementation of it in Net::DNS it will fail to read if
CREATE_RR => 1 in the read method.

=item TODO

This code needs to know of RR types that have RDATA with dnames.

For completeness these are the RRtypes that have domain names in
their rdata and that have been implemented.

NS, CNAME, SOA, MB, PTR, MG, MR, PTR, MINFO, MX, RP, AFSDB, RT,
SIG, NXT, SRV, DNAME, NSEC, and RRSIG

RRtypes that do not have domain names in their RDATA will be parsed 
transparently.

New types will need to be implemented if they become available.
Please inform the developer of new RRtypes with a domain name in them
that has not been implemented.

=back

=head1 COPYRIGHT

Copyright (c) 2003, 2004  RIPE NCC.  Author Olaf M. Kolkman
<net-dns-sec@ripe.net>

All Rights Reserved

Permission to use, copy, modify, and distribute this software and its
documentation for any purpose and without fee is hereby granted,
provided that the above copyright notice appear in all copies and that
both that copyright notice and this permission notice appear in
supporting documentation, and that the name of the author not be
used in advertising or publicity pertaining to distribution of the
software without specific, written prior permission.

THE AUTHOR DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE, INCLUDING
ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS; IN NO EVENT SHALL
AUTHOR BE LIABLE FOR ANY SPECIAL, INDIRECT OR CONSEQUENTIAL DAMAGES OR ANY
DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN
AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

The $GENERATE primitive parser is based on code in Net::DNS::ZoneFile

=head1 SEE ALSO

L<perl(1)>, L<Net::DNS>, L<Net::DNS::RR>, L<Net::DNS::RR::RRSIG>,
L<Net::DNS::Zone>

=head1 AUTHOR

Juerd Waalboer <juerd@tnx.nl>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by Juerd Waalboer.

This is free software, licensed under:

  The (three-clause) BSD License

=cut
