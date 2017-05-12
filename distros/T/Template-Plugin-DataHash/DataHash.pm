#!/usr/bin/perl -w

package Template::Plugin::DataHash;

use strict;

use vars qw($VERSION @ISA $EXTENSION $DEFAULT_INCLUDE_PATH);
$VERSION = '0.04';

use Template::Plugin;
@ISA = qw(Template::Plugin);
$EXTENSION = {
  perl     => qr/\.pl$/i,
  split    => qr/\.split$/i,
  storable => qr/\.sto$/i,
  xml      => qr/\.xml$/i,
  yaml     => qr/\.yaml$/i,
};

### $EXTENSION is a list of regular expression objects used to determine
### how to read in the given conf file

### if a INCLUDE_PATH isn't in the Template::Toolkit object, $DEFAULT_INCLUDE_PATH
### will be used as the INCLUDE_PATH
$DEFAULT_INCLUDE_PATH = ['/tmp'];

sub new {
  my $type  = shift;
  my $template_object = shift || {};

  my @PASSED_ARGS = (ref $_[0] eq 'HASH') ? %{$_[0]} : @_;
  my %DEFAULT_ARGS = (
    extension => {
      %{$EXTENSION},
    },
    extension_order => [qw(yaml perl storable xml split)],
  );
  my $self = bless \%DEFAULT_ARGS, $type;
  $self->merge_in_args(@_);
  unless($self->{INCLUDE_PATH}) {
    if($template_object->{CONFIG}{INCLUDE_PATH}) {
      $self->{INCLUDE_PATH} = [reverse @{$template_object->{CONFIG}{INCLUDE_PATH}}];
    } else {
      $self->{INCLUDE_PATH} = $DEFAULT_INCLUDE_PATH;
    }
  }
  return $self;
}

sub hash {
  my $self = shift;
  my $filename = shift;
  my $dirs = shift || $self->{INCLUDE_PATH};

  my $return = {};
  foreach my $dir (to_array($dirs)) {
    my $full_path = "$dir/$filename";
    next unless(-e $full_path);
    my $this_ref;
    foreach my $regex (@{$self->{extension_order}}) {
      if($full_path =~ $self->{extension}{$regex}) {
        my $method = "load_$regex";
        my $ref = $self->can($method);
        if($ref) {
          $this_ref = $self->$ref($full_path);
        } elsif($self->{$method}) {
          my $method_ref = ref $self->{$method};
          if($method_ref && $method_ref eq 'CODE') {
            $this_ref = &{$self->{$method}}($self, $full_path);
          } else {
            die "\$self->{$method_ref} needs to be a CODE ref";
          }
        } else {
          die "couldn't find a $method method to load $full_path";
        }
      }
    }
    die "conf file returned a non-hash ref" unless(ref $this_ref && ref $this_ref eq 'HASH');
    foreach (keys %{$this_ref}) {
      $return->{$_} = $this_ref->{$_};
    }
  }
  return $return;
}

sub to_array {
  my $values = shift;
  return () unless defined $values;
  if (ref $values eq "ARRAY") {
    return @$values;
  }
  return ($values);
}

sub merge_in_args {
  my $self = shift;
  my %PASSED_ARGS = (ref $_[0] eq 'HASH') ? %{$_[0]} : @_;
  foreach my $passed_arg (keys %PASSED_ARGS) {
    if(ref $PASSED_ARGS{$passed_arg} && ref $PASSED_ARGS{$passed_arg} eq 'HASH') {
      foreach my $key (keys %{$PASSED_ARGS{$passed_arg}}) {
        $self->{$passed_arg}{$key} = $PASSED_ARGS{$passed_arg}{$key};
      }
    } else {
      $self->{$passed_arg} = $PASSED_ARGS{$passed_arg}
    }
  }
}

sub load_yaml {
  my $self = shift;
  my $full_path = shift;
  require YAML;
  return YAML::LoadFile($full_path);
}

sub load_perl {
  my $self = shift;
  my $full_path = shift;
  return do $full_path;
}

sub load_storable {
  my $self = shift;
  my $full_path = shift;
  require Storable;
  return Storable::retrieve($full_path);
}
sub load_split {
  my $self = shift;
  my $full_path = shift;
  my $this_ref = {};
  open(FILE, $full_path) || die "couldn't open $full_path: $!";
  while(<FILE>) {
    next if(/^\s*#/);
    next unless(/^(\S+)\s+(.+)\n?/);
    $this_ref->{$1} = $2;
  }
  close(FILE);
  return $this_ref;
}

sub load_xml {
  my $self = shift;
  my $full_path = shift;
  require XML::Simple;
  return XML::Simple::XMLin($full_path);
}

1;

__END__

=head1 NAME

Template::Plugin::DataHash - use INCLUDE_PATH to get confs with key fallback

=head1 OVERVIEW

Template::Plugin::DataHash provides a simple way to turn conf files, gathered
from your INCLUDE_PATH into a single hash ref (no support for non hashes).
I walk the INCLUDE_PATH, tack on the filename onto the end of each directory and this
gives me the full_path of the file I will check.  If the file exists, I run all the regexes
in $self->{extension} (going in the order specified in $self->{extension_order}),
to see which $type of conf I have, and then look for either
a load_$type method or $self->{load_$type} (a CODE ref) and run the appropriate method.
Each load_$type method takes a refence to $self and the full_path of the file, and returns a hash ref.

Two structures in the object help manage the process.

=head1 $self->{extension}

$self->{extension} contains a hash ref of regex objects that map a type (Storable
for example) to a regex that gets run on the full_path of the file.

=head1 $self->{extension_order}

$self->{extension_order} contains a array ref specifying the order to check the
extensions.

=head1 EXAMPLE

Let's say you have two conf files: 

/tmp/default/conf.yaml

  key1: default1
  key2: default2

/tmp/override/conf.yaml

  key2: override2

In your template you could put

  [% USE dho = DataHash({INCLUDE_PATH => ['/tmp/override', '/tmp/default']}) %]
  [% hash = dho.hash('conf.yaml') %]

hash would then look like {
    key1 => 'default1',
    key2 => 'override2',
  }

By default, the INCLUDE_PATH comes from $template_object->{CONFIG}{INCLUDE_PATH}.

=head1 SUPPORTED EXTENSIONS

This is the set of default extension regexes

    extension => {
      perl     => qr/\.pl$/i,
      split    => qr/\.split$/i,
      storable => qr/\.sto$/i,
      xml      => qr/\.xml$/i,
      yaml     => qr/\.yaml$/i,
    },

The default extension order is

    extension_order => [qw(yaml perl storable xml split)],


=head1 ADDING YOUR OWN EXTENSION TYPES

If I have left out an extension that you feel others may be interested in, let
me know and I can easily add new types.  If you have a custom extension, you
need to get the custom name into $self->{extension}, like

$self->{extension}{custom} = qr/\.custom$/;

then you can either do an overriding object, or specify the method in your object, like

$self->{load_custom} = sub {
  my $self = shift;
  my $full_path = shift;
  ...
  convert file to $ref in custom fashion
  ...
  return $ref
};

=head1 AUTHOR

Copyright 2003, Earl J. Cahill.  All rights reserved.

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

Address bug reports and comments to: cpan@spack.net.

When sending bug reports, please provide the version of Template::Plugin::DataHash,
the version of Perl, and the name and version of the operating system
you are using.
