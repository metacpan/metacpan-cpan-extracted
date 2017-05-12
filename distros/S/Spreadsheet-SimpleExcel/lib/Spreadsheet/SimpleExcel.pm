package Spreadsheet::SimpleExcel;

# ABSTRACT: Create Excel files with Perl

use 5.006;
use strict;
use warnings;

use Spreadsheet::WriteExcel;
use IO::Scalar;
use IO::File;
use XML::Writer;

our $VERSION     = '1.92';
our $errstr      = '';

sub new{
  my ($class,%opts) = @_;
  my $self = {};
  $self->{worksheets} = $opts{-worksheets} || [];
  $self->{type}       = 'application/vnd.ms-excel';
  $self->{BIG}        = $opts{-big}        || 0;
  $self->{FILE}       = $opts{-filename}   || '';
  bless($self,$class);
  
  for my $sheet( @{ $self->{worksheets} } ){
      if( length($sheet->[0]) > 31 ){
          warn "length of worksheet name is greater than 31. It is truncated...";
          $sheet->[0] = substr $sheet->[0], 0, 30;
      }
  }
  
  $self->_last_sheet('');
  
  return $self;
}# end new

sub current_sheet{
    my ($self) = @_;
    return $self->_last_sheet;
}

sub add_worksheet{
    my ($self,@array) = @_;
    my ($package,$filename,$line) = caller();
    unless(defined $array[0]){
        $errstr = qq~No worksheet defined at Spreadsheet::SimpleExcel add_worksheet() from
            $filename line $line\n~;
        $array[0] = 'unknown' unless defined $array[0];
        return undef;
    }

    if( length( $array[0] ) > 31 ){
        $errstr = qq~Length of worksheet name has be at most 31~;
        return undef;
    }
  
    $self->_last_sheet($array[0]);
  
    if(grep{$_->[0] eq $array[0]}@{$self->{worksheets}}){
        $errstr = qq~Duplicate worksheet-title at Spreadsheet::SimpleExcel add_worksheet() from
            $filename line $line\n~;
        return undef;
    }
    push(@{$self->{worksheets}},[@array]);
    return 1;
}# end add_worksheet

sub _last_sheet{
    my ($self,$title) = @_;
    
    $self->{last_sheet} = $title if defined $title;
    
    return $self->{last_sheet};
}

sub del_worksheet{
    my ($self,$title) = @_;
    my ($package,$filename,$line) = caller();
  
    $title = $self->_last_sheet unless defined $title;
    $self->_last_sheet( $title );
  
    unless(defined $title){
        $errstr = qq~No worksheet-title defined at Spreadsheet::SimpleExcel del_worksheet() from
            $filename line $line\n~;
        return undef;
    }
    my @worksheets = grep{$_->[0] ne $title}@{$self->{worksheets}};
    $self->{worksheets} = [@worksheets];
}# end del_worksheet

sub add_row{
    my ($self,$title,$arref,$props) = @_;
    my ($package,$filename,$line) = caller();
  
    if(ref $title eq 'ARRAY'){
        $props  = $arref;
        $arref  = $title;
        $title  = $self->_last_sheet;
    }
  
    $title = $self->_last_sheet unless $title;
    $self->_last_sheet( $title );
  
    unless(grep{$_->[0] eq $title}@{$self->{worksheets}}){
        $errstr = qq~Worksheet $title does not exist at Spreadsheet::SimpleExcel add_row() from
            $filename line $line\n~;
        return undef;
    }
    unless(ref($arref) eq 'ARRAY'){
        $errstr = qq~Is not an arrayref at Spreadsheet::SimpleExcel add_row() from
            $filename line $line\n~;
        return undef;
    }
    foreach my $worksheet(@{$self->{worksheets}}){
        if($worksheet->[0] eq $title){
            push(@{$worksheet->[1]->{'-data'}},$arref);
            last;
        }
    }
    return 1;
}# end add_data

sub set_headers{
    my ($self,$title,$arref,$props) = @_;
    my ($package,$filename,$line) = caller();
  
    if(ref $title eq 'ARRAY'){
        $props  = $arref;
        $arref  = $title;
        $title  = $self->_last_sheet;
    }
  
    $title ||= $self->_last_sheet;
    $self->_last_sheet( $title );
    
    unless(grep{$_->[0] eq $title}@{$self->{worksheets}}){
        $errstr = qq~Worksheet $title does not exist at Spreadsheet::SimpleExcel set_headers() from
            $filename line $line\n~;
        return undef;
    }
    unless(ref($arref) eq 'ARRAY'){
        $errstr = qq~Is not an arrayref at Spreadsheet::SimpleExcel set_headers() from
            $filename line $line\n~;
        return undef;
    }
    foreach my $worksheet(@{$self->{worksheets}}){
        if($worksheet->[0] eq $title){
            $worksheet->[1]->{'-headers'} = $arref;
            last;
        }
    }
    return 1;
}# end add_headers

sub set_headers_format{
    my ($self,$title,$arref) = @_;
    my ($package,$filename,$line) = caller();
  
    if(ref $title eq 'ARRAY'){
        $arref = $title;
        $title = $self->_last_sheet;
    }
  
    $title = $self->_last_sheet unless defined $title;
    $self->_last_sheet( $title );
  
    unless(grep{$_->[0] eq $title}@{$self->{worksheets}}){
        $errstr = qq~Worksheet $title does not exist at Spreadsheet::SimpleExcel set_headers_format() from
            $filename line $line\n~;
        return undef;
    }
    unless(ref($arref) eq 'ARRAY'){
        $errstr = qq~Is not an arrayref at Spreadsheet::SimpleExcel set_headers_format() from
            $filename line $line\n~;
        return undef;
    }
    foreach my $worksheet(@{$self->{worksheets}}){
        if($worksheet->[0] eq $title){
            $worksheet->[1]->{'-headers_format'} = $arref;
            last;
        }
    }
    return 1;
}# end add_headers

sub set_data_format{
    my ($self,$title,$arref) = @_;
    my ($package,$filename,$line) = caller();
  
    if(ref $title eq 'ARRAY'){
        $arref = $title;
        $title = $self->_last_sheet;
    }
  
    $title = $self->_last_sheet unless defined $title;
    $self->_last_sheet( $title );
    
    unless(grep{$_->[0] eq $title}@{$self->{worksheets}}){
        $errstr = qq~Worksheet $title does not exist at Spreadsheet::SimpleExcel set_data_format() from
            $filename line $line\n~;
        return undef;
    }
    unless(ref($arref) eq 'ARRAY'){
        $errstr = qq~Is not an arrayref at Spreadsheet::SimpleExcel set_data_format() from
            $filename line $line\n~;
        return undef;
    }
    foreach my $worksheet(@{$self->{worksheets}}){
        if($worksheet->[0] eq $title){
            $worksheet->[1]->{'-data_format'} = $arref;
            last;
        }
    }
    return 1;
}# end add_headers

sub add_row_at{
    my ($self,$title,$index,$arref,$props) = @_;
    my ($package,$filename,$line) = caller();
  
    if(ref $index eq 'ARRAY'){
        $props = $arref;
        $arref = $index;
        $index = $title;
        $title = $self->_last_sheet;
    }
  
    $title = $self->_last_sheet unless defined $title;
    $self->_last_sheet( $title );
  
    unless(grep{$_->[0] eq $title}@{$self->{worksheets}}){
        $errstr = qq~Worksheet $title does not exist at Spreadsheet::SimpleExcel add_row_at() from
            $filename line $line\n~;
        return undef;
    }
    unless(ref($arref) eq 'ARRAY'){
        $errstr = qq~Is not an arrayref at Spreadsheet::SimpleExcel add_row() from
            $filename line $line\n~;
        return undef;
    }
    foreach my $worksheet(@{$self->{worksheets}}){
        if($worksheet->[0] eq $title){
            my @array = @{$worksheet->[1]->{'-data'}};
            if($index =~ /[^\d]/ || $index > $#array){
                $errstr = qq~Index not in Array at Spreadsheet::SimpleExcel add_row_at() from
                    $filename line $line\n~;
                return undef;
            }
            splice(@array,$index,0,$arref);
            $worksheet->[1]->{'-data'} = \@array;
            last;
        }
    }
    return 1;
}# end add_row_at

sub sort_data{
    my ($self,$title,$index,$type) = @_;
    my ($package,$filename,$line) = caller();
  
    if(scalar @_ == 1){
        $errstr = qq~at least column index is missing ($filename line $line)~;
        return undef;
    }
    elsif(scalar @_ == 2){
        if($title =~ /\D/){
            $errstr = qq~Index not in Array at Spreadsheet::SimpleExcel sort_data() from
                $filename line $line\n~;
            return undef;
          
        }
        else{
            $index = $title;
            $title = $self->_last_sheet;
        }
    }
    elsif(scalar @_ == 3){
        if($title =~ /^\d+$/ and $index =~ /^ASC|DESC$/){
            $type  = $index;
            $index = $title;
            $title = $self->_last_sheet;
        }
    }
  
    $title = $self->_last_sheet unless defined $title;
    $type  ||= 'ASC';
    
    $self->_last_sheet( $title );
  
    unless(grep{$_->[0] eq $title}@{$self->{worksheets}}){
        $errstr = qq~Worksheet $title does not exist at Spreadsheet::SimpleExcel sort_data() from
            $filename line $line\n~;
        return undef;
    }
  
    foreach my $worksheet(@{$self->{worksheets}}){
        if($worksheet->[0] eq $title){
            $worksheet->[1]->{sortstring} = '' unless(exists $worksheet->[1]->{sortstring});
            my $join = $worksheet->[1]->{sortstring} =~ /\w/ ? ' || ' : '';
            my @array = @{$worksheet->[1]->{'-data'}};
            last unless(scalar(@array) > 0);
            if($index >= scalar(@{$array[0]})){
                $errstr = qq~Index not in Array at Spreadsheet::SimpleExcel sort_data() from
                    $filename line $line\n~;
                return undef;
            }
            if(not defined $index || $index =~ /\D/){
                $errstr = qq~Index not in Array at Spreadsheet::SimpleExcel sort_data() from
                    $filename line $line\n~;
                return undef;
            }
            if(_is_numeric(\@array,$index)){
                if($type && $type eq 'DESC'){
                    $worksheet->[1]->{sortstring} .= "$join \$b->[$index] <=> \$a->[$index]";
                }
                else{
                    $worksheet->[1]->{sortstring} .= "$join \$a->[$index] <=> \$b->[$index]";
                }
            }
            else{
                if($type && $type eq 'DESC'){
                    $worksheet->[1]->{sortstring} .= "$join \$b->[$index] cmp \$a->[$index]";
                }
                else{
                    $worksheet->[1]->{sortstring} .= "$join \$a->[$index] cmp \$b->[$index]";
                }
            }
            last;
        }
    }
    return 1;
}# end sort_data

sub reset_sort{
    my ($self,$title) = @_;
    my ($package,$filename,$line) = caller();
    
    $title = $self->_last_sheet unless defined $title;
    $self->_last_sheet( $title );
    
    unless(grep{$_->[0] eq $title}@{$self->{worksheets}}){
        $errstr = qq~Worksheet $title does not exist at Spreadsheet::SimpleExcel add_row_at() from
            $filename line $line\n~;
        return undef;
    }
    my (@worksheets) = grep{$_->[0] eq $title}@{$self->{worksheets}};
    for my $sheet(@worksheets){
        $sheet->[1]->{sortstring} = '';
    }
}# reset_sort

sub errstr{
    return $errstr;
}# end errstr

sub sort_worksheets{
    my ($self,$type) = @_;
    $type ||= 'ASC';
    
    my @title_array = map{$_->[0]}@{$self->{worksheets}};
    if( _is_title_numeric(\@title_array) ){
        @{$self->{worksheets}} = sort{$a->[0] <=> $b->[0]}@{$self->{worksheets}};
    }
    else{
        @{$self->{worksheets}} = sort{$a->[0] cmp $b->[0]}@{$self->{worksheets}};
    }
    @{$self->{worksheets}} = reverse(@{$self->{worksheets}}) if($type && $type eq 'DESC');
    return @{$self->{worksheets}};
}# end sort_worksheets

sub _is_numeric{
    my ($arref,$index) = @_;
    foreach(@$arref){
        return 0 if($_->[$index] =~ /[^\d\.]/);
    }
    return 1;
}# end _is_numeric


sub _is_title_numeric{
    my ($arref,$index) = @_;
    foreach(@$arref){
        return 0 if($_ =~ /[^\d\.]/);
    }
    return 1;
}# end _is_numeric

sub _do_sort{
  my ($worksheet) = @_;
  my @array = @{$worksheet->[1]->{'-data'}};
  if(exists  $worksheet->[1]->{sortstring} && 
     defined $worksheet->[1]->{sortstring} && 
             $worksheet->[1]->{sortstring} =~ /\w/){
    $worksheet->[1]->{-data} = [sort{eval($worksheet->[1]->{sortstring})}@array];
  }
}# _do_sort

sub output{
  my ($self,$lines) = @_;
  my ($package,$filename,$line) = caller();
  $lines ||= 32000;
  $lines =~ s/\D//g;
  my $excel = $self->_make_excel($lines);
  unless(defined $excel){
    $errstr = qq~Could not create Spreadsheet at Spreadsheet::SimpleExcel output() from
         $filename line $line\n~;
    return undef;
  }
  print "Content-type: ".$self->{type}."\n\n",
        $excel;
}# end output

sub output_as_string{
  my ($self,$lines) = @_;
  my ($package,$filename,$line) = caller();
  $lines ||= 32000;
  $lines =~ s/\D//g;
  my $excel = $self->_make_excel($lines);
  unless(defined $excel){
    $errstr = qq~Could not create Spreadsheet at Spreadsheet::SimpleExcel output_to_file() from
        $filename line $line\n~;
    return undef;
  }
  return $excel;
}# end output_as_string

sub output_to_file{
  my ($self,$filename,$lines) = @_;
  my ($package,$file,$line) = caller();
  $lines ||= 32000;
  $lines =~ s/\D//g;
  unless($filename){
    if($self->{FILE}){
        $filename = $self->{FILE};
    }
    else{
        $errstr = qq~No filename specified at Spreadsheet::SimpleExcel output_to_file() from
            $file line $line\n~;
        return undef;
    }
  }
  #$filename =~ s/[^A-Za-z0-9_\.\/]//g; #/
  my $excel = $self->_make_excel($lines);
  unless(defined $excel){
    $errstr = qq~Could not create $filename at Spreadsheet::SimpleExcel output_to_file() from
        $file line $line\n~;
    return undef;
  }
  open(EXCEL,">$filename") or die $!;
  binmode EXCEL;
  print EXCEL $excel;
  close EXCEL;
  return 1;
}# end output_to_file

sub output_to_XML{
  my ($self,$filename) = @_;
  my ($package,$file,$line) = caller();
  unless($filename){
    $errstr = qq~No filename specified at Spreadsheet::SimpleExcel output_to_XML() from
        $file line $line\n~;
    return undef;
  }
  unless(scalar(@{$self->{worksheets}}) >= 1){
    $errstr = qq~No worksheets in Spreadsheet~;
    return undef;
  }
  
  my $fh = IO::File->new(">$filename");
  my $xml = XML::Writer->new(OUTPUT => $fh, DATA_MODE => 1, DATA_INDENT => 2);
  $xml->xmlDecl('UTF-8','yes');
  $xml->startTag('workbook');
  for my $worksheet(@{$self->{worksheets}}){
    my $name = $worksheet->[0];
    $name =~ s~[^\w]~_~g;
    $xml->startTag($name);
    
    my @headers;
    my @datasets = @{$worksheet->[1]->{-data}};
    if(exists $worksheet->[1]->{-headers}){
      @headers = (@{$worksheet->[1]->{-headers}});
      for(@headers){
        s~[^\w]~_~g; 
      }
    }
    else{
      my $var = 'A';
      for(0..scalar(@{$datasets[0]})-1){
        ++$var;
        push(@headers,$var);
      }
    }
    my $row = 0;
    for my $data(@datasets){
      $xml->startTag('Row'.(++$row));
      for my $i(0..scalar(@$data)-1){
        $xml->startTag($headers[$i]);
        $xml->characters($data->[$i]);
        $xml->endTag($headers[$i]);
      }
      $xml->endTag('Row'.$row);
    }
    
    $xml->endTag($name);
  }
  $xml->endTag('workbook');
  $xml->end();
  $fh->close();
}# output_to_XML

sub _make_excel{
  my ($self,$nr_of_lines) = @_;
  my ($package,$filename,$line) = caller();
  my $c_lines = $nr_of_lines || 32000;
  unless(scalar(@{$self->{worksheets}}) >= 1){
    $errstr = qq~No worksheets in Spreadsheet~;
    return undef;
  }
  my $output;
  tie(*XLS,'IO::Scalar',\$output);
  my $excel;
  unless($excel = new Spreadsheet::WriteExcel(\*XLS)){
    $errstr = qq~Could not create spreadsheet object ($!) from
        $filename line $line~;
    return undef;
  }
  if($self->{BIG}){
    eval{require Spreadsheet::WriteExcel::Big};
    if($@){
      $errstr = $@;
      return undef;
    }
    unless($excel = new Spreadsheet::WriteExcel::Big(\*XLS)){#$fname)){
      $errstr = qq~Could not create spreadsheet object ($!) from
          $filename line $line~;
      return undef;
    }
  }
  #else{
    my @titles = map{$_->[0]}@{$self->{worksheets}};
    foreach my $worksheet(@{$self->{worksheets}}){
      my $sheet = $excel->addworksheet($worksheet->[0]);
      _do_sort($worksheet);
      my $col  = 0;
      my $row  = 0;
      my $page = 2;
      _header2sheet($sheet,$worksheet->[1]->{-headers},$worksheet->[1]->{-headers_format});
      $row++ if(exists $worksheet->[1]->{'-headers'} && scalar(@{$worksheet->[1]->{'-headers'}}) > 0);
      foreach my $data(@{$worksheet->[1]->{-data}}){
        $col = 0;
        if($row >= $c_lines){
          my $title = $worksheet->[0].'_p'.$page;
          while(grep{$_ eq $title}@titles){
            $page++;
            $title = $worksheet->[0].'_p'.$page;
          }
          push(@titles,$title);
          $sheet = $excel->addworksheet($title);
          $row = 0;
          if(scalar(@{$worksheet->[1]->{'-headers'}}) > 0){
            $row = 1;
            _header2sheet($sheet,$worksheet->[1]->{-headers},$worksheet->[1]->{-headers_format});
          }
        }
        my $formatref = $worksheet->[1]->{-data_format};
        foreach my $value(@$data){
          if(defined $formatref && defined $formatref->[$col]){
            if($formatref->[$col] eq 's'){
              $sheet->write_string($row,$col,$value);
            }
            elsif($formatref->[$col] eq 'n'){
              $sheet->write_number($row,$col,$value);
            }
            else{
              $sheet->write($row,$col,$value);
            }
          }
          #elsif($value =~ /^=/){
          #  $sheet->write_string($row,$col,$value);
          #}
          else{
            $sheet->write($row,$col,$value);
          }
          $col++;
        }
        $row++;
      }
    }
    $excel->close();
  #}
  return $output;
}# end _make_excel

sub _header2sheet{
  my ($sheet,$arref,$formatref) = @_;
  my $col = 0;
  foreach(@$arref){
    unless(defined $formatref && defined $formatref->[$col]){
      $sheet->write(0,$col,$_);
    }
    else{
      if($formatref->[$col] eq 's'){
        $sheet->write_string(0,$col,$_);
      }
      elsif($formatref->[$col] eq 'n'){
        $sheet->write_number(0,$col,$_);
      }
      else{
        $sheet->write(0,$col,$_);
      }
    }
    $col++;
  }
}# end _header2sheet

sub sheets{
    my ($self) = @_;
    my @titles = map{$_->[0]}@{$self->{worksheets}};
    return wantarray ? @titles : \@titles;
}# end sheets

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Spreadsheet::SimpleExcel - Create Excel files with Perl

=head1 VERSION

version 1.92

=head1 SYNOPSIS

  use Spreadsheet::SimpleExcel;

  binmode(\*STDOUT);
  # data for spreadsheet
  my @header = qw(Header1 Header2);
  my @data   = (['Row1Col1', 'Row1Col2'],
                ['Row2Col1', 'Row2Col2']);

  # create a new instance
  my $excel = Spreadsheet::SimpleExcel->new();

  # add worksheets
  $excel->add_worksheet('Name of Worksheet',{-headers => \@header, -data => \@data});
  $excel->add_worksheet('Second Worksheet',{-data => \@data});
  $excel->add_worksheet('Test');

  # add a row into the middle
  $excel->add_row_at('Name of Worksheet',1,[qw/new row/]);

  # sort data of worksheet - ASC or DESC
  $excel->sort_data('Name of Worksheet',0,'DESC');

  # remove a worksheet
  $excel->del_worksheet('Test');

  # sort worksheets
  $excel->sort_worksheets('DESC');

  # create the spreadsheet
  $excel->output();

  # print sheet-names
  print join(", ",$excel->sheets()),"\n";

  # get the result as a string
  my $spreadsheet = $excel->output_as_string();

  # print result into a file and handle error
  $excel->output_to_file("my_excel.xls") or die $excel->errstr();
  $excel->output_to_file("my_excel2.xls",45000) or die $excel->errstr();

  ## or

  # data
  my @data2  = (['Row1Col1', 'Row1Col2'],
                ['Row2Col1', 'Row2Col2']);

  my $worksheet = ['NAME',{-data => \@data2}];
  # create a new instance
  my $excel2    = Spreadsheet::SimpleExcel->new(-worksheets => [$worksheet]);

  # add headers to 'NAME'
  $excel2->set_headers('NAME',[qw/this is a test/]);
  # append data to 'NAME'
  $excel2->add_row('NAME',[qw/new row/]);

  $excel2->output();
  
  $excel2->output_to_XML('test.xml');

=head1 DESCRIPTION

Spreadsheet::SimpleExcel simplifies the creation of excel-files in the web. It does
provide simple cell-formats, but only three types of formats (to keep the module simple).

=head1 METHODS

Added in version 1.4:

If you want a method to do the functionality for the last inserted worksheet
(current sheet), you don't have to pass the title as a parameter for the method.

So now you can do something like this:

  $excel->add_worksheet("Test");
  $excel->add_row(\@data);
  $excel->sort_date($column_idx);

This leads to more usability.

=head2 new

  # create a new instance
  my $excel = Spreadsheet::SimpleExcel->new();

  # or

  my $worksheet = ['NAME',{-data => ['This','is','an','Test']}];
  my $excel2    = Spreadsheet::SimpleExcel->new(-worksheets => [$worksheet]);

  # to create a file
  my $filename = 'test.xls';
  my $excel = Spreadsheet::SimpleExcel->new(-filename => $filename);
  
  #if a file > 7 MB should be created
  $excel = Spreadsheet::SimpleExcel->new(-big => 1);

If -big is set to true, Spreadsheet::WriteExcel::Big is required!

=head2 add_worksheet

  # add worksheets
  $excel->add_worksheet('Name of Worksheet',{-headers => \@header, -data => \@data});
  $excel->add_worksheet('Second Worksheet',{-data => \@data});
  $excel->add_worksheet('Test');

The first parameter of this method is the name of the worksheet and the second one is
a hash with (optional) information about the headlines and the data.
No duplicate worksheets allowed.

=head2 del_worksheet

  # remove a worksheet
  $excel->del_worksheet('Test');

Deletes all worksheets named like the first parameter

=head2 add_row

  # append data to 'NAME'
  $excel->add_row('NAME',[qw/new row/]);

Adds a new row to the worksheet named 'NAME'

=head2 add_row_at

  # add a row into the middle
  $excel->add_row_at('Name of Worksheet',1,[qw/new row/]);

This method inserts a row into the existing data

=head2 sort_data

  # sort data of worksheet - ASC or DESC
  $excel->sort_data('Name of Worksheet',0,'DESC');

sort_data sorts the rows. All sorts for one worksheet are combined, so 

  $excel->sort_data('Name of Worksheet',0,'DESC');
  $excel->sort_data('Name of Worksheet',1,'ASC');

will sort the column 0 first and then (within this sorted data) the
column 1.

=head2 reset_sort

  $excel->reset_sort('Name of Worksheet');

The data won't be sorted, the data are in original order instead.

=head2 set_headers

  # add headers to 'NAME'
  $excel->set_headers('NAME',[qw/this is a test/]);

set the headers for the worksheet named 'NAME'

=head2 errstr

returns error message.

=head2 sort_worksheets

  # sort worksheets
  $excel->sort_worksheets('DESC');

sorts the worksheets in DESCending or ASCending order.

=head2 output

  $excel2->output();

prints the worksheet to the STDOUT and prints the Mime-type 'application/vnd.ms-excel'.

=head2 output_as_string

  # get the result as a string
  my $spreadsheet = $excel->output_as_string();

returns a string that contains the data in excel-format

=head2 output_to_file

  # print result into a file [output_to_file(<filename>,<lines>)]
  $excel->output_to_file("my_excel.xls");
  $excel->output_to_file("my_excel2.xls",45000) or die $excel->errstr();

prints the data into a file.
The data will be printed into more worksheets, if the number of rows is greater than <lines> (default 32000).

=head2 output_to_XML

  $excel2->output_to_XML('test.xml');

prints the data into a XML file.

=head2 sheets

  $ref = $excel->sheets();
  @names = $excel->sheets();

In listcontext this subroutines returns a list of the names of sheets that are in $excel, in
scalar context it returns a reference on an Array.

=head2 set_headers_format

  # set formats for headers of 'NAME'
  # first col 'string', second col 'number', third col default format, fourth col 'number'
  $excel2->set_headers_format('NAME',['s','n',undef,'n']);

sets the headers formats for a specified worksheet. If formats are commited, the default
format is set. Default format is set by Spreadsheet::WriteExcel

=head2 set_data_format

  # set formats for headers of 'NAME'
  # first col 'string', second col 'number', third col default format, fourth col 'number'
  $excel2->set_data_format('NAME',['s','n',undef,'n']);

sets the data formats for a specified worksheet. If formats are commited, the default
format is set. Default format is set by Spreadsheet::WriteExcel

=head2 current_sheet

  $excel->add_worksheet('Testtitle');
  print $excel->current_sheet;

returns the title of the current worksheet.

=head1 EXAMPLES

=head2 PRINT ON STDOUT

  #! /usr/bin/perl

  use strict;
  use warnings;
  use Spreadsheet::SimpleExcel;

  binmode(\*STDOUT);
  # data for spreadsheet
  my @header = qw(Header1 Header2);
  my @data   = (['Row1Col1', 'Row1Col2'],
                ['Row2Col1', 'Row2Col2']);

  # create a new instance
  my $excel = Spreadsheet::SimpleExcel->new();

  # add worksheets
  $excel->add_worksheet('Name of Worksheet',{-headers => \@header, -data => \@data});
  $excel->add_worksheet('Second Worksheet',{-data => \@data});
  $excel->add_worksheet('Test');

  # add a row into the middle
  $excel->add_row_at('Name of Worksheet',1,[qw/new row/]);

  # sort data of worksheet - ASC or DESC
  $excel->sort_data('Name of Worksheet',0,'DESC');

  # remove a worksheet
  $excel->del_worksheet('Test');

  # create the spreadsheet
  $excel->output();

=head2 RECEIVE DATA AS A SCALAR

  #!/usr/bin/perl

  use strict;
  use warnings;
  use Spreadsheet::SimpleExcel;

  # data
  my @data2  = (['Row1Col1', 'Row1Col2'],
                ['Row2Col1', 'Row2Col2']);

  my $worksheet = ['NAME',{-data => \@data2}];
  # create a new instance
  my $excel2    = Spreadsheet::SimpleExcel->new(-worksheets => [$worksheet]);

  # add headers to 'NAME'
  $excel2->set_headers('NAME',[qw/this is a test/]);
  # append data to 'NAME'
  $excel2->add_row('NAME',[qw/new row/]);

  # receive as string
  my $string = $excel2->output_as_string();

=head2 PRINT INTO FILE

  #! /usr/bin/perl

  use strict;
  use warnings;
  use Spreadsheet::SimpleExcel;

  # data
  my @data2  = (['Row1Col1', 'Row1Col2'],
                ['Row2Col1', 'Row2Col2']);

  my $worksheet = ['NAME',{-data => \@data2}];
  # create a new instance
  my $excel2    = Spreadsheet::SimpleExcel->new(-worksheets => [$worksheet]);

  # add headers to 'NAME'
  $excel2->set_headers('NAME',[qw/this is a test/]);
  # append data to 'NAME'
  $excel2->add_row('NAME',[qw/new row/]);

  # print into file
  $excel2->output_to_file("my_excel.xls");

=head2 PRINT INTO FILE (break worksheets)

  #! /usr/bin/perl

  use strict;
  use warnings;
  use Spreadsheet::SimpleExcel;

  # create a new instance
  my $excel    = Spreadsheet::SimpleExcel->new();

  my @header = qw(Header1 Header2);
  my @data   = (['Row1Col1', 'Row1Col2'],
                ['Row2Col1', 'Row2Col2']);
  for(0..70000){
    push(@data,[qw/1 2 4 6 8/]);
  }
  # add worksheets
  $excel->add_worksheet('Name of Worksheet',{-headers => \@header, -data => \@data});
  $excel->add_row('Name of Worksheet',[qw/1 2 3 4 5/]);

  # print into file
  $excel->output_to_file("my_excel.xls",10000);

=head1 DEPENDENCIES

This module requires Spreadsheet::WriteExcel and IO::Scalar

=head1 SEE ALSO

Spreadsheet::WriteExcel

IO::Scalar

IO::File

XML::Writer

=head1 AUTHOR

Renee Baecker <reneeb@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by Renee Baecker.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
