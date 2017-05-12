package RDF::Server::Role::Model;

use Moose::Role;

use MooseX::Types::Moose qw( Str HashRef Bool Object );
use Class::MOP;

has base_uri => (
    is => 'rw',
    isa => Str,
    lazy => 1,
    default => sub { (shift) -> namespace }
);

has namespaces => (
    is => 'rw',
    isa => HashRef,
    lazy => 1,
    default => sub { +{ } },
);

has namespace => (
    is => 'rw',
    isa => 'Str',
    required => 1
);

has expand_qnames => (
    is => 'rw',
    isa => Bool,
    lazy => 1,
    default => sub { 0 },
);

has uuid_generator => (
    is => 'rw',
    isa => Object,
    lazy => 1,
    default => sub {
        Class::MOP::load_class('Data::UUID');
        new Data::UUID;
    },
    handles => {
        'new_uuid' => 'create_str'
    }
);

requires 'resource';

requires 'resources';

requires 'resource_exists';

# has_triple(s,p,o)
# where s|p|o can be a string or arrayref ([ nameSpace, localName ])
requires 'has_triple';

requires 'add_triple';

requires 'get_triples';

1;

__END__

=pod

=head1 NAME

RDF::Server::Role::Model - triple store role

=head1 SYNOPSIS

 package My::TripleStore;

 use Moose;
 with 'RDF::Server::Role::Model';

 has store => (
    is => 'rw',
    isa => 'RDF::Core::Model',
    default => sub {
        new RDF::Core::Model( Storage => new RDF::Core::Storage::Memory )
    }
 );

 sub has_triple { }
 sub resource { }
 sub resources { }

 ...

=head1 DESCRIPTION

This role defines the interface expected by the RDF::Server framework when
working with a triple store.  RDF::Server comes with several built for current
RDF storage modules.  See L<RDF::Server::Model>.

=head1 METHODS

=over 4

=item resource ($namespace, $id) : Resource

=item resources ($namespace) : Iterator

=item resource_exists ($namespace, $id) : Bool

=item add_triple ($s, $p, $o) : Bool

=item has_triple ($s, $p, $o) : Bool

Returns true if the indicated triple is present in the triple store.  Any of
the parameters may be array references to two-element arrays of the form 
C<[ $namespace, $localvalue ]>.

=back

=head1 AUTHOR 
            
James Smith, C<< <jsmith@cpan.org> >>
      
=head1 LICENSE
    
Copyright (c) 2008  Texas A&M University.
    
This library is free software.  You can redistribute it and/or modify
it under the same terms as Perl itself.
            
=cut

