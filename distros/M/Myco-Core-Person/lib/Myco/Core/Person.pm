package Myco::Core::Person;

###############################################################################
# $Id: Person.pm,v 1.1.1.1 2006/02/28 22:15:51 sommerb Exp $
#
# See license and copyright near the end of this file.
###############################################################################

=head1 NAME

Myco::Core::Person - Myco Person objects.

=item Release

1.0

=cut

our $VERSION = 1.0;

=head1 SYNOPSIS

  use Myco;

  # Constructors. See Myco::Entity for more.
  my $p = Myco::Core::Person->new;

  # Name.
  my $last = $p->get_last;
  $p = $p->set_last($last);
  my $first = $p->get_first;
  $p = $p->set_first($first);
  my $middle = $p->get_middle;
  $p = $p->set_middle($middle);
  my $prefix = $p->get_prefix;
  $p = $p->set_prefix($prefix);
  my $suffix = $p->get_suffix;
  $p = $p->set_suffix($suffix);
  my $nick = $p->get_nick;
  $p = $p->set_nick($nick);

  # Vital Stats.
  my $gender = $p->get_gender;
  $p = $p->set_gender($gender);
  my $birthdate = $p->get_birthdate;
  $p = $p->set_birthdate($birthdate);

  # Added instance methods.
  my $format = "%p% f% M% l%, s";
  my $name = $p->strfname($format);
  my $uidf = $p->get_unique_id_fmt;

  # Persistence methods.
  $p->save;
  $p->destroy;

=head1 DESCRIPTION

This class represents what may well be the central object of any Myco-based
application: the Person. Myco::Core::Person provides the absolute bare bones
skeleton of what most applications will need in a person object.

=cut

##############################################################################
# Dependencies
##############################################################################
# Module Dependencies and Compiler Pragma
use warnings;
use strict;
use Myco::Exceptions;

##############################################################################
# Programmatic Dependencies
use Lingua::Strfname ();
use Myco::Util::Strings;

##############################################################################
# Inheritance & Introspection
##############################################################################
use lib '/usr/home/sommerb/dev/myco/lib';
use base qw(Myco::Entity);
my $md = Myco::Entity::Meta->new
  ( name => __PACKAGE__,
    tangram => { table => 'myco_core_person' },
  );

##############################################################################
# Function and Closure Prototypes
##############################################################################

# Use this code reference to validate the Unique ID.
my $chk_uid = sub {
    Myco::Exception::DataValidation->throw
      (error => "id must be of form ####-####-# (dashes optional)")
      unless defined ${$_[0]} and ${$_[0]} =~ /^\d{9}$/;
};

##############################################################################
# Queries - this is delayed to avoid compile loops
##############################################################################
my $queries = sub {
    my $md = shift;

    $md->add_query( name => 'default',
                    remotes => { '$p_' => 'Myco::Core::Person', },
                    result_remote => '$p_',
                    params => { last => [ qw($p_ last) ], },
                    filter => {
                               parts => [ { remote => '$p_',
                                            attr => 'last',
                                            oper => 'eq',
                                            param => 'last' },
                                        ] },
                  );

};

##############################################################################
# Constructor, etc.
##############################################################################

=head1 COMMON ENTITY INTERFACE

Constructor, accessors, and other methods -- as inherited from Myco::Entity.

=cut

##############################################################################
# Attributes & Attribute Accessors / Schema Definition
##############################################################################

=head1 ATTRIBUTES

Attributes may be initially set during object construction (with C<new()>) but
otherwise should be accessed solely through accessor methods. Typical usage:

=over 3

=item *

Set attribute value

 $p->set_attribute($value);

Check functions (see L<Class::Tangram|Class::Tangram>) perform data
validation. If there is any concern that the set method might be called with
invalid data then the call should be wrapped in an C<eval> block to catch
exceptions that would result.

=item *

Get attribute value

 $value = $p->get_attribute;

=back

A listing of available attributes follows:

=cut

=head2 last

 type: string(64)  required: not empty

The personE<39>s last name.

=cut

$md->add_attribute( name => 'last',
                    type => 'string',
                    type_options => { string_length => 64 },
                    synopsis => 'Last Name',
                    tangram_options => { required => 1 },
                  );


=head2 first

 type: string(64)

The personE<39>s first name.

=cut

$md->add_attribute(name => 'first',
                   type => 'string',
		   type_options => { string_length => 64 },
                   synopsis => 'First Name',
                  );


=head2 middle

 type: string(64)

The personE<39>s middle name.

=cut

$md->add_attribute(name => 'middle',
                   type => 'string',
		   type_options => { string_length => 64 },
                   synopsis => 'Middle Name',
                  );

=head2 prefix

 type: string(32)

The prefix to the personE<39>s name.

=cut

$md->add_attribute(name => 'prefix',
                   type => 'string',
		   type_options => { string_length => 32 },
                   synopsis => 'Prefix',
		   values => [ qw( __select__ Ms. Miss Mrs. Mr. __other__ )],
                  );

=head2 suffix

 type: string(32)

The suffix to the personE<39>s name.

=cut

$md->add_attribute(name => 'suffix',
                   type => 'string',
		   type_options => { string_length => 32 },
                   synopsis => 'Suffix',
		   values => [ qw( __select__ Jr. Sr. M.D. PhD. __other__ )],
                  );

=head2 nick

 type: string(64)

The personE<39>s nick name.

=cut

$md->add_attribute(name => 'nick',
                   type => 'string',
		   type_options => { string_length => 64 },
                   synopsis => 'Nick Name',
                  );

=head2 birthdate

 type: rawdate

The personE<39>s birthday.

=cut

$md->add_attribute( name => 'birthdate',
		    syntax_msg => 'YYYY-MM-DD (dashes optional)',
                    type => 'rawdate',
                    ui => { label => 'Birth Date' },
                  );


##############################################################################
# Methods
##############################################################################

=head1 ADDED CLASS / INSTANCE METHODS

=head2 strfname

  my $format = "%p% f% M% l%, s";
  my $name = $person->strfname($format);

This method allows the parts of the personE<39>s name to be formatted according
to the strfname formatting template syntax. See
L<Lingua::Strfname|Lingua::Strfname> for the details of the formatting
syntax. Note that the only difference here is that the "first extra name" is
always the personE<39>s nick name. Thus, the formatting characters are as
follows:

  %l Last Name
  %f First Name
  %m Middle Name
  %p Prefix
  %s Suffix
  %a Nick Name
  %L Last Name Initial with period
  %F First Name Initial with period
  %M Middle Name Initial with period
  %A Nick Name Initial with period
  %T Last Name Initial
  %S First Name Initial
  %I Middle Name Initial
  %1 Nick Name Initial

=cut

sub strfname {
    Lingua::Strfname::strfname($_[1],
      @{$_[0]}{qw(last first middle prefix suffix nick)})
}

##############################################################################
# Object Schema Activation and Metadata Finalization
##############################################################################
$md->activate_class( queries => $queries );

1;
__END__

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2006 the myco project. All rights reserved.
This software is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHORS

Charles Owens <charles@mycohq.com>, David Wheeler <david@wheeler.net>, and
Ben Sommer <ben@mycohq.com>

=head1 SEE ALSO

L<t/person.t>,
L<Myco::Entity|Myco::Entity>,
L<Myco|Myco>,
L<Tangram|Tangram>,
L<Class::Tangram|Class::Tangram>,

=cut
