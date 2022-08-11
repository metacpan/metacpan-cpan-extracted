package Perl::Critic::Policy::Modules::RequireExplicitPackage::ObjectPad;
use strict;
use warnings;
use parent qw(Perl::Critic::Policy::Modules::RequireExplicitPackage);
use Class::Method::Modifiers;
our $VERSION = "0.001";

=head1 NAME

Perl::Critic::Policy::Modules::RequireExplicitPackage::ObjectPad - Always make the package/Object::Pad class explicit.

=cut

=head1 METHOLDS

=head2 violates

Please see L<Perl::Critic::Policy::Modules::RequireExplicitPackage::violates>

=cut

# PODNAME: Perl::Critic::Policy::Modules::RequireExplicitPackage

around violates => sub {
    my $orig = shift;
    my ($self, $elem, $doc) = @_;
    $doc = _replace_class($doc);
    return $orig->($self, $elem, $doc);
};

=head2 _replace_class

replace 'use Object::Pad' and 'class XXXX' with `package XXX` in L<PPI::Document> object, to make it be processable by L<Perl::Critic::Policy::Modules::RequireExplicitPackage::violates>

Argument: PPI::Document object
Return: cloned PPI::document object

=cut

sub _replace_class {
    my $doc        = shift;
    my $cloned_doc = $doc->clone();
    my $object_pad = $cloned_doc->find_first(
        sub {
                    $_[1]->parent == $_[0]
                and $_[1]->isa('PPI::Statement::Include')
                and ($_[1]->type   // '') eq 'use'
                and ($_[1]->module // '') eq 'Object::Pad';
        });
    return $cloned_doc unless $object_pad;
    my $class = $cloned_doc->find_first(
        sub {
                    $_[1]->parent == $_[0]
                and $_[1]->isa('PPI::Statement')
                and $_[1]->child(0)->isa('PPI::Token::Word')
                and $_[1]->child(0)->literal eq 'class';
        });
    return $cloned_doc unless $class;
    return $cloned_doc unless "$class" =~ /class\s+(\w+)/;
    my $class_name = $1;
    $cloned_doc->remove_child($object_pad);
    my $package_code      = "package $class_name;";
    my $package_doc       = PPI::Document->new(\$package_code);
    my $package_statement = $package_doc->find_first(sub { $_[1]->isa('PPI::Statement::Package') });
    $package_doc->remove_child($package_statement);
    $class->insert_before($package_statement);
    return $cloned_doc;
}
1;

