package Net::FTPTurboSync::PrgOpts;

use Net::Netrc;
# singleton :)
our $theOpts = undef;

sub new {
    my ($class, $argv ) = @_;
    my $self = {
        dbh=>undef,
        newDB=>0,
        dbpath=>"",
        uildDB=>0,
        nodelete=>0,
        returncode=>0,
        configfile=>$ENV{"HOME"}."/.turbo-ftp-sync",
        # basics
        localdir=>"",
        remoteURL=>"",
        ftpuser=>"anonymous",
        ftppasswd=>"anonymos",
        ftpserver=>"localhost",
        ftpdir=>"",
        maxerrors=> 3, 
        ftptimeout=>120,
        # verbosity
        doverbose=>1,
        dodebug=>0,
        doquiet=>0,
        doinfoonly=>0,
        infotext=>"",
        docheckfirst=>0,
        ignoremask => "",
        followsymlinks=>0,
        doflat=>0,
    };
    bless $self, $class;
    $self->parseCommandLineParameters( $argv );
    return $self;
}

# return cfgfoptions
sub readConfigFile {
    my ( $self ) = @_;
    my @cfgfoptions=();
    if ($self->{configfile} ne "") {
        if (-r $self->{configfile}) {
            #print "Reading config file.\n"; # For major problem debugging
            open (CONFIGFILE,"<$self->{configfile}");
            while (<CONFIGFILE>) {
                $_ =~ s/([ 	\n\r]*$|\.\.|#.*$)//gs;
                if ($_ eq "") { next; }
                if ( ($_ =~ /[^=]+=[^=]+/) || ($_ =~ /^-[a-zA-Z]+$/) ) { push @cfgfoptions, $_; }
            }
            close (CONFIGFILE);
        } # else { print "Config file does not exist.\n"; } # For major problem debugging
    } # else { print "No config file to read.\n"; } # For major problem debugging
    return \@cfgfoptions;
}

sub print_options() {
    my ( $self ) = @_;
    print "\nPrinting options:\n";
    # meta
    print "returncode    = ", $self->{returncode}    , "\n";
    print "configfile    = ", $self->{configfile}    , "\n";
    # basiscs
    print "localdir      = ", $self->{localdir}      , "\n";
    # FTP stuff
    print "remoteURL     = ", $self->{remoteURL}     , "\n";
    print "ftpuser       = ", $self->{ftpuser}       , "\n";
    print "ftppasswd     = ", $self->{ftppasswd}     , "\n";
    print "ftpserver     = ", $self->{ftpserver}     , "\n";
    print "ftpdir        = ", $self->{ftpdir}        , "\n";
    # verbsityosity
    print "doverbose     = ", $self->{doverbose}     , "\n";
    print "dodebug       = ", $self->{dodebug}       , "\n";
    print "doquiet       = ", $self->{doquiet}       , "\n";
    #  print "db       = ", $dbh       , "\n";  
    #
    print "doinfoonly    = ", $self->{doinfoonly}    , "\n";
    print "\n";
}

sub print_syntax() {
    print "\n";
    print "turbo-ftp-sync.pl $VERSION (2011-05-12)\n";
    print "author is Daneel S. Yaitskov ( rtfm.rtfm.rtfm\@gmail.com )\n";    
    print "\n";
    print " turbo-ftp-sync [ options ] [ localdir remoteURL ]\n";
    print " options = [-dfgpqv] [ cfg|ftpuser|ftppasswd|ftpserver|ftpdir=value ... ] \n";
    print "   localdir    local directory, defaults to \".\".\n";
    print "   remoteUrl   full FTP URL, scheme\n";
    print '               ftp://[ftpuser[:ftppasswd]@]ftpserver/ftpdir'."\n";
    print "               ftpdir is relative, so double / for absolute paths as well as /\n";
    print "   -c | -C     like -i, but then prompts whether to actually do work\n";
    print "   -d | -D     turns debug output (including verbose output) on\n";
    print "   -f | -F     flat operation, no subdir recursion\n";
    print "   -h | -H     prints out this help text\n";
    print "   -i | -I     forces info mode, only telling what would be done\n";
    print "   -n | -N     no deletion of obsolete files or directories\n";
    print "   -l | -L     follow local symbolic links as if they were directories\n";
    print "   -q | -Q     turns quiet operation on\n";
    print "   -b | -B     build DB only - i.e don't upload data to remote host\n";  
    print "   -v | -V     turnes verbose output on\n";
    print "   maxerrors=  if not 0 then program exit with nonzero code.\n";     
    print "   cfg=        read parameters and options from file defined by value.\n";
    print "   ftpserver=  defines the FTP server, defaults to \"localhost\".\n";
    print "   ftpuser=    defines the FTP user, defaults to \"ftp\".\n";
    print "   db=         defines the file where info about uploaded files is stored.\n";  
    print "   ftppasswd=  defines the FTP password, defaults to \"anonymous\".\n";
    print "   ignoremask= defines a regexp to ignore certain files, like .svn"."\n";
    print "\n";
    print " Later mentioned options and parameters overwrite those mentioned earlier.\n";
    print " Command line options and parameters overwrite those in the config file.\n";
    print " Don't use '\"', although mentioned default values might motiviate you to.\n";
    print "\n";
    print " If ftpuser or ftppasswd resovle to ? (no matter through which options),\n";
    print " turbo-ftp-sync.pl asks you for those interactively.\n";
    print "\n";
    print " PROGRAM CAN UPLOAD CHANGES ONLY IN ONE DIRECTION\n";
    print " FROM YOUR MACHINE TO REMOTE MACHINE.\n";
    print " ALSO PROGRAM CANNOT KNOW ABOUT CHANGES WERE MADE ON A REMOTE MACHINE.\n";        
    print "\n";
    print " Demo usage: turbo-ftp-sync.pl db=db.db webroot ftp://yaitskov:secret\@ftp.vosi.biz//\n";        
    print "\n";    
}

sub parseParameters {
    my ( $self, $curopt ) = @_;
    $self->{noofopts}++;
    my ($fname, $fvalue) = split /=/, $curopt, 2;
    if    ($fname eq "cfg")       { return; }
    elsif ($fname eq "ftpdir") {
        $self->{ftpdir}     =$fvalue;
        if ($self->{ftpdir} ne "/") { $self->{ftpdir}=~s/\/$//; }
    }
    elsif ($fname =~ m/ftppass(w(or)?d)?/i) {
        $self->{ftppasswd}=$fvalue;
    }
    elsif ($fname eq "ftpserver") {
        $self->{ftpserver}  =$fvalue;
    }
    elsif ($fname eq "ftpuser")   {
        $self->{ftpuser}    =$fvalue;
    }elsif ( $fname eq "maxerrors" ){
        if ( $fvalue =~ /^[0-9]{1,3}$/ ){
            $self->{maxerrors} = $fvalue;
        }else {
            $self->{returncode} += 1;
            print STDERR "maxerrors must non-negative integer but got: '$fvalue'\n" ;
        }
    }elsif ($fname eq "localdir")  {
        $self->{localdir}   =$fvalue; $self->{localdir}=~s/\/$//;
    }
    elsif ($fname eq "timeout")   { if ($fvalue>0) { $self->{ftptimeout} =$fvalue; } }
    elsif ($fname eq "ignoremask") { $self->{ignoremask} = $fvalue; }
    elsif ($fname eq "db" ){
        $self->{dbpath} = $fvalue;
    }
}
sub parseFtpParameter {
    my ( $self, $curopt ) = @_;
    $self->{noofopts}++;
    $self->{remoteURL} = $curopt;
    $self->parseRemoteURL();
}
sub parseRemoteURL() {
    my ( $self ) = @_;
    if ($self->{remoteURL} =~ /^ftp:\/\/(([^@\/\\\:]+)(:([^@\/\\\:]+))?@)?([a-zA-Z01-9\.\-]+)\/(.*)/) {
        #print "DEBUG: parsing ".$remoteURL."\n";
        #print "match 1 = ".$1."\n";
        #print "match 2 = ".$2."\n";
        #print "match 3 = ".$3."\n";
        #print "match 4 = ".$4."\n";
        #print "match 5 = ".$5."\n";
        #print "match 6 = ".$6."\n";
        #print "match 7 = ".$7."\n";
        if (length($2) > 0) { $self->{ftpuser}   = $2; }
        if (length($4) > 0) { $self->{ftppasswd} = $4; }
        $self->{ftpserver} = $5;
        $self->{ftpdir} = $6;
        if ($self->{ftpdir} ne "/") { $self->{ftpdir}=~s/\/$//; }
    }
}

sub parseOptions {
    my ( $self, $curopt ) = @_;
    my $i;
    for ($i=1; $i < length($curopt); $i++) {
        my $curoptchar = substr ($curopt, $i, 1);
        $self->{noofopts}++;
        if    ($curoptchar =~ /[cC]/)  { $self->{docheckfirst}=1; }
        elsif ($curoptchar =~ /[dD]/)  { $self->{dodebug}=1; $self->{doverbose}=3; $self->{doquiet}=0; }
        elsif ($curoptchar =~ /[fF]/)  { $self->{doflat}=1; }
        elsif ($curoptchar =~ /[hH?]/) { $self->print_syntax(); exit 0; }
        elsif ($curoptchar =~ /[iI]/)  { $self->{doinfoonly}=1; }
        elsif ($curoptchar =~ /[lL]/)  { $self->{followsymlinks}=1; }
        elsif ($curoptchar =~ /[qQ]/)  { $self->{dodebug}=0; $self->{doverbose}=0; $self->{doquiet}=1; }
        elsif ($curoptchar =~ /[vV]/)  { $self->{doverbose}++; }
        elsif ($curoptchar =~ /[nN]/)  { $self->{nodelete}=1; }
        elsif ($curoptchar =~ /[bB]/) { $self->{buildDB} = 1 ; }
        else  { print "ERROR: Unknown option: \"-".$curoptchar."\"\n"; $self->{returncode}+=1; }
    }    
}
sub parseLocalDir {
    my ( $self, $curopt ) = @_;
    if ($self->{localdir} eq "") {
        $self->{noofopts}++;
        $self->{localdir} = $curopt;
    } else {
        print "ERROR: Unknown parameter: \"".$curopt."\"\n"; $self->{returncode}+=1
    }    
}
# function has side effect; return nothing
# it changes variables of current package
sub parseOptionsAndParameters {
    my ( $self, $cfgfoptions, $cloptions ) = @_;
    $self->{noofopts}=0;
    for my $curopt (@$cfgfoptions, @$cloptions) {
        if ($curopt =~ /^-[a-zA-Z]/) {
            $self->parseOptions( $curopt );
        }
        elsif ($curopt =~ /^ftp:\/\/(([^@\/\\\:]+)(:([^@\/\\\:]+))?@)?([a-zA-Z01-9\.\-]+)\/(.*)/) {
            $self->parseFtpParameter ( $curopt );
        }
        elsif ($curopt =~ /^[a-z]+=.+/) {
            $self->parseParameters ( $curopt );
        }
        else {
            $self->parseLocalDir ( $curopt );
        }
    }
    if (0 == $self->{noofopts}) { $self->print_syntax(); exit 0; }    
}
sub parseCfg {
    my ( $self, $argv ) =  @_ ;
    my @cloptions=();
    for my $curopt (@ARGV) {
        if ($curopt =~ /^cfg=/) {
            $self->{configfile}="$'";
            if (! -r $self->{configfile}) {
                print "Config file does not exist: "
                    . $self->{configfile} . "\n";
                $self->{returncode} += 1;
            }
        } else {
            push @cloptions, $curopt;
        }
    }    
    return \@cloptions;
}
sub netRC {
    my ( $self ) = @_;
    if ( ($self->{ftpserver} ne "") and ($self->{ftppasswd} eq "anonymous") ) {
        if ($self->{ftpuser} eq "ftp") {
            my $netrcdata = Net::Netrc->lookup($self->{ftpserver});
            if ( defined $netrcdata ) {
                $self->{ftpuser} = $netrcdata->login;
                $self->{ftppasswd} = $netrcdata->password;
            }
        } else { 
            my $netrcdata = Net::Netrc->lookup($self->{ftpserver},$self->{ftpuser});
            if ( defined $netrcdata ) {
                $self->{ftppasswd} = $netrcdata->password;
            }
        }
    }            
}
sub validateFtp {
    my ( $self ) = @_;
    if ($self->{ftpuser}   eq "?") { print "User: ";     $self->{ftpuser}=<STDIN>;   chomp($self->{ftpuser});   }
    if ($self->{ftppasswd} eq "?") { print "Password: "; $self->{ftppasswd}=<STDIN>; chomp($self->{ftppasswd}); }
    if ($self->{ftpserver} eq "") { print "ERROR: No FTP server given.\n"; $self->{returncode}+=1; }
    if ($self->{ftpdir}    eq "") { print "ERROR: No FTP directory given.\n"; $self->{returncode}+=1; }
    if ($self->{ftpuser}   eq "") { print "ERROR: No FTP user given.\n"; $self->{returncode}+=1; }
    if ($self->{ftppasswd} eq "") { print "ERROR: No FTP password given.\n"; $self->{returncode}+=1; }    
}

sub parseCommandLineParameters {
    my ( $self, $argv ) = @_;
    my $cloptions = $self->parseCfg ( $argv );
    my $cfgfoptions = $self->readConfigFile ();
    $self->parseOptionsAndParameters( $cfgfoptions, $cloptions );
    if ( $self->{dbpath} eq "" ){
        die "Required path to a file with the database (use parameter db=)";
    }
    if ( $self->{dodebug} ) { $self->print_options(); }
    if ( ($self->{localdir}  eq "" ) || (! -d $self->{localdir} ) )  {
        print "ERROR: Local directory does not exist: '$self->{localdir}'\n";
        $self->{returncode}+=1;
    }
    $self->{newDB} = ! -f $self->{dbpath};    
    if ( ! $self->{buildDB} ) {
        $self->netRC();
        $self->validateFtp();
    }
    if ($self->{returncode} > 0) {
        die "Aborting due to missing or wrong options!"
            . "Call turbo-ftp-sync -? for more information.\n";
    }
}

1;
