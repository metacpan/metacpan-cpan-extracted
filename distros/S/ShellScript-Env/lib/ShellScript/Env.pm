package ShellScript::Env;

use strict;

use File::Find;

sub new {
  my $this = shift;
  my $class = ref($this) || $this;
  my $self = {};
  bless $self, $class;

  $self->{'prefix'} = shift;
  if (!defined $self->{'prefix'}) {
    warn ref($self) . ' constructed with no argument, using `.\' as prefix';
    $self->{'prefix'} = '.';
  }

  %{$self->{'dir_search'}} = 
      (
       'LD_LIBRARY_PATH' => ['lib'],
       'PATH' => ['bin'],
       'MANPATH' => ['man'],
       'INFOPATH' => ['info'],
       );

  push @{$self->{'skip_dirs'}}, 'src';

  return $self;
}


#######################
# Functions to be considered public

# Functions that searches the prefix directory for common path names.
sub automatic {
    my $self = shift;

    foreach my $env (keys %{$self->{'dir_search'}}) {
	my @found = $self->dir_find(@{$self->{'dir_search'}->{$env}});
	if (scalar(@found) > 0) {
	    $self->set_path($env, @found, "\$$env");
	}
    }
    return $self;
}


# Just sets a list, no processing or notten.
sub set {
  my $self = shift;
  my $env = shift;

  @{$self->{'env'}->{$env}} = @_;
  $self->{'utok'}->{$env} = 0;
  push @{$self->{'order'}}, $env;
  
  return $self;
}

# Make a list and check it twice.  Well, appends $self->{'prefix'} if
# needed and check if you want utok.
sub set_path {
  my $self = shift;
  my $env = shift;
  my @dirs = @_;

  for (@dirs) {
      my $prefix = quotemeta($self->{'prefix'});
      if (($_ !~ m/^$prefix/) && ($_ =~ m:^[^\$\/]:)) {
	s:^:$self->{'prefix'}/:;
      }
  }
  $self->set($env, @dirs);
  $self->{'utok'}->{$env} = ($ShellScript::Env::utok || 0);

  return $self;
}

# deletes a variable.
sub unset {
  my $self = shift;
  my $env = shift;

  # Remove one element from a list.  Isn't there a cool way to do this
  # with map?
  my @rebuild;
  for (@{$self->{'order'}}) {
    if ($_ ne $env) {
      push @rebuild, $_;
    }
  }
  @{$self->{'order'}} = @rebuild;

  delete $self->{'env'}->{$env};
  delete $self->{'utok'}->{$env};

  return $self;
}

# Returns 0 if there are no errors.
sub save {
  my $self = shift;

  my $error = 0;

  my $csh_file = "$self->{prefix}.csh";
  if (open(CSH, ">$csh_file")) {
    print "Writing $csh_file\n";
    print CSH $self->csh();
    close(CSH);
  } else {
    ++$error;
    warn "Can't write $csh_file: $!";
  }

  my $sh_file = "$self->{prefix}sh";
  if (open(SH, ">$sh_file")) {
    print "Writing $sh_file.\n";
    print SH $self->sh();
    close(SH);
  } else {
    ++$error;
    warn "Can't write $sh_file: $!";
  }

  return $error;
}
  


##################
# functions to generate shell scripts, these are considered public
# too.  Are there other common shells that arn't compatible with C or
# Bourne Shell?

# output Bourne Shell.
sub sh {
  my $self = shift;

  my $output = '';
  my $export = 'export ';

  for (@{$self->{'order'}}) {
    $export .= "$_ ";

    if ($self->{'utok'}->{$_}) {
      $output .= "$_=`utok ";
    } else {
      $output .= "$_=";
    }


    for (@{$self->{'env'}->{$_}}) {
      $output .= "$_:";
    }
    
    if ($self->{'utok'}->{$_}) {
      $output =~ s/:$/\`\n/;
    } else {
      $output =~ s/:$/\n/;
    }

  }

  if ($export ne 'export ') {
      $output .= $export;
  }
  $output =~ s/\ $/\n/;

  return $output;
}

# output C Shell.
sub csh {
  my $self = shift;

  my $output = '';
  for (@{$self->{'order'}}) {

    my $delimiter = ':';
    # I hate how C Shell set every variable one way, and PATH another.
    # It bugs me to no end.
    if ($_ eq 'PATH') {
      $delimiter = ' ';
      $output .= "set path = (";
    } else {
      $output .= "setenv $_ ";
    }

    if ($self->{'utok'}->{$_}) {
      if ($delimiter ne ':') {
	$output .= "`utok -s '$delimiter' ";
      } else {
	$output .= '`utok ';
      }
    }

    my $item;
    foreach $item (@{$self->{'env'}->{$_}}) {
      if (($_ eq 'PATH') && ($item eq '$PATH')) {
	$output .= "\$path$delimiter";
      } else {
	$output .= "$item$delimiter";
      }
    }

    $delimiter = quotemeta($delimiter);
    if ($self->{'utok'}->{$_}) {
      $output =~ s/$delimiter$/\`\n/;
    } else {
      $output =~ s/$delimiter$/\n/;
    }

    if ($_ eq 'PATH') {
      $output =~ s/\n$/\)\n/;
    }
  }

  return $output;
}


#####################
# Private functions.

# I really wish File::Find's find returned an array.  I also wish it
# worked while tainted.  oh well.
sub dir_find {
  my $self = shift;

  @ShellScript::Env::find = @_;
  undef @ShellScript::Env::found;
  @ShellScript::Env::skip = @{$self->{'skip_dirs'}};

  my @output;
  if (-l $self->{'prefix'}) {


    my $newdir = $self->{'prefix'};
    $newdir =~ s<[^/]*$><>;
    chdir($newdir);

    my $prefix = readlink($self->{'prefix'});
    find(\&wanted, $prefix);
    $prefix = quotemeta($prefix);
    @output = map(s/^$prefix/$self->{'prefix'}/g && $_,
		  @ShellScript::Env::found);

  } else {
    find(\&wanted, $self->{'prefix'});
    @output = @ShellScript::Env::found;
  }

  undef @ShellScript::Env::skip;
  undef @ShellScript::Env::found;
  undef $ShellScript::Env::find;

  return sort @output;
}

# Only used for call to find.
sub wanted {
  foreach my $find (@ShellScript::Env::find) {
    $find = quotemeta($find);
    if (m/^$find$/ && -d $_) {
      for (@ShellScript::Env::skip) {
	my $skip = quotemeta($_);
	if ($File::Find::name =~ m</$skip/>) {
	  return 0;
	}
      }
      push @ShellScript::Env::found, $File::Find::name;
      return 1;
    }
  }
  return 0;
}



###################
# bye, bye.
return 1;

