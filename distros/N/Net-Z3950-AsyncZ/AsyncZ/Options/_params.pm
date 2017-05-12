# $Date: 2003/05/06 00:35:20 $
# $Revision: 1.3 $
package Net::Z3950::AsyncZ::Options::_params;
use Net::Z3950;
use Net::Z3950::AsyncZ::Report;
require Net::Z3950::AsyncZ;
use Carp;
use strict;
use vars '$AUTOLOAD';
{

my @_options = ();
my %_optiondata = (
      pipetimeout=> undef,     # timeout in seconds for each piped process--default 20
      interval => undef,       # timer interval for each piped process--default 5
      format => undef,         # reference to a callback function that formats each row of a record
      HTML => 0, 	       # (boolean) if true use default HTML formatting, if false format as plain text: see Record.pm
      raw => 0, 	       # (boolean) if true the raw record data is returned unformatted 
      startrec => 1,           # number of the record with which to start report
      num_to_fetch => 5,       # number of records to include in  a report		                
      marc_fields => $Net::Z3950::AsyncZ::Report::std,  # default: $std, others are $xtra or $all
      marc_xcl => undef,       # reference to hash of MARC fields to exclude from report
      marc_subst=>undef,	
      marc_userdef => undef,   # reference to user-defined hash of MARC fields for report 	 		
      query=>undef,
      utf8=>0,
      _this_server=>undef,
      _this_pid=>undef, 
      render => 1,	       # raw records default to $record->render()	
      log=>undef,    	       # path to errors log file	     
      cb=>undef,	       # reference to callback function to which records will be sent as available	
      querytype =>undef,       # Z3950 querytype: default: 'prefix', can be set to'ccl', or 'ccl2rpn'
      preferredRecordSyntax=>Net::Z3950::RecordSyntax::USMARC,   
      Z3950_options => undef   # reference to hash of additional Z3950 options--these
			       # take precedence over the options hash and values set in Async->new
   );

sub new {
  my($class, %args) = @_;
  my $opt_ref = { %_optiondata };

  foreach my $field ( keys %_optiondata ) {
    $opt_ref->{$field} = $args{$field}
          if defined $args{$field};
  }

  push @_options,$opt_ref;
  my $self = $#_options; 
  bless  \$self, $class;


}

sub test {
   my $self=@_;
   my $opt_ref = $_options[${$_[0]}];
   foreach my $fld( keys %$opt_ref ) {
       print $fld, " = ", $opt_ref->{$fld}, "\n",
          if defined $opt_ref->{$fld};
   }
}


# call: $self->_getFieldValue('field');
# returns value if successful, undef if not
sub _getFieldValue {
  return $_options[${$_[0]}]->{$_[1]} 
      if $_[0]->_is_option($_[1]);
  return undef;
 }


#   $self->_setFieldValue('field', 'newval');
#   returns old value, or undef if field is not valid
sub _setFieldValue
 {
  my $temp = $_[0]->_getFieldValue($_[1]);

  $_options[${$_[0]}]->{$_[1]} = $_[2], return $temp,
      if $_[0]->_is_option($_[1]); 
  return undef;
}

=pod

  $self->option('field');
 	returns value of field

  $self->option(%hash);
        sets values of fields in hash:  field=>value,field=>value. . .  
        returns:  reference to a hash of old values;
                  if the field is not a valid option
                  the field's value is set to undef;
                    
                  Because an old value may have been undefined and returns undef
                  you must use either validOption() or invalidOption()
                  to determine whether the field is in fact invalid 
                    
=cut


sub option
{
 my( $self, @args) = @_;
 my @temp;
 return $self->_getFieldValue($args[0]) if scalar @args == 1;

 my %args = (@args);
 foreach my $fld (keys %args) {       
       push @temp, $fld, $self->_setFieldValue($fld, $args{$fld});
 }
  return {@temp};
}



# _updateObjectHash() 
# internal function. 

# returns a reference to a hash whose key=>value pairs have been
# set through the options setting mechanisms of Net::Z3950::AsyncZ::_params and which have
# equivalents in the class object which is passed in the $hash parameter. 
# This enables each class either to reset its own  options hash, or to use the
# Net::Z3950::AsyncZ::_params options, as required by the class code.
# params:
#  $self:	 Net::Z3950::AsyncZ::_params object
#  $hash:	 object of class to be updated  

sub _updateObjectHash
{
my ($self, $hash) = @_;
my %matches = ();

      foreach my $key (keys %_optiondata) {
        if( exists $hash->{$key} ) { 
          my $value = $self->_getFieldValue($key);
          $matches{$key} = $value if defined $value;
        }
      }
return \%matches;
}


sub MARCList
{
 my($self, $list_ref) = @_;
 $list_ref = $self->_getFieldValue('marc_fields') if !$list_ref;
 
 foreach my $number (sort keys %{$list_ref}) {
    print $number, "  ", $list_ref->{$number}, "\n";
  }
}

my %_fn_equiv = (
  
   # functions requiring user parameters or returning values	
      pipetimeout=>undef,
      interval => undef,
      format =>undef,
      HTML => undef,
      raw => undef,             
      startrec =>undef,   
      num_to_fetch =>undef,      
      marc_fields =>undef,
      marc_xcl =>undef,
      marc_subst=>undef,	
      marc_userdef =>undef,
      log=>undef, 
      render=>undef,
      query=>undef,        	            
      cb=>undef,
      utf8=>undef,
      querytype =>undef,
      preferredRecordSyntax=>undef,
      Z3950_options=>undef
);


my %_fn_predef = (
   # functions using predefined parameters
      marc_xtra => [ 'marc_fields', $Net::Z3950::AsyncZ::Report::xtra ],    
      marc_all =>  [ 'marc_fields', $Net::Z3950::AsyncZ::Report::all ],
      marc_std =>  [ 'marc_fields', $Net::Z3950::AsyncZ::Report::std ],
      raw_on =>    [ 'raw', 1 ],	
      raw_off =>   [ 'raw', 0  ],   
      plaintext=>  [ 'HTML', 0 ],     
      HTML=>	   [ 'HTML', 1 ],     
      prefix =>    [ 'querytype', 'prefix'],
      ccl=>        [ 'querytype',  'ccl'],
      GRS1=>	   [ 'preferredRecordSyntax', Net::Z3950::RecordSyntax::GRS1],
      USMARC=>     [ 'preferredRecordSyntax', Net::Z3950::RecordSyntax::USMARC]
   );


=pod

    $opt->validOption(<option>)
    $opt->invalidOption(<option>)

These test for validity of options which have been set with the option setting
functions, either option() or the set_<option>() family.  An invalid result
occurs when attempting to set an option which does not exist. 



=cut


 # public form of _is_option(), in case changes need to be made one or the other of these
sub validOption {  &_is_option; } 
sub invalidOption { !&_is_option; } 


# true if value is in %_options array, hence can be set or read
sub _is_option { exists $_options[${$_[0]}]->{$_[1]}; }

sub _is_fn_equiv {
    exists $_fn_equiv{ $_[1]};
}

sub _is_fn_predef {
    exists $_fn_predef{ $_[1]};
}


#  All the AUTOLOAD function equivalents return undef if unsuccessful
#  Autoload carps an error message if an invalid function name is used

sub AUTOLOAD {
no strict "refs";
my ($self, $val) = @_;

  if( $AUTOLOAD =~ /.*::get_(\w+)/) {
       if ($self->_is_option($1)) {

           my $option = $1;
          *{$AUTOLOAD} = sub {  $_[0]->_getFieldValue($option); };
          return  $self->_getFieldValue($1);
        }
  }

 if( $AUTOLOAD =~ /.*::set_(\w+)/) {
  
    if($self->_is_fn_predef($1)) {
          my ($option, $value) = @{$_fn_predef{$1}};       
          *{$AUTOLOAD} = sub { return $_[0]->_setFieldValue($option=>$value); };
          return $self->_setFieldValue($option=>$value);
    }
    elsif ($self->_is_fn_equiv($1)) {
           my $option = $1;      
           if ($option =~ /utf8/) {
               return if !Net::Z3950::AsyncZ::_setupUTF8();      
           }
          *{$AUTOLOAD} = sub { return $_[0]->_setFieldValue($option=>$_[1]); };

          return $self->_setFieldValue($option=>$val);
        }
  }
  
  carp "$AUTOLOAD is not a valid function call\n";            
  return undef;

}  # AUTOLOAD

}





sub DESTROY { }


1;


