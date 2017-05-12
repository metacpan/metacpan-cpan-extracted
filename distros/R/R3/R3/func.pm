package R3::func;
# Copyright (c) 1999 Johan Schoen. All rights reserved.

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

require Exporter;
require AutoLoader;

@ISA = qw(Exporter AutoLoader);
@EXPORT = qw( );
@EXPORT_OK = qw( );

$VERSION = '0.31';

#
# Methods
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
                $xt=R3::rfcapi::r3_get_exception_type() || "R3FUNC";
                $m=R3::rfcapi::r3_get_error_message();
		if ($m)
		{
			$m = "\n$m";
		}	
                croak $xt . ":" . $x . $m;
        }
}

sub new
{
	my $type = shift;
	my $self = {};
	my $conn = shift;
	my $funcname = shift;
	my $h_conn=$conn->{h_conn};	
	_tjo();
	$self->{h_func}=R3::rfcapi::r3_new_func($h_conn, $funcname);
	_tjim();
	return bless $self, $type;
}

sub DESTROY
{
	my $self = shift;
	if ($self->{h_func})
	{
		_tjo();
		R3::rfcapi::r3_del_func($self->{h_func});
		_tjim();
	}
}

sub call
{
	no strict 'vars';
	my $self = shift;
	local *exp_par;
	local *table_par;
	*exp_par = shift;
	*table_par = shift;
	my $i;
	my $h=$self->{h_func};
	_tjo();
	R3::rfcapi::r3_clear_params($h);
	_tjim();
	for ($i=0; $i<@exp_par; $i+=2)
	{
		_tjo();
		R3::rfcapi::r3_set_export_value($h, $exp_par[$i], $exp_par[$i+1]);
		_tjim();
	}
	for ($i=0; $i<@table_par; $i+=2)
	{
		_tjo();
		R3::rfcapi::r3_set_table($h, $table_par[$i], 
			$table_par[$i+1]->{h_itab});
		_tjim();
	}
	_tjo();
	R3::rfcapi::r3_call_func($h);
	_tjim();
	for ($i=0; $i<@_; $i+=2)
	{
		_tjo();
		$_[$i+1]=R3::rfcapi::r3_get_import_value($h, $_[$i]);
		_tjim();
	}
}

1;
__END__
# Below is the documentation for R3::func!

=head1 NAME

R3::func - Perl extension for calling remote functions in a R/3 system

=head1 SYNOPSIS

  use R3::func;
  $func = new R3::func ($conn, $func_name);
  call $func (\@export, \@tables, $field_1, $value_1, $field_2, $value_2,
  $field_3, $value_3, ... $field_n, $value_n);
  undef $func;

=head1 DESCRIPTION

R3::func::new enables a R/3 function to be called from perl. The function
interface is retrieved from the R/3 system. R3::func::new takes two parameters,
first parameter is a R3::conn, second is the name of the ABAP function.

R3::func::call calls the ABAP function specified in R3::func::new.
R3::func::call takes two or more parameters. First parameter is a reference
to an array of export variable and export value pairs. Second parameter is a
reference to an array of table name and table handle pairs. Third and further
parameters are import variable name and import variable pairs. Use 
references to empty arrays, [], if there is no export variables and/or tables
in the function interface.

Example:
  ...
  $func=new R3::func ($conn, "RFC_GET_TABLE_ENTRIES");
  $itab=new R3::itab ($conn, "TAB512");
  call $func ([TABLE_NAME=>'TVKO', GEN_KEY=>'2'],
    [ENTRIES=>$itab], NUMBER_OF_ENTRIES=>$e);
  ...

=head1 AUTHOR

Johan Schoen, johan.schon@capgemini.se

=head1 SEE ALSO

perl(1), R3(3), R3::conn(3), R3::itab(3) and R3::rfcapi(3).

=cut
