use FindBin;
die unless ($FindBin::Script =~ m/^(.*?)\.PL$/);
open(STDOUT, ">$1") || die;
print <DATA>
__END__
#! /usr/local/bin/perl

# UserReport - a sample script demonstrating a perl report using Spectrum::CLI
# Copyright (C) 2000  Dave Plonka

# $Id: UserReport.PL,v 1.3 2003/12/16 15:54:28 dplonka Exp $
# Dave Plonka <plonka@doit.wisc.edu>

=head1 NAME

UserReport - a sample script demonstrating a perl report using Spectrum::CLI

=head1 SYNOPSIS

 UserReport [-vVO] [vnmhost]
    -v - cause Spectrum::CLI object be 'v'erbose
    -V - cause Spectrum::CLI object be 'V'ery verbose
    -O - 'O'ptimize by using seek rather than show_models and by
	 specifying a list of attributes with show_attributes("mh=...")
	 (Note that as of this writing this, surprisingly, doesn't
	 really speed things up at all, which leads me to believe that
	 perhaps such filters are performed by the CLI commands themselves
	 rather than by the SpectroSERVER.)

=head1 DESCRIPTION

=head1 AUTHOR

Dave Plonka <plonka@doit.wisc.edu>

=cut

use Getopt::Std;
use FindBin;
use Spectrum::CLI;

getopts('vVOhw:') || usage(2);
$opt_h && usage(0);

my $cli = new Spectrum::CLI { verbose => $opt_v || $opt_V,
			      Verbose => $opt_V,
			      CLIMNAMEWIDTH => $opt_w }, $ARGV[0];
die "Spectrum::CLI constructor failed!\n" unless ref($cli);

my(%Users, $model, $attr, $u, $assoc, %A);

# Find the attribute Ids for User type (to speed up "show_associations(mh=)"):
foreach my $type ($cli->show_types) {
   if ('User' eq $type->{Name}) {
      map {
	 $A{User}{$_->{Name}} = $_
      } $cli->show_attributes("mth=$type->{Handle}");
      last
   }
}

foreach $model ($opt_O? $cli->seek(
				 "attr=$A{User}{Modeltype_Name}{Id},value=User")
				 : $cli->show_models) {
   next unless $opt_O ||
		$model->{MTypeName} =~ m/^User\s+/;
   $Users{$model->{MName}} = $model;
   foreach $attr ($opt_O? $cli->show_attributes(
				   "attr=$A{User}{Model_Name}{Id}",
				   "attr=$A{User}{User_Community_String}{Id}",
				   "attr=$A{User}{User_Full_Name}{Id}",
				   "attr=$A{User}{mdl_creat_time}{Id}",
                                   "mh=$model->{MHandle}")
			  : $cli->show_attributes("mh=$model->{MHandle}")) {
      $Users{$model->{MName}}{Attributes}{$attr->{Name}} = $attr->{Value}
   }
   foreach $assoc ($cli->show_associations("mh=$model->{MHandle}")) {
      if ('Has_Member' eq $assoc->{Relation}) {
	 $Users{$model->{MName}}{Attributes}{Group} = $assoc->{LMName}
      }
   }
}

# generate the report
map {
   $u = $Users{$_}{Attributes};
   $u->{created_string} = scalar(localtime($u->{mdl_creat_time}));
   write
} sort keys %Users;

exit;

format STDOUT_TOP =
User     Group    Community Full Name                        Created
-------- -------- --------- -------------------------------- -------------------
.

format STDOUT =
@<<<<<<< @<<<<<<< @<<<<<<<< @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< @>>>>>>>>>>>>>>>>>>
$u->{Model_Name} $u->{Group} $u->{User_Community_String} $u->{User_Full_Name} $u->{created_string}
.

sub usage {
my $status = shift;
print STDERR <<_EOF_
usage: $FindBin::Script [-vVO] [vnmhost]
       -v - cause Spectrum::CLI object be 'v'erbose
       -V - cause Spectrum::CLI object be 'V'ery verbose
       -O - 'O'ptimize by using seek rather than show_models and by
	    specifying a list of attributes with show_attributes("mh=...")
	    (Note that as of this writing this, surprisingly, doesn't
	    really speed things up at all, which leads me to believe that
	    perhaps such filters are performed by the CLI commands themselves
	    rather than by the SpectroSERVER.)
_EOF_
;
exit($status)
}
