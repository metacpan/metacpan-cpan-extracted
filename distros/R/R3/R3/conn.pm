package R3::conn;
# Copyright (c) 1999, Johan Schoen. All rights reserved.

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

require Exporter;
require AutoLoader;

@ISA = qw(Exporter AutoLoader);
@EXPORT = qw( );
@EXPORT_OK = qw( );

$VERSION = '0.31';

#
# Method implementation
#

require R3::rfcapi;
use Carp;

sub _tjo
{
	R3::rfcapi::r3_rfc_clear_error();
}

sub _tjim
{
	my $x;
	my $xt;
	my $m;
	if (R3::rfcapi::r3_get_error())
	{
		$x=R3::rfcapi::r3_get_exception();
		$xt=R3::rfcapi::r3_get_exception_type() || "R3CONN";
		$m=R3::rfcapi::r3_get_error_message();
		if ($m)
		{
			$m = "\n$m" 
		}
		else
		{
			$m = "\nconnection failed"
		}
		croak $xt . ":" . $x . $m; 
	}
}

sub new
{
	my $type = shift;
	my %param = @_;
	my $self = {};
	$self->{client}=$param{client};
	$self->{user}=$param{user};
	$self->{passwd}=$param{password} || $param{passwd};
	$self->{lang}=$param{language} || $param{lang} || "E";
	$self->{host}=$param{hostname} || $param{host};
	$self->{sysnr}=$param{systemnr} || $param{sysnr};
	$self->{gwhost}=$param{gwhost} || "";
	$self->{gwservice}=$param{gwservice} || "";
	$self->{trace}=$param{trace} || 0;
	$self->{pre4}=$param{pre4} || 0;
	_tjo();
	$self->{h_conn} = R3::rfcapi::r3_new_conn(
		$self->{client},
		$self->{user},
		$self->{passwd},
		$self->{lang},
		$self->{host},
		$self->{sysnr},
		$self->{gwhost},
		$self->{gwservice},
		$self->{trace});
	_tjim();
	if ($self->{pre4})
	{
		R3::rfcapi::r3_set_pre4($self->{h_conn});		
	}
	return bless $self, $type;
}

sub DESTROY
{
	my $self = shift;
	if ($self->{h_conn})
	{
		R3::rfcapi::r3_del_conn($self->{h_conn});
	}
}


1;
__END__
# Below is the documentation for the module.

=head1 NAME

R3::conn - Perl extension for handling connection to a SAP R/3 system

=head1 SYNOPSIS

  use R3::conn;

  $conn = new R3::conn (client=>"100", user=>"SAP*",
    password=>"pass", hostname=>"apollo", sysnr=>0);

  undef $conn;

=head1 DESCRIPTION

R3::conn::new creates a new connection to a R/3 system. It takes the following named parameters:
  client => R/3 client
  user => user ID
  password => user's password
  passwd => alias for password
  language => logon language, defaults to 'E'
  lang => alias for language
  hostname => application server's hosname
  host => alias for hostname
  systemnr => system number
  sysnr => alias for systemnr
  gwhost => gateway host, defaults to host
  gwservice => gateway service, defaults to service "sapgw##" with ## = 'sysnr'
  trace => rfc trace on if set to 1, defaults to 0 (off)
  pre4 => should be set to true value if target host has R/3 release < 40A

=head1 AUTHOR

Johan Schoen, johan.schon@capgemini.se

=head1 SEE ALSO

perl(1), R3(3), R3::func(3), R3::itab(3) and R3::rfcapi(3).

=cut
