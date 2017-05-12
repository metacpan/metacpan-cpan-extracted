package Parse::CSV::Colnames;

=pod

=head1 NAME

Parse::CSV::Colnames - Highly flexible CSV parser including column names (field names) manipulation

=head1 NOTE

This Module derives from L<Parse::CSV> by Adam Kennedy inheriting its methods. 
The main extensions are methods for column names manipulation and some simple method-fixes.  

=head1 SYNOPSIS

Column names manipulation makes only sense if the fields-parameter is auto, i.e. column names are in the first line.

  # Parse a colon-separated variables file  from a handle as a hash
  # based on headers from the first line.
  my $objects = Parse::CSV::Colnames->new(
      handle => $io_handle,
      sep_char   => ';',
      fields     => 'auto',
   # select only rows where column name fieldname is "value"
      filter     => sub { if($_->{fieldname} eq "value") 
                       {$_} else 
                       {undef}
	                }
      );

  # get column names
  my @fn=$objects->colnames
  # you want lower case field names
  @fn=map {lc} @fn;
  # you want field names without blanks 
  @fn=map { s/\s+//g} @fn;
  # set column names
  $objects->colnames(@fn);

  while ( my $object = $objects->fetch ) {
      $object->do_something;
  } 

=head1 DESCRIPTION

This module is only an extension of L<Parse::CSV>

For a detailed description of all methods see L<Parse::CSV>

For a detailed description of the underlying csv-parser see L<Text::CSV_XS>


=cut

use 5.005;
use strict;
use Carp         ();
#use IO::File     ();
#use Text::CSV_XS ();
#use Params::Util qw{ _STRING _ARRAY _HASH0 _CODELIKE _HANDLE };

use Parse::CSV;
our @ISA=("Parse::CSV");

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.07';
}







=pod

=head1 Fixed METHODS

These methods have not work in the parent module L<Parse::CSV> yet, because Adam Kennedy is very busy.

=head2 combine

  $status = $csv->combine(@columns);

The C<combine> method is passed through
to the underlying L<Text::CSV_XS> object. See example 3.

It sets the fields and constructs the corresponding csv string from the arguments. You can read this array with the C<fields> method.

=cut

sub combine {
	shift->{csv_xs}->combine(@_);
}

=pod

=head2 string (deprecated)

  $line = $csv->string;

The C<string> method is passed through
to the underlying L<Text::CSV_XS> object. See example 3 and example 4.

It returns the parsed string or the corresponding combine-setting.

=cut

#sub string {
#	shift->{csv_xs}->string(@_);
#}

=pod

=head2 print

  $status = $csv->print($io, $colref);

The C<print> method is passed through
to the underlying L<Text::CSV_XS> object. See example 1.

It prints the string of the corresponding @$colref directly to an IO handle.


=cut

sub print {
	shift->{csv_xs}->print(@_);
}

=pod

=head1 Added METHODS

=head2 fields (deprecated) 

  @fields = $csv->fields;

The C<fields> method is passed through
to the underlying L<Text::CSV_XS> object. 

It returns the input to C<combine>-method or the actual row as an array.

=cut

#sub fields {
#	shift->{csv_xs}->fields;
#}

=pod

=head2 colnames

  @colnames = $csv->colnames("fn1","fn2") # sets colnames
                  or
  @colnames = $csv->colnames; # gets colnames

The C<colnames> method sets or gets colnames (=C<fields>-param).
So you can rename the colnames (hash-keys in L<Parse::CSV::Colnames> object).

=cut

sub colnames {
	my $self=shift;
	$self->{fields}=$self->{names} if(exists($self->{names})); # quick and dirty
	@{$self->{fields}}=@_ if(@_);
	return @{$self->{fields}};
}

=pod

=head2 pushcolnames

  @colnames = $csv->pushcolnames("fn1","fn2") 

The C<pushcolnames> method adds colnames at the end of $csv->colnames (=C<fields>-param).
You can do that if the C<filter>-method adds some new fields at the end of fields-array in L<Parse::CSV::Colnames> object .
Please consider that these colnames or fields are not 
in the underlying L<Text::CSV_XS> object. See example 1 and example 4.

=cut

sub pushcolnames {
	my $self=shift;
	$self->{fields}=$self->{names} if(exists($self->{names})); # quick and dirty
	push @{$self->{fields}},@_;
	return @{$self->{fields}};
}

=pod

=head2 pushcombine

  @colnames = $csv->pushcombine("fn1","fn2") 

The C<pushcombine> method adds fields at the end of the actual row (=C<fields>-method) and constructs the corresponding csv string. 
You can read the result with the C<fields>-method.
The pushcombine and pushcolnames belong together. See example 4.

=cut

sub pushcombine {
	my $self=shift;
	$self->combine($self->fields,@_);
}

1;

=pod

=head1 EXAMPLES

You can test these examples with copy and paste

=cut

=pod

=head2 Example 1

Using C<< csv->print >>, C<< csv->pushcolnames >>


  #!/usr/bin/perl 

  use strict;
  use warnings;
  use Parse::CSV::Colnames;
  my $fh=\*DATA;
  my $fhout=\*STDOUT; # only for demo
  my $csv = Parse::CSV::Colnames->new(
  			 #file => "testnamen.csv",
  			 handle     => $fh,
  			 sep_char   => ';',
  			 fields     => 'auto',
  			 binary     => 1, # for german umlauts and utf
  			 filter     => sub { $_->{country}="Germany"; 
  				 $_->{product}=$_->{factor1}*$_->{factor2};
  				 # select only rows where column name product>0 
  				 if($_->{product}>0) {
  					 $_;
  				 } else {
  					 undef
  				 }
  			}
  			 );

  # add colnames at the end
  $csv->pushcolnames(qw(product country));
  # get column names
  my @fn=$csv->colnames;
  # you want lower case field names
  @fn=map {lc} @fn;
  # you want field names without blanks
  map { s/\s+//g} @fn;
  # set column names
  $csv->colnames(@fn);

  # headerline for direct output
  $csv->print($fhout,[$csv->colnames]); # print header-line
  print "\n";


  while(my $line=$csv->fetch) {
  	# csv direct output
  	$csv->print($fhout,[$csv->fields,$line->{product},$line->{country}]); # only input-fields are printed with method fields
  	print "\n";
  }

  __DATA__
  Name;Given Name;factor1;factor2
  Hurtig;Hugo;5.4;4.6
  Schnallnichts;Carlo;6.4;4.6
  Weissnich;Carola;7.4;4.6
  Leer;Hinnerk;0;4.6
  Keine Ahnung;Maximilian;8.4;4.6
  
=cut

=pod

=head2 Example 2

Building new fields by hand with map



  #!/usr/bin/perl 

  use strict;
  use warnings;
  use Parse::CSV::Colnames;
  my $fh=\*DATA;
  my $csv = Parse::CSV::Colnames->new(
  			 #file => "testnamen.csv",
  			 handle     => $fh,
  			 sep_char   => ';',
  			 fields     => 'auto',
  			 binary     => 1, # for german umlauts
  			 filter     => sub { $_->{country}="Germany"; 
  				 $_->{product}=$_->{factor1}*$_->{factor2};
  				 # select only rows where column name product>0 
  				 if($_->{product}>0) {
  					 $_;
  				 } else {
  					 undef
  				 }
  			}
  			 );
  #add new fieldname at the end
  $csv->pushcolnames(qw(product));
  # get column names
  my @fn=$csv->colnames;
  # you want lower case field names
  @fn=map {lc} @fn;
  # you want field names without blanks
  map { s/\s+//g} @fn;
  # set column names
  $csv->colnames(@fn);

  # headerline with only 2 fields
  my @outcolnames1=(qw(givenname product));
  print join(";",@outcolnames1) . "\n"; 


  while(my $line=$csv->fetch) {
  	print join(";",map {$line->{$_}} @outcolnames1) . "\n"; 

  }

  __DATA__
  Name;Given Name;factor1;factor2
  Hurtig;Hugo;5.4;4.6
  Schnallnichts;Carlo;6.4;4.6
  Weissnich;Carola;7.4;4.6
  Leer;Hinnerk;0;4.6
  Keine Ahnung;Maximilian;8.4;4.6

=cut


=pod

=head2 Example 3

Using C<< csv->combine >> and C<< csv->string >>


  #!/usr/bin/perl 

  use strict;
  use warnings;
  use Parse::CSV::Colnames;
  my $fh=\*DATA;
  my $csv = Parse::CSV::Colnames->new(
  			 #file => "testnamen.csv",
  			 handle     => $fh,
  			 sep_char   => ';',
  			 fields     => 'auto',
  			 binary     => 1, # for german umlauts
  			 filter     => sub { $_->{country}="Germany"; 
  				 $_->{product}=$_->{factor1}*$_->{factor2};
  				 # select only rows where column name product>0 
  				 if($_->{product}>0) {
  					 $_;
  				 } else {
  					 undef
  				 }
  			}
  			 );
  $csv->pushcolnames(qw(product country));
  # get column names
  my @fn=$csv->colnames;
  # you want lower case field names
  @fn=map {lc} @fn;
  # you want field names without blanks
  map { s/\s+//g} @fn;
  # set column names
  $csv->colnames(@fn);

  # headerline
  my @outcolnames2=(qw(givenname product country));
  $csv->combine(@outcolnames2);
  print $csv->string . "\n";


  while(my $line=$csv->fetch) {
  	# csv output
  	$csv->combine(map {$line->{$_}} @outcolnames2);
  	print $csv->string . "\n";


  }


  __DATA__
  Name;Given Name;factor1;factor2
  Hurtig;Hugo;5.4;4.6
  Schnallnichts;Carlo;6.4;4.6
  Weissnich;Carola;7.4;4.6
  Leer;Hinnerk;0;4.6
  Keine Ahnung;Maximilian;8.4;4.6

=cut


=pod

=head2 Example 4

Using C<< csv->pushcombine >> , C<< csv->pushcolnames >> and C<< csv->string >>


  #!/usr/bin/perl 

  use strict;
  use warnings;
  use Parse::CSV::Colnames;
  my $fh=\*DATA;
  my $csv = Parse::CSV::Colnames->new(
  			 #file => "testnamen.csv",
  			 handle     => $fh,
  			 sep_char   => ';',
  			 fields     => 'auto',
  			 binary     => 1, # for german umlauts
  			 filter     => sub { $_->{country}="Germany"; 
  				 $_->{product}=$_->{factor1}*$_->{factor2};
  				 # select only rows where column name product>0 
  				 if($_->{product}>0) {
  					 $_;
  				 } else {
  					 undef
  				 }
  			}
  			 );
  $csv->pushcolnames(qw(product country));
  # get column names
  my @fn=$csv->colnames;
  # you want lower case field names
  @fn=map {lc} @fn;
  # you want field names without blanks
  map { s/\s+//g} @fn;
  # set column names
  $csv->colnames(@fn);

  # headerline
  $csv->combine($csv->colnames);
  print $csv->string . "\n";


  while(my $line=$csv->fetch) {
  	# csv output
	$csv->pushcombine(map {$line->{$_}} qw(product country));
	# is like
  	$csv->pushcombine($line->{product},$line->{country});
	 
  	print $csv->string . "\n";


  }


  __DATA__
  Name;Given Name;factor1;factor2
  Hurtig;Hugo;5.4;4.6
  Schnallnichts;Carlo;6.4;4.6
  Weissnich;Carola;7.4;4.6
  Leer;Hinnerk;0;4.6
  Keine Ahnung;Maximilian;8.4;4.6

=cut

=pod

=head1 TODO

Creating Methods C<popcolnames> and C<popcombine>. These methods delete the last fieldnames (column names) or fields. (I will add these methods if anybody wants this)

Creating Methods C<(un)shiftcolnames> and C<(un)shiftcombine>. These methods add/delete the first fieldnames (column names) or fields. (I will add these methods if anybody wants this)

Integrating methods C<getline_hr> and C<column_names> of the underlying object L<Text::CSV_XS>.

=head1 SUPPORT

Bugs should always be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Parse-CSV-Colnames>


=head1 AUTHORS

Uwe Sarnowski E<lt>uwes at cpan.orgE<gt>

Author of the parent modul L<Parse::CSV> : Adam Kennedy 


=head1 SEE ALSO

L<Parse::CSV>, L<Text::CSV_XS>

=head1 COPYRIGHT

Copyright 2011 Uwe Sarnowski

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
