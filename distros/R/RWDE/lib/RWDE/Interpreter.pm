package RWDE::Interpreter;

use strict;
use warnings;

use Error qw(:try);
use RWDE::Exceptions;

use vars qw($VERSION);
$VERSION = sprintf "%d", q$Revision: 507 $ =~ /(\d+)/;

sub parser {
  my ($self, $params) = @_;

  while () {
    print "To start, enter the desired type of the object (i.e. LS::Account, empty string to finish): ";
    my $type = <>;
    chomp($type);
    last if ($type eq '');

    print 'Now, enter desired id (empty for a static call): ';
    my $term_id = <>;
    chomp($term_id);

    my $term = $self->instantiate({ type => $type, term_id => $term_id });

    next if (not defined $term);

    $self->execute_loop({ term => $term });
  }

  return ();
}

sub instantiate {
  my ($self, $params) = @_;

  my $type = $$params{type};
  my $term_id = $$params{term_id};

  my $term;
  if (defined $term_id && $term_id ne '' && $term_id ne '0') {
    try {
      $term = $type->fetch_by_id({ $type->get_id_name() => $term_id });
    }

    catch Error with {
      my $ex = shift;
      print "An error occurred, info: $ex \n";
    };

  }
  else {
    $term = $type;
  }

  return $term;
}

sub execute_loop {
  my ($self, $params) = @_;

  my $term = $$params{term};

  while () {
    my ($action_values, $action);
    my $type = ref $term;

    if (ref $term) {
      print "Enter desired function for $type({" . $term->get_id_name . " => " . $term->get_id . "})\n";
			print "(blank for display, done to finish with this object): ";
    }

    else {
      $type = $term;
      print "Enter desired function for $type\n";
			print "(done to finish with this object): ";
    }

    $action = <>;
    chomp($action);

		last if ($action eq 'done');
		
	  if ($action eq '' && ref $term) {
	    $action = 'display';
	  }
	
		elsif ($action eq ''){
			print "No default action for static calls\n";
			next;
		}
		
		else{
		  if (ref $term) {
		    print "Enter desired params for $type({" . $term->get_id_name() . " => " . $term->get_id() . "})->$action\n";
		  }
	
		  else {
		    print "Enter desired params for $type -> $action\n";
		  }
	
		  print "(key value pairs key => value separated by commas): ";

		  $action_values = <>;
		  chomp($action_values);
		}
		
		$self->execute({ term => $term, action => $action, action_values => $action_values });
  }

  return ();
}

sub execute{
	my ($self, $params) = @_;

	my $term = $$params{term};
	my $type = ref $term || $term;
	my $action = $$params{action};
	my $action_values = $$params{action_values} or '';

	my $result;

  try {
	  my $action_params;
    print "---------------------------Request--------\n";
    if ((defined $action_values) && ($action_values =~ m/=/)){
      #for hash style params, parse them
      $action_values = "{$action_values}";
  	  $action_params = RWDE::DB::Record->hashify({ string => "$action_values"});  
    }
    else{
      $action_params = $action_values; 
    }
    print "$type->$action($action_values)\n";  	  
    print "---------------------------Action result--\n";    
    $result = $term->$action($action_params);
  }

  catch Error with {
    my $ex = shift;
    print "An error occurred: $ex\n";
  };

	if (defined $result){
    print "Function returned: ($result)\n";
		print "Boolean response would be: " . ($result ? 'true' : 'false') . "\n";
	}
  print "---------------------------End------------\n";	

	#handle array results  
	if (ref $result eq 'ARRAY'){
		print 'There are: ' . scalar @{$result} . " elements returned.\n";
	}
	elsif (ref $result){
	  $self->execute_loop({ term => $result });
	}

	return;
}

sub run{
  my ($self,@params) = @_;
  # Welcome to RWDE interpreter
  # short and sweet conduit to the heart of your RWDE app
  # this command line driven interface will allow you to run methods on specific objects

  my $type = shift @params;
  my $action = shift @params;
  my $term_id = shift @params;
  my $action_values = shift @params;

  if (defined $type 
  	&& ($type eq '-h' || $type eq '-H' || $type eq '-?' || $type eq '-help')
  	){
  	print "RWDE interpreter\n";
  	print "\nFor easy development or unit testing invoke the interpreter in non-interactive mode\n";
  	print "interpreter <class_type> <method_name> [<class_id|0 for static calls> [parameter,value]]\n\n";
  	print "ie. ./interpreter LS::List fetch_by_id 0 list_id,3\n\n";
  	print "ie. ./interpreter LS::List display 3\n\n";
  	print "Or start it without params to get the interactive 'shell;\n\n";
  	exit;
  }
  elsif (defined $type){

  	my $term = RWDE::Interpreter->instantiate({ type => $type, term_id => $term_id });

  	exit
  	unless defined $term;

	  $action_values =~ s/,/ => /g;  	
  	
  	RWDE::Interpreter->execute({ term => $term, action => $action, action_values => $action_values });

  	exit;
  }

  RWDE::Interpreter->parser();
  
  return;
}
  
1;
