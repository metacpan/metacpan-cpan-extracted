package Solr::Schema;

use 5.006;
use strict;
use warnings;
use XML::Simple;
#use Data::Dumper;

require Exporter;

our @ISA = qw(Exporter);

our %EXPORT_TAGS = (
    'all' => [
        qw(

          )
    ]
);

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(

);

our $VERSION = '0.03';

sub new {
    my $class    = shift;
    my (%params) = @_;
    my $self     = \%params;
    bless( $self, $class );
    $self->_init;
    return $self;
}

sub _init {
    my $self = shift;
    unless ( -f "$self->{schema}" ) {
        die "$!: must supply the path to the schema.xml file";
    }
    unless ("$self->{port}") {
        die "$!: must supply a valid port for solr master server";
    }
    unless ("$self->{url}") {
        die "$!: must supply a valid url for solr master server";
    }
    $self->{update_post_url} = $self->{url} . ":" . $self->{port} . "/solr/update";
    $self->_getFields();
    return $self;
}

sub _getFields {

# reads schema file, parses, and takes user declared fields
# puts field names into an array of objects under $self->{field}
# user defined field attributes can be accessed per object.
# example $self->{field}->{indexed} would return 'true' for a field that is indexed
    my $self = shift;
    my $xml  = XMLin( $self->{schema} );
    $self->{defaultSearchField} = $xml->{defaultSearchField}; # put defaultSearchFeild here for easy access.
    $self->{uniqueKey} = $xml->{uniqueKey}; # put uniqueKey here for easy access
    $self->{schemaXml} = $xml; # put the entire schema in this hash for access if needed
    my @fields;
    $self->{fields} =
      $xml->{fields};    # puts data structure into $self->{fields} based
     #on schema data structure.  Here's a typical example as in the solr example schema config 

#     fields = {
#         'dynamicField' => {
#                           '*_t' => {
#                                    'indexed' => 'true',
#                                    'stored' => 'true',
#                                    'type' => 'text'
#                                  },
#                           '*_i' => {
#                                    'indexed' => 'true',
#                                    'stored' => 'true',
#                                    'type' => 'sint'
#                                  },
#                           '*_d' => {
#                                    'indexed' => 'true',
#                                    'stored' => 'true',
#                                    'type' => 'sdouble'
#                                  },
#                           '*_f' => {
#                                    'indexed' => 'true',
#                                    'stored' => 'true',
#                                    'type' => 'sfloat'
#                                  },
#                           '*_l' => {
#                                    'indexed' => 'true',
#                                    'stored' => 'true',
#                                    'type' => 'slong'
#                                  },
#                           '*_b' => {
#                                    'indexed' => 'true',
#                                    'stored' => 'true',
#                                    'type' => 'boolean'
#                                  },
#                           '*_s' => {
#                                    'indexed' => 'true',
#                                    'stored' => 'true',
#                                    'type' => 'string'
#                                  },
#                           '*_dt' => {
#                                     'indexed' => 'true',
#                                     'stored' => 'true',
#                                     'type' => 'date'
#                                   }
#                         },
#         'field' => {
#                    'features' => {
#                                  'indexed' => 'true',
#                                  'multiValued' => 'true',
#                                  'stored' => 'true',
#                                  'type' => 'text'
#                                },
#                    'sku' => {
#                             'indexed' => 'true',
#                             'omitNorms' => 'true',
#                             'stored' => 'true',
#                             'type' => 'textTight'
#                           },
#                    'name' => {
#                              'indexed' => 'true',
#                              'stored' => 'true',
#                              'type' => 'text'
#                            },
#                    'manu' => {
#                              'indexed' => 'true',
#                              'omitNorms' => 'true',
#                              'stored' => 'true',
#                              'type' => 'text'
#                            },
#                    'popularity' => {
#                                    'indexed' => 'true',
#                                    'stored' => 'true',
#                                    'type' => 'sint'
##                                  },
#                    'cat' => {
#                             'indexed' => 'true',
#                             'multiValued' => 'true',
#                             'omitNorms' => 'true',
#                             'stored' => 'true',
#                             'type' => 'text_ws'
#                           },
#                    'manu_exact' => {
#                                    'indexed' => 'true',
#                                    'stored' => 'false',
#                                    'type' => 'string'
#                                  },
#                    'text' => {
#                              'indexed' => 'true',
#                              'multiValued' => 'true',
#                              'stored' => 'false',
#                              'type' => 'text'
#                            },
#                    'weight' => {
#                                'indexed' => 'true',
#                                'stored' => 'true',
#                                'type' => 'sfloat'
#                              },
#                    'price' => {
#                               'indexed' => 'true',
#                               'stored' => 'true',
#                               'type' => 'sfloat'
#                             },
#                    'id' => {
#                            'indexed' => 'true',
#                            'stored' => 'true',
#                            'type' => 'string'
#                          },
#                    'includes' => {
#                                  'indexed' => 'true',
#                                  'stored' => 'true',
#                                  'type' => 'text'
#                                },
#                    'inStock' => {
#                                 'indexed' => 'true',
#                                 'stored' => 'true',
#                                 'type' => 'boolean'
#                               }
#                  }
#       };
    # creates a simply array of non_dyamic fields
    foreach my $key ( keys %{ $xml->{fields}->{field} } ) {
        push @fields, $key;
    }

    # store array here
    $self->{field} = \@fields;
    

    # creates a simply array of dyamic fields
    my @dfields;
    foreach my $key ( keys %{ $xml->{fields}->{dynamicField} } ) {
        push @dfields, $key;
    }

    # store array here
    $self->{dyanamic} = \@dfields;
    return $self;
}

1;
__END__

=head1 NAME

Solr::Schema - Reads user defined fields from solr config file schema.xml .

=head1 SYNOPSIS

Internal Module used by Solr.pm.  See Solr.pm for example of usage.

=head1 DESCRIPTION

Blah blah blah.

=head2 EXPORT

None by default.


=head1 SEE ALSO


=head1 AUTHOR

Timothy Garafola, timothy.garafola@cnet.com

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by CNET Networks

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software distributed under
    the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
    KIND, either express or implied. See the License for the specific language governing
    permissions and limitations under the License.

=cut
