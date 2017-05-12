################################
package Sman::Util;
use Sman;   # for VERSION

use strict;
use warnings;
use Config; # to get perl version string
use File::Temp; # used in RunCommand()
use IPC::Run qw( run timeout );
use version;

our $VERSION = '1.04';
our $SMAN_DATA_VERSION = "1.4";     # this is only relevant to Sman

#  TODO: FIX THIS, to not hard code dirs
use lib '/usr/local/lib/swish-e/perl';  # for source installs, so we can find SWISH::DefaultHighlight.pm
use lib '/usr/libexec/swish-e/perl/';   # for rpm installs, so we can find SWISH::DefaultHighlight.pm
use lib '/sw/lib/swish-e/perl';         # for fink-installed SWISH::DefaultHightlight. TODO: cleanup.

# this checks if the SWISH::API is recent enough to have 
# the features we use. returns 1 if yes, 0 otherwise
sub CheckSwisheVersion {
    #eval { # wrap the version check in an EVAL in case of failure
    #   require SWISH::API;
    #   no strict 'vars';
    #   use vars qw( $SWISH::API::VERSION );
    #   unless ($SWISH::API::VERSION && $SWISH::API::VERSION >= 0.03) {
    #       $@ = "Can't run: need SWISH::API >= 0.03\n"; 
    #       return 0;
    #   }
    #};
    my $class = "SWISH::API";
    eval "require $class";  # if the class exists, this should load it
    
    if ($@) {
        warn "$0: Can't load $class\n";
        return 0;
    }

    no strict 'vars';
    use vars qw( $SWISH::API::VERSION );
    unless ($SWISH::API::VERSION && version->new($SWISH::API::VERSION) >= 0.03) {
        # PAUSE namespace indexer complains about the line above:
            # " The PAUSE indexer was not able to parse the following line
            # in that file: C< unless ($SWISH::API::VERSION &&
            # $SWISH::API::VERSION >= 0.03) { > Note: the indexer is
            # running in a Safe compartement and cannot provide the full
            # functionality of perl in the VERSION line. It is trying
            # hard, but sometime it fails. As a workaround, please
            # consider writing a proper META.yml that contains a
            # 'provides' attribute (currently only supported by
            # Module::Build) or contact the CPAN admins to investigate
            # (yet another) workaround against "Safe" limitations.) "

        # I don't understand why the namespace indexer needs to parse (run) this function

        warn "$0: Can't run: need SWISH::API >= 0.03\n";
        $@ = "Can't run: need SWISH::API >= 0.03\n";    # SET $@ for caller, if they check
        return 0;
    }
    return 1;  # it's OK
}

sub MakeXML { # output xml version of hash
   my $metas = shift;
   my $xml = join ("", 
   map { "<$_>\n" . XMLEscape($metas->{$_}) . "\n</$_>\n" }
   keys %$metas); 
   my $pre = qq{<?xml version="1.0" standalone="yes"?>\n\n};
   return qq{$pre<all>\n$xml\n</all>\n};
}

sub XMLEscape { 
   return "" unless defined($_[0]); 
    my $v = shift;
    $v =~ s/&/&amp;/g;
    $v =~ s/</&lt;/g;
    $v =~ s/>/&gt;/g;
   return $v;
} 

# like File::Slurp::read_file()
sub ReadFile { 
    my $file = shift; 
    local( $/, *FFF );  # $/ is set to undef
    open(FFF, "<", $file) || warn "Couldn't open $file: $!" && return ""; 
    my $content = <FFF>;    # file slurped at once
    close(FFF) || warn "Error closing $file: $!";
    return $content;
} 
# like File::Slurp::write_file()
sub WriteFile {
    my ($file, $contentref) = @_;
    open(my $fh, ">", "$file") || warn "Couldn't open $file: $!" && return 0;
    print $fh $$contentref;
    close($fh) || warn "Error closing $file: $!";
    return $contentref; 
}


# given a command and optional tmpdir, returns (stdout, stderr, $?) 
# uses IPC::Run::run() underneath
sub RunCommandNew {
    my ($cmd_ref, $tmpdir, $should_be_undef) = @_;
    my @cmd = @$cmd_ref;

    die "$0: Internal Error: Sman::Util::RunCommand called with three arguments\n" 
        if $should_be_undef;
    $tmpdir = "/tmp" unless defined $tmpdir;

    #my @cmd = ($cmd);
    my ($in, $out, $err) = ("", "", "");
    run( \@cmd, \$in, \$out, \$err , timeout( 30 ) );
    return ( $out, $err, $? );
}

# RunCommand's block, to encapsulate @tmpfiles.
{
    my @tmpfiles = ();
    # given a command and optional tmpdir, returns (stdout, stderr, $?) 
    # uses the shell underneath
    sub RunCommand {
        my ($cmd, $tmpdir, $should_be_undef) = @_;
        die "$0: Internal Error: Sman::Util::RunCommand called with three arguments\n" 
            if $should_be_undef;
        $tmpdir = "/tmp" unless defined $tmpdir;
        my ($out, $err) = ("", "");
        my $r = sprintf("%04d", rand(9999));
        my ($ofh, $outfile) = File::Temp::tempfile( "cmd-out.XXXXX", DIR => $tmpdir);
        my ($efh, $errfile) = File::Temp::tempfile( "cmd-err.XXXXX", DIR => $tmpdir);
        # use two temporary filenames 
        my $torun = "$cmd 1>$outfile 2>$errfile";
        push(@tmpfiles, $outfile, $errfile);    # in case of SIG
        #print "RUNNING $torun\n";
        system($torun);
        if ($?) {
            my $exit  = $? >> 8;
            my $signal = $? & 127;
            my $dumped = $? & 128;

            $err .= "** ERROR: $torun\n";
            $err .= "exitvalue $exit";
            $err .= ", got signal $signal" if $signal;
            $err .= ", dumped core" if $dumped;
            $err .= "\n";
        }
        my $dollarquestionmark = $?;
            
        $out .= ReadFile($outfile);
        $err .= ReadFile($errfile);

        unlink($errfile) || warn "$0: couldn't unlink $errfile: $!";
        pop(@tmpfiles);
        unlink($outfile) || warn "$0: couldn't unlink $outfile: $!";
        pop(@tmpfiles);

        return ($out, $err, $dollarquestionmark);
    }
    END {   # hopefully this will get triggered 
            # if RunCommand throws an exception
        for my $tmpfile (@tmpfiles) {
            unlink($tmpfile) || warn "** Couldn't unlink tmp file $tmpfile"; 
        }
    }
}

sub GetIndexDescriptionString {
    my ($index) = @_;
    my $indexmodtime = (stat( "$index.prop" ))[9];
    return sprintf("Using index %s, %s\n", 
        $index, $indexmodtime ? "updated " . scalar(localtime( $indexmodtime ) ) : "(index not found)" );
}

sub GetVersionString {
    my ($prog, $swishecmd) = @_;
    require SWISH::API; # for $VERSION
    require Sman;       # for $VERSION
    my $str = "$prog $Sman::Util::VERSION, using SWISH::API $SWISH::API::VERSION";
    if ($swishecmd) {
        my $cmd = $swishecmd . " -V";
        my @lines = `$cmd`;
        if (defined($lines[0])) {
            chomp($lines[0]);
            ($lines[0] =~ / ([\d.]+)/) && ($lines[0] = "Swish-e $1");
            $str .= ", $lines[0]";
        }
    }
    $str .=   ", and perl $Config{version}";
    return $str;
}


sub ExtractSummary {
    require SWISH::DefaultHighlight;    # defer till now, so sman -V doesn't need SWISH::API
    my %header = (
        wordcharacters => q{0123456789abcdefghijklmnopqrstuvwxyz});
                #q{ªµºÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖØÙÚÛÜÝÞß} . 
                #q{àáâãäåæçèéêëìíîïðñòóôõöøùúûüýþÿ});
    my %highlight  = (
        show_words      => 4,    # Number of "swish words" words to show around highlighted word
        max_words       => 10,   # If no words are found to highlighted then show this many words
        occurrences     => 4,     # Limit number of occurrences of highlighted words
        highlight_on   => '*', # highlighting code
        highlight_off  => '*',
    );

    my ($str, $termsref, $prefix, $width) = @_; 
    my $sho = new SWISH::DefaultHighlight( \%highlight, \%header );
    #my $sho = new SWISH::SimpleHighlight( \%highlight, \%header );
    my @phrases;
    for my $t (@$termsref) {
        my @list = ($t);
        push(@phrases, \@list);
    } 
    $sho->highlight(\$str, \@phrases, 'swishdescription');
    $str =~ s/&quot;/'/g;
    $str =~ s/&gt;/>/g;
    $str =~ s/&lt;/</g;
    $str =~ s/^\s+//;
    $str =~ s/\s+$//;
    $str = $prefix . $str;
    $str = substr($str, 0, $width-3) . "..." if length($str) > $width;
    return $str; 
}


1;

=pod

=encoding utf-8

=head1 NAME

Sman::Util - Utility functions for Sman

=head1 SYNOPSIS 

Sman::Util currently provides the following functions:

  # XMLEscape escapes XML
  my $str = Sman::Util::XMLEscape("a-fun#y&%$TRiñg");
  
  # MakeXML makes XML from a simple hash of names->strings
  my $xml = Sman::Util::MakeXML(\%somehash);    
  
  # ReadFile reads the contents of a file and returns it as a scalar
  my $content = Sman::Util::ReadFile("filename"); 
  
  # RunCommand uses the shell to capture stdout and stderr and $?
  # Pass command and tempdir to save its temp files in. 
  # tmpdir defaults to '/tmp'
  my ($out, $err, $dollarquestionmark) = Sman::Util::RunCommand("ls -l", "/tmp"); 

  # GetVersionString gives you a version string like 
  # 'sman v0.8.3 using SWISH::API v0.01 and Swish-e v2.4.0'
  # pass program name and the Swish-e command path
  my $vstr = Sman::Util::GetVersionString('prog', '/usr/local/bin/swish-e');
    
=head1 DESCRIPTION

This module implements utility functions for sman-update and sman

=head1 AUTHOR

Copyright Josh Rabinowitz 2004-2016 <joshr>

=head1 SEE ALSO

L<sman-update>, L<sman>

=cut

