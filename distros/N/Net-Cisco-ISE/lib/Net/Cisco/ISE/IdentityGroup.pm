package Net::Cisco::ISE::IdentityGroup;
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

    %actions = (	"query" => "/ers/config/identitygroup/",
                    "create" => "/ers/config/identitygroup/",
               		"update" => "/ers/config/identitygroup/",
                	"getById" => "/ers/config/identitygroup/",
           ); 

# MOOSE!
		   
has 'description' => (
      is  => 'rw',
      isa => 'Any',
  );

has 'id' => (
      is  => 'rw',
      isa => 'Str',
  );

has 'name' => (
	is => 'rw',
	isa => 'Str',
	);

# No Moose	
	
sub toXML
{ my $self = shift;
  my $id = $self->id;
  my $description = $self->description || ""; 
  my $name = $self->name || "";
  my $result = "";
  
  if ($id) { $result = "   <id>$id</id>\n"; }
  $result .= <<XML;
   <description>$description</description>
   <name>$name</name>
XML

return $result;
}

sub header
{ my $self = shift;
  my $users = shift;
  return qq{<?xml version="1.0" encoding="UTF-8" standalone="yes"?><ns2:identityGroups xmlns:ns2="identity.rest.mgmt.ise.nm.cisco.com">$users</ns2:identityGroups>};
}

#################### main pod documentation end ###################
__PACKAGE__->meta->make_immutable();

1;
# The preceding line will help the module return a true value

