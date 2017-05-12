package Sman::Man::Convert;
#$Id$

use strict;
use warnings;
use Cwd;
use fields qw( config cache options );
use FreezeThaw qw( freeze thaw );
use Compress::Zlib qw ( compress uncompress );
use Digest::MD5 qw( md5_hex );
use File::Temp;

# call like my $converter = new Sman::Man::Convert($config);
# or my $converter = new Sman::Man::Convert($config, { nocache=>1 } );
sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self  = {};
    bless ($self, $class);
    $self->{config} = shift;     
    $self->{options} = shift || {};  
    my $cachepath = $self->{config}->GetConfigData("CACHEPATH");

    unless($self->{options}->{nocache}) {
        eval {
            require Sman::Man::Cache::FileCache; 
            $self->{cache} = new Sman::Man::Cache::FileCache ( $cachepath );
        };
        if ($@) {
            warn "Couldn't create cachepath $cachepath, continuing: $@";
            delete($self->{cache});
        }
    }
    
    return $self;
}
sub ClearCache {
    my $self = shift;
    my $cache = $self->{cache};
    $cache->Clear();
}

#returns a list of (ParserToUse, ContentRef)
sub ConvertManfile {   
    my ($self, $file) = @_; 
    my $filemtime = (stat($file)) [9];
    my $hascache = defined($self->{cache});
    my $rawdata;
    my $config = $self->{config};
    my $cachename = "[$Sman::Util::SMAN_DATA_VERSION] " . $config->GetConfigData("MANCMD") . " '$file'";
    if ($hascache && defined($rawdata = $self->{cache}->get($cachename))) {
        my ($mtime, $xml) = thaw( $rawdata );
        $rawdata = "";  # return memory
        if ($mtime) {
            if ($filemtime < $mtime) {
                #  cached file is newer than source manfile! fetched from our cache.
                $xml = uncompress($xml);
                print "** Found data in cache for $file\n" if $self->{config}->GetConfigData("VERBOSE");
                return("XML*", \$xml);
            } else {
                warn "** Data too old found in cache for $file" if $self->{config}->GetConfigData("DEBUG");
            }
        } else {
            warn "** Data not found in cache for $file" if $self->{config}->GetConfigData("DEBUG");
        }
    } 

    my $origdir;
    my $hadwarning = 0;
    my ($out, $err) = ("", "");
    if ($file =~ /^(.*\/man\/)/) {
        $origdir = Cwd::getcwd();
        my $dir = $1;
        #warn "** $0: chdir-ing to $dir\n";
        chdir($dir) || ( (warn "** Couldn't cd to $dir!\n") && ($origdir = "") );   
    } else {
        warn "** Couldn't find /man/... dir to cd into for $file" if $config->GetConfigData("VERBOSE");
    }
    ## DOCLIFTER HACKED IN FOR TESTING: 
    #if (-x "/usr/local/bin/doclifter" ) {
    #    my ($stdout, $stderr, $dollarquestionmark) = 
    #        Sman::Util::RunCommand( "/bin/zcat -f '$file' | /usr/local/bin/doclifter" );
    #    $out = $stdout;
    #    if ($stderr) {
    #        warn "Error from doclifter: $stderr\n";
    #    }
    #}
    # DOCLIFTER HACKED IN FOR TESTING: 
    unless($out) {
        my $hashref = $self->ConvertManfileManually($file);
        $out = Sman::Util::MakeXML($hashref); 
    }

    if ($out && $hascache) {    # only store the XML if we got a man page.
        $self->{cache}->set($cachename, freeze( time(), compress($out) ));
        warn "** Cached (mtime=$filemtime, bytes = " . length($out) . ") for $file" 
            if $self->{config}->GetConfigData("DEBUG"); 
    }

    unless ($out) {
        warn "** Couldn't get any data for $file!\n";
        my %hhh = ();
        $out = Sman::Util::MakeXML( \%hhh );
    }
    if ($origdir) { chdir($origdir) || warn "** Couldn't cd back to $origdir: $!"; }
    return ("XML*", \$out);
}


sub ConvertManfileManually {   # do it manually, if we can
   my ($self, $file) = @_;
   my ($manpage, $cur_content) = ('', '');
   my ($cur_section,%h) = qw(NOSECTION);

    my $config = $self->{config};
    my $man = $config->GetConfigData("MANCMD") || die "Couldn't get a man cmd: need MANCMD set.";
    my $col = $config->GetConfigData("COLCMD") || "col -b";
    my $warn = $config->GetConfigData("WARN");
    my $debug = $config->GetConfigData("DEBUG");
    my $autoconfiguring = $config->GetConfigData("AUTOCONFIGURING");    # internal flag

    my $tmpdir = $config->GetConfigData("TMPDIR") || "/tmp";

    my $testfile = $file;

    
    print "** testfile starts out $testfile\n" if $debug;
    $testfile =~ s/\.(gz|bz2)$//;   # remove compression ending 
    print "** testfile is now $testfile\n" if $debug;
    $testfile =~ s/\.((\d|\w)[^.]{0,3})$//; #remove .3-like ending 
    print "** testfile is now $testfile\n" if $debug;

    $testfile =~ m!man/man([^/]+) / (.+)? !x;
        # above works for manpages like /usr/man/man1/ls.1.gz or
        # (italian) /usr/share/man/it/man1/ls.1.gz
        # changed to also work with /usr/X11R6/man/man7/X.Org.7

    my $cmd = $2 || $file;
    my $sec = $1 || $3 || "";
    warn "** Couldn't figure out cmd for $file" if ($warn && $cmd eq $file);
    warn "** Couldn't figure out section for $file" if ($warn && $sec eq "");
    #if ($sec =~ /^n$/i) { $sec = ""; } 
        # section 'n' doesn't work on some versions of osx (pre-10.4) and linux, but tk 
        # installs in places like /sw/share/man/mann/wm.n. So we ignore section 'n'.
        # hm, now, in 10.4, section 'n' works (ala 'man n wm'). Apparently we should 
        # autoprobe the features of the local man command... (sigh... added to TODO list)
    my $mancmd = $man;
    $mancmd =~ s/%F/'$file'/;
    $mancmd =~ s/%C/'$cmd'/;
    $mancmd =~ s/%S/'$sec'/;
    print qq{** Running "$mancmd"...\n} if ($config->GetConfigData("VERBOSE"));
    my $timeout = $config->GetConfigData("CONVERSION_TIMEOUT") || 60;
    my ($out, $err);
    eval {
        local $SIG{ALRM} = sub { die "ALARM\n"; };
        alarm( $timeout );
        ($out, $err) = Sman::Util::RunCommand($mancmd, $tmpdir);
        alarm( 0 );
    };
    if ($@) {
        if ($@ eq "ALARM\n") {
            $err .= "\n(Conversion with $mancmd timed out after $timeout seconds\n";
        } else {
            die "$0: Error converting $file: $@\n";
        }
    } else {
    }
   
   
    if (!$autoconfiguring && $config->GetConfigData("WARN") && $err && (!$out || $warn)) {
        warn "** Errors from '$mancmd'\n";
        my @errlines = split(/\n/, $err);
        for(@errlines) { warn "** MAN: $_\n"; }
    }
    if (!$out) {
        return \%h; # no vals
    } 
    #my $tmpname = "$tmpdir/sman-man-$$.tmp";
    my ($tempfh, $tmpname) = File::Temp::tempfile( "sman-mantxt.XXXXX", DIR => $tmpdir);
    Sman::Util::WriteFile($tmpname, \$out) || 
        die "Couldn't write file $tmpname: $!";
    if ($debug) {
        print "DEBUG: $tmpname is\n" . Sman::Util::ReadFile($tmpname) . "\n"; 
    }
    my $colcmd = "cat $tmpname | $col ";

    my ($out2, $err2) = Sman::Util::RunCommand($colcmd, $tmpdir);
    unlink($tmpname) || warn "Couldn't unlink $tmpname: $!";
    if (!$autoconfiguring && $config->GetConfigData("WARN") && $err2 && (!$out2 || $warn)) {
        warn "** Errors from '$colcmd'\n";
        my @errlines = split(/\n/, $err2);
        for(@errlines) { warn "** COL: $_\n"; }
    }

    my @lines = split(/\n/, $out2);
    my ($line1, $lineM) = (shift(@lines) || "", ""); 

    # parse manpage into sections
    for my $l (@lines) {
        $l =~ s/\s+$//; # remove trailing ws
        $l =~ s/\s+/ /; # replace multiple ws
        $l .= "\n";
        next if (!defined($l) || $l =~ /^\s*$/);    # skip ws
        $line1 = $l if $line1 =~ /^\s*$/;
        $manpage .= $lineM = $l;
        if ($l =~ s/^(\w(\s|\w)+)// || $l =~ s/^\s*(NAME)//i){
            chomp( my $sectitle = $1 );  # section title
            $h{$cur_section} .= $cur_content;
            $cur_content = "";
            $cur_section = $sectitle; # new section name
      }
      $cur_content .= $l unless $l =~ /^\s*$/;
   } 
   $h{$cur_section} .= $cur_content;   

   # examine NAME, HEADer, FOOTer, (and
   # maybe the filename too).

   @h{qw(A_AHEAD A_BFOOT)} = ($line1, $lineM);
   my ($mn, $ms, $md) = ($cmd, $sec, "");
   # NAME mn, SECTION ms, & DESCRIPTION md
    
   for(sort keys(%h)) { # A_AHEAD & A_BFOOT first
      my ($k, $v) = ($_, $h{$_}); # copy key&val
      if (/^A_(AHEAD|BFOOT)$/) { #get sec or cmd 
          # look for the 'section' in ()'s
         if ($v =~ /\(([^)]+)\)\s*$/) {$ms||= $1;}
      } elsif($k =~ s/^\s*(NOSECTION|NAME)\s*//) {
         my $namestr = $v || $k; # 'cmd - a desc'
         if ($namestr =~ /(\S.*)\s+--?\s*(.*)/) {
            $mn ||= $1 || "";
            $md ||= $2 || "";
         } else { # that regex could fail. oh well.
            $md ||= $namestr || $v;
         }  
      }
   }
   if (!$ms && $file =~ m!/man/man([^/]*)/!) {
      $ms = $1; # get sec from path if not found
   }
   ($mn = $file) =~ s!(^.*/)|(\.gz$)!! unless $mn;
    $mn =~ s/\s+/ /g;
    $ms =~ s/\s+/ /g;
    $md =~ s/\s+/ /g;

   my %metas;
   @metas{qw(swishtitle sec desc swishdefault manpage digest)} = 
      ($mn, $ms, $md, $manpage, $manpage, md5_hex($manpage)); 
        #yes, manpage is twice. 
        # Once for swishdefault, and once for the manpage property
        # Q: can one make swishdefault a Property?
   return ( \%metas ); # return ref to hash.
} 

1;

=head1 NAME

Sman::Man::Convert - Convert manpages to XML for sman-update and sman

=head1 SYNOPSIS

  # this module is intended for internal use by sman-update
  my $smanconfig = new Sman::Config();
  $smanconfig->ReadDefaultConfigFile();
  my $converter = new Sman::Man::Convert($smanconfig);
  #$converter->ClearCache();    # if you wish
  my ($type, $outputref) = 
    $converter->ConvertManfile($manfile); 
    
=head1 DESCRIPTION

Use MANCMD and COLCMD (see 'perldoc sman.conf') to convert 
the man pages from ASCII into XML.

=head1 AUTHOR

Josh Rabinowitz <joshr>

=head1 SEE ALSO

L<sman-update>, L<sman>, L<sman.conf>

=cut

