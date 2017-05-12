package RDF::Helper::Statement;
use Moose;
use Moose::Util::TypeConstraints;

class_type 'RDF::Helper::Node::Resource';
class_type 'RDF::Helper::Node::Literal';
class_type 'RDF::Helper::Node::Blank';

my $ValidNode = subtype as
'RDF::Helper::Node::Resource|RDF::Helper::Node::Literal|RDF::Helper::Node::Blank';

has [qw(subject predicate object)] => (
    isa      => $ValidNode,
    is       => 'ro',
    required => 1
);

sub BUILDARGS {
    my $class = shift;
    my ( $s, $p, $o ) = @_;
    return { subject => $s, predicate => $p, object => $o };
}

package RDF::Helper::Node::API;
use Moose::Role;

requires 'as_string';

sub is_resource { 0 }
sub is_literal  { 0 }
sub is_blank    { 0 }

package RDF::Helper::Node::Resource;
use Moose;
use URI;
with qw(RDF::Helper::Node::API);

has uri => (
    isa      => 'Str',
    reader   => 'uri_value',
    required => 1,
);

sub uri         { URI->new( shift->uri_value ) }
sub is_resource { 1 }
sub as_string   { shift->uri_value }

package RDF::Helper::Node::Literal;
use Moose;
with qw(RDF::Helper::Node::API);

has value => (
    isa      => 'Str',
    reader   => 'literal_value',
    required => 1,
);

has datatype => (
    is        => 'ro',
    predicate => 'has_datatype'
);

has language => (
    reader => 'literal_value_language',
);

sub literal_datatype {
    my $self = shift;
    return unless defined $self->has_datatype;
    return URI->new( $self->datatype );
}

sub is_literal { 1 }
sub as_string  { shift->literal_value }

package RDF::Helper::Node::Blank;
use Moose;
with qw(RDF::Helper::Node::API);

has identifier => (
    isa      => 'Str',
    reader   => 'blank_identifier',
    required => 1
);

sub is_blank  { 1 }
sub as_string { shift->blank_identifier }

1
__END__