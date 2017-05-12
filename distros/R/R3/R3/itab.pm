package R3::itab;
# Copyright (c) 1999 Johan Schoen

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

require Exporter;
require AutoLoader;

@ISA = qw(Exporter AutoLoader);
@EXPORT = qw( );
@EXPORT_OK = qw( );

$VERSION = '0.31';


# Preloaded methods go here.
# Autoload methods go after =cut, and are processed by the autosplit program.

use Carp;
require R3::rfcapi;

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
                $xt=R3::rfcapi::r3_get_exception_type() || "R3ITAB";
                $m=R3::rfcapi::r3_get_error_message();
		if ($m)
		{
			$m="\n$m";
		}
                croak $xt . ":" . $x . $m;
        }
}

sub new
{
	my $type = shift;
	my $self = {};
	my $conn = shift;
	my $name = shift;
	my $h_conn=$conn->{h_conn};	
	_tjo();
	$self->{h_itab}=R3::rfcapi::r3_new_itab($h_conn, $name);
	_tjim();
	return bless $self, $type;
}

sub DESTROY
{
	my $self = shift;
	if ($self->{h_itab})
	{
		_tjo();
		R3::rfcapi::r3_del_itab($self->{h_itab});
		_tjim();
	}
}

sub _set_record
{
	my $self=shift;
	my $i;
	_tjo();
	R3::rfcapi::r3_clear_itab_fields($self->{h_itab});
	_tjim();
	for ($i=0; $i<@_; $i+=2)
	{
		_tjo();
		R3::rfcapi::r3_set_field_value($self->{h_itab}, 
			$_[$i], $_[$i+1]);
		_tjim();
	}
}

sub set_record
{
	my $self = shift;
	my $line = shift;
	_tjo();
	R3::rfcapi::r3_set_row($self->{h_itab}, $line);
	_tjim();
	_tjo();
	_set_record($self, @_);		
	_tjim();
}

sub ins_record
{
	my $self = shift;
	my $line = shift;
	_tjo();
	R3::rfcapi::r3_ins_row($self->{h_itab}, $line);
	_tjim();
	_tjo();
	_set_record($self, @_);		
	_tjim();
}

sub add_record
{
	my $self = shift;
	_tjo();
	R3::rfcapi::r3_add_row($self->{h_itab});
	_tjim();
	_tjo();
	_set_record($self, @_);		
	_tjim();
}

sub del_record
{
	my $self=shift;
	my $line=shift;
	_tjo();
	R3::rfcapi::r3_del_row($self->{h_itab}, $line);
	_tjim();
}

sub get_records
{
	my $self=shift;
	my $i;
	_tjo();
	$i=R3::rfcapi::r3_rows($self->{h_itab});
	_tjim();
	return $i;
}

sub get_record
{
	my $self=shift;
	my $line=shift;
	my @row;
	my $fields;
	my $i;
	my ($field, $value);
	_tjo();
	R3::rfcapi::r3_set_row($self->{h_itab}, $line);
	_tjim();
	_tjo();
	$fields=R3::rfcapi::r3_get_fields($self->{h_itab});
	_tjim;
	for ($i=0; $i<$fields; $i++)
	{
		_tjo();
		$field=R3::rfcapi::r3_get_field_name($self->{h_itab}, $i);
		_tjim();
		_tjo();
		$value=R3::rfcapi::r3_get_f_val($self->{h_itab}, $i);
		_tjim();
		push @row, $field, $value;
	}
	return @row;
}

sub get_lines
{
	my $self=shift;
	my $i;
	_tjo();
	$i=R3::rfcapi::r3_rows($self->{h_itab});
	_tjim();
	return $i;
}

sub get_line
{
	my $self = shift;
	my $line = shift;
	my $rec;
	_tjo();
	R3::rfcapi::r3_set_row($self->{h_itab}, $line);
	_tjim();
	_tjo();
	$rec=R3::rfcapi::r3_get_record($self->{h_itab});
	_tjim;
	return $rec;
}

sub set_line
{
	my $self = shift;
	my $line = shift;
	my $rec = shift;
	_tjo();
	R3::rfcapi::r3_set_row($self->{h_itab}, $line);
	_tjim();
	_tjo();
	R3::rfcapi::r3_set_record($self->{h_itab}, $rec);		
	_tjim();
}


sub add_line
{
	my $self = shift;
	my $rec = shift;
	_tjo();
	R3::rfcapi::r3_add_row($self->{h_itab});
	_tjim();
	_tjo();
	R3::rfcapi::r3_set_record($self->{h_itab}, $rec);		
	_tjim();
}

sub ins_line
{
	my $self = shift;
	my $line = shift;
	my $rec = shift;
	_tjo();
	R3::rfcapi::r3_ins_row($self->{h_itab}, $line);
	_tjim();
	_tjo();
	R3::rfcapi::r3_set_record($self->{h_itab}, $rec);		
	_tjim();
}

sub del_line
{
	my $self=shift;
	my $line=shift;
	_tjo();
	R3::rfcapi::r3_del_row($self->{h_itab}, $line);
	_tjim();
}

sub trunc
{
	my $self=shift;
	_tjo();
	R3::rfcapi::r3_trunc_rows($self->{h_itab});
	_tjim();
}

sub line2record
{
	my $self=shift;
	my $s=shift;
	my @r;
	$self->add_line($s);
	@r=$self->get_record($self->get_lines());
	$self->del_line($self->get_lines());
	return @r; 
}

sub record2line
{
	my $self=shift;
	my @r=@_;
	my $s;
	$self->add_record(@r);
	$s=$self->get_line($self->get_lines());
	$self->del_line($self->get_lines());
	return $s; 
}

1;
__END__
# Below is the stub of documentation for R3::itab!

=head1 NAME

R3::itab - Perl extension for handling ABAP internal tables

=head1 SYNOPSIS

  use R3::itab;
  $itab = new R3::itab ($conn, "MARA");

  $itab->get_records();
  %h = $itab->get_record($i);
  $itab->set_record($i, %h);
  $itab->ins_record($i, %h);
  $itab->add_record(%h);
  $itab->del_record($i);

  $itab->get_lines();
  $s = $itab->get_line($i);
  $itab->set_line($i, $s); 
  $itab->ins_line($i, $s);
  $itab->add_line($s);
  $itab->del_line($i);

  $itab->trunc();

  %h = $itab->line2record($s);
  $s = $itab->record2line(%h);

=head1 DESCRIPTION

First record in a R3::itab is 1. This is the same as in ABAP.

$itab->get_records() returns the number of records in $itab

$itab->get_record($i) returns an array of field name, value pairs for 
the $i:th record in $itab

$itab->set_record($i, %h) replaces the values of the $i:th record in $itab
with the values in the field name, value pairs following the first parameter

$itab->ins_record($i, %h) inserts a record at the $i:th position in $itab
and sets the values to the value in the field name, value pairs following the
first parameter

$itab->add_record(%h) appends a new record to the end of $itab and
sets the values to the value in the field name, value pairs in %h

$itab->del_record($i) deletes the $i:th record from $itab

$itab->get_lines() returns the number of records in $itab; should be the
same amount as $itab->get_records() returns

$itab->get_line($i) returns an unpacked hex string with the values of
the $i:th record in $itab

$itab->set_line($i, $s) replace the values of the $i:th record with the
content in the unpacked hex string in $s

$itab->ins_line($i, $s) inserts a new record at the $i:th position in $itab
and sets the values to the content in the unpacked hex string $s

$itab->add_line($s) adds a new record to the end of $itab and sets the
values to the content in the unpacked hex string $s

$itab->del_line($i) deletes the $i:th record from $itab

$itab->trunc() deletes all records from $itab

$itab->line2record($s) returns the unpacked hex string as an array
of field name, value pairs

$itab->record2line(%h) returns an unpacked hex string corresponding
to the array of field name, value pairs

=head1 AUTHOR

Johan Schoen, johan.schon@capgemini.se

=head1 SEE ALSO

perl(1), R3(3), R3::conn(3), R3::func(3) and R3::rfcapi(3).

=cut
