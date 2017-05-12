package MongoDBx::AutoDeref::LookMeUp;
BEGIN {
  $MongoDBx::AutoDeref::LookMeUp::VERSION = '1.110560';
}

#ABSTRACT: Provides the sieve that replaces DBRefs with deferred scalars.

use Moose;
use namespace::autoclean;

use Scalar::Util('weaken');
use MooseX::Types::Structured(':all');
use MooseX::Types::Moose(':all');
use Data::Visitor::Callback;
use Moose::Util::TypeConstraints();
use MongoDBx::AutoDeref::Types(':all');
use MongoDBx::AutoDeref::DBRef;
use Perl6::Junction('any');


has mongo_connection =>
(
    is => 'ro',
    isa => 'MongoDB::Connection',
    required => 1,
);



has visitor =>
(
    is => 'ro',
    isa => 'Data::Visitor::Callback',
    lazy => 1,
    builder => '_build_visitor',
    handles => { 'sieve' => 'visit' },
);

sub _build_visitor
{
    my ($self) = @_;
    weaken($self);
    if($self->sieve_type eq 'output')
    {
        return Data::Visitor::Callback->new
        (
            hash => sub
            {
                my ($visitor, $data) = @_;
                return unless is_DBRef($data);
                $_ = MongoDBx::AutoDeref::DBRef->new
                (
                    %$data,
                    mongo_connection => $self->mongo_connection,
                    lookmeup => $self,
                );
            },
            ignore_return_values => 1,
        );
    }
    else
    {
        return Data::Visitor::Callback->new
        (
            'MongoDBx::AutoDeref::DBRef' => sub
            {
                my ($visitor, $obj) = @_;
                $_ = $obj->revert()
            },
            ignore_return_values => 1,
        );
    }
}


has sieve_type =>
(
    is => 'ro',
    isa => Moose::Util::TypeConstraints::enum([qw/input output/]),
    required => 1,
);

1;


=pod

=head1 NAME

MongoDBx::AutoDeref::LookMeUp - Provides the sieve that replaces DBRefs with deferred scalars.

=head1 VERSION

version 1.110560

=head1 DESCRIPTION

This module provides the guts for L<MongoDBx::AutoDeref>. It modifies documents
in place to replace DBRefs with actual objects that implement the deferred
fetch. This class also will deflate those same objects back into plain hashes.

=head1 PUBLIC_ATTRIBUTES

=head2 mongo_connection

    is: ro, isa: MongoDB::Connection, required: 1

In order to defer fetching the referenced document, a connection object needs to
be accessible. This is required for construction of the object.

=head2 visitor

    is: ro, isa: Data::Visitor::Callback
    lazy: 1, builder => _build_visitor
    handles: sieve => visit

In order to find the DBRefs within the returned document, Data::Visitor is used
to traverse the structure. The raw hashes are replaced with proper objects that
implement the lookup via L<MongoDBx::AutoDeref::DBRef/fetch>. Upon
insert/update, these objects are then deflated back to their raw hash
references.

=head2 sieve_type

    is: ro, isa: enum(input,output), required: 1

The LookMeUp object can operate in two modes. In the input mode,
L<MongoDBx::AutoDeref::DBRef> objects will be deflated to plain hashes. In
output mode, plain hashes that pass the DBRef type constraint will be inflated.

=head1 PUBLIC_METHODS

=head2 sieve

    (HashRef)

This method takes the returned document from MongoDB and traverses it to replace
DBRefs with defered lookups of the actual document. It does this IN PLACE on the
document.

The obverse is true as well. If storing a document the document will be
traversed and the DBRef objects will be deflated into plain hashes

=head1 AUTHOR

Nicholas R. Perez <nperez@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Nicholas R. Perez <nperez@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

