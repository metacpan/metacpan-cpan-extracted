package SAS::TRX::MySQL;
#
#	Format TRX-learned structure and data into MySQL dialect
#


use strict;
use warnings;

use base qw(SAS::TRX);
use IO::File;

#
#	Constructor
#
sub new
{
	my $class	= shift;
	my %param	= @_;
	my $self	= $class->SUPER::new(@_);

	# Open destination files
	foreach my $dst (qw(DATASET STRUCT)) {
		if ($param{$dst}) {
			$self->{$dst} = new IO::File $param{$dst}, 'w';
		}
	}

	bless ($self,$class);
        return $self;
}


#
#	Can be used to construct data a row header
#
sub data_header
{
	my $self	= shift;
	my $dsname	= shift;

	print  { $self->{DATASET} } "INSERT INTO $dsname (",
		join(',', @{$self->{TRX}{$dsname}{CNAMES}}),
		") VALUES \n";
}
sub data_footer
{
	my $self	= shift;
	my $dsname	= shift;

	seek $self->{DATASET}, -2, 1;	# Write over the last ",\n"
	print { $self->{DATASET} } ";\n";
}


#
#	Create an INSERT line for a given dataset and list of data values
#
#	Numeric data length and type is unreliable in TRX library,
#	everything is assumed FLOAT.
#
#	Gather some statistics for CREATE TABLE:
#		- maximum value to compute desired column length
#		- detect if the values are really floating point
#
sub data_row
{
	my $self	= shift;
	my $dsname	= shift;
	my $row		= shift;

	for (my $i=0; $i<= $#{$row}; $i++) {
		if (defined $$row[$i]) {
			if ($self->{TRX}{$dsname}{CTYPES}[$i] == 2) {	# Character data
				$$row[$i] =~ s/'+/''/g;	# Escape quotes. '
				$$row[$i] = '\''.$$row[$i].'\'';
			} else {					# Numeric data
			    unless (defined ($self->{TRX}{$dsname}{VAR}[$i]{MAX}) &&
			    $self->{TRX}{$dsname}{VAR}[$i]{MAX}>= abs($$row[$i])) {
				    $self->{TRX}{$dsname}{VAR}[$i]{MAX} = abs($$row[$i])
			    }
			    $self->{TRX}{$dsname}{VAR}[$i]{FLOAT} = 1
				if (index($$row[$i],'.') >= 0);
			}
		} else {
			$$row[$i] = 'NULL';
		}
	}
	print { $self->{DATASET} } '('. join(',', @{ $row }),"),\n";
}

#
#	Make CREATE TABLE constructs
#
sub data_description
{
	my $self	= shift;
	my @dd;

	foreach my $tbl (keys %{$self->{TRX}}) {
		print { $self->{STRUCT} } "CREATE TABLE $tbl (\n\t";
		@dd = ();
		foreach my $var (@{ $self->{TRX}{$tbl}{VAR} }) {
			push @dd, $var->{NNAME} . length($var->{NNAME}) < 8 ? "\t\t" : "\t".
				( $var->{NTYPE} == 2 ? 'CHAR(' . $var->{NLNG} .')' :
					$var->{FLOAT} ? 'REAL' : 
					'INTEGER('.length($var->{MAX}).')'
					 )
		}
		print { $self->{STRUCT} } join(",\n\t", @dd), "\n);\n";
	}
}

1;

__END__

=head1 NAME

SAS::TRX::MySQL - Format TRX-learned structure and data into MySQL dialect.

=head1 SYNOPSIS

  use SAS::TRX::MySQL;

  my $trx = new SAS::TRX::MySQL DATASET=>'trx_insert.sql', STRUCT=>'trx_dd.sql';
  $trx->load('source.trx');

=head1 DESCRIPTION


Parses 'source.trx' and splits onto DATASET and STRUCT files. Make sure you have
write access permission to the destination files. INSERT is in packed format like

    INSERT INTO DATA_TABLE (COLUMN1, COLUMN2, ...) VALUES
    (VALUE1, VALUE2, ...),
    (VALUE1, VALUE2, ...),
    ...
    (VALUE1, VALUE2, ...);

=head1 SEE ALSO

SAS::TRX for the base class


=head1 AUTHOR

Alexander Kuznetsov, <acca (at) cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Alexander Kuznetsov

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.


=cut
