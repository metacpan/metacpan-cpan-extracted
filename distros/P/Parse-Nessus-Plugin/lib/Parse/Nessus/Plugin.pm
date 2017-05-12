#
# OO methods to parse Nessus plugins
#
# Author: Roberto Alamos Moreno <ralamosm@cpan.org>
#
# Copyright (c) 2005 Roberto Alamos Moreno. All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
# June 2005. Antofagasta, Chile.
#
package Parse::Nessus::Plugin;

require 5.004;

$VERSION = '0.4';

use strict;
use warnings;

=head1 NAME

Parse::Nessus::Plugin - OO methods to parse Nessus plugins

=head1 SYNOPSIS

  use Parse::Nessus::Plugin;

  $plugin = Parse::Nessus::Plugin->new || undef;
  if(!$plugin) {
    die("It wasn't posible to initialize parser");
  }

  $plugin->parse_file($nasl_file);     # Parse from a filename
  $plugin->parse_string($nasl_string); # Parse from a string

  $plugin->description; # Get description
  $plugin->solution;    # Get solution


=head1 DESCRIPTION

Parse::Nessus::Plugin provides OO methods that easily parse Nessus plugins written in NASL. With this
module you can get the script id, solution, description, risk factor and many other information in your
NASL plugin with a simple call to an OO method.

=cut

=head1 METHODS

=over 4

=item Method B<new>

Usage : 

  my $plugin = Parse::Nessus::Plugin->new;

This method returns an instance of the Parse::Nessus::Plugin class.

=cut
sub new {
  my $class = shift || undef;
  if(!defined $class) {
    return undef;
  }

  my $objref = { RAWERROR => '',
		 ERROR => '',
		 NASL => 1, # By now we only allow .nasl files
		 FILE => '',
		 FILENAME => '',
		 PLUGIN_ID => '',
	       };
  bless $objref, $class;

  return $objref;
}

=item Method B<parse_file>

Usage :

  $plugin->parse_file($nasl_filename);

This method tells Parse::Nessus::Plugin to be ready to parse $nasl_filename, where $nasl_filename is the path to the
.nasl plugin (for example /usr/nessus/cifs445.nasl). If this method returns true, then you can continue with the parsing,
otherwise, the argument given wasn't a valid .nasl plugin.

=cut
sub parse_file {
  my $self = shift || undef;
  if(!$self) {
    return undef;
  }

  $self->clean;
  $self->cleanfilename;

  my $namefile = shift || undef;
  if(!$namefile) {
    $self->error('NO_FILE');
    return undef;
  }

  $self->filename($namefile);

  my $file = '';
  # Open file
  if(open(FILE,$namefile)) {
    while(my $line = <FILE>) {
      $file .= $line;
    }
    close(FILE);
  } else {
    $self->error('NO_FILE');
    return undef;
  }

  if($file eq '') {
    $self->error('NO_FILE');
    return undef;
  }

  return $self->parse_string($file);
}

=item Method B<parse_string>

Usage :

  $plugin->parse_string($nasl_string);

This method tells Parse::Nessus::Plugin to be ready to parse $nasl_string, where $nasl_string is a SCALAR variable
that contains the code of a Nessus plugin written in NASL. If this method returns true, then you can continue with the parsing,
otherwise, the string given as argument isn't a valid .nasl plugin.

=cut
sub parse_string {
  my $self = shift || undef;
  if(!$self) {
    return undef;
  }

  $self->clean;

  my $string = shift || undef;
  if(!$string || $string eq '') {
    return undef;
  }

  # We'll to determine if we have a .nasl or .c plugin
  # Check if we have a script id
  if($string =~ /script\_id\(([^\)]*)\);/) {
    my $id = $1;
    $id =~ s/\D//go;
    if(!$id || $id eq '') {
      $self->error('NO_NESSUS_PLUGIN');
      return undef;
    }
    $self->id($id);
    $self->is_nasl(1);
  } elsif($string =~ /plug\_set\_id\(([^\,]*),([^\)]*)\)/) {
    my $id = $2;
    $id =~ s/\D//go;
    if(!$id || $id eq '') {
      $self->error('NO_NESSUS_PLUGIN');
      return undef;
    }
    $self->id($id);
    $self->is_nasl(0);
  } else {
    $self->error('NO_NESSUS_PLUGIN');
    return undef;
  }
  
  $self->{FILE} = $string;

  return 1;
}

=item Method B<id>

Usage :

  my $id = $plugin->id;

This method returns the plugin id of the last plugin processed with parse_file or parse_string, as SCALAR variable.

=cut
sub id {
  my $self = shift || undef;
  if(!$self) {
    return undef;
  }

  $self->cleanerror;

  if(@_) {
    $self->{PLUGIN_ID} = shift @_;
  } else {
    if(exists $self->{PLUGIN_ID} && $self->{PLUGIN_ID} ne '') {
      return $self->{PLUGIN_ID};
    } else {
      return undef;
    }
  }
}

=item Method B<filename>

Usage :

  my $filename = $plugin->filename;

This method returns the name of the plugin's file (only if you used B<parse_file> method).

=cut
sub filename {
  my $self = shift || undef;
  if(!$self) {
    return undef;
  }

  $self->cleanerror;

  if(@_) {
    my $filename = shift @_;
    $filename =~ /([^\/]*)$/;
    $self->{FILENAME} = $1;
  } else {
    if(exists $self->{FILENAME} && $self->{FILENAME} ne '') {
      return $self->{FILENAME};
    } else {
      return undef;
    }
  }
}

=item Method B<cve>

Usage :

  my @cve = $plugin->cve;

This method returns the list of CVE names associated with the current plugin.

=cut
sub cve {
  my $self = shift || undef;
  if(!$self) {
    return undef;
  }

  $self->cleanerror;

  my $file = $self->{FILE} || undef;
  if(!$file || $file eq '') {
    $self->error('NO_FILE');
    return undef;
  }

  if($file =~ /script\_cve\_id\(\"([^\)]*)\"\)/o) {
    my $cve = $1;
    $cve =~ s/\"//g;$cve =~ s/\s//g;
    if(my $cve || $cve eq '') {
      $self->error('NO_CVE');
      return undef;
    }
    my @cve = split(/,/,$cve);
    return \@cve;
  } else {
    $self->error('NO_CVE');
    return undef;
  }
}

=item Method B<bugtraq>

Usage :

  my @bugtraq = $plugin->bugtraq;

This method returns the list of bugtraq ids associated with the current plugin.

=cut
sub bugtraq {
  my $self = shift || undef;
  if(!$self) {
    return undef;
  }

  $self->cleanerror;

  my $file = $self->{FILE} || undef;
  if(!$file || $file eq '') {
    $self->error('NO_FILE');
    return undef;
  }

  if($file =~ /script\_bugtraq\_id\(([^\)]*)\)/o) {
    my $bid = $1;
    $bid =~ s/\s//go;
    if(!$bid || $bid eq '') {
      $self->error('NO_BUGTRAQID');
      return undef;
    }
    my @bid = split(/,/,$bid);
    return \@bid;
  } else {
    $self->error('NO_BUGTRAQID');
    return undef;
  }
}

=item Method B<version>

Usage :

  my $version = $plugin->version;

This method returns the version of the current plugin.

=cut
sub version {
  my $self = shift || undef;
  if(!$self) {
    return undef;
  }

  $self->cleanerror;

  my $file = $self->{FILE} || undef;
  if(!$file || $file eq '') {
    $self->error('NO_FILE');
    return undef;
  }

  if($file =~ /script\_version\s*\(\s*(\"|\')([^\1\)]*)\1\s*\)\s*\;/mo) {
    my $version = $2;
    $version =~ s/\$//go;
    if(!$version || $version eq '') {
      $self->error('NO_VERSION');
      return undef;
    }
    return $version;
  } else {
    $self->error('NO_VERSION');
    return undef;
  }
}

=item Method B<name>

Usage :

  my $name = $plugin->name;

This method returns the name of the current plugin.

=cut
sub name {
  my $self = shift || undef;
  if(!$self) {
    return undef;
  }

  $self->cleanerror;

  my $file = $self->{FILE} || undef;
  if(!$file || $file eq '') {
    $self->error('NO_FILE');
    return undef;
  }

  if($file =~ /name\[\"english\"\]\s*\=\s*\"([^\"]*)\"\s*\;/mo) {
    my $name = $1;
    $name =~ s/\'//go;
    if(!$name || $name eq '') {
      $self->error('NO_NAME');
      return undef;
    }
    return $name;
  } elsif($file =~ /script\_name\s*\(.*english\:\s*\"([^\"]*)\"\s*,?/mo) {
    my $name = $1;
    $name =~ s/\'//go;
    if(!$name || $name eq '') {
      $self->error('NO_NAME');
      return undef;
    }
    return $name;
  } else {
    $self->error('NO_NAME');
    return undef;
  }
}

=item Method B<summary>

Usage :

  my $summary = $plugin->summary;

This method returns the summary of the current plugin.

=cut
sub summary {
  my $self = shift || undef;
  if(!$self) {
    return undef;
  }

  $self->cleanerror;

  my $file = $self->{FILE} || undef;
  if(!$file || $file eq '') {
    $self->error('NO_FILE');
    return undef;
  }

  if($file =~ /summary\[\"english\"\]\s*\=\s*\"([^\"]*)\"\s*\;/mo) {
    my $summary = $1;
    if(!$summary || $summary eq '') {
      $self->error('NO_SUMMARY');
      return undef;
    }
    return $summary;
  } elsif($file =~ /script\_summary\s*\(.*english\:\s*\"([^\"]*)\"\s*,?/mo) {
    my $summary = $1;
    if(!$summary || $summary eq '') {
      $self->error('NO_SUMMARY');
      return undef;
    }
    return $summary;
  } else {
    $self->error('NO_SUMMARY');
    return undef;
  }
}

=item Method B<description>

Usage :

  my $description = $plugin->description;

This method returns the description of the current plugin. Attention: JUST the description. Other data
as solution, risk factor, etc. can be reached via their own methods.

=cut
sub description {
  my $self = shift || undef;
  if(!$self) {
    return undef;
  }

  $self->cleanerror;

  my $file = $self->{FILE} || undef;
  if(!$file || $file eq '') {
    $self->error('NO_FILE');
    return undef;
  }

  my $desc = '';
  if($file =~ /desc\[\"english\"\]\s*\=\s*\'\s*([^\']*)\'\s*\;/so) {
    $desc = $1;
  } elsif ($file =~ /desc\[\"english\"\]\s*\=\s*\"\s*([^\"]*)\"\s*\;/so) {
    $desc = $1;
  } elsif ($file =~ /desc\[\"english\"\]\s*\=\s*string\s*\(\s*\"\s*([^\)]*)\"\s*\)\s*\;/so) {
    $desc = $1;
  } elsif ($file =~ /desc\[\"english\"\]\s*\=\s*string\s*\(\s*\"\s*([^\)]*)\"\s*\)\s*\;/so) {
    $desc = $1;
  } elsif ($file =~ /desc\s*\=\s*string\s*\(\s*\"\s*([^\)]*)\"\s*\)\s*\;/so) {
    $desc = $1;
  } elsif ($file =~ /desc\s*\=\s*string\s*\(\s*\'\s*([^\)]*)\'\s*\)\s*\;/so) {
    $desc = $1;
  } elsif ($file =~ /desc\s*\=\s*\"\s*([^\"]*)\"\s*\;/so) {
    $desc = $1;
  } elsif ($file =~ /desc\s*\=\s*\'\s*([^\']*)\'\s*\;/so) {
    $desc = $1;
  } elsif ($file =~ /script\_description\s*\(.*english\:\s*string\s*\(\s*\"\s*([^\"\)]*)\"\s*\),?/so) {
    $desc = $1;
  } elsif ($file =~ /script\_description\s*\(.*english\:\s*string\s*\(\s*\'\s*([^\'\)]*)\'\s*\),?/so) {
    $desc = $1;
  } elsif ($file =~ /script\_description\s*\(\s*english\:\s*[^\"]*\"\s*([^\"\)]*)\"\s*,?/sxo) {
    $desc = $1;
  } elsif ($file =~ /script\_description\s*\(\s*english\:\s*[^\']*\'\s*([^\'\)]*)\'\s*,?/sxo) {
    $desc = $1;
  } else {
    $self->error('NO_DESCRIPTION');
    return undef;
  }

  # Check if we get something
  if($desc eq '') {
    $self->error('NO_DESCRIPTION');
    return undef;
  }

  if($desc =~ /\bSolutions?\s*:\s*/sio) {
    $desc =~ s/Solutions?\s*:\s*.*//sio;
  }
  if($desc =~ /\bSee also\s*:\s*/sio) {
    $desc =~ s/See also\s*:\s*.*//sio;
  }
  if($desc =~ /\bRisk Factor\s*:\s*/sio) {
    $desc =~ s/Risk Factor\s*:\s*.*//sio;
  } elsif($desc =~ /\bRisk\s*:\s*/sio) {
    $desc =~ s/Risk\s*:\s*.*//sio;
  }
  $desc =~ s/^\s*//o;
  $desc =~ s/\s*$//o;
  $desc =~ s/\"$//go;
  $desc =~ s/^\"//go;
  $desc =~ s/;$//go;

  return $desc;
}

=item Method B<solution>

Usage :

  my $solution = $plugin->solution;

This method returns the solution of the current plugin.

=cut
sub solution {
  my $self = shift || undef;
  if(!$self) {
    return undef;
  }

  $self->cleanerror;

  my $file = $self->{FILE} || undef;
  if(!$file || $file eq '') {
    $self->error('NO_FILE');
    return undef;
  }

  my $sol = '';
  if($file =~ /\bSolutions?\s*:\s*([^\"]*)\"\s*\)?\s*\;/sio) {
    $sol = $1;
  } elsif($file =~ /\bSolutions?\s*:\s*([^\']*)\'\s*\)?\s*\;/sio) {
    $sol = $1;
  } else {
    $self->error('NO_SOLUTION');
    return undef;
  }

  # Check if we have something
  if($sol eq '') {
    $self->error('NO_SOLUTION');
    return undef;
  }

  if($sol =~ /\bSee also\s*:\s*/sio) {
    $sol =~ s/See also\s*:\s*.*//sio;
  }
  if($sol =~ /\bRisk Factor\s*:\s*/sio) {
    $sol =~ s/Risk Factor\s*:\s*.*//sio;
  } elsif($sol =~ /\bRisk\s*:\s*/sio) {
    $sol =~ s/Risk\s*:\s*.*//sio;
  }
  $sol =~ s/^\s*//o;
  $sol =~ s/\s*$//o;
  $sol =~ s/\"$//go;
  $sol =~ s/^\"//go;
  $sol =~ s/;$//go;

  return $sol;
}

=item Method B<risk>

Usage :

  my $risk = $plugin->risk;

This method returns the risk factor of the current plugin.

=cut
sub risk {
  my $self = shift || undef;
  if(!$self) {
    return undef;
  }

  $self->cleanerror;

  my $file = $self->{FILE} || undef;
  if(!$file || $file eq '') {
    $self->error('NO_FILE');
    return undef;
  }

  my $risk = '';
  if($file =~ /\bRisk Factor\s*:\s*(critical|high|serious|medium|low|none)/mio) {
    $risk = $1;
  } elsif($file =~ /\bRisk\s*:\s*(critical|high|serious|medium|low|none)/mio) {
    $risk = $1;
  } else {
    $self->error('NO_RISK');
    return undef;
  }


  # Check if we have something
  if($risk eq '') {
      $self->error('NO_RISK');
      return undef;
  }

  return $risk;
}

=item Method B<family>

Usage :

  my $family = $plugin->family;

This method returns the family of the current plugin.

=cut
sub family {
  my $self = shift || undef;
  if(!$self) {
    return undef;
  }

  $self->cleanerror;

  my $file = $self->{FILE} || undef;
  if(!$file || $file eq '') {
    $self->error('NO_FILE');
    return undef;
  }

  my $family = '';
  if($file =~ /family\[\"english\"\]\s*\=\s*\"([^\"]*)\"\s*\;/mo) {
    $family = $1;
  } elsif ($file =~ /script\_family\s*\(.*english\:\s*\"([^\"]*)\"\s*,?/mo) {
    $family = $1;
  } else {
    $self->error('NO_FAMILY');
    return undef;
  }

  # Check if we have something
  if($family eq '') {
      $self->error('NO_FAMILY');
      return undef;
  }

  $family =~ s/\'//go;
  $family =~ s/^\s*//o;
  $family =~ s/\s*$//o;
  $family =~ s/\"$//go;
  $family =~ s/^\"//go;
  $family =~ s/;$//go;

  return $family;
}

=item Method B<category>

Usage :

  my $category = $plugin->category;

This method returns the category of the current plugin.

=cut
sub category {
  my $self = shift || undef;
  if(!$self) {
    return undef;
  }

  $self->cleanerror;

  my $file = $self->{FILE} || undef;
  if(!$file || $file eq '') {
    $self->error('NO_FILE');
    return undef;
  }

  if($file =~ /script\_category\s*\((ACT\_(INIT|SCANNER|SETTINGS|GATHER\_INFO|ATTACK|MIXED\_ATTACK|DESTRUCTIVE\_ATTACK|DENIAL|KILL\_HOST))\)/mo) {
    my $categ = $1;
    if(!$categ || $categ eq '') {
      $self->error('NO_CATEGORY');
      return undef;
    }
    return $categ;
  } else {
    $self->error('NO_CATEGORY');
    return undef;
  }
}

=item Method B<copyright>

Usage :

  my $copyright = $plugin->copyright;

This method returns the copyright of the current plugin.

=cut
sub copyright {
  my $self = shift || undef;
  if(!$self) {
    return undef;
  }

  $self->cleanerror;

  my $file = $self->{FILE} || undef;
  if(!$file || $file eq '') {
    $self->error('NO_FILE');
    return undef;
  }

  if($file =~ /script\_copyright\s*\([^\"]*\"([^\"]*)\"/mo) {
    my $cright = $1;
    if(!$cright || $cright eq '') {
      $self->error('NO_COPYRIGHT');
      return undef;
    }
    return $cright;
  } else {
    $self->error('NO_COPYRIGHT');
    return undef;
  }
}

sub is_nasl {
  my $self = shift || undef;
  if(!$self) {
    return undef;
  }

  $self->cleanerror;

  if(@_) {
    $self->{NASL} = shift @_;
  } else {
    if(exists $self->{NASL} && $self->{NASL} != 0) {
      return $self->{NASL};
    } else {
      return 0;
    }
  }
}

=item Method B<register_service>

Usage :

  my $is_fs = $plugin->register_service;

This method returns True if the plugin registers a service or False if it doesn't

=cut
sub register_service {
  my $self = shift || undef;
  if(!$self) {
    return undef;
  }

  $self->cleanerror;

  my $file = $self->{FILE} || undef;
  if(!$file || $file eq '') {
    $self->error('NO_FILE');
    return undef;
  }

  if($file =~ /register\_service/mo) {
    return 1;
  }

  $self->error('NO_REGISTER_SERVICE');
  return 0;
}

=item Method B<register_service_proto>

Usage:

  my $proto = $plugin->register_service_proto;

This method return the 'proto' argument of a call to the register_service function

=cut
sub register_service_proto {
  my $self = shift || undef;
  if(!$self) {
    return undef;
  }

  $self->cleanerror;

  my $file = $self->{FILE} || undef;
  if(!$file || $file eq '') {
    $self->error('NO_FILE');
    return undef;
  }

  if($self->register_service) {
    $file =~ /register\_service\s*\(\s*.*proto\:\s*\"([^\"]*)\"/mo;
    if(!$1 || $1 eq '') {
      $self->error('NO_REGISTER_SERVICE_PROTO');
      return undef;
    }
    return $1;
  }

  $self->error('NO_REGISTER_SERVICE');
  return undef;
}

=item Method B<error>

Usage :

  my $error = $plugin->error;

This method returns the last error happened during the parsing of the current plugin.

List of errors:

  NO_FILE: The filename gived to parse_file method doesn't exist or it's empty.
  NO_NESSUS_PLUGIN: The string gived to parse_string method isn't a valid NASL plugin.
  NO_CVE: The current plugin hasn't an associated a CVE names list.
  NO_BUGTRAQID: The current plugin hasn't associated a BUGTRAQIDs list.
  NO_NAME: The current plugin hasn't a script_name field.
  NO_SUMMARY: The current plugin hasn't a script_summary field.
  NO_DESCRIPTION: The current plugin hasn't a script_description field.
  NO_SOLUTION: The current plugin hasn't a solution field inside the script_description field.
  NO_RISK: The current plugin hasn't a risk factor field inside the script_description field.
  NO_FAMILY: The current plugin hasn't a script_family field.
  NO_CATEGORY: The current plugin hasn't a script_category field.
  NO_COPYRIGHT: The current plugin hasn't a script_copyright field.
  NO_REGISTER_SERVICE: The current plugin doesn't execute the register_service function
  NO_REGISTER_SERVICE_PROTO: The current plugin does execute the register_service function but it doesn't specify a proto

=cut
sub error {
  my $self = shift || undef;
  if(!defined $self) {
    return undef;
  }

  if(@_) {
    $self->{ERROR} = shift @_;
  } else {
    if(exists $self->{ERROR} && $self->{ERROR} ne '') {
      return $self->{ERROR};
    } else {
      return undef;
    }
  }
}

sub rawerror {
  my $self = shift || undef;
  if(!defined $self) {
    return undef;
  }

  if(@_) {
    $self->{RAWERROR} = shift @_;
  } else {
    if(exists $self->{RAWERROR} && $self->{RAWERROR} ne '') {
      return $self->{RAWERROR};
    } else {
      return undef;
    }
  }
}

sub cleanfilename {
  my $self = shift || undef;
  if(!defined $self) {
    return undef;
  }

  $self->{FILENAME} = '';

  return 1;
}

sub cleanerror {
  my $self = shift || undef;
  if(!defined $self) {
    return undef;
  }

  $self->{ERROR} = '';
  $self->{RAWERROR} = '';

  return 1;
}

sub clean {
  my $self = shift || undef;
  if(!defined $self) {
    return undef;
  }

  $self->{ERROR} = '';
  $self->{RAWERROR} = '';
  $self->{NASL} = 1;
  $self->{FILE} = '';
  $self->{PLUGIN_ID} = '';

  return 1;
}

=back 4

=head1 EXAMPLE

  # This example takes a .nasl file and prints its file name, plugin id, name and CVE list
  use Parse::Nessus::Plugin;

  my $plugin = Parse::Nessus::Plugin->new;
  if($plugin->error) {
    die ("There were an error. Reason: ".$plugin->error);
  }

  if(!$plugin->parse_file('/path/to/plugin.nasl') {
    die ("There were an error. Reason: ".$plugin->error);
  }

  print "FILENAME:".$plugin->filename."\n";
  print "PLUGIN ID:".$plugin->id."\n";
  print "NAME:".$plugin->name."\n";
  my $cve = $plugin->cve;
  if($cve) {
    print " CVE:\n";
    foreach my $cve (@{$cve}) {
      print "  $cve\n";
    }
  }

Check the examples directory to see more examples.

=head1 BUGS

There aren't reported bugs yet, but that doesn't mean that it's free of them :)

=head1 AUTHOR

Roberto Alamos Moreno <ralamosm@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2005-2007 Roberto Alamos Moreno. All rights reserved.
This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
1;
