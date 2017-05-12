package Snail::CSV;

use strict;
use Text::CSV_XS;
use IO::File;

use vars qw($VERSION);
$VERSION = '0.07';

sub new
{
	my $class = shift;
	my $this = bless {}, $class;

	$this->{'OPTS'} = shift || {};
	unless ( %{$this->{'OPTS'}} )
	{
		$this->{'OPTS'} = { 'eol' => "\015\012", 'sep_char' => ';', 'quote_char'  => '"', 'escape_char' => '"', 'binary' => 1 };
	}
	return $this;
}

sub setFile
{
	my $this = shift;
	$this->{'FILE'} = shift;
	$this->{'FIELDS'} = shift || [];
	$this->{'FILTER'} = shift || {};

	$this->{'FILE'} or die "Please provide a filename to parse\n";
	-f $this->{'FILE'} or die "Cannot find filename: ". $this->{'FILE'}. "\n";

	return $this;
}

sub fetchall_arrayref
{
	return shift->parse([]);
}

sub fetchall_hashref
{
	return shift->parse({});
}

sub parse
{
	my $this = shift;
	exists($this->{'FILE'}) or die "Please provide a filename to parse\n";
	exists($this->{'CSVXS'}) or $this->_init_csv;

	$this->{'DATA'} = shift || [];
	my $dtype = ref $this->{'DATA'};

	{
		local $/ = $this->{'OPTS'}->{'eol'} || "\015\012";

		my $fh = new IO::File "$this->{'FILE'}", "r";
		if (defined $fh)
		{
			my $NUMB = 1;
			while (my $columns = $this->{'CSVXS'}->getline($fh))
			{
				last unless @{$columns};
				my $tmp = {};
				my $f_flag = 1;
				for (my $j = 0; $j < @{$columns}; $j++)
				{
					my $colname = $this->{'FIELDS'}->[$j] ? $this->{'FIELDS'}->[$j] : "";
					next unless $colname;

					$tmp->{$colname} = $columns->[$j];
					if (exists($this->{'FILTER'}->{$colname}) && ref $this->{'FILTER'}->{$colname} eq 'CODE')
					{
						$f_flag = $this->{'FILTER'}->{$colname}->($tmp->{$colname});
					}
					if (exists($this->{'FILTER'}->{$colname}) && !ref($this->{'FILTER'}->{$colname}))
					{
						$f_flag = $this->{'FILTER'}->{$colname} eq $tmp->{$colname} ? 1 : 0;
					}
				}
				if ($f_flag && $dtype eq 'ARRAY') { $tmp->{'NUMBER'} = $NUMB; push @{$this->{'DATA'}}, $tmp; }
				if ($f_flag && $dtype eq 'HASH') { $this->{'DATA'}->{$NUMB} = $tmp; }
				$NUMB++;
			}
			$fh->close;
		}
	}
	return $this->{'DATA'};
}

sub getData
{
	my $this = shift;
	return exists($this->{'DATA'}) ? $this->{'DATA'} : [];
}

sub setData
{
	my $this = shift;
	$this->{'DATA'} = shift || [];
	return $this;
}

sub update
{
	my $this = shift;
	my $nfile = shift || $this->{'FILE'};
	my $tfile = $nfile . "." . time; # temp file for inplace update - it is bad method for create filename

	if (ref $this->{'DATA'} eq 'ARRAY') { $this->_to_hashref; }
	if (ref $this->{'DATA'} ne 'HASH') { return $this; }
	unless (%{$this->{'DATA'}}) { return $this; }

	{
		local $/ = $this->{'OPTS'}->{'eol'} || "\015\012";

		my $tfh = new IO::File "$tfile", "w";
		if (defined $tfh)
		{
			my $fh = new IO::File "$this->{'FILE'}", "r";
			if (defined $fh)
			{
				my $NUMB = 1;
				while (my $columns = $this->{'CSVXS'}->getline($fh))
				{
					last unless @{$columns};
					unless (exists($this->{'DATA'}->{$NUMB}))
					{
						$this->{'CSVXS'}->combine( @{$columns} );
						print $tfh $this->{'CSVXS'}->string;
						$NUMB++; next;
					}

					for (my $j = 0; $j < @{$columns}; $j++)
					{
						my $colname = $this->{'FIELDS'}->[$j] ? $this->{'FIELDS'}->[$j] : "COLUMNS" . $NUMB;
						if (exists($this->{'DATA'}->{$NUMB}->{$colname}) && $this->{'DATA'}->{$NUMB}->{$colname} ne $columns->[$j])
						{
							$columns->[$j] = $this->{'DATA'}->{$NUMB}->{$colname};
						}
					}

					$this->{'CSVXS'}->combine( @{$columns} );
					print $tfh $this->{'CSVXS'}->string;

					$NUMB++;
				}
				$fh->close;
			}
			$tfh->close;
		}
	}
	rename $tfile, $nfile;
	unlink $tfile;
	return $this;
}

sub save
{
	my $this = shift;
	my $nfile = shift || $this->{'FILE'};
	my $tfile = $nfile . "." . time; # temp file for inplace update - it is bad method for create filename

	if (ref $this->{'DATA'} eq 'ARRAY') { $this->_to_hashref; }
	if (ref $this->{'DATA'} ne 'HASH') { return $this; }
	unless (%{$this->{'DATA'}}) { return $this; }

	{
		local $/ = $this->{'OPTS'}->{'eol'} || "\015\012";

		my $tfh = new IO::File "$tfile", "w";
		if (defined $tfh)
		{

			$this->{'CSVXS'}->combine( @{$this->{'FIELDS'}} );
			print $tfh $this->{'CSVXS'}->string;

			foreach my $nitem (keys %{$this->{'DATA'}})
			{
				my $columns = [];
				for (@{$this->{'FIELDS'}})
				{
					push @{$columns}, exists($this->{'DATA'}->{$nitem}->{$_}) ? $this->{'DATA'}->{$nitem}->{$_} : "";
				}
				$this->{'CSVXS'}->combine( @{$columns} );
				print $tfh $this->{'CSVXS'}->string;
			}
			$tfh->close;
		}
	}
	rename $tfile, $nfile;
	unlink $tfile;
	return $this;
}


sub _to_hashref
{
	my $this = shift;
	my $hash = {};
	while (defined(my $item = shift @{$this->{'DATA'}}))
	{
		next unless exists($item->{'NUMBER'});
		unless (exists($hash->{$item->{'NUMBER'}}))
		{
			$hash->{$item->{'NUMBER'}} = $item;
			delete $hash->{$item->{'NUMBER'}}->{'NUMBER'};
		}
	}
	$this->{'DATA'} = {};
	$this->{'DATA'} = $hash;
	return $this;
}

sub _init_csv
{
	my $this = shift;
	$this->{'CSVXS'} = Text::CSV_XS->new( $this->{'OPTS'} );
	return $this;
}

sub version { return $VERSION; }

1;

=head1 NAME

Snail::CSV - Perl extension for read/write/update CSV files.

=head1 SYNOPSIS

  use Snail::CSV;
  my $csv = Snail::CSV->new(\%args); # %args - Text::CSV_XS options


  my %filter = (
                 'pq'   => 3,
                 'name' => sub { my $name = shift; $name =~ /XP$/ ? 1 : 0; }
               );

  $csv->setFile("lamps.csv", [ "id", "name", "pq" ], \%filter);


    my $lamps = $csv->parse;

    # or

    $csv->parse;
    # some code
    my $lamps = $csv->getData;


  $csv->setFile("tents.csv", [ "id", "name", "brand", "price" ]);


    my $tents = $csv->fetchall_hashref; # $tents is HASHREF
    for my $item (values %{$tents})
    {
      $item->{'price'} = $item->{'brand'} eq 'Marmot' ? 0.95 * $item->{'price'} : $item->{'price'};
    }
    $csv->setData($tents);
    $csv->update; # to tents.csv

    # or

    for my $item ( @{ $csv->fetchall_arrayref } )
    {
      $item->{'price'} = $item->{'brand'} eq 'Marmot' ? 0.95 * $item->{'price'} : $item->{'price'};
    }
    $csv->update("/full/path/to/new_file.csv"); # to new CSV file


=head1 DESCRIPTION

This module can be used to read/write/update data from/to CSV files. L<Text::CSV_XS> is used for parsing CSV files.

=head1 METHOD

=over

=item B<new()>

=item B<new(\%args)>

This is constructor. %args - L<Text::CSV_XS> options. Return object.

=item B<setFile('file.csv', \@fields_name)>

=item B<setFile('file.csv', \@fields_name, \%filter)>

Set CSV file, fields name and filters for fields name. Return object.

Fields and Filters:

  my @fields_name = ("id", "name", "pq");
  my %filter = (
                 'pq'   => 3,
                 'name' => sub { my $name = shift; $name =~ /XP$/ ? 1 : 0; }
               );

=item B<parse>

Read and parse CSV file. Return arrayref.

=item B<fetchall_arrayref>

An alternative to B<parse>. Return arrayref.

=item B<fetchall_hashref>

An alternative to B<parse>. Return hashref.

=item B<getData>

Return current data. Use this method after B<parse> (B<fetchall_arrayref>, B<fetchall_hashref>).

=item B<setData(\@data)>

=item B<setData(\%data)>

Set new data. Return object.

=item B<update>

=item B<update('/full/path/to/new_file.csv')>

Attention! If new file not defined, update current file. Return object.

=item B<save>

=item B<save('/full/path/to/new_file.csv')>

Save current object data. Attention! If new file not defined, save data to current file. Return object.

=item B<version>

Return version number.

=back

=head2 EXPORT

None by default.



=head1 EXAMPLE

=head2 First example.

Code:

  #!/usr/bin/perl -w
  use strict;

  use Snail::CSV;
  use Data::Dumper;

  my $csv = Snail::CSV->new();

    $csv->setFile("lamps.csv", [ "id", "name", "pq" ]);
    # or
    $csv->setFile("lamps.csv", [ "id", "", "pq" ], { 'pq' => sub { my $pq = shift; $pq > 2 ? 1 : 0; } });

  my $lamps = $csv->parse;

  print Dumper($lamps);

lamps.csv

  1;"Tikka Plus";3
  2;"Myo XP";1
  3;"Duobelt Led 8";5

If you wrote:

  $csv->setFile("lamps.csv", [ "id", "name", "pq" ]);

then C<dump> is:

  $VAR1 = [
            {
              'id'   => '1',
              'name' => 'Tikka Plus',
              'pq'   => '3'
            },
            {
              'id'   => '2',
              'name' => 'Myo XP',
              'pq'   => '1'
            },
            {
              'id'   => '3',
              'name' => 'Duobelt Led 8',
              'pq'   => '5'
            }
          ];

but if:

  $csv->setFile("lamps.csv", [ "id", "", "pq" ], { 'pq' => sub { my $pq = shift; $pq > 2 ? 1 : 0; } });

C<dump> is:

  $VAR1 = [
            {
              'id'   => '1',
              'pq'   => '3'
            },
            {
              'id'   => '3',
              'pq'   => '5'
            }
          ];

=head2 Other example.

	Done.


=head1 TODO

Goog idea? Welcome...


=head1 SEE ALSO

L<Text::CSV_XS>, L<IO::File>

=head1 AUTHOR

Dmitriy Dontsov, E<lt>mit@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Dmitriy Dontsov

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut
