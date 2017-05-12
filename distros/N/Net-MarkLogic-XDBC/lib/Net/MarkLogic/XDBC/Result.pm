
package Net::MarkLogic::XDBC::Result;


=head1 NAME

Net::MarkLogic::XDBC::Result- A sequence of XQUERY values returned from the execution of an XQUERY statement. 

=head1 SYNOPSIS

  use Net::MarkLogic::XDBC::Result

  my $result = $xdbc->query($xquery);

  print $result->content;
  print $result->as_xml;

  @items = $result->items;
  print $item->content;
  
=head1 DESCRIPTION

Alpha. API will change.

The XDBC server returns results as a multipart message. If your xquery
statement returns a series of XML nodes instead of one XML node with subnodes,
expect lots of items. Otherwise, you can probably get away with calling
content().

If you want to deal with your results piece by piece, call items().

=cut

use strict;
use Data::Dumper;
use LWP::UserAgent;
use Net::MarkLogic::XDBC::Result::Item;
use Class::Accessor;
use Class::Fields;

our @BASIC_FIELDS = qw(response);

use base qw(Class::Accessor Class::Fields);
use fields @BASIC_FIELDS, qw(items);
Net::MarkLogic::XDBC::Result->mk_accessors( @BASIC_FIELDS );

=head1 METHODS

=head2 new()

  $resp = Net::MarkLogic::XDBC::ResultSet->new( response => $http_resp );

Result objects are normally created for you after calls to XDBC->query.

=cut

sub new
{
    my ($class, %args) = @_;

    die "No HTTP::Response argument" unless $args{response};

    my $self = bless ({}, ref ($class) || $class);
    

    $self->response($args{response});

    if (!$self->response->is_success)
    {
        # TODO - error handling
        $self->{items} = ();
        return $self;
    }

    $self->{items} = $self->_parse_multipart_header;
     
    return $self;
}

sub _parse_multipart_header {
    my $self = shift;

    my @items = ();
    my $ctype = $self->response->header('Content-Type'); 

    my $boundary;
    
    if ($ctype && ($ctype =~ m/boundary=(\w+)/))
    {
       $boundary = "--" . $1;

        foreach my $part (split("$boundary", $self->response->content()) ) 
        {
            if ( $part =~ m/Content-Type: \s (\S*) \s*
                        X-Primitive: \s (\S*)  \s*
                        (.*)/xs ) 
            {
                push (@items, Net::MarkLogic::XDBC::Result::Item->new(
                                content_type => $1,
                                type         => $2,
                                content      => $3,
                            ));
            }
        }
    }

    return \@items;
}

=head2 content()

print $result->content();

The content of the response, usually XML. Doesn't contain any info about the
content's data type. If the response contains multiple parts, the content of
each part is concatenated. The results are returned inside of a <result>
tag to ensure a complete XML document.

=cut

sub content 
{
    my $self = shift;
 
    my $content;
    
    $content = qq{<xq:result xmlns:xq="http://xqzone.com/xdbc/driver">\n};
    foreach my $item ($self->items) 
    {
        $content .= $item->content;
    }
    $content .= "</result>\n";

    return $content;
}

=head2 as_xml()

print $result->as_xml

Returns an XML representation of the result including content type and xml
type. The document has a root node of result and each part of the response
is inside an entry node. The entry node contains two attributes, content_type 
and x_type.

=cut

sub as_xml 
{
    my $self = shift;
                                                                                
    my $xml = qq{<xq:result xmlns:xq="http://xqzone.com/xdbc/driver">\n};
                                                                                
    foreach my $item ($self->items) 
    {
        $xml .= $item->as_xml;
    }
    $xml .= "</result>\n";
                                                                                
    return $xml;
}


=head2 items()

  @items= $result->items();

Return Net::MarkLogic::CIS::Result::Item objects for each part of the
response.

=cut

sub items 
{
    my $self = shift;
                                                                                
    return @{$self->{items}};
}
                                                                                

=head2 response()

my $http_resp = $result->response;

Returns the HTTP::Response object used to create this object.

=head1 BUGS

Big time. Watch out for changing APIs.


=head1 AUTHOR

    Tony Stubblebine
    tonys@oreilly.com

=head1 COPYRIGHT

Copyright 2004 Tony Stubblebine 

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

=head1 SEE ALSO

MarkLogic CIS documentation:
http://xqzone.marklogic.com

=cut

1; 
__END__

