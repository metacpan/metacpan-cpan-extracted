package SemanticWeb::OAI::ORE::Agent;
#$Id: Agent.pm,v 1.4 2010-12-06 14:44:15 simeon Exp $

=head1 NAME

SemanticWeb::OAI::ORE::Agent - Module to represent http://purl.org/dc/terms/Agent

=head1 SYNPOSIS

  my $agent=SemanticWeb::OAI::ORE::Agent->new;
  $agent->name("A Person");
  $agent->mbox("person\@example.org");
  print "Agent = ".$agent->name." <".$agent->mbox.">\n";

=head1 DESCRIPTION

Within OAI-ORE an agent, typically but not necessarily a person,
may have a name, an email address and a URI.

=cut

use strict;
use warnings;

use Class::Accessor;

use base qw(Class::Accessor);
SemanticWeb::OAI::ORE::Agent->mk_accessors(qw(uri name mbox));

=head1 METHODS

=head2 Creator 

=head3 new()

Create SemanticWeb::OAI::ORE::Agent, may set uri, name and mbox via
hash arguments.

=cut

sub new {
  my $class=shift;
  my $self={@_};
  bless $self, (ref($class) || $class);
  return($self);
}

=head2 Accessors

=head3 uri

URI of the Agent. This may be a blank node id. Use instead
L<real_uri> if you want only globally meaningful URI.

=head3 real_uri

Wrapper around L<uri> which returns either a globally meaningful
URI or undef if not set or a blank node. Cannot be used to set
L<uriXX>.

=cut

sub real_uri {
  my $self=shift;
  my $uri=$self->uri(@_);
  return( $uri && $uri!~/^_/ ? $uri : undef );
}

=head3 name

Accessor for foaf:name of this Agent

=head3 mbox

Accessor for foaf:mbox of this Agent

=cut

1;
