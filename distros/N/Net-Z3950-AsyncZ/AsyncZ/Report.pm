# $Date: 2003/12/05 17:02:57 $
# $Revision: 1.6 $ 

our $VERSION = '0.02';
package Net::Z3950::AsyncZ::Report;
use Net::Z3950;
use MARC::Base;

use strict;

my %MARC_FIELDS_STD = (
	"020"=>'ISBN',
        "050"=>"LC call number", 
	100=>'author',
	245=>'title',
	250=>'edition',
	260=>'publication',
	300=>'description',
	440=>'series',
        500=>'note',
	520=>'annotation',
	650=>'subject',
	700=>'auth, illus, ed',
);

my %MARC_FIELDS_XTRA = (
          
	"082"=>'Dewey decimal number',
        240=>'Uniform title',
        246=>'alternate title',
        130=>'main entry',
	306=>'playing time',
        504=>'Bibliography', 
	508=>'creation/production credits',
	510=>'citation/references',
	511=>'participant or performer',
        520=>'Summary,note',
	521=>'target audience',
	530=>'physical form',
	586=>'awards'
);

my %MARC_FIELDS_ALL = (%MARC_FIELDS_STD, %MARC_FIELDS_XTRA);

use vars qw(%MARC_FIELDS);
%MARC_FIELDS = %MARC_FIELDS_STD;

use vars qw($std $xtra $all);
 $std = \%MARC_FIELDS_STD;
 $xtra = \%MARC_FIELDS_XTRA;
 $all = \%MARC_FIELDS_ALL;

{

my $_marc_sep = "MARC";
my $_grs_sep = "GRS-1";
my $_raw_sep = "RAW";
my $_def_sep = "DEFAULT";


sub _get_MARCsep 	{ $_marc_sep; }
sub _get_GRSsep 	{ $_grs_sep; }
sub _get_RAWsep 	{ $_raw_sep; }
sub _get_DEFAULTsep 	{ $_def_sep; }

sub get_MARC_pat 	{  _get_pat (_get_MARCsep()) }
sub get_GRS1_pat	{  _get_pat (_get_GRSsep()) }
sub get_RAW_pat		{  _get_pat (_get_RAWsep()) }
sub get_DEFAULT_pat 	{  _get_pat (_get_DEFAULTsep()) }
sub get_pats		{  get_MARC_pat() . '|' . get_GRS1_pat() . '|' . get_RAW_pat() . '|' . _get_DEFAULTsep()}

sub _get_pat { 
 my ($pat) = @_;
 return '\[' . $pat . '\s\d+\]';
}

}

##
##  params
##      $num_to_fetch: number of records to retrieve in current pass
##      format => undef,       # reference to a callback function that formats each row of a record
##      raw => 0,              # (boolean) if true the raw record data is returned unformatted 
##      start => 1,            # number of the record with which to start report
##      num_to_fetch => 5,     # number of records to include in  a report
##      marc_fields => $std,   # default: $std, others are $xtra or $all
##      marc_xcl => undef,     # reference to hash of MARC fields to exclude from report
##      marc_userdef => undef, # reference to user specified hash of MARC fields for report 	 		
##      marc_subst => undef    # reference to a hash which subtitutes field names for default names	
##      HTML =>0 	        # (boolean) if true use default HTML formatting, 
                        # if false format as plain text
                	# if true each row will be formatted as follows:
                        #    "<tr><td>field name<td>field data\n"     
                        # if false each row will be formatted as follows:
			#    "MARC_field_number  field_name   field_data\n"

## record row priority sequence:  raw, format, HTML, plaintext

##marc_xcl:	the hash values can be in any form, as long as the keys pass
##                the exists test:  if exists $marc_xcl->{ $key }:
 
##                    { '020'=>"", 500=>"", 300=>undef, 520=>'annotation' }

##                 the key is always three digits;
##                 if the first digit is 0, then the key must be enclosed 
##	         in quotation marks
##
## marc_userdef	this allows the user to specify which fields to include in the report
##		and what names are to be used for them	
##
## marc_subst      enables user-defined field names, for instance, where the defualt is:
##			250=>'edition', 650=>'subject'
##                a hash can be specfied with substitutions:
##			{ 250=>'ed.', 650=>'subj.'}
                
		
## marc fields priority sequence:  marc_userdef, marc_fields, marc_xcl, marc_subst
##		This means that
##                   1. marc_userdef will replace marc_fields if marc_userdef exists
##		     2.	marc_xcl will be applied to the hash which results from operation 1
##		     3. marc_subst will be applied to the hash resulting from 1 plus 2 		



#   Internal Params:    
#	$rs: 		record set
#	recnum: 	number of records in record set	
#	result:		  array of record data to be returned (reference)  --
#			  each line in record is treated as array element
#			  except for return of raw data which is pushed
#			  in the format returned from record->render(),
#			  which is itself an array
#

#      options:        a _params object
			  
sub new {
my ($class, $rs, $options) = @_;

  my $self = {
      rs=>$rs,
      recnum=>$rs->size(),
      result=>[],
      format => undef,   
      raw => 0,          
      startrec => 1,        
      marc_fields => $std,
      marc_xcl => undef,    
      marc_userdef => undef, 
      marc_subst => undef,
      HTML =>0, 
      render => 1,		# default is to use record->render() on raw record output
      _this_server => undef,
      _this_pid => undef,
      num_to_fetch => 5     
   };


       my $update = $options->_updateObjectHash($self);
       $self = {%$self,%$update};

       $self->{marc_fields} = $self->{marc_userdef} if defined $self->{marc_userdef};

       if(defined $self->{marc_xcl}) {            
            foreach my $opt(keys %{$self->{marc_fields}}) {
                delete $self->{marc_fields}->{$opt} if exists $self->{marc_xcl}->{$opt};
            }
       }

       if(defined $self->{marc_subst}) { 
            foreach my $opt(keys %{$self->{marc_subst}}) {
                 $self->{marc_fields}->{$opt} = $self->{marc_subst}->{$opt}
                               if defined $self->{marc_subst}->{$opt} 
                                  && defined $self->{marc_fields}->{$opt};
            }
       }

     %MARC_FIELDS = %{$self->{marc_fields}} if $self->{marc_fields};
  
     bless $self, $class;
}


sub reportResult {

my ($self) = @_;
my $rs = $self->{rs};
my $found = 0;
my $numErrors=0;

        my $start = $self->{startrec}; 
        my $num_to_fetch = $self->{startrec} + $self->{num_to_fetch}-1;       



        if($num_to_fetch > $self->{recnum}) {
             $num_to_fetch = $self->{recnum};
             $start = $num_to_fetch - $self->{num_to_fetch};
             $start = 1 if $start < 1;
        }


       $rs->present($start, $num_to_fetch);


        foreach my $i ($start..$num_to_fetch)         {

	    my $rec = $rs->record($i);

	    if (!defined $rec) { 
                if($numErrors > 2) {                  
                   Net::Z3950::AsyncZ::Errors::report_error($rs);
                }
                 $numErrors++;                
                 next;                 
               }

            
	    my $raw = $rec->rawdata(); 

            $found = 1;            

            if ($self->{raw}) {              
               $self->{'render'} ? $self->printRenderedRaw($rec,$i) : $self->printRaw($raw, $i);
            }
	    elsif ($rec->isa('Net::Z3950::Record::GRS1')) { 
      		         # raw data for GRS-1 is reference to Net::Z3950::Record object
	                 $self->printGRS_1($raw, $i); 
	    }
	    elsif ($rec->isa('Net::Z3950::Record::USMARC')) {
                        # raw data for MARC record is string w/o new-lines
	                $self->printMARCRecord($raw, $i);
	    } 
            else {
		# pass in a Net::Z3950::Record which can then call render()
             $self->defaultPrintRec($rec, $i);
            }

	}

  return $found;
}



sub _defaultRecordRowHTML {
  my ($row) = @_;
  return "<tr><td>" . $MARC_FIELDS{$row->[0]} . "<td>" . $row->[1] . "\n";  
}


sub _defaultRecordRow {
  my ($row) = @_;
  return  $row->[0] . "\t" . $MARC_FIELDS{$row->[0]} . ":\t" . $row->[1] . "\n";  
  
}


sub _formatRecordRow {
 my ($self,$row) = @_; 
 my $str;

  if(defined $self->{format}) {
      $str = $self->{format}->($row); 
      chomp $str;  $str .= "\n";   # need nl for splitting into array but only one nl!
  }
  elsif($self->{HTML}) {
        $str = _defaultRecordRowHTML($row);
  }
  else { 
    $str = _defaultRecordRow($row);
  } 

   push(@{$self->{result}},$str);
}

# new record header: [TYPE RECORD_NUMBER], e.g [MARC 1]
sub _newRec {
my($self, $type, $recnum) = @_;
  push(@{$self->{result}}, "<!--" .  $self->{_this_server} . "-->", "\n");
  push(@{$self->{result}}, "<#--" .  $self->{_this_pid} . "-->", "\n");
  push(@{$self->{result}},"[$type $recnum]\n");
}
      
sub defaultPrintRec {
 my $self = shift;
 my $record = shift;
 my $recnum = shift;

 
 my $recString = $record->render();    
 my @recArray = split /\n/, $recString;
 return if scalar @recArray < 2;

 $self->_newRec(_get_DEFAULTsep(), $recnum);
 foreach my $field(@recArray) {
   $field =~ s/[\_\|\$]./ /g;
   $field =~ s/\"//g;      
   my $id;
   if($field =~ /^\(/) {
       $field =~ s/^\(\d+,\s*(\d+)\)\s+//;
       $id = $1;   
   }
   else {
      $field =~ s/^(\d+)\s+\d*//; 
      $id = $1;   
   }
  if($id && exists $MARC_FIELDS{$id}) {
   $self->_formatRecordRow([$id, $field]);
  }
  elsif(!$id) {
       $self->_formatRecordRow(["", $field]);
   }
 }

}


sub printGRS_1 {
 my $self = shift;
 my $record = shift;
 my $recnum = shift;

 $self->_newRec(_get_GRSsep(), $recnum);

# $record is a reference to an array of elements,
# each representing one of the fields of the record. 

 my $recString = $record->render();    
 my @recArray = split /\n/, $recString;

 foreach my $i (1..scalar (@recArray)-1) {
   my $field = $recArray[$i];
   $field =~ s/^\(\d+,\s*(\d+)\)\s+//;
   my $id = $1; 
   if($id && exists $MARC_FIELDS{$id}) {
           $field =~ s/\_./ /g; 
	   $field =~ s/\"//g;     
           $self->_formatRecordRow([$id, $field]);
   }  
		# this is a hack for something that needs
		# a more sophisticated response, one that will acutally read the
		# GRS-1 fields that the Marc tags don't represent
   elsif($id && $self->{marc_fields} != $std) {  
      $field =~ s/\_./ /g;
      $field =~ s/\"//g;     
      push(@{$self->{result}},$field, "\n");
   }
 }


}


sub printRaw {
 my $self = shift;
 my $raw = shift;
 my $recnum = shift;
 $self->_newRec(_get_RAWsep(), $recnum);
 push(@{$self->{result}},$raw);
}


sub printRenderedRaw {
 my $self = shift;
 my $record = shift;
 my $recnum = shift;

 $self->_newRec(_get_RAWsep(), $recnum);
 push(@{$self->{result}},$record->render());
}


sub printMARCRecord {

 my $self = shift;
 my  $record = shift;

 my $recnum = shift;
    my @marc_array = &marc2array ($record);  
 $self->_newRec(_get_MARCsep(), $recnum);

    foreach my $f(@marc_array) {

      next if $f=~ /^LDR/;
      $f=~ s/(\d+)\s+\d*//; 
      my $id = $1;  

      if( exists $MARC_FIELDS{$id}) {
           $f=~ s/\|./ /g;
	   $f=~s/^ +/ /;     
	   $self->_formatRecordRow([$id, $f]);
	 }
    }

}



1;


__END__

=head2  CONSTRUCTOR


  params
      $num_to_fetch: number of records to retrieve in current pass
      format => undef,       # reference to a callback function that formats each row of
                             # a record
      raw => 0,              # (boolean) if true the raw record data is returned unformatted 
      start => 1,            # number of the record with which to start report
      num_to_fetch => 5,     # number of records to include in  a report
      marc_fields => $std,   # default: $std, others are $xtra or $all
      marc_xcl => undef,     # reference to hash of MARC fields to exclude from report
      marc_userdef => undef, # reference to user specified hash of MARC fields for report 	 		
      marc_subst => undef    # reference to a hash which subtitutes field names for default
			     # names	
      HTML =>0 	        # (boolean) if true use default HTML formatting, 
                        # if false format as plain text
                	# if true each row will be formatted as follows:
                        #    "<tr><td>field name<td>field data\n"     
                        # if false each row will be formatted as follows:
			#    "MARC_field_number  field_name   field_data\n"

 record row priority squence:  raw, format, HTML, plaintext

 marc_xcl:	the hash values can be in any form, as long as the keys pass
                the exists test  (if exists $marc_xcl->{ $key }), for instance:
 
                    { '020'=>"", 500=>"", 300=>undef, 520=>'annotation' }

                 the key is always three digits;
                 if the first digit is 0, then the key must be enclosed 
	         in quotation marks

 marc_userdef	this allows the user to specify which fields to include in the
                report and what names are to be used for them	

 marc_subst      enables user-defined field names, for instance, where the 
                 defualt is:
			250=>'edition', 650=>'subject'
                a hash can be specfied with substitutions:
			{ 250=>'ed.', 650=>'subj.'}
                
		
 marc fields priority sequence:  marc_userdef, marc_fields, marc_xcl, marc_subst
		This means that
                     1. marc_userdef will replace marc_fields if marc_userdef exists
		     2.	marc_xcl will be applied to the hash which results from 
			operation 1
		     3. marc_subst will be applied to the hash resulting from 1 plus 2 		

