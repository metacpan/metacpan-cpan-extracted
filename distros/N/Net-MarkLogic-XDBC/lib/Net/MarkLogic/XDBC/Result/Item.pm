
package Net::MarkLogic::XDBC::Result::Item;


=head1 NAME

Net::MarkLogic::CIS::Result::Item - Part of the response returned after an XDBC query.

=head1 SYNOPSIS

  print $item->content;
  print $item->as_xml;

  $type = $item->content_type;
  $type = $item->x_type;
  
=head1 DESCRIPTION

Alpha. API will change.

This class represents a single part of a multipart XDBC response.

=cut

use strict;
use Data::Dumper;
use LWP::UserAgent;
use Class::Accessor;
use Class::Fields;

our $VERSION     = 0.01;
our @BASIC_FIELDS = qw(content_type type content);
use base qw(Class::Accessor Class::Fields);
use fields @BASIC_FIELDS; 
Net::MarkLogic::XDBC::Result::Item->mk_accessors( @BASIC_FIELDS );

=head1 METHODS

=cut
 
sub new
{
    my ($class, %args) = @_;

    my $self = bless ({}, ref ($class) || $class);

    $self->content_type($args{content_type});
    $self->type($args{type});
    $self->content($args{content});
 
    return $self;
}

=head2 content()

  print $part->content;

The content returned in this part, often XML or an XML snippit.

=head2 as_xml()

An XML representation of this part including content type and xml type. The
part content is wrapped inside an entry node. The entry node contains two
attributes, content_type and type.

=cut

sub as_xml {
    my $self = shift;
                                                                                
    my $xml .= "<item content_type='" . $self->content_type . "'"
               . " type='" . $self->type . "'>\n"
               . $self->content
               . "</item>\n\n";
                                                                                
    return $xml;
}

=head2 content_type()

Content type, ex: text/xml

=head2 type

Schema type, Ex: node()


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

=cut

1; 
__END__

