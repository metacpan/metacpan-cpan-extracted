#########################################################################
# We would represent this as CPAN/Config.pm does;			#
# however we broke it up as some values depend upon others. 		#
#									#
#########################################################################
# Add new 							#
# 	$Config{'name'} = "value"; 				#
# entries that you can use from all of you NCustom scripts.	#
# 								#
#################################################################

package NCustom ;

no warnings;

$Config{'test_data1'}	= "global_value";
$Config{'test_data2'}	= "global_value";
$Config{'test_url1'}	= "baneharbinger.com/NCustom/index.html";
$Config{'base_dir'}	= "$ENV{HOME}/.ncustom";
$Config{'save_dir'}	= "$Config{'base_dir'}/save";
$Config{'tmp_dir'}	= "$Config{'base_dir'}/tmp";
$Config{'get_url'}	= \&get_url;
$Config{'src_fqdn'}	= "baneharbinger.com";
$Config{'default_src'}	= ["~/", "./", "http://$Config{'src_fqdn'}/NCustom/"] ;

$Config{'internal_fqdn'}	= "internal.home";
$Config{'perimeter_fqdn'}	= "perimeter.home";
$Config{'external_fqdn'}	= "example.com";
$Config{'lanserver'}		= "lanserver.$Config{'internal_fqdn'}";
$Config{'netserver'}		= "netserver.$Config{'perimeter_fqdn'}";

$Config{'country_code'}		= "AU" ;
$Config{'state'}		= "Victoria" ;
$Config{'city'}			= "Melbourne" ;
$Config{'organisation'}		= "Home" ;
$Config{'organisation_unit'}	= "Home" ;


# passwords generated with slappasswd
# override them in your personal config file
# dont change them in this global file (as it is world readable)
$Config{'users'}  	= { user1 => 501, user2 => 502, user3 => 503 } ;
$Config{'admin_user'}	= "user1" ;
$Config{'low_password'} = [ "{CLEAR}changeme", "{CRYPT}wMgpRr3xnNKbk", "{SSHA}HI89zc2t1e87G/snv4wWMDbTj2ghFySR" ] ;
$Config{'high_password'} = [ "{CLEAR}secret", "{CRYPT}LC4DzvurxORlw", "{SSHA}imWMYrKs2Vo6FcPVkDIivekMw4wo08wD" ] ;

sub get_url {
  my ($url, $target_dir) = @_;
  # the following should be configured for your system
  # it can also be configured in ~/.ncustom/NCustom/MyConfig.pm
  # you may use your favorite utility (curl, wget, pavuk...)
  # you may want to add arguments, such as proxy, or .netrc 
  $url =~ /([^\/]*)$/ ;
  my $basename = $1;
  my $target = "$target_dir/$basename" ;
  my $rc =system("/usr/bin/curl $url --fail -o $target > /dev/null 2>&1 ");
  if($rc != 0){ unlink($target); }
  chmod 0750, $target ;
  return (! $rc);
}

1;
__END__
 
# ///////////////////////////////////////////////////////////////////
#<< TT: Inline Testing   <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
# \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

=begin testing

use File::Copy ;
use File::Path ;
use File::Temp qw/ tempdir /;
use vars qw($output);

test_reset();

use_ok("NCustom::Config", qw(:all) )
  || diag("TEST:<general> can use ok");

my $dir = tempdir( CLEANUP => 1);
ok(-d $dir)
  || diag("TEST:<set up> require temporary directory");
my $rc = &NCustom::get_url($NCustom::Config{'test_url1'}, $dir);
$NCustom::Config{'test_url1'} =~ /([^\/]*)$/ ;
my $file = $1;
ok(-f "$dir/$file")
  || diag("TEST:<get_url> fetches file into dir from url");
ok($rc && -f "$dir/$file")
  || diag("TEST:<get_url> returns success when successful");
#
#
$rc = &NCustom::get_url( "www.bogus.bogus/dummy.html" , $dir);
ok(!$rc && ! -f "$dir/dummy.html")
  || diag("TEST:<get_url> returns fail when unsuccessful");
#
# supress expected error message:
#$_STDERR_ =~ s/get_url: unexpected return code \d+//;
#
output();

sub test_reset {
  $output = "./t/embedded-NCustom-Config.o";
  rmtree  $output;
  mkpath  $output;
  $ENV{HOME} = $output ; # lets be non-intrusive
}
sub output {
  $_STDOUT_ && diag($_STDOUT_);
  $_STDERR_ && diag($_STDERR_);
}

=end testing

=cut

# ///////////////////////////////////////////////////////////////////
#<< PP: POD   <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
# \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

=head1 NAME

NCustom::Config - configuration file for NCustom

=head1 SYNOPSIS

  use NCustom::Config;

=head1 ABSTRACT

  Configuration file for NCustom.

=head1 DESCRIPTION

Useful only with NCustom.

NCustom::Config provides configuration for NCustom. 
This is affected by NCustom "using" NCustom::Config, whereupon NCustom::Config creates and sets configuration variables in NCustom's namespace.

Should a user of NCustom require personalised configuration, they may copy part or all (depending on whether they wish to over ride part or all of the configuration settings) of NCustom::Config to ~/.ncustom/NCustom/MyConfig.pm.
The file must be a perl module.
If such a file exists is will be "used" by NCustom after it has "used" NCustom::Config.

=head2 EXPORT

None - but it does create and set variables within the NCustom namespace.

=head2 CONFIGURATION VARIABLES

Following is a descriptin of configuration variables.

=over 1

=item C<test_data1, test_data2, test_url1>

Ignore these. They are for internal use only (make test).

=item C<base_dir>

This is the base directory for NCustom.
It is within here that personalised configuration file will be searched for.
It is within here that transactions shall be archived.

=item C<save_dir>

The directory into which transactions shall be archived. So that they may be later undone.

=item C<tmp_dir>

NCustom requires a temporary directory on occassion. It makes troubleshooting easier if we know where that is.

=item C<src_fqdn>

The fully qualified domain name of the default server for fetching source such as NCustom files, or rpms from.
Not using fully qualified domain name may affect fetching of source for some utilities for some command line options (such as dont follow offsite links).

=item C<default_src>

A reference to an anonymous array that contains which directories or urls to look in to find files for whom a path name was not given.

=item C<get_url>

A subroutine ref for fetching the file(s) from a particular url, and placing them in a given target directory.

Simple needs should be met by the provided subroutine.
Desired behaviour (such as proxy configuration or reference to passwords) are easily met by adding command line arguments to the provided subroutine's system call.
Complex needs would require recoding of the subroutine.

=back

=head1 SEE ALSO

NCustom
NCustom::Config
ncustom

http://baneharbinger.com/NCustom

=head1 AUTHOR

Bane Harbinger, E<lt>bane@baneharbinger.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2003 by Bane Harbinger

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

