# $Date: 2003/05/05 16:50:12 $
# $Revision: 1.4 $ 


package Net::Z3950::AsyncZ::ZSend;
use Net::Z3950;
use Carp;
use strict;

 {
   my $mgr;
     sub getMgr { 
      $mgr = new Net::Z3950::Manager(), if !$mgr;
      my $args = $_[0]->_getFieldValue('Z3950_options');

      foreach my $key (keys %$args) {
                  # reset our value so it doesn't accidentally clobber the one set by $mgr
		  # this applies the $mgr options to all _params objects
             $_[0]->_setFieldValue($key=>$args->{$key}); 
             $mgr->option($key=>$args->{$key});
      }

      return $mgr;
    }
 }

sub connection { return $_[0]->{_conn}; }
sub rs {  return $_[0]->{_rs}; }
sub rsize { return $_[0]->{_rsize}; }
sub querytype { return $_[0]->{_conn}->option('querytype'); }

sub closedown {
  $_[0]->{_conn}->close() if $_[0]->{_open};  
  $_[0]->{_open} = 0;
}

sub new {
my ($class, %arg) = @_; 
my $self = {                          # _params query, if any, substituted at fork in Async
	_query =>  $arg{query} || croak("missing query"), 
        _mgr   =>  $arg{manager} || getMgr($arg{options}),
        _host  =>  $arg{host},
        _port  =>  $arg{port},
        _db    =>  $arg{db},
	_rs    =>  "",		# set in sendQuery
	_rsize =>  0,	  	# set in sendQuery
	_open  =>  0,  		# set in sendQuery
        _options => $arg{options},
        _querytype => $arg{querytype},  # set to default (prefix) if undefined
        _preferredRecordSyntax => $arg{preferredRecordSyntax}
                                 || Net::Z3950::RecordSyntax::USMARC

};
   my $qt = $self->{_options}->_getFieldValue('querytype');
   $self->{_querytype} = $qt if $qt;        

   my $ps = $self->{_options}->_getFieldValue('preferredRecordSyntax');
   $self->{_preferredRecordSyntax} = $ps if $ps;   

   bless $self,$class;
   $self->{_conn}  = $self->make_connection(); 
   $self->{_open}  = 1 if $self->{_conn};
   return $self; 
   
}


sub sendQuery {
my $self = shift;
       $self->{_conn}->option(querytype => $self->{querytype}), if $self->{querytype};

	my $rs = $self->{_conn}->search($self->{_query}); 


        if(!$rs) { 
             Net::Z3950::AsyncZ::Errors::report_error($self->{_conn});            
       }  
       $self->{_rs} = $rs;
       $self->{_rsize} = $rs->size();
}



sub make_connection {
my $self = shift;

	my $conn = new Net::Z3950::Connection($self->{_mgr}, $self->{_host}, $self->{_port})
	   or return 0;
        $conn->option(databaseName => $self->{_db});
        $conn->option(preferredRecordSyntax=>$self->{_preferredRecordSyntax})
                if defined $self->{_preferredRecordSyntax};    

        return $conn;
}

1;


__END__

=pod

To Do:

handle failed connection in constructor
=cut
