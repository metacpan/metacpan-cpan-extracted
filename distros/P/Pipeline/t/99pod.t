#!/usr/bin/perl -w
#
# Make sure the PODs don't contain invalid markup
#
# Use podchecker to find the actual POD error
#
# An awful lot of this was nicked from Test::Pod

use strict;
use vars qw(@files);

# Pod::Parser has some warnings, so disable them
local $SIG{__WARN__} = sub {};

BEGIN {
  eval {
    require File::Find::Rule;
    require Pod::Checker;
  };
  if ($@) {
    print "1..0 # Skipped - do not have Find::File::Rule or Pod::Checker installed\n";
    exit;
  }
}

BEGIN {
  use File::Find::Rule;
  @files = File::Find::Rule->file()->name('*.pm', '*.pod')->in('.');
}

use IO::Null;
use Test::More tests => scalar @files;

use constant OK       =>  0;
use constant NO_FILE  => -2;
use constant NO_POD   => -1;
use constant WARNINGS =>  1;
use constant ERRORS   =>  2;

foreach my $file ( @files ) {
  my $hash = _check_pod( $file );
  my $status = $hash->{result};

  if ( $status == NO_FILE ) {
    ok( 0, "Did not find [$file]");
  } elsif ( $status == OK ) {
    ok( 1, "Pod OK in [$file]" );
  } elsif ( $status == ERRORS ) {
    ok( 0, "Pod had errors in [$file]" );
    system("podchecker", $file);
  } elsif ( $status == WARNINGS ) {
    ok( 1, "Pod had warnings in [$file], but that's okay" );
  } elsif ( $status == WARNINGS ) {
    ok( 0, "Pod had warnings in [$file]" );
  } elsif ( $status == NO_POD ) {
    ok( 0, "Found no pod in [$file]" );
  } else {
    ok( 0, "Mysterious failure for [$file]" );
  }
}

sub _check_pod {
  my $file = shift;
  return { result => NO_FILE } unless -e $file;
  my %hash     = ();
  my $checker = Pod::Checker->new();
  # i pass it a null filehandle because i need to fool
  # Pod::Checker into thinking it is sending the errors
  # somewhere so it will count them for me.
  tie( *NULL, 'IO::Null' );       
  $checker->parse_from_file( $file, \*NULL );
  $hash{ result } = do {
    $hash{errors}   = $checker->num_errors;
    $hash{warnings} = $checker->can('num_warnings') ?
      $checker->num_warnings : 0;
    if ( $hash{errors} == -1  ) {
      NO_POD;
    } elsif ( $hash{errors}   > 0  ) {
      ERRORS;
    } elsif ( $hash{warnings} > 0  ) {
      WARNINGS;
    } else {
      OK;
    }
  };
  return \%hash;
}



