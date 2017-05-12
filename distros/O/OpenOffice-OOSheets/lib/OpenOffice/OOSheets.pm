package OpenOffice::OOSheets;

use strict;
use XML::Parser;
#use Data::Dumper;
#use utf8;
our $VERSION = '0.70';
#=========
#use:
#GetData( text=><>,ref=>[
#	{
#	table=>'sheet1',
#	cells=>['B2','AA2','A1','E6','B4','C10','C11']
#	}
#	]
#	)
#==========

sub GetData {
my (%arg)=@_;
our ($ref,$text)=@arg{qw/ref text/};
#Levels,Flags,Variabels
our $number;
our $curr_rec;
our %sonar_cells;
our ($c_row,$c_cell);
our %current;
our $par_text=0;
our %res;
our $n=0;
our %map;
map {$map{$_}=++$n} ('A'..'Z');
our %enumeration_map;

sub A1_2_11 {
my $addr=shift;
my ($X,$Y)=$addr=~m/(\D+)(\d+)/;
my @sym=split("",$X);
my $cell;
 while(my $symbol = shift(@sym)){
	 my $sym_cod = $map{$symbol};
	 $cell += $sym_cod * (26 ** scalar(@sym));
	}
my $res="$Y:$cell";
$enumeration_map{$res}=$addr;
return $res;
}

sub _11_2_A1 {
my $addr=shift;
return $enumeration_map{$addr};
}

sub handle_start {
       
    
	my ($ref_Ex,$name,%attr)=@_;
	next unless $name;
	for ($name) {
	/table:table$/  && (
			    ($curr_rec=(grep {
				
#				my $conv=new Text::Iconv ("utf-8","koi8-r");
#				my $koi_curr=$conv->convert($attr{'table:name'});
#				my $koi_need=$conv->convert($_->{table});
				my $koi_curr=$attr{'table:name'};
				my $koi_need=$_->{table};
				$koi_need =~/$koi_curr$/ ;
				} @$ref )[0])
				&& 
			do {
			$c_row=0;
			@sonar_cells{map {A1_2_11($_)} @{$curr_rec->{cells}}}=();
			1;
			}
			)
		||
	!(ref $curr_rec)  && do {return}
			||
	/table:table-row$/ &&  do {
				$c_row++;$c_cell=0;
				%current=("$c_row:$c_cell",1);
				}
			||
	/table:table-cell$/ && do {
			
			$c_cell++;
			%current=("$c_row:$c_cell",1);
			my $repeat=$attr{'table:number-columns-repeated'};
			if ($repeat){
			map {$current{$_}=1}
				map {"$c_row:".++$c_cell} @{[1..$repeat-1]};
			}
			$c_cell += $attr{'table:number-columns-spanned'}-1 if $attr{'table:number-columns-spanned'};
			}
			||
	/text:p$/ && do {$par_text=1}
	}
}

sub handle_end {
	my ($ref_Ex,$name)=@_;
	$_=$name;
	$curr_rec=undef if /table:table$/;
	$par_text=0 if /text:p$/;
}

sub handle_char {
	my ($ref_Ex,$data)=@_;
	 if ($par_text) {
	 	@{$res{$curr_rec->{table}}}{ map {_11_2_A1($_)} grep {exists $sonar_cells{$_}} keys %current}.=$data ;
	}
}

my $parser=new XML::Parser(Handlers => {
    			Start => sub {&handle_start(@_)},
			End   => sub {&handle_end(@_)},
			Char  => sub {&handle_char(@_)}
			});
$parser->parse ($text);
return \%res;
}

# Preloaded methods go here.

1;
__END__

=head1 NAME OpenOffice::OOSheets

OpenOffice::OOSheets - Perl module for quick access to spreadsheets cells by address and sheets by name.

=head1 SYNOPSIS

  use OpenOffice::OOSheets;

  ...

  my $zip = Archive::Zip->new($tmp_file_name);
  my $content=$zip->contents('content.xml');

  ...

   my $res=OpenOffice::OOSheets::GetData (text=>$content,ref=>
   		 [
                   {
                     'cells' => [
                                'Q46'
                              ],
                     'table' => 'Sheet1'
                   },
                   {
                     'cells' => [
                                'B10'
                              ],
                     'table' => 'Sheet2'
                   }
                 ]);
 ...

 print Dumper $res;
 
 ...

=head1 DESCRIPTION

Perl module for quick access to spreadsheets cells by address and sheets by name.


=head1 PUBLIC METHODS

=item * OpenOffice::OOSheets::GetData - parse and return result

Parametrs :

  (
	text=>$data,
	ref=>[
	   {
	   table=>'sheet1',
	   cells=>['B2','AA2','A1','E6','B4','C10','C11']
	   }
	   ]
	   
    )


Results:

   {
          'Sheet1' => {
                        'Q46' => '21'
                      }
      };


=head1 SEE ALSO

samples/README - for sample

=head1 AUTHOR

Zahatski Aliaksandr, E<lt>zagap@users.sourceforge.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004 by Zahatski Aliaksandr

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.2 or,
at your option, any later version of Perl 5 you may have available.


=cut
