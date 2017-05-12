package Remote::Use;
use strict;
use warnings;

use File::Path;
use File::Spec;
use File::Basename;

use Scalar::Util qw{reftype};

our $VERSION = '0.04';

# Receives s.t. like 'Remote/Use.pm' and returns 'Remote::Use'
sub filename2modname {
  my $config = shift;

  my $confid = $config;
  $confid =~ s{/}{::}g;
  $confid =~ s{\.pm$}{};
  return $confid;
}

# Evaluates the ppmdf file as perl code.
# The resulting hash is set as the attribute 'cache'
# of the Remote::Use object
sub setinstallation {
  my $self = shift;
  
  $self->{cache} = {};
  if (-e $self->{ppmdf}) {
    if (open(my $f, $self->{ppmdf})) {
      local $/ = undef;
      my $s = <$f>;
      my @s = eval $s;
      die "Error evaluating cache file: $@" if $@;
      $self->{cache} = { @s };
    }
  }
}

sub import {
  my $module = shift;
  my %arg = @_;

  my $config = $arg{config};

  # Set the code handler in @INC so that we can later manage "use Module"
  # via Remote::Use::INC

  my $self = $module->new();
  push @INC, $self;

  # If the 'config' option is used we take the 
  # arguments from the configuration package
  if (defined($config) && -r $config) {
    eval {
      require $config;
    };
    die "Error in $config: $@" if $@;

    my $confid = $arg{package};
    
    $confid = filename2modname($config) unless defined($confid);

    # The $confid package must have defined 
    # the 'getarg' method
    
    $self->{confid} = $confid;
    %arg = $confid->getarg($self);
  }

  # host is the machine where to look for
  my $host = $arg{host};
  die "Provide a host" unless defined $host;
  delete $arg{host};
  $self->{host} = $host;

  # The 'prefix' attribute is the path where files and libraries
  # will be installed. If not provided it will be set to s.t. like
  # /home/myname/perl5lib

  my $perl5lib = "$ENV{HOME}/perl5lib" if $ENV{HOME};
  $perl5lib    = "$ENV{USERPROFILE}/perl5lib" if !$perl5lib && $ENV{USERPROFILE};

  my $prefix = $self->{prefix} = ($arg{prefix} || $perl5lib || File::Spec->tmpdir);
  die "Provide a prefix directory" unless defined $prefix;
  delete $arg{prefix};

  # Create the directory if it does not exists
  mkpath($prefix) unless -d $prefix;
  unshift @INC, "$prefix/files";

  my $ppmdf = $arg{ppmdf};
  die "Provide a .installed.modules filename (ppmdf argument)" unless defined $ppmdf;
  delete $arg{ppmdf};
  $self->{ppmdf} = $ppmdf;

  # Opens and evaluates the ppmdf file. It sets the attribute 'cache'
  $self->setinstallation;

  # What application shall we use: rsync? wget? ...
  my $command = $arg{command};
  die "Provide a command" unless defined $command;
  $self->{command} = $command;
  delete $arg{command};

  $self->{$_} = $arg{$_} for keys(%arg); 
}

sub Remote::Use::INC {
  my ($self, $filename) = @_;

  if ($filename =~ m{^[\w/\\]+\.pm$}) {
    my $prefix = $self->{prefix}; # prefix path where the file will be stored ('/tmp/perl5lib')
    my $host = $self->{host};     # the 'host part' defining where the server is ('orion:')

    my $command = $self->{command}; # rsync, scp, wget, etc. Options included

    # options required by $command that go after the $host$sourcefile part
    my $commandoptions = $self->{commandoptions} || ''; 

    # an entry for some $filename is like:
    # 'IO/Tty.pm' => { dir => '/usr/local/lib/perl/5.8.8', files => [
    #                '/usr/local/lib/perl/5.8.8/auto/IO/Tty/Tty.so',
    #                '/usr/local/lib/perl/5.8.8/auto/IO/Tty/Tty.bs',
    #                         '/usr/local/lib/perl/5.8.8/IO/Tty.pm' ] },
    my %files;
    my $entry = $self->{cache}{$filename};
    %files = %{$entry} if $entry && (reftype($entry) eq 'HASH');

    # No files, nothing to download
    return unless %files;

    my $remoteprefix = quotemeta($files{dir});
    delete $files{dir};

    my $f = $files{files};
    delete $files{files};

    my $conf = $self->{confid}; # configuration package name

    my @files;
    @files= @$f if $f && (reftype($f) eq 'ARRAY');
    for (@files) {
       my $url = "$host$_"; # s.t. like 'orion:/usr/local/lib/perl/5.8.8/auto/IO/Tty/Tty.so'
       my $file = $_;       # s.t. like '/usr/local/lib/perl/5.8.8/auto/IO/Tty/Tty.so'
       $file =~ s{^$remoteprefix}{$prefix/files/}; # s.t. like '/tmp/perl5lib/files/auto/IO/Tty/Tty.so'

       # If the configuration package defines a 'prefiles' method, use it to obtain
       # the final name of the file:
       $file = $conf->prefiles($url, $file, $self) if $conf && ($conf->can('prefiles'));

       my $path =  dirname($file);    # s.t. like ''/tmp/perl5lib/files/auto/IO/Tty/'
       mkpath($path) unless -d $path;

       # grab the $url and store it in $file
       system("$command $url $commandoptions $file");

       # If the configuration package defines a 'postfiles' method, use it 
       # to do any required modifications to the file (changing its mod access for example)
       $conf->postfiles($file, $self) if ($conf && $conf->can('postfiles'));
    }

    # Find if there are alternative families of files (bin, man, etc.)
    my @families = keys %files;
    for (@families) {
      my $f = $files{$_}; # [ '/usr/local/bin/eyapp', '/usr/local/bin/treereg' ]
      my @files;          # ( '/usr/local/bin/eyapp', '/usr/local/bin/treereg' )
      @files = @$f if $f && (reftype($f) eq 'ARRAY');

      for my $b (@files) {
         my $url = "$host$b"; # 'orion:/usr/local/bin/eyapp'
         my $file = $b;                 # name in the client:
         $file =~ s{^.*/}{$prefix/$_/}; #   /tmp/perl5lib/bin/eyapp

         my $pre = "pre$_";
         $file = $conf->$pre($url, $file, $self) if ($conf && $conf->can($pre));

         my $path =  dirname($file);
         mkpath($path) unless -d $path;

         system("$command $url $commandoptions $file");

         my $post = "post$_";
         $conf->$post($file, $self) if ($conf && $conf->can($post));
      }
    }

     open my $fh, '<', "$prefix/files/$filename";
     return $fh;
  }

  return undef;
}

sub new {
  my $this = shift;
  my $class = ref($this) || $this;

  return bless { @_ }, $class;
}

1;
__END__
