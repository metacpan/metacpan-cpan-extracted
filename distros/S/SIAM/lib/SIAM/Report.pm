package SIAM::Report;

use warnings;
use strict;

use base 'SIAM::Object';
use JSON;

=head1 NAME

SIAM::Report - Report object class

=head1 SYNOPSIS

   my $sorted_items = $report->get_items();
   my $item_class = $report->attr('siam.report.object_class');
   foreach my $item (@{$sorted_items}) {       
     my $obj = $item->{'siam.report.item'};
     my $traffic_in = $item->{'traffic.in'};
     ...
   }

=head1 METHODS

=head2 get_items

Returns arrayref with hashes. The content of these hashes is defined by
the report type. Each hash has a mandatory key C<siam.report.item>
that points to an instantiated object.

=cut

sub get_items
{
    my $self = shift;

    my $ret = [];
    my $objclass = $self->attr('siam.report.object_class');
    my $content_json = $self->computable('siam.report.content');
    if( not defined($content_json) )
    {
        $self->error('Computable siam.report.contents returned undef');
        return $ret;
    }
    
    my $content = eval { decode_json($content_json) };
    if( $@ )
    {
        $self->error('Failed to process JSON in ' .
                     'siam.report.contents computable: ' . $@);
        return $ret;
    }
    
    if( ref($content) ne 'ARRAY' )
    {
        $self->error('siam.report.contents returned non-array data');
        return $ret;
    }

    foreach my $item (@{$content})
    {
        my $objid = $item->{'siam.report.item_id'};
        if( not defined($objid) )
        {
            $self->error('siam.report.contents has array element ' .
                         'without siam.report.item_id');
            next;
        }
        
        my $object = $self->instantiate_object($objclass, $objid);
        if( not defined($object) )
        {
            $self->error('Cannot instantiate a report item "' . $objid . '"');
            next;
        }

        my $ret_item = {'siam.report.item' => $object};
        while( my($key, $val) = each %{$item} )
        {
            if( $key ne 'siam.report.item_id' )
            {
                $ret_item->{$key} = $val;
            }
        }

        push(@{$ret}, $ret_item);
    }
    
    return $ret;
}


            
    
# mandatory attributes

my $mandatory_attributes =
    [ 'siam.report.name',
      'siam.report.description',
      'siam.report.object_class',
      'siam.report.type',
      'siam.report.last_updated' ];

sub _mandatory_attributes
{
    return $mandatory_attributes;
}


sub _manifest_attributes
{
    my $ret = [];
    push(@{$ret}, @{$mandatory_attributes},
         @{ SIAM::Reports->_manifest_attributes() });

    return $ret;
}


1;

# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 4
# cperl-continued-statement-offset: 4
# cperl-continued-brace-offset: -4
# cperl-brace-offset: 0
# cperl-label-offset: -2
# End:
