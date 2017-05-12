package Nginx::Simple::Ajax;

use strict;

use XML::Simple;

=head1 MODULE

Nginx::Simple::Ajax

=head1 METHODS

=cut

=head3 my $ajax = new Ajax($self);

Initialize with Nginx::Simple object.

=cut

sub new 
{
    my ($class, $nginx_simple) = @_;
    my $self = {};
    
    $self->{export}{javascript} = q[];
    $self->{nginx_simple} = $nginx_simple;

    bless($self);

    return $self;
}

=head3 $self->read

Read values into an ajax object.

=cut

sub read
{
    my $self = shift;

    my %items_table;
    my $form_data = $self->{nginx_simple}->request_body;

    return unless $form_data;

    $self->reset;
    
    my $xml = eval { 
        XMLin($form_data, ForceArray => [ 'element' ])
    };

    return unless $xml;

    ### read in and parse inputs from server
    for my $element (ref($xml->{element}) eq 'ARRAY' 
                     ? (@{$xml->{element}})
                     : ($xml->{element}))
    {
        $items_table{$_} = $element->{$_}{content}
            for keys %$element;
    }

    $self->{items_table}  = \%items_table;
}

=head3 $self->param( $id )

Akin to Nginx::Simple->param.

=cut

sub param
{
    my ($self, $id) = @_;

    return unless ref $self->{items_table} eq 'HASH';

    if ($id)
    {
        return $self->get( id => $id );
    }
    else
    {
        return keys %{$self->{items_table}};
    }
}   

=head3 $self->get( id => 'foo' )

Returns data as scalar given an element_id.

=cut

sub get
{
    my ($self, %params) = @_;

    die qq(\$self->get: Param id must be given\n)
        unless $params{id};

    my $item_id = $params{id};
    my $data = $self->{items_table}{$item_id};

    return $data;

}

=head3 $self->add( foo => 'bar' || javascript => "alert('foo!')" )

Enqueue an item to be generated into javascript xml.

=cut

sub add
{
    my ($self, %params) = @_;

    my $export = $self->{export};

    if ( exists( $params{javascript} ) )
    {
        $export->{javascript} .= $params{javascript};
    }

    if ( exists( $params{pre_javascript} ) )
    {
        $export->{pre_javascript} .= $params{pre_javascript};
    }

    for my $key (keys %params)
    {
        next if $key eq 'javascript';
        next if $key eq 'pre_javascript';
        
        $export->{elements}{$key} = $params{$key};
    }   
}

=head3 $self->send

Send Ajax returned XML.

=cut

sub send
{
    my $self = shift;

    my $export = $self->{export};

    $self->{nginx_simple}->header_set('Content-Type', 'text/xml');

    my $xml = qq(<x-response>\n);
    
    if ($export->{javascript})
    {
        my $js = $export->{javascript};

        $xml .= qq{ <response type="javascript"><![CDATA[$js]]></response>\n};
    }

    if ($export->{pre_javascript})
    {
        my $js = $export->{pre_javascript};

        $xml .= qq{ <response type="pre-javascript"><![CDATA[$js]]></response>\n};
    }

    for my $key (keys %{$export->{elements}})
    {
        my $html = $export->{elements}{$key};
        $xml .= qq{ <response type="element" id="$key"><![CDATA[$html]]></response>\n};
    }
    $xml .= qq(</x-response>\n);

    $self->{nginx_simple}->print($xml);
}

=head3 $self->reset

Reset the object.

=cut

sub reset
{
    my $self = shift;

    delete $self->{items_table};
    delete $self->{export};

    $self->{export}{javascript}     = q[];
    $self->{export}{pre_javascript} = q[];
}

=head1 Author

Michael J. Flickinger, C<< <mjflick@gnu.org> >>

=head1 Copyright & License

You may distribute under the terms of either the GNU General Public
License or the Artistic License.

=cut

1;
