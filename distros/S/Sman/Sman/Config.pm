package Sman::Config; 

#$Id$

use 5.006;
use strict;
use warnings;
use FindBin qw($Bin);
use POSIX qw(sysconf _PC_CHOWN_RESTRICTED);     # for _isverysafe
use Cwd;                                        # for _isverysafe
use File::stat; # used in _issafe()
use fields qw( conf );

# call like my $smanconfig = new Sman::Config();
sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self  = {};
    bless ($self, $class);
    $self->{conf} = []; # empty list
    my $configfile = shift;
    if (defined($configfile)) {
        $self->ReadSingleConfigFile($configfile);
    } 
    return $self;
}

# Gets a config var. Because we're case INsensitive.
# returns "" if no data found.
sub GetConfigData { 
    my ($self, $directive) = @_; 
    #print "Looking for $directive...\n";
    for(@ {$self->{conf}} ) {
        return $_->[1] if (uc($_->[0]) eq uc($directive) && defined($_->[1]));
    }
    return "";
}

# Sets a config var. Because we're case INsensitive.
# if an existing value is set for a name, it's replaced, WHERE IT WAS.
# returns the data.
sub SetConfigData {
    my ($self, $directive, $data) = @_;
    #print "Setting '$directive' to '$data'\n";
    for (my $i=0; $i < scalar(@ {$self->{conf}}); $i++ ) {
        if (uc($self->{conf}->[$i]->[0]) eq uc($directive)) { 
            warn "Clobbering previous setting for '$directive'\n" 
                if defined($self->{verbose});   # there is no self->{verbose}. Why no error?
            $self->{conf}->[$i]->[1] = $data;
            return $data;
        }
    }
    my @line = ($directive, $data); # stored as originally input
    push(@ {$self->{conf}}, \@line);    # push the listref on the list
    return $data;
}

# this returns only the first one found in the path
#  $Bin/sman.conf, ~/.sman.conf, /usr/local/etc/sman.conf, /etc/sman.conf
sub FindDefaultConfigFile {
    my $self = shift;
    my (@dirs) = $self->_getconfigdirs();
    for(@dirs) {
        if (-e "$_/sman-defaults.conf") {
             if($self->_isverysafe("$_/sman-defaults.conf") ) {
                return "$_/sman-defaults.conf"; 
            } else {
                warn "$0: Can't use $_/sman-defaults.conf: ownership not safe.\n";
            }
        }
    }
    return "";
}

# finds and returns the config file(s). Looks for sman.conf(s) in:
#  $Bin/sman.conf, ~/.sman.conf, /usr/local/etc/sman.conf, /etc/sman.conf 
#  (in that order)
sub FindConfigFiles {
    my $self = shift;
    my (@dirs, @configs) = $self->_getconfigdirs();
    for(@dirs) {
        my $f = "$_/sman.conf";
        if (-e $f && $self->_isverysafe($f) ) {
            push(@configs, $f);
        }
    }
    my $defaultconfig = $self->FindDefaultConfigFile();
    push(@configs, $defaultconfig) if ($defaultconfig);
    return @configs;
}

# we pass verbose here because it could be that the user's verbose setting is overridden from above
# returns the name of the file read, or "" if none found.
sub ReadDefaultConfigFile {
    my ($self, $verbose) = @_; 
    my @configfiles = $self->FindConfigFiles();     # this includes the default one.
    
    # read the first config file.
    for (@configfiles) {
        print "Reading config file $_\n" if $verbose;
        $self->ReadSingleConfigFile($_);
        last;
    } 
    #print "Used config file '$configfiles[0]', found '" . join(", ", @configfiles) . "'.\n" 
    #   if ($verbose || $self->GetConfigData("VERBOSE")); 
    if (scalar(@configfiles)) {
        return $configfiles[0];
    } else {
        return "";
    }
}

# adds data from the file into our configuration data
# returns the filename read, or "" on error 
sub ReadSingleConfigFile {
    my ($self, $file) = @_;
    my $prevline;
    if (!open(FILE, "< $file")) {
        die "Couldn't open $file: $!";
    } else {
        while(defined(my $line = <FILE>)) { 
            chomp($line);
            if (defined($prevline)) {
                $line = "$prevline $line";
                undef $prevline;
            } 
            if ($line =~ s/\\$//) { # if the last char is \, remove it, and
                $prevline = $line;  # record it 
            } else {                        # else parse it
                next if $line =~ /^\s*$/;   # empty line
                next if $line =~ /^\s*#/;   # a comment
                $line =~ s/^\s+//;          # strip leading ws
                my ($directive, $value) = split(/\s+/, $line, 2);
                if (defined($directive) && $directive && defined($value)) {
                    $self->SetConfigData($directive, $value); # will clobber old setting
                }
            }
        } 
        close(FILE) || die "Couldn't close $file: $!"; 
    }
    return $file;
}

sub Reset {
    my $self = shift;
    $self->{conf} = {}; # reset the puppy
}

# returns a list of params from the config
sub GetConfigNames { 
    my $self = shift;
    my @names = ();
    for( @ {$self->{conf}} ) {
        if (defined($_->[0]) && defined($_->[1])) {
            push(@names, $_->[0]);
        }
    }
    return @names;
}

sub Dump {
    my $self = shift;
    my $str = "# Sman::Config settings:\n";
    for (@ { $self->{conf} } ) {
        $str .= " $_->[0] $_->[1]\n";
    }
    return $str;
}

sub SetEnvironmentVariablesFromConfig 
{   
    my $self = shift;
    my $verbose = $self->GetConfigData("VERBOSE");
    my @envs = grep { /^ENV_/ } $self->GetConfigNames();
    for my $e (@envs) {
        (my $copy = $e ) =~ s/^ENV_//;
        $ENV{uc($copy)} = $self->GetConfigData($e);
        print "Set ENV{$copy} to " . $self->GetConfigData($e) . "\n"
            if ($verbose);
    }
    return @envs;
}

sub _getconfigdirs {
    my (@dirs, @configs) = ( $Bin );    # From FindBin
    if (defined($ENV{HOME})) { push(@dirs, $ENV{HOME}); }
    push(@dirs, qw(/etc/ /usr/local/etc/));
    return @dirs;
}

#from perl cookbook "8.17. Testing a File for Trustworthiness"
sub _issafe {
    my ($self, $path) = @_;
    my $info = stat($path);
    return 0 unless $info;

    # owner neither superuser nor me 
    # the real uid is in stored in the $< variable
    if (($info->uid != 0) && ($info->uid != $<)) {
        return 0;
    }

    # check whether group or other can write file.
    # use 066 to detect either reading or writing
    if ($info->mode & 022) {   # someone else can write this
        return 0 unless -d _;  # non-directories aren't safe
            # but directories with the sticky bit (01000) are
        return 0 unless $info->mode & 01000;        
    }
    return 1;
}

#from perl cookbook "8.17. Testing a File for Trustworthiness"
sub _isverysafe {
    my ($self, $path) = @_;
    return $self->_issafe($path) if sysconf(_PC_CHOWN_RESTRICTED);
    $path = getcwd() . '/' . $path if $path !~ m{^/};
    do {
        return unless $self->_issafe($path);
        $path =~ s#([^/]+|/)$##;               # dirname
        $path =~ s#/$## if length($path) > 1;  # last slash
    } while length $path;

    return 1;
}







1;
__END__ 

=head1 NAME

Sman::Config - Find and read config files for the Sman tool

=head1 SYNOPSIS 

  # this module is intended for internal use by sman and sman-update
  my $smanconfig = new Sman::Config();
  my @conffiles = $smanconfig->FindConfigFiles();
  # or
  my $fileread = $smanconfig->ReadDefaultConfigFile();
  
  my $indexfile = $smanconfig->GetConfigData("SWISHE_IndexFile");
    
=head1 DESCRIPTION

Find and read Sman configuration files.  

The 'default config file' is the first file called 'sman.conf' in the 
directory with the invoking perl script, $ENV{HOME}, /usr/local/etc, or 
/etc. If no file name sman.conf is is found in any of those directories, the first
file called 'sman-defaults.conf' in the same list of directories is used.  

=head1 AUTHOR

Josh Rabinowitz <joshr>

=head1 SEE ALSO

L<sman.conf>, L<sman-update>, L<sman>

=cut
