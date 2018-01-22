package Net::Cisco::ISE::InternalUser;
use strict;
use Moose;

BEGIN {
    use Exporter ();
    use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS %actions);
    $VERSION     = '0.06';
    @ISA         = qw(Exporter);
    @EXPORT      = qw();
    @EXPORT_OK   = qw();
    %EXPORT_TAGS = ();
};

    %actions = (	"query" => "/ers/config/internaluser/",
        			"create" => "/ers/config/internaluser/",
               		"update" => "/ers/config/internaluser/",
                	"getById" => "/ers/config/internaluser/",
           ); 

# MOOSE!
		   
has 'email' => (
      is  => 'rw',
      isa => 'Any',
  );

has 'firstName' => (
	is => 'rw',
	isa => 'Any',
);

has 'lastName' => (
	is => 'rw',
	isa => 'Any',
);

has 'id' => (
      is  => 'rw',
      isa => 'Any',
  );

has 'identityGroups' => ( 
	is => 'rw',
	isa => 'Any',
	);

has 'name' => (
	is => 'rw',
	isa => 'Any',
	);

has 'changePassword' => ( 
	is => 'ro',
	isa => 'Maybe[Str]',
    default => "",
	);

#has 'customAttributes' => ( 
#	is => 'ro',
#	isa => 'ArrayRef',
#	auto_deref => '1',
#	);		

has 'expiryDateEnabled' => (
	is => 'rw',
	isa => 'Any',
	);

has 'expiryDate' => (
	is => 'rw',
	isa => 'Any',
);

has 'enablePassword' => (
	is => 'rw',
	isa => 'Any',
	);

has 'enabled' => (
	is => 'rw', 
	isa => 'Any',
	);

has 'password' => (
	is => 'rw',
	isa => 'Any',
	);

has 'passwordIDStore' => (
	is => 'rw',
	isa => 'Any',
	);

# No Moose	
	
sub toXML
{ my $self = shift;
  my $id = $self->id;
  my $identitygroups = $self->identityGroups || "";
  my $name = $self->name || "";
  my $changepassword = $self->changePassword || "false";
  my $enabled = $self->enabled || "true";
  my $password = $self->password || "";
  my $passwordidstore = $self->passwordIDStore || "Internal Users";
  my $enablepassword = $self->enablePassword || "";
  my $expirydate = $self->expiryDate || "";
  my $expirydateenabled = $self->expiryDateEnabled || "false";
  my $lastname = $self->lastName || "";
  my $firstname = $self->firstName || "";
  my $email = $self->email || "";
  my $result = "";

#   <expiryDateEnabled>$expirydateenabled</expiryDateEnabled>
#   <expiryDate>$expirydate</expiryDate>
#   <passwordIDStore>$passwordidstore</passwordIDStore>

#<name>$name</name>
 
  #if ($id) { $result = "   <id>$id</id>\n"; }
  $result .= <<XML;
  <changePassword>$changepassword</changePassword>
  <customAttributes/>
  <email>$email</email>
  <enabled>$enabled</enabled>
  <firstName>$firstname</firstName>
  <identityGroups>$identitygroups</identityGroups>
  <lastName>$lastname</lastName>
  <password>$password</password> 
XML
warn $result;
return $result;
}

sub header
{ my $self = shift;
  my $data = shift;
  my $record = shift;
  my $name = " name=\"".$record->name."\"" if $record->name;
  my $id = " id=\"".$record->id."\"" if $record->id;
  $id ||= "";
  my $description = " description=\"".$record->firstName." ".$record->lastName."\"";
  
  return qq{<?xml version="1.0" encoding="UTF-8" standalone="yes"?><ns3:internaluser$description$name$id xmlns:ns2="ers.ise.cisco.com" xmlns:ns3="identity.ers.ise.cisco.com">$data</ns3:internaluser>};

}

#################### main pod documentation end ###################
__PACKAGE__->meta->make_immutable();

1;
# The preceding line will help the module return a true value

