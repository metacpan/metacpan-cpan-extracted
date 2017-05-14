package Myco::Query::Part::Clause;

###############################################################################
# $Id: Clause.pm,v 1.6 2006/03/19 19:34:08 sommerb Exp $
#
# See license and copyright near the end of this file.
###############################################################################

=head1 NAME

Myco::Query::Part::Clause - a Myco entity class

=head1 SYNOPSIS

  use Myco;

  # Constructors. See Myco::Entity for more.
  my $clause = Myco::Query::Part::Clause->new( remote => '$person_remote_',
                                               attr => 'last_name',
                                               oper => 'eq',
                                               param => 'Hancock' );

  my $stringified_clause = $clause->get_clause;

  print "OK\n" if $stringified_clause eq
    '$person_remote_->{last_name} eq Hancock';

  # On second thought, I want anyone _not_ a 'Hancock'...
  $clause->set_oper( 'ne' );

  print "Better now\n" if $clause->get_clause =~ /ne Hancock$/;

=head1 DESCRIPTION

The clause is the basic building block of a Myco query. It encapsulates the
perl-namespace remote object name (in the example above '$person_remote_',
the object attribute name that our logic is operating on, the operator,
and the paramater we're using. Full support for all types of parameters is
offered, including scalars, objects, sets, etc. See L<Tangram> for an
exhaustive discussion of these, as well as how to design a query.

=cut

##############################################################################
# Dependencies
##############################################################################
# Module Dependencies and Compiler Pragma
use warnings;
use strict;
use Myco::Exceptions;
use Myco::Entity::Meta;

##############################################################################
# Programatic Dependencies


##############################################################################
# Constants
##############################################################################

# Building up a big-ass ugly hash of operators and methods, w/metadata
#  * req_param is needed for methods like is_null, which don't use a param
our $opers = { 'eq' => { label => 'equal (string)',
                         req_param => 1,
                         oper_meth => 'oper' },
               '==' => { label => 'equal (numeric)',
                         req_param => 1,
                         oper_meth => 'oper' },
               'ne' => { label => 'not equal (string)',
                         req_param => 1,
                         oper_meth => 'oper' },
               '!=' => { label => 'not equal (numeric)',
                         req_param => 1,
                         oper_meth => 'oper' },
               'gt' => { label => 'greater than (string)',
                         req_param => 1,
                         oper_meth => 'oper' },
               '>' => { label => 'greater than (numeric)',
                        req_param => 1,
                        oper_meth => 'oper' },
               'lt' => { label => 'less than (string)',
                         req_param => 1,
                         oper_meth => 'oper' },
               '<' => { label => 'less than (numeric)',
                        req_param => 1,
                        oper_meth => 'oper' },
               'ge' => { label => 'greater than or equals (string)',
                         req_param => 1,
                         oper_meth => 'oper' },
               '>=' => { label => 'greater than or equals (numeric)',
                         req_param => 1,
                         oper_meth => 'oper' },
               'le' => { label => 'less than or equals (string)',
                         req_param => 1,
                         oper_meth => 'oper' },
               '<=' => { label => 'less than or equals (numeric)',
                         req_param => 1,
                         oper_meth => 'oper' },
               is_null => { label => 'is null',
                            req_param => 0,
                            oper_meth => 'meth' },
               like => { label => 'is like',
                         req_param => 1,
                         oper_meth => 'meth' },
               match => { label => 'matches',
                          req_param => 1,
                          oper_meth => 'meth' },
               includes => { label => 'includes (in a set)',
                             req_param => 1,
                             oper_meth => 'meth' },
             };


##############################################################################
# Inheritance & Introspection
##############################################################################
use base qw( Myco::Query::Part );
my $md = Myco::Entity::Meta->new
  ( name => __PACKAGE__,
    ui => {
           displayname => sub {
               my $self = shift;
               my $clause = $self->get_clause;
               # Truncate it to first 25 characters.
               $clause =~ s/(.+){25}(.*)/$1/;
               return $clause;
           },
           list => { layout => [ qw(__DISPLAYNAME__) ] },
           view => { layout => [ qw(remote attr oper param) ] },
          }
  );

##############################################################################
# Function and Closure Prototypes
##############################################################################


##############################################################################
# Constructor, etc.
##############################################################################

=head1 COMMON ENTITY INTERFACE

Constructor, accessors, and other methods -- as inherited from
Myco::Entity.

=cut

##############################################################################
# Attributes & Attribute Accessors / Schema Definition
##############################################################################

=head1 ATTRIBUTES

Attributes may be initially set during object construction (with C<new()>) but
otherwise are accessed solely through accessor methods. Typical usage:

=over 3

=item *

Set attribute value

 $obj->set_attribute($value);

Check functions (see L<Class::Tangram|Class::Tangram>) perform data
validation. If there is any concern that the set method might be called with
invalid data then the call should be wrapped in an C<eval> block to catch
exceptions that would result.

=item *

Get attribute value

 $value = $obj->get_attribute;

=back

A listing of available attributes follows:

=head2 remote

 type: transient

 $query_clause->set_remote( '$p_' );

The remote variable name

=cut

$md->add_attribute( name => 'remote',
                    type => 'transient',
                    ui => { label => 'Remote Variable', },
                  );

=head2 attr

 type: transient

 # Last name
 $query_clause->set_attr( 'last' );

The persistent attribute name corresponding to the remote API.

=cut

$md->add_attribute( name => 'attr',
                    type => 'transient',
                    ui => { label => 'Entity Attribute', },
                  );

=head2 oper

 type: transient

 $query_clause->set_oper( 'ne' );


The Perl operator to be appended to the clause.

=cut

$md->add_attribute( name => 'oper',
                    type => 'transient',
                    values => [ keys %$opers ],
                    value_labels => { map { $_ => $opers->{$_}->{label} }
                                            keys %$opers },
                    ui => { label => 'Operator', },
                  );
sub set_oper {
    my ($self, $attr) = @_;
    Myco::Exception::DataValidation->throw
        ( error =>  "$attr is not a valid operator" )
          unless defined $opers->{$attr};
    $self->SUPER::set_oper( $attr );
}

=head2 param

 type: transient

 $query_clause->set_param( 'Hancock' );

The parameter value used in the query clause. Certain method operators are
multipart in nature, such as 'match', which takes a left regex operator, the
param itself, and a right regex operator. Either of these operators may be left
undefined. This will be discovered wehn calling 'get_clause'.

=cut

$md->add_attribute( name => 'param',
                    type => 'transient',
                    ui => { label => 'Parameter', },
                  );

##############################################################################
# Methods
##############################################################################

=head1 ADDED CLASS / INSTANCE METHODS

=head2 get_clause

  my $stringified_clause = $clause->get_clause;

Concatenates into a string clause the atomic parts of a
Myco::Query::Part::Clause. Accepts as an argument a hash of parameters that
are marked as optional in the Myco::Query 'params' attribute.

=cut

sub get_clause {
    my $self = shift;
    my $query = shift;

    my $oper = $self->get_oper;
    my $param = $self->get_param;
    my $remote = $self->get_remote;
    my $attr = $self->get_attr;
    my $part_join_oper = $self->get_part_join_oper ?
      ' '.$self->get_part_join_oper : ' ';
    my $remotes = $query ? $query->get_remotes : {};

    # Abort right off if param looks like a remote variable name but isn't in
    # the remotes hash.
    my $param_isa_remote = $param =~ /^\$.*/;
    Myco::Exception::Query::Clause->throw
        ( error => "param looks like a remote variable but isn't in the remotes hash - line ".__LINE__.': '.__PACKAGE__ )
          if $param_isa_remote && ! exists $remotes->{$param};

    # Check if oper is an operator or a method
    my $isa_oper = $opers->{$oper}->{oper_meth} eq 'oper';
    my $isa_meth = $opers->{$oper}->{oper_meth} eq 'meth';

    my $clause;

    if ($isa_oper) {
        # Must assume knowledge of namespace reality in ::Query::Template
        # i.e., '$params{param}'
        # Also, checking if param is a remote
        $clause = $param_isa_remote
          ? $remote.'->{'.$attr.'} '.$oper.' '.$param
            : $remote.'->{'.$attr.'} '.$oper.' $params{'.$param.'}';
    } elsif ($isa_meth) {
        if ($opers->{$oper}->{req_param}) {
            # If param is needed, use it
            if ($oper eq 'match') {
                # Munge together the regex stuff.
                my $param_name = '$params{'.$param->[0].'}';
                my $regex_oper = $param->[1];
                my $parsed_param = $param->[2];
                $parsed_param =~ s/{}/\'\.$param_name\.\'/g;
                $clause = $remote.'->{'.$attr.'}->match(\''.$regex_oper
                        . '\', \''.$parsed_param.'\')';
            } else {
                $clause = $param_isa_remote
                  ? $remote.'->{'.$attr.'}->'.$oper.'('.$param.')'
                    : $remote.'->{'.$attr.'}->'.$oper.'($params{'.$param.'})';
            }
        } else { # or else just ignore param
            $clause = $remote.'->{'.$attr.'}->'.$oper;
        }
    }
    return $clause.$part_join_oper;
}


##############################################################################
# Object Schema Activation and Metadata Finalization
##############################################################################
$md->activate_class;

1;
__END__


=head1 LICENSE AND COPYRIGHT

Copyright (c) 2006 the myco project. All rights reserved.
This software is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.



=head1 SEE ALSO

L<Myco::Query::Part::Clause::Test|Myco::Query::Part::Clause::Test>,
L<Myco::Entity|Myco::Entity>,
L<Myco|Myco>,
L<Tangram|Tangram>,
L<Class::Tangram|Class::Tangram>,
L<myco-mkentity|mkentity>

=cut
