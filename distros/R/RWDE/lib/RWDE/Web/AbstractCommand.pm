package RWDE::Web::AbstractCommand;

use strict;

use RWDE::DB::Record;
use RWDE::Exceptions;

use vars qw($VERSION);
$VERSION = sprintf "%d", q$Revision: 509 $ =~ /(\d+)/;

sub new {
  my ($proto, $params) = @_;

  my $class = ref($proto) || $proto;

  my $self = { _data => {}, };

  bless $self, $class;

  $self->helper($$params{helper});

  $self->initialize($params);

  return $self;
}

sub initialize {
  my ($self, $params) = @_;

  my $helper = $$params{helper};

  my $req = $helper->get_req();

  $req->print_header({ pagetype => $helper->get_pagetype()});

  return ();
}

=pod

=head2 baggage_handling

=cut

sub baggage_handling {
  my ($self, $params) = @_;

  my @search_terms = @{ $$params{search_terms} };

  my $session = $self->helper->get_session();

  my $formdata = $self->helper->get_formdata();

  my $baggage;

  #reset the baggage hash if we are starting a new search
  if ($$formdata{init_baggage}) {

    foreach my $param (@search_terms) {
      if (defined $$formdata{$param}) {
        $$baggage{$param} = $$formdata{$param};
      }
    }
    $session->baggage($baggage);
  }

  #otherwise we need those variables copied into our formdata
  else {
    $baggage = $session->baggage;

    foreach my $key (keys %{$baggage}) {
      $$formdata{$key} = $$baggage{$key};
    }
  }

  return ();
}

sub execute {
  my ($self, $params) = @_;

  warn " Abstract Command execute - are you sure you don't want to do anything more specific here? ";

  return ();
}

=head2 get_missing_hash

Create and populate a hash with input from a comma delim string

=cut

sub parse_missing {
  my ($self, $params) = @_;

  my $missing = RWDE::DB::Record->hashify({ string => $$params{info} });

  my @missing_array;
  foreach my $key (keys %{$missing}) {
    push @missing_array, $$missing{$key};
  }
  my $missing_string = join(', ', @missing_array);

  my $info = "Sorry, some of the required information is missing.  Did you remember to fill in your  <b>($missing_string)</b>? Please enter the missing information and try again.";

  $self->helper->set_stash({ info => $info });

  $self->helper->set_stash({ missing => $missing });

  return ();
}

=pod

=head2 FIELDNAME($field[,$value])

All field names of the record are accessible via the field name.  If a
second parameter is provided, that value is stored as the data,
otherwise the existing value if any is returned.  Throws an 'undef'
exception on error.  It is intended to be called by an F<AUTOLOAD()>
method from the subclass.

Example:

 $rec->owner_email('new@add.ress');
 $rec->user_addr2(undef);
 print $rec->user_fname();

Would be converted by F<AUTOLOAD()> in the subclass to calls like

 $rec->FIELDNAME('owner_email','new@add.ress');

and so forth.

=cut

sub FIELDNAME {
  my $self = shift;
  my $name = shift;

  my $classref = ref($self)
    or throw RWDE::DevelException({ info => "No method by name: $name could be located. FIELDNAME tried to find the attribute  by $name - but the call was on $self, not an object." });

  $name =~ s/.*://;    # strip fully-qualified portion

  #if you are trying to set data, have a name and the data...
  if ((defined($name)) && (defined($_[0]))) {

    #set the data
    $self->{_data}->{$name} = $_[0];
  }

  return $self->{_data}->{$name};
}

=pod
  
=head2 FIELDNAME()
    
All field names of the record are accessible via the field name.  If a
parameter is provided, that value is stored as the data, otherwise the
existing value if any is returned.  Throws an 'undef' exception on
error.
      
Example:
     
 $rec->password('blahblah');
 print $rec->password();
    
=cut

use vars qw($AUTOLOAD);

sub AUTOLOAD {
  my ($self, @args) = @_;
  if (not ref $self) {
    my ($package, $filename, $line) = caller();
    throw RWDE::DataBadException(
      { info => "AbstractCommand::AUTOLOAD invoked with the fieldname: $AUTOLOAD; probably static access to an undefined field/method from $filename Line: $line " . join(':', @args) . "\n" });
  }
  return $self->FIELDNAME($AUTOLOAD, @args);
}

# do nothing.  here just to shut up TT when AUTOLOAD is present
sub DESTROY {

}

1;
