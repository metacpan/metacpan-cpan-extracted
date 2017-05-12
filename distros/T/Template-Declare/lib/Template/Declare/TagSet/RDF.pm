package Template::Declare::TagSet::RDF;

use strict;
use warnings;
use base 'Template::Declare::TagSet';
#use Smart::Comments;

sub get_tag_list {
    return [ qw{
        Alt    Bag    Description
        List    Property    RDF
        Seq    Statement    XMLLiteral
        about   li
        first    nil    object
        predicate    resource    rest
        subject    type    value
    }, (map { "_$_" } 1..10) ];
}


1;
__END__

=head1 NAME

Template::Declare::TagSet::RDF - Template::Declare tag set for RDF

=head1 SYNOPSIS

    # normal use on the user side:
    use base 'Template::Declare';
    use Template::Declare::Tags RDF => { namespace => 'rdf' };

    template foo => sub {
        rdf::RDF {
            attr { 'xmlns:rdf' => "http://www.w3.org/1999/02/22-rdf-syntax-ns#" }
            rdf::Description {
                attr { about => "Matilda" }
                #...
            }
        }
    };

=head1 DESCRIPTION

Template::Declare::TagSet::RDF defines a full set of RDF tags for use in
Template::Declare templates. You generally won't use this module directly, but
will load it via:

    use Template::Declare::Tags 'RDF';

=head1 METHODS

=head2 new( PARAMS )

    my $html_tag_set = Template::Declare::TagSet->new({
        package   => 'MyRDF',
        namespace => 'rdf',
    });

Constructor inherited from L<Template::Declare::TagSet|Template::Declare::TagSet>.

=head2 get_tag_list

    my $list = $tag_set->get_tag_list();

Returns an array ref of all the RDF tags defined by
Template::Declare::TagSet::RDF. Here is the complete list:

=over

=item C<Alt>

=item C<Bag>

=item C<Description>

=item C<List>

=item C<Property>

=item C<RDF>

=item C<Seq>

=item C<Statement>

=item C<XMLLiteral>

=item C<about>

=item C<li>

=item C<first>

=item C<nil>

=item C<object>

=item C<predicate>

=item C<resource>

=item C<rest>

=item C<subject>

=item C<type>

=item C<value>

=item C<_1>

=item C<_2>

=item C<_3>

=item C<_4>

=item C<_5>

=item C<_6>

=item C<_7>

=item C<_8>

=item C<_9>

=item C<_10>

=back

This list may be not exhaustive; if you find some important missing ones,
please let us know. :)

=head1 AUTHOR

Agent Zhang <agentzh@yahoo.cn>

=head1 SEE ALSO

L<Template::Declare::TagSet>, L<Template::Declare::TagSet::HTML>,
L<Template::Declare::TagSet::XUL>, L<Template::Declare::Tags>,
L<Template::Declare>.

=begin comment

Tag set for RDF Schema:

    Class    Container    ContainerMembershipProperty
    Datatype    Literal    Resource
    comment    domain    isDefinedBy
    label    member    range
    seeAlso    subClassOf    subPropertyOf

=cut
