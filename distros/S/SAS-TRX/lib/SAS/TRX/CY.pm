package SAS::TRX::CY;
#
#	Format TRX-learned structure into CSV + YAML
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

	print  { $self->{DATASET} }
		join("\t", $dsname, @{$self->{TRX}{$dsname}{CNAMES}}),
		"+\n";
}

#
#	Create an INSERT line for a given dataset and list of data values
#
sub data_row
{
	my $self	= shift;

	my $dsname	= shift;
	my $row		= shift;

	print { $self->{DATASET} } join("\t", map { defined $_ ? $_ : 'NULL'} @{ $row }), "-\n";
}

use YAML qw/Dump/;

sub data_description
{
	my $self	= shift;

	my %struct;

	foreach my $tbl (keys %{$self->{TRX}}) {
		foreach my $var (@{ $self->{TRX}{$tbl}{VAR} }) {
			push @{ $struct{$tbl} },
				{
				NAME => $var->{NNAME},
				TYPE => $var->{NTYPE} == 1 ? 'NUMBER' : 'CHAR',
				LABEL=> $var->{NLABEL},
				};
		}
	}
	print { $self->{STRUCT} } Dump(\%struct);
}

1;

__END__

=head1 NAME

SAS::TRX::CY - Convert a TRX library into a YAML description and CSV data.

=head1 SYNOPSIS

  use SAS::TRX::CY;

  my $cy = new SAS::TRX::CY DATASET=>'trx.csv', STRUCT=>'trx.yml';
  $cy->load('source.trx');

=head1 DESCRIPTION


Parses 'source.trx' and splits onto DATASET and STRUCT files. Make sure you have
write access permission to the destination files.

YAML defines data types in TRX terms:
    ---
    TABLE_NAME:
	- LABEL: column1 label
	  NAME: column1 name
	  TYPE: CHAR or NUMBER
	- LABEL: column2 label
	  NAME: column2 name
	  TYPE: CHAR or NUMBER

To determine needed column length and distinguish INTEGER and FLOAT, use SAS::TRX::MySQL or SAS::TRX::SQLite.

Each line in CSV file ends with '+' to describe the structure in the following section or '-' to indicate actual
data rows. The '+' line contains the table name followed by column names.

Thus the CSV parser may be like this:

    my ($tbl, @cols, %data);
    while (<>) {
	chomp;
	my $tag = chop;
	if ($tag eq '+') {
	    ($tbl, @cols) = split;
	    next;
	} elsif ($tag eq '-') {
	    @data{@cols} = split;
	    next;
	} else {
	    die 'Format violation';
	}
    }

=head2 EXPORT

Nothing is exported.


=head1 SEE ALSO

    SAS::TRX for the base class
    SAS::TRX::MySQL, SAS::TRX::SQLite for data types

=head1 AUTHOR

Alexander Kuznetsov, <acca (at) cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Alexander Kuznetsov

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.


=cut
