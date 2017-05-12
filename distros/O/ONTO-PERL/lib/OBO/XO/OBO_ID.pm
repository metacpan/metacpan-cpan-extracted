# $Id: OBO_ID.pm 2010-09-29 erick.antezana $
#
# Module  : OBO_ID.pm
# Purpose : A OBO_ID.
# License : Copyright (c) 2006-2015 by Erick Antezana. All rights reserved.
#           This program is free software; you can redistribute it and/or
#           modify it under the same terms as Perl itself.
# Contact : Erick Antezana <erick.antezana -@- gmail.com>
#

package OBO::XO::OBO_ID;

use strict;
    
sub new {
	my $class = shift;
	my $self  = {};

	$self->{IDSPACE} = undef; # string
	$self->{LOCALID} = undef; # localID (string)

	bless ($self, $class);
	return $self;
}

=head2 idspace

  Usage    - print $id->idspace() or $id->idspace($idspace)
  Returns  - the idspace (string)
  Args     - the idspace (string)
  Function - gets/sets the idspace # TODO this is actually the LocalIDSpace
  
=cut

sub idspace {
	my ($self, $ns) = @_;
	if ($ns) { $self->{IDSPACE} = $ns }
	return $self->{IDSPACE};
}

=head2 localID

  Usage    - print $id->localID() or $id->localID($name)
  Returns  - the localID (string)
  Args     - the localID (string)
  Function - gets/sets the localID
  
=cut

sub localID {
	my ($self, $n) = @_;
	if ($n) { $self->{LOCALID} = $n }
	return $self->{LOCALID};
}

=head2 id_as_string

  Usage    - print $id->id_as_string() or $id->id_as_string("XO:X0000001")
  Returns  - the id as string (scalar)
  Args     - the id as string
  Function - gets/sets the id as string
  
=cut

sub id_as_string () {
	my ($self, $id_as_string) = @_;
	if ( defined $id_as_string && $id_as_string =~ /(\w+):(\d+)/ ) {
		$self->{IDSPACE} = $1;
		my $factor = '1'.0 x length($2);
		$self->{LOCALID} = substr($2 + $factor, 1, 7); # trick: forehead zeros # TODO
	} elsif ($self->{IDSPACE} && $self->{LOCALID}) {
		return $self->{IDSPACE}.':'.$self->{LOCALID};
	}
}
*id = \&id_as_string;

=head2 equals

  Usage    - print $id->equals($id)
  Returns  - 1 (true) or 0 (false)
  Args     - the other ID (OBO::XO::OBO_ID)
  Function - tells if two IDs are equal
  
=cut

sub equals () {
	my ($self, $target) = @_;
	return (($self->{IDSPACE} eq $target->{IDSPACE}) && 
			($self->{LOCALID} == $target->{LOCALID}));
}

=head2 next_id

  Usage    - $id->next_id()
  Returns  - the next ID (OBO::XO::OBO_ID)
  Args     - none
  Function - returns the next ID, which is new
  
=cut

sub next_id () {
	my $self = shift;
	my $next_id = OBO::XO::OBO_ID->new();
	$next_id->{IDSPACE} = $self->{IDSPACE};
	my $factor = '1'.0 x length($self->{LOCALID});
	$next_id->{LOCALID} = substr($factor + 1 + $self->{LOCALID}, 1, 7); # trick: forehead zeros
	return $next_id;
}

=head2 previous_id

  Usage    - $id->previous_id()
  Returns  - the previous ID (OBO::XO::OBO_ID)
  Args     - none
  Function - returns the previous ID, which is new
  
=cut

sub previous_id () {
	my $self = shift;
	my $previous_id = OBO::XO::OBO_ID->new();
	$previous_id->{IDSPACE} = $self->{IDSPACE};
	my $factor = '1'.0 x length($self->{LOCALID});
	$previous_id->{LOCALID} = substr(($factor + $self->{LOCALID}) - 1, 1, 7); # trick: forehead zeros
	return $previous_id;
}

1;

__END__


=head1 NAME

OBO::XO::OBO_ID - A module for describing identifiers of any OBO ontology (e.g. XO). Its IDSpace and LocalID are stored.

=head1 SYNOPSIS

use OBO::XO::OBO_ID;

$id = OBO_ID->new();

$id->idspace("XO");

$id->localID("0000001");

$idspace = $id->idspace();

$localID = $id->localID();

print $id->id_as_string();

$id->id_as_string("XO:1234567");

=head1 DESCRIPTION

The OBO::XO::OBO_ID class implements an identifier for any OBO ontology.

A XO ID holds: IDSPACE, and a LOCALID in the following form:

	IDSPACE:LOCALID

For instance: XO:1234567

Identifiers (IDs) in OBO should be strings consisting of an IDSpace 
concatenated to a LocalID via a : (colon) character. The ID should not 
contain any whitespace. The IDSpace should not itself contain any colon 
characters, and should ideally be registered on the GO xrefs page or with OBO. 

More info at:

	http://www.obofoundry.org/id-policy.shtml

=head1 AUTHOR

Erick Antezana, E<lt>erick.antezana -@- gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2006-2015 by Erick Antezana. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.7 or,
at your option, any later version of Perl 5 you may have available.

=cut