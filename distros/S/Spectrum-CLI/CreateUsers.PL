use FindBin;
die unless ($FindBin::Script =~ m/^(.*?)\.PL$/);
open(STDOUT, ">$1") || die;
print <DATA>
__END__
#! /usr/local/bin/perl

# CreateUsers - a script to create Spectrum users
# Copyright (C) 2000  Dave Plonka

# $Id: CreateUsers.PL,v 1.12 2003/12/16 15:55:09 dplonka Exp $
# Dave Plonka <plonka@doit.wisc.edu>

=head1 NAME

CreateUsers - a script to create Spectrum users

=head1 SYNOPSIS

 CreateUsers [-h] [-vV] [-t|-T] [-g group[,group2[,...]]]
     -h - 'h'elp (shows this usage information)
     -v - be 'v'erbose (with messages)
     -V - be 'V'ery verbose (with messages)
     -t - create TroubleShooter models for these users as well
     -T - just create TroubleShooter models, not User models
     -g group - create the users that are members of the specified group(s)
		group can be a regular expression, e.g. "-g spec.*".
		If more than one group or pattern is used they should
		be comma-separated.
		If this option is not specified, th login group of the
		user running this script will be used.

=head1 DESCRIPTION

=head1 AUTHOR

Dave Plonka <plonka@doit.wisc.edu>

=cut

use strict;
use English;
use Getopt::Std;
use FindBin;
use IO::File;
use Spectrum::CLI 1.005;

# MAIN #########################################################################

my %opt = ( v => 0, V => 0, h => 0 );

getopts('vVhg:tT', \%opt) || usage(2);
$opt{h} && usage(0);

# { user should have one of these shells:
# (this is to ensure that they could login and run "spectrum" and
# also that their account has not be "deactivated" by making the
# shell "/bin/false" or something like that.)
my @safe_shell;
my $fh = new IO::File('/etc/shells', 'r');
# die "open \"/etc/shells\", \"r\": $!\n" unless ref($fh);
foreach my $line (<$fh>) {
   chomp $line;
   $line =~ s/\s+$//;
   push(@safe_shell, $line)
}
$fh->close;
print("valid shells: \"", join('", "', @safe_shell), "\"\n") if $opt{v};
# }

my(%M, %T, %A); # hashes of models, types, and associations

my $session = new Spectrum::CLI { verbose => $opt{v}, Verbose => $opt{V} };
if (!ref($session)) {
   die "Failed to create Spectrum::CLI session!\n"
}

die unless map { $M{Name}{$_->{MName}} = $_ } $session->show_models;
die unless map { $T{Name}{$_->{Name}} = $_ } $session->show_types;

die unless defined $T{Name}{User}{Handle};

foreach my $type (qw(User UserGroup TroubleShooter)) {
   die unless map {
                 $A{$type}{Name}{$_->{Name}} = $_
              } $session->show_attributes("mth=$T{Name}{$type}{Handle}")
}

# { be sure these attributes exist (just as a sanity check):
die unless defined $A{User}{Name}{Model_Name};
die unless defined $A{User}{Name}{User_Full_Name};
die unless defined $A{User}{Name}{User_Phone};
die unless defined $A{User}{Name}{User_Location};
die unless defined $A{User}{Name}{User_Organization};
die unless defined $A{User}{Name}{User_Community_String}; # ADMIN,0
die unless defined $A{User}{Name}{Security_String}; # ADMIN

die unless defined $A{UserGroup}{Name}{Model_Name};

die unless defined $A{TroubleShooter}{Name}{Model_Name};
die unless defined $A{TroubleShooter}{Name}{EmailAddress};
# }

my(@group);
if ($opt{g}) {
   @group = split(',', $opt{g})
} else { # default to this user's login group
   @group = scalar(getgrgid($GID))
}
die unless @group;

my(%User, %UserGroup, %TroubleShooter);
map {
   $User{$_->{MName}} = $_
} $session->seek("attr=$A{User}{Name}{Modeltype_Name}{Id},val=User");

map {
   $UserGroup{$_->{MName}} = $_
} $session->seek("attr=$A{UserGroup}{Name}{Modeltype_Name}{Id},val=UserGroup");

map {
   $TroubleShooter{$_->{MName}} = $_
} $session->seek("attr=$A{TroubleShooter}{Name}{Modeltype_Name}{Id},val=TroubleShooter");

while (my($name, $passwd, $gid, $members) = getgrent) {
   next unless grep { $name =~ m/^${_}$/ } @group;

   if (!$opt{T} && !defined $UserGroup{$name}{MHandle}) {
      if (!$session->create_model("mth=$T{Name}{UserGroup}{Handle}",
              "attr=$A{UserGroup}{Name}{Model_Name}{Id},val=${name}")) {
	 warn "create_model failed:\n[", $session->results, "]\n";
	 next
      }
      my $mh = model_handle($session->results);
      if (!$mh) {
	 warn "UserGroup model handle not found in results:\n[", $session->results, "]\n";
	 next
      }
      print "created model ${mh} (UserGroup \"$name\").\n" if $opt{v};
      $M{Name}{$name}{MHandle} = $mh;
      $UserGroup{$name}{MHandle} = $mh;
      die unless $M{Name}{$name}{MHandle};
   }

   foreach my $user (split(' ', $members)) {
      my($login, $passwd, $uid, $gid, $quota, $comment, $gcos, $dir, $shell);
      if (!(($login, $passwd, $uid, $gid, $quota, $comment, $gcos, $dir, $shell) = getpwnam($user))) {
         warn "getpwnam \"$user\" failed.\n";
	 next
      }
      if (!grep($_ eq $shell, @safe_shell)) {
         warn "User \"$user\" does not have an appropriate login shell: \"$shell\".\n";
         next
      }
      my($full_name) = split(',', $gcos);
      if (!$opt{T} && !defined $User{$user}{MHandle}) {
	 if (!$session->create_model("mth=$T{Name}{User}{Handle}",
                "attr=$A{User}{Name}{Model_Name}{Id},val=${login}",
                "attr=$A{User}{Name}{User_Full_Name}{Id},val='${full_name}'")) {
	    warn "create_model failed:\n[", $session->results, "]\n";
	    next
	 }
	 my $mh = model_handle($session->results);
	 if (!$mh) {
	    warn "User model handle not found in results:\n[", $session->results, "]\n";
	    next
         }
         print "created model ${mh} (User \"$login\").\n" if $opt{v};
         $M{Name}{$user}{MHandle} = $mh;
         $User{$user}{MHandle} = $mh;
         die unless $M{Name}{$user}{MHandle};

         # Place this User in their UserGroup:
         if (!$session->create_association("rel=Has_Member",
		 "lmh=$UserGroup{$name}{MHandle}",
		 "rmh=$M{Name}{$user}{MHandle}")) {
            warn "creation of \"$UserGroup{$name}{MHandle} Has_Member rmh=$M{Name}{$user}{MHandle}\" association failed:\n[", $session->results, "]\n"
         }
      }
      if (($opt{T} || $opt{t}) && !defined($TroubleShooter{$user}{MHandle})) {
	 if (!$session->create_model("mth=$T{Name}{TroubleShooter}{Handle}",
              "attr=$A{TroubleShooter}{Name}{Model_Name}{Id},val=${login}",
              "attr=$A{TroubleShooter}{Name}{EmailAddress}{Id},val=${login}")) {
	    warn "create_model failed:\n[", $session->results, "]\n";
	    next
	 }
	 my $mh = model_handle($session->results);
	 if (!$mh) {
	    warn "TroubleShooter model handle not found in results:\n[", $session->results, "]\n";
	    next
         }
	 # FIXME - create Is_Assigned association, lmh=User rmh=TroubleShooter
      }
   }
}

undef $session;

exit;

################################################################################

sub model_handle {
   my $mh;
   grep { m/(0x[0-9A-Fa-f]+)$/ && ($mh = $&)} @_;
   return $mh
}

################################################################################

sub usage {
   my $status = shift;
print <<_EOF_
usage: $FindBin::Script [-h] [-vV] [-t|-T] [-g group[,group2[,...]]]
       -h - 'h'elp (shows this usage information)
       -v - be 'v'erbose (with messages)
       -V - be 'V'ery verbose (with messages)
       -t - create TroubleShooter models for these users as well
       -T - just create TroubleShooter models, not User models
       -g group - create the users that are members of the specified group(s).
		  group can be a regular expression, e.g. "-g spec.*".
		  If more than one group or pattern is used they should
		  be comma-separated.
		  If this option is not specified, th login group of the
		  user running this script will be used.
_EOF_
   ;
   exit $status
}
