package Myco::QueryTemplate;

###############################################################################
# $Id: QueryTemplate.pm,v 1.1.1.1 2004/11/22 19:16:01 owensc Exp $
###############################################################################

=head1 NAME

Myco::QueryTemplate - a Myco template class

=head1 VERSION

=over 4

=item Release

0.01

=cut

our $VERSION = 0.01;

=item Repository

$Revision$ $Date$

=back

=head1 DESCRIPTION

A template class for Myco::Base::Entity::Meta::Query.

=cut

##############################################################################
# Dependencies
##############################################################################
# Module Dependencies and Compiler Pragma
use warnings;
use strict;
use Myco::Exceptions;
use CGI;
use Myco::Base::Entity::Meta;
use Myco::Base::Entity::Meta::Attribute;
use Myco::Base::Entity::Meta::Attribute::UI;
use Myco::Query::Part::Filter;
use Myco::Query::Part::Clause;

##############################################################################
# Constants
##############################################################################
use constant FILTER => 'Myco::Query::Part::Filter';
use constant CLAUSE => 'Myco::Query::Part::Clause';
use constant ATTR_META => 'Myco::Base::Entity::Meta::Attribute';
use constant UI_META => 'Myco::Base::Entity::Meta::Attribute::UI';

##############################################################################
# Inheritance & Introspection
##############################################################################
use base qw( Class::Tangram );
my $md = Myco::Base::Entity::Meta->new( name => __PACKAGE__ );

##############################################################################
# Constructor, etc.
##############################################################################

=head1 COMMON ENTITY INTERFACE

Constructor, accessors, and other methods -- as inherited from
Myco::Base::Entity.

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



=head2 name

 type: string

Name of the query.

=cut

$md->add_attribute( name => 'name',
                    type => 'string',
                    template => 1,
                    type_options => { string_length => 64 },
                    ui => { label => 'Name',
                            widget => [ 'textfield', -size => 15 ], },
                  );



=head2 description

 type: string  required

Description of the query.

=cut

$md->add_attribute( name => 'description',
                    type => 'string',
                    template => 1,
                    type_options => { string_length => 2048 },
                    ui => { label => 'Description',
                            widget => ['textarea', -rows => 3, cols => 25], },
                  );



=head2 result_remote

 type: string  required

The remote class of objects to return.

=cut

$md->add_attribute( name => 'result_remote',
                    type => 'string',
                    template => 1,
                    type_options => { string_length => 64 },
                    tangram_options => {
#                                        required => 1,
                                       },
                    ui => { label => 'Result Class' },
                  );



=head2 filter

 type: perl_dump

  $query->set_filter( $filter );

The string dump of ::Filter and ::Clause objects comprising the filter.

=cut

$md->add_attribute( name => 'filter',
                    type => 'perl_dump',
                    template => 1,
                    tangram_options => {
                                        sql => 'VARCHAR(5100)',
                                        class => FILTER,
                                        col => 'filter',
                                       },
                  );

sub set_filter {
    my ($self, $filter) = @_;
    if (ref $filter eq FILTER) {
        # handed a FILTER obj... use it!
        $self->SUPER::set_filter($filter);
    } elsif (ref $filter eq 'HASH' && exists $filter->{parts}) {
        # $filter is a FILTER->new happy hashref.
        $self->SUPER::set_filter(FILTER->new( %$filter ))
    } else {
        Myco::Exception::Query::Filter->throw
            ( error => 'Error setting filter in the Query Template object' );
    }
}



=head2 remotes

 type: flat_hash  required

 $query->set_remote( {'$u_' => 'Myco::User'} );

A hash of remote variable and class names. Use declare_remote to add new ones.

=cut

$md->add_attribute( name => 'remotes',
                    type => 'flat_hash',
                    template => 1,
                    tangram_options => { table => 'query_remotes',
                                         key_type => 'string',
                                         type => 'string',
                                         aggreg => 1,
                                       },
                  );



=head2 params

 type: perl_dump

  $query->set_params( last_name => ['$p_', 'last'],
                      middle_name => ['$p_', 'middle', 1],
                      first_initial => ['$p_', 'middle',
                                        widget => ['textfield',
                                                   -size => 2, maxlength => 2],
                                       ],
                    );

A hash of arrays of arg names consisting of the relevant remotes, and the
attribute name. May also include boolean flag to indicate optionality, as well
as a custom CGI widget spec.

=cut

$md->add_attribute( name => 'params',
                    type => 'perl_dump',
                    template => 1,
                    tangram_options => { col => 'params' },
                  );


=head2 params_order

  $query->set_params_order( ['mid', 'log'] );

Since params is a hash, its values cannot be accessed in the order it was
originally specified, this attribute can used to explicity set the order.

=cut

$md->add_attribute( name => 'params_order',
                    type => 'perl_dump',
                    template => 1,
                    tangram_options => { col => 'params_order' },
                  );


##############################################################################
# Methods
##############################################################################

=head1 ADDED CLASS / INSTANCE METHODS

=head2 add_remotes

  $query->add_remotes( { '$peeps_' => 'Myco::Person',
                         '$stooges_' => 'Myco::Person::Stooge'} );

Add remotes without clobbering the current list.

=cut

sub add_remotes {
    my ($self, $remotes) = @_;
    my $existing_remotes = $self->get_remotes;
    $self->set_remotes($existing_remotes = {} ) unless $existing_remotes;
    for my $varname (keys %$remotes) {
        $existing_remotes->{$varname} = $remotes->{$varname}
          unless exists $existing_remotes->{$varname};
    }
    $self->set_remotes($existing_remotes);
}



=head2 get_filter_string

  my $filter_string = $query->get_filter_string;

A wrapper method around Myco::Query::Part::Filter->get_combined_parts. Works on
the filter attribute. Accepts as an argument the same hash of parameters passed
to run_query.

=cut

sub get_filter_string {
    my $self = shift;
    my $run_query_params = shift;

    if ($run_query_params) {
        # Process any optional params
        my %optional_params_not_submitted;
        for my $param ( keys %{$self->get_params} ) {
            # Build up a simple list of params and their optionality
            # Throw an exception here if a required attribute was not passed.
            my $is_optional = 1 if defined $self->get_params->{$param}->[2];
            if ($is_optional && ! $run_query_params->{$param}) {
                $optional_params_not_submitted{$param} = 1;
            } elsif (! $is_optional && ! exists $run_query_params->{$param}) {
                Myco::Exception::Query::Params->throw
                    ( error => 'Missing required query parameters' );
            }
            # The last case is that the param is optional and was passed anyway
        }
        # Let ::Filter deal with optional params
        return $self->get_filter->get_combined_parts
          ( $self, $run_query_params, \%optional_params_not_submitted );
    } else {
        return $self->get_filter->get_combined_parts( $self );
    }
}


=head2 run_query

  my @results = $query->run_query;

Run the query.

=cut

sub run_query {
    my $self = shift;
    my %params = @_;
    # Verify that params passed in were explicitly set prior
    if ($self->get_params) {
        Myco::Exception::Query::Params->throw( error => 'Params not passed.' )
            if ! %params;
    } else {
        for my $key (keys %params) {
            Myco::Exception::Query::Params->throw
                ( error => 'Params attribute not set.' )
                  if ! $self->get_params->{$key};
        }
    }
    # Verify that variable names present in filter string are pre-declared
    my $filter_string = $self->get_filter_string( \%params );
    my $result = $self->get_result_remote;
    Myco::Exception::Query::Filter->throw
        ( error => 'Missing remote variable in filter statement' )
          if ! $filter_string =~ /$result/;
    # Build up the remotes declaration string
    my $r_string;
    $r_string .= "my $_ = Myco->remote('".$self->get_remotes->{$_}.'\');'
      for keys %{ $self->get_remotes };
    # Compile the remotes and filter string at once
    my ($filter, $remote_);
    {
        # Suppress a new operator precedence warning in 5.8.2
        local $SIG{__WARN__} = sub {};
        ($filter, $remote_) = eval $r_string
          . ' return ('.$filter_string.','.$result .')';
    }
    my @objects = eval { Myco->select( $remote_, $filter ) };
    if ($@) {
        Myco::Exception::Query::Init->throw
            ( error => "Error running Query. Raw exception message: $@" );
    } else {
        return @objects;
    }
}

=head2 get_ui_md

  my $ui_md = $query->get_ui_md;

Returns ::UI metadata objects for each attribute in params attribute. Keyed by
attribute alias

=cut

sub get_ui_md {
    my $self = shift;

    my %md_ui_objs;
    for my $r_ ( keys %{$self->get_remotes} ) {
        for my $attr ( keys %{$self->get_params} ) {
            my $attr_r_ = $self->get_params->{$attr}->[0];
            my $attr_name = $self->get_params->{$attr}->[1];
            my $remote_class = $self->get_remotes->{$r_};
            eval "use $remote_class";
            my $md = $remote_class->introspect->get_attributes;
            if ($attr_r_ eq $r_) {
                if ($md->{$attr_name}->get_type =~ /^(?:ref|iset)$/ ) {
                    # skip - should be handled directly by ::Controller
                } else {
                    $md_ui_objs{$attr} = $md->{$attr_name}->get_ui;
                }
            }
        }
    }
    return %md_ui_objs ? \%md_ui_objs : undef;
}

=head2 get_ref_params

  my $ref_params = $query->get_ref_params;

Returns a hash reference like { 'person' => 'Myco::Person' } for any 'ref' or
'iset' params required by the query object.

=cut

sub get_ref_params {
    my $self = shift;
    my %ref_params;
    for my $param ( keys %{$self->get_params} ) {
        my $remote = $self->get_params->{$param}->[0];
        my $attr = $self->get_params->{$param}->[1];
        my $md = $self->get_remotes->{$remote}->introspect->get_attributes;
        if ($md->{$attr}->get_type =~ /^(?:ref|iset)$/ ) {
            my $class = $md->{$attr}->get_tangram_options->{class};
            $ref_params{$param} = $class;
        }
    }
    return %ref_params ? \%ref_params : undef;
}


=head2 get_closure

  my $cgi_widget = $query->get_closure( 'first_name' );

Get an appropriate CGI widget for a given param. Leverages L<Myco::Base::Entity::Meta::Attribute::UI|Myco::Base::Entity::Meta::Attribute::UI>.

=cut

sub get_closure {
    my ($self, $param, $cgi) = @_;
    $cgi = CGI->new if ! $cgi;

    my @param_spec = @{ $self->get_params->{$param} };
    my $widget_spec = $param_spec[3] ? $param_spec[3] :
      (ref $param_spec[2] eq 'ARRAY' ? $param_spec[2] : undef);
    my $ui_meta;

    if ($widget_spec) {
        # Create dummy ::Attribute and ::UI objects.
        my $attr_meta = ATTR_META->new( name => 'foo', type => 'string');
        $ui_meta = UI_META->new(widget => $widget_spec, attr => $attr_meta);
    } else {
        # Sniff out attribute for meatadata for $param
        $ui_meta = $self->get_ui_md->{$param};
    }
    return $ui_meta->get_closure->( $cgi, '',
                                    '-name' => $param,
                                    '-class' => 'view_attrval' );
}

##############################################################################
# Object Schema Activation and Metadata Finalization
##############################################################################
$md->activate_class;

1;
__END__
