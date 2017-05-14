package Myco::Config;

################################################################################
# $Id: Config.pm,v 1.8 2006/03/17 22:04:31 sommerb Exp $
#
# See license and copyright near the end of this file.
################################################################################

=pod

=head1 NAME

Myco::Config - Myco Configuration Module

=head1 SYNOPSIS

  # In myco.conf:
  <foobar>
      FOOBAR_PORT_NUM = 6288
      FOOBAR_HOST = localhost
  </foobar>  
  <barbaz>
      BARBAZ_USER = bazdude
      <BARBAZ_PROFILE>
          uid = 1999
          gid = 1999
      <BARBAZ_PROFILE>
  </barbaz>
  
  <<include my_myco_app.conf>>

  
  # In a Myco entity class:
  use Myco::Config qw(:foobar);

  # In another Myco entity class:
  use Myco::Config qw(:barbaz);

  # To get all constants:
  use Myco::Config qw(:all);

=head1 DESCRIPTION

This module reads in a configuration file and sets up a bunch of constants
that are used in the Myco framework. It will also parse any external config
files included from within L<conf/myco.conf>, enabling myco-based applications
to make centralized use of Myco::Config.

Myco::Config generates a series of constants for the values in a configuration
file. The top-level config blocks are converted to labels under which the
constants are listed. This makes it very simple to create export tags that can
be used in modules to import only the constants associated with a given label.

While no constants are exported by Myco::Config by default, the special C<all>
tag can be used to export I<all> of the constants created from the
configuration file, as well as included files:

  use Myco::Config qw(:all);
  
Configuration files are parsed using 
L<Config::General|Config::General> and their syntax should conform to its
requirements. See L<conf/myco.conf-dist> and L<conf/myco.conf-dist> for an
example.

=cut

use strict;
use warnings;
use Myco::Exceptions;
use File::Spec::Functions qw(catfile);
use Myco::Util::Misc;
use Config::General;
use base qw(Exporter);
our (@EXPORT_OK, %EXPORT_TAGS);

BEGIN {
  # Load the configuration file.
  my $conf_file = '';
  if ($ENV{MYCO_ROOT}) {
    $conf_file = catfile($ENV{MYCO_ROOT}, 'conf', 'myco.conf');
  } elsif (-f '/etc/myco.conf') {
    $conf_file = '/etc/myco.conf';
  } elsif (-f '/usr/local/etc/myco.conf') {
    $conf_file = '/usr/local/etc/myco.conf';
  } else {
    Myco::Exception::Stat->throw
        (error => "Could not stat configuration file 'myco.conf'");
  }

  my %conf = ParseConfig( -ConfigFile => $conf_file, -IncludeRelative => 1 );

  while (my ($label, $set) = each %conf) {
    my @export;
      while (my ($const, $val) = each %$set) {
        # convert blank-value hash refs to array refs, based on keys
        if (ref $val eq 'HASH') {
            $val = Myco::Util::Misc->hash_with_no_values_to_array($val);
        }
        eval "use constant $const => \$val";
        push @EXPORT_OK, $const;
        push @export, $const;
    }
    $EXPORT_TAGS{$label} = \@export;
  }
  $EXPORT_TAGS{all} = \@EXPORT_OK;
}

1;
__END__

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2006 the myco project. All rights reserved.
This software is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

David Wheeler <david@wheeler.net>

=cut
