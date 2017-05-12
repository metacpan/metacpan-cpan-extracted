package Net::OAI::Record::NamespaceFilter;

use strict;
use warnings;
use base qw( XML::SAX::Base );
use Storable;
use Carp qw( carp croak );
our $VERSION = "1.20";

=head1 NAME

Net::OAI::Record::NamespaceFilter - general filter class based on namespace URIs

=head1 SYNOPSIS

 $plug = Net::OAI::Record::NamespaceFilter->new(); # Noop

 $multihandler = Net::OAI::Record::NamespaceFilter->new(
    'http://www.openarchives.org/OAI/2.0/oai_dc/' => 'Net::OAI::Record::OAI_DC',
    'http://www.openarchives.org/OAI/2.0/provenance' => 'MySAX::ProvenanceHandler'
   );

 $saxfilter = new SOME_SAX_Filter;
 ...
 $filter = Net::OAI::Record::NamespaceFilter->new(
    '*' => $saxfilter, # '*' for any namespace
   );

 $filter = Net::OAI::Record::NamespaceFilter->new(
   '*' => sub { my $x = ""; 
                return XML::SAX::Writer->new(Output => \$x);
              };
  );



=head1 DESCRIPTION

It will forward any element belonging to a namespace from this list 
to the associated SAX filter and all of the element's children 
(regardless of their respective namespace) to the same one. It can be used either as a 
C<metadataHandler> or C<recordHandler>.

This SAX filter takes a hashref C<namespaces> as argument, with namespace 
URIs for keys ('*' for "any namespace") and the values are either 

=over 4

=item undef

Matching elements and their subelements are suppressed.

If the list of namespaces ist empty or C<undefined> is connected to 
the filter, it effectively acts as a plug to Net::OAI::Harvester. This
might come handy if you are planning to get to the raw result by other
means, e.g. by tapping the user agent or accessing the result's xml()
method:

 $plug = Net::OAI::Record::NamespaceFilter->new();
 $harvester = Net::OAI::Harvester->new( [
     baseURL => ...,
     ] );

 $tapped_by_ua = "";
 open ($TAP, ">", \$tapped_by_ua);
 $harvester->userAgent()->add_handler(response_data => sub { 
        my($response, $ua, $h, $data) = @_;
        print $TAP $data;
     });

 $list = $harvester->listRecords( 
    metadataPrefix  => 'a_strange_one',
    recordHandler => $plug,
  );

 print $tapped_by_ua; # complete OAI response
 print $list->xml();  # should be exactly the same


Comment: This is quite an efficient way of not processing the XML content
of OAI records received.


=item a class name of a SAX filter

As usual for any record element of the OAI response a new instance is created.

  # end_document() of instances of MyWriter returns something meaningful...
  $consumer = Net::OAI::Record::NamespaceFilter->new('*'=> 'MyWriter');

  $filter = Net::OAI::Record::NamespaceFilter->new(
      '*' => $consumer
    );
 
  $list = $harvester->listAllRecords( 
     metadataPrefix  => 'oai_dc',
     recordHandler => $filter,
   );

  while( $r = $list->next() ) {
     next if $r->status() eq "deleted";
     $xmlstringref = $r->recorddata()->result('*');
     ...
  };

Note: The handlers are instantiated for each single OAI record in the response
and will see one start_document() and end_document() event in any case (this
behavior is different from that of handler class names directly specified as 
C<metadataHandler> or C<recordHandler> for a request: instances from those
constructions will never see such events).


=item a code reference for an constructor

Must return a SAX filter ready to accept a new document.

The following example returns a string serialization for each single
record:

 # end_document() events will return \$x
 $constructor = sub { my $x = ""; 
                      return XML::SAX::Writer->new(Output => \$x);
                    };
 $filter = Net::OAI::Record::NamespaceFilter->new(
      '*' => $constructor
   );
 
 $list = $harvester->listRecords( 
     metadataPrefix  => 'oai_dc',
     recordHandler => $filter,
  );

 while( $r = $list->next() ) {
     $xmlstringref = $r->recorddata()->result('*');
     ...
  };


Comment: This example shows an approach to insulate the "true contents" of individual
response records without having to provide a SAX handler class of one's own (just
the addidtional prerequisite of L<XML::SAX::Writer>). But what you get is a 
serialized XML document which then has to be parsed for further processing ...


=item an already instantiated SAX filter

As usual in this case no C<start_document()> and C<end_document()> events are
forwarded to the filter. 

 open $fh, ">", $some_file;
 $builder = XML::SAX::Writer->new(Output => $fh);
 $builder->start_document();
 $rootEL = { Name => 'collection',
           LocalName => 'collection',
        NamespaceURI => "http://www.loc.gov/MARC21/slim",
              Prefix => "",
          Attributes => {}
              };
 $builder->start_element( $rootEL );

 # filter for OAI-Namespace in records: forward all
 $filter = Net::OAI::Record::NamespaceFilter->new(
      'http://www.loc.gov/MARC21/slim' => $builder);

 $list = $harvester->listRecords( 
     metadataPrefix  => 'a_strange_one',
     metadataHandler => $filter,
  );
 # handle resumption tokens if more than the first
 # chunk shall be stored into $fh ....

 $builder->end_element( $rootEL );
 $builder->end_document();
 close($fh);
 # ... process contents of $some_file

In this example calling the C<result()> method for individual records in
the response will probably not be of much use.

=back

Caution: Depending on the namespaces specified, even a handlers which
are freshly instantiated for each OAI record might be fed with more
than one top-level XML element.


=head1 METHODS

=head2 new( [%namespaces] )

Creates a Handler suitable as recordHandler or metadataHandler. %namespaces
has namespace B<URIs> for keys and values according to the four types
described as above.


=cut

sub new {
    my ( $class, %opts ) = @_;
    my $self = bless { namespaces => {%opts} }, ref( $class ) || $class;
    $self->{ _activeStack } = [];
    $self->{ _tagStack } = [];
    $self->{ _result } = [];
    $self->{ _prefixmap } = {};
    $self->set_handler( undef );
    delete $self->{ _noHandler };  # follows set_handler()
    $self->{ _handlers } = {};
    $self->{ _performing } = {};
    while ( my ($key, $value) = each %{$self->{ namespaces }} ) {
        if ( ! defined $value ) {   # no handler
            Net::OAI::Harvester::debug( "new(): case 1 for $key" );
          }
        elsif ( ! ref($value) ) {    # class name
            Net::OAI::Harvester::debug( "new(): case 2 for $key: $value");
            Net::OAI::Harvester::_verifyHandler( $value );
          }
        elsif ( ref($value) eq "CODE" ) {    # constructor
            Net::OAI::Harvester::debug( "new(): case 3 for $key");
            # can't verify now
          }
        else {    # active instance
            Net::OAI::Harvester::debug( "new(): case 4 for $key" );
            $self->{ _handlers }->{ $key } = $value;
            $self->{ _performing }->{ $value }--;
          }
      };
    return( $self );
}

=head2 result ( [namespace] ) 

If called with a I<namespace>, it returns the result of the handler,
i.e. what C<end_document()> returned for the record in question.
Otherwise it returns a hashref for all the results with the
corresponding namespaces as keys.

=cut

sub result {
    my ( $self, $ns ) = @_;
    if ( defined $ns ) {
      return $self->{ _result }->{$ns} || undef}
    else {
      return $self->{ _result }}
}

=head1 AUTHOR

Thomas Berger <ThB@gymel.com>

=cut

## Storable hooks

sub STORABLE_freeze {
  my ($obj, $cloning) = @_;
  return if $cloning;
  return "", $obj->{ _result };   # || undef;
}

sub STORABLE_thaw {
  my ($obj, $cloning, $serialized, $listref) = @_;
  return if $cloning;
  $obj->{ _result } = $listref;
#carp "thawed @$listref";
}


## SAX handlers

sub start_document {
  my ($self, $document) = @_;
  carp(<<"XxX");
unexpected start_document()
\t_activeStack: @{$self->{ _activeStack }}
\t_tagStack: @{$self->{ _tagStack }}
XxX
  $self->SUPER::start_document( $document );
}
sub end_document {
  my ($self, $document) = @_;
  carp(<<"XxX");
unexpected end_document()
\t_activeStack: @{$self->{ _activeStack }}
\t_tagStack: @{$self->{ _tagStack }}
XxX
  $self->SUPER::end_document( $document );
}

sub start_prefix_mapping {
  my ($self, $mapping) = @_;
  $self->SUPER::start_prefix_mapping( $mapping ) unless $self->{ _noHandler };
  return if $self->{ _activeStack }->[0];
  $self->{ _prefixmap }->{ $mapping->{Prefix} } = $mapping;
  my $activehdl = $self->get_handler();
  croak ("wrong assumption") unless (! defined $activehdl) or $self->{ _performing }->{ $activehdl };
  my $switched;
  foreach my $hdl ( keys %{$self->{ _performing }} ) {
      $self->set_handler( $hdl );
      $self->SUPER::start_prefix_mapping( $mapping );
      $switched = 1;
    }
  $self->set_handler( $activehdl ) if $switched;
}

sub end_prefix_mapping {
  my ($self, $mapping) = @_;
  $self->SUPER::end_prefix_mapping( $mapping ) unless $self->{ _noHandler };
  return if $self->{ _activeStack }->[0];
  croak ( "mapping @{[%$mapping]} already removed" ) unless $self->{ _prefixmap }->{ $mapping->{Prefix} };
  my $activehdl = $self->get_handler();   # always undef
  croak ( "wrong assumption" ) unless (! defined $activehdl) or $self->{ _performing }->{ $activehdl };
  my $switched;
  foreach my $hdl ( keys %{$self->{ _performing }} ) {
      $self->set_handler( $hdl );
      $self->SUPER::end_prefix_mapping( $mapping );
      $switched = 1;
    }
  delete $self->{ _prefixmap }->{ $mapping->{Prefix} };
  $self->set_handler( $activehdl ) if $switched;
}

sub start_element {
    my ( $self, $element ) = @_;
#    Net::OAI::Harvester::debug(<<"XxX");
#\t((( $element->{ Name } (((
#\t\t_activeStack: @{$self->{ _activeStack }}
#\t\t_tagStack: @{$self->{ _tagStack }}
#XxX
    if ( $self->{ _activeStack }->[0] ) {   # handler already set up
      }
    else {
        unless ( $self->{ _tagStack }->[0] ) {      # should be the start of a new record
            $self->{ _result } = {};
# start_document here for all defined handlers?
            my $activehdl = $self->get_handler();   # always undef
            croak( "handler $activehdl already active" ) if defined $activehdl;
            my $switched;

            while ( my ($key, $value) = each %{$self->{ namespaces }} ) {
                $self->{ _result }->{ $key } = undef;
                my $hdl;
                if ( ! defined $value ) {   # no handler
#                   Net::OAI::Harvester::debug( "start_element(): case 1 for $key" );
                  }
                elsif ( ! ref($value) ) {    # class name
#                   Net::OAI::Harvester::debug( "start_element(): case 2 for $key" );
                    $hdl = $value->new();
                  }
                elsif ( ref($value) eq "CODE" ) {    # constructor
#                   Net::OAI::Harvester::debug( "start_element(): case 3 for $key" );
                    $hdl = &$value();
                    Net::OAI::Harvester::_verifyHandler( $hdl );
                  }
                else {    # always active instance
#                   Net::OAI::Harvester::debug( ""start_element(): case 4 for $key. Handler is $value" );
                $switched = 1;
                $self->set_handler( $value );
# Those mapping evends *have* already been forwarded... => Bugfix for XML::SAX::Writer?
                foreach my $mapping ( values %{$self->{ _prefixmap }} ) {
#                   Net::OAI::Harvester::debug( "bugfix supply of deferred @{[%$mapping]}" );
                    $self->SUPER::start_prefix_mapping( $mapping )}
                    next;
                  }

                $self->{ _handlers }->{ $key } = $hdl;
                next unless defined $hdl;
                next if $self->{ _performing }->{ $hdl }++;
                $switched = 1;
                $self->set_handler( $hdl );
                $self->SUPER::start_document({});
                foreach my $mapping ( values %{$self->{ _prefixmap }} ) {
                    $self->SUPER::start_prefix_mapping( $mapping )}
              }
            $self->set_handler( $activehdl ) if $switched;
          };

        if ( exists $self->{ namespaces }->{$element->{ NamespaceURI }} ) {
            if ( defined (my $hdl = $self->{ _handlers }->{$element->{ NamespaceURI }}) ) {
                $self->set_handler( $hdl );
                $self->{ _noHandler } = 0;
              };
          }
        elsif ( exists $self->{ namespaces }->{'*'} ) {
            if ( defined (my $hdl = $self->{ _handlers }->{'*'}) ) {
                $self->set_handler( $hdl );
                $self->{ _noHandler } = 0;
              };
          }
        else {
            push (@{$self->{ _tagStack }}, $element->{ Name });
            return;
          };
      };

    push (@{$self->{ _activeStack }}, $element->{ Name });
    return if $self->{ _noHandler };
    $self->SUPER::start_element( $element );
}

sub end_element {
    my ( $self, $element ) = @_;
#    Net::OAI::Harvester::debug(<<"XxX");
#\t))) $element->{ Name } )))
#\t\t_activeStack: @{$self->{ _activeStack }}
#\t\t_tagStack: @{$self->{ _tagStack }}
#XxX
    if ( $self->{ _activeStack }->[0] ) {
        unless ( $self->{ _noHandler } ) {
            $self->SUPER::end_element( $element );
          };
        pop (@{$self->{ _activeStack }});
        return if $self->{ _activeStack }->[0];
        unless ( $self->{ _noHandler } ) {
            $self->set_handler(undef);
            $self->{ _noHandler } = 1;
          }
      }
    elsif ( $self->{ _tagStack }->[0] ) {
        pop (@{$self->{ _tagStack }});
      }
    return if $self->{ _tagStack }->[0];
    my $activehdl = $self->get_handler();   # always undef
    croak ( "handler $activehdl still active" ) if defined $activehdl;
    my $switched;
    while ( my ($key, $value) = each %{$self->{ namespaces }} ) {
        if ( ! defined $value ) {
#           Net::OAI::Harvester::debug( "end_element(): case 1 for $key" );
            $self->{ _result }->{ $key } = "";
          }
        elsif ( my $hdl = $self->{ _handlers }->{ $key } ) {
            if ( ! $self->{ _performing }->{ $hdl } ) {
                carp "already(?) inactive handler $hdl for $key";
                delete $self->{ _handlers }->{ $key };
                next;
              }
            elsif ( $self->{ _performing }->{ $hdl } < 0 ) {      # always active handler
#               Net::OAI::Harvester::debug( "end_element(): case 4 for $key" );
                $self->{ _result }->{ $key } = undef;
                next;
              };
#           Net::OAI::Harvester::debug( "end_element(): case 2/3 for $key" );
            delete $self->{ _handlers }->{ $key };
            delete $self->{ _performing }->{ $hdl };
            $switched = 1;
            $self->set_handler( $hdl );
# revoke some stored namespace mappings, too?
            my $result = $self->SUPER::end_document({});
            $self->{ _result }->{ $key } = $result;
          }
        else {
            croak("Assertion failed: $key not listed as _handler");
          };
      };
    $self->set_handler( $activehdl ) if $switched;
}

sub characters {
    my ( $self, $characters ) = @_;
    return if $self->{ _noHandler };
    return $self->SUPER::characters( $characters );
}

sub ignorable_whitespace {
    my ( $self, $characters ) = @_;
    return if $self->{ _noHandler };
    return $self->SUPER::ignorable_whitespace( $characters );
}

sub comment {
    my ( $self, $comment ) = @_;
    return if $self->{ _noHandler };
    return $self->SUPER::comment( $comment );
}

sub processing_instruction {
    my ( $self, $pi ) = @_;
    return if $self->{ _noHandler };
    return $self->SUPER::processing_instruction( $pi );
}

1;

