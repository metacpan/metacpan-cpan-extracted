package RDF::Server::Semantic::Atom::Types;

use MooseX::Types -declare => [qw(
    Workspace Collection Category
    WorkspaceCodeRef
    CollectionCodeRef
    CategoryCodeRef
    AtomHandler
)];

use RDF::Server::Types qw( Handler );

use MooseX::Types::Moose qw(
    Object
    ClassName
    Str
    CodeRef
    ArrayRef
);

subtype AtomHandler,
    as Handler;

coerce AtomHandler,
    from ArrayRef =>
    via {
        RDF::Server::Semantic::Atom -> build_atomic_handler(@_);
    };

coerce AtomHandler,
    from HashRef =>
    via {
        RDF::Server::Semantic::Atom -> build_atomic_handler(@_);
    };

subtype Workspace,
    as Object,
    where { $_ -> isa( 'RDF::Server::Semantic::Atom::Workspace' ) },
    message { "Object isn't a Workspace" };

subtype Collection,
    as Object,
    where { $_ -> isa( 'RDF::Server::Semantic::Atom::Collection' ) },
    message { "Object isn't a Collection" };

subtype Category,
    as Object,
    where { $_ -> isa( 'RDF::Server::Semantic::Atom::Category' ) },
    message { "Object isn't a Category" };

subtype WorkspaceCodeRef,
    as CodeRef
    ;

coerce WorkspaceCodeRef,
    from ArrayRef,
    via { 
        my($a) = @_; 
        return sub { $a };
    };

subtype CollectionCodeRef,
    as CodeRef
    ;

coerce CollectionCodeRef,
    from ArrayRef,
    via { 
        my($a) = @_; 
        return sub { $a };
    };

subtype CategoryCodeRef,
    as CodeRef
    ;

coerce CategoryCodeRef,
    from ArrayRef,
    via { 
        my($a) = @_; 
        return sub { $a };
    };

1;

__END__

=pod

=head1 NAME

RDF::Server::Semantic::Atom::Types - Atom-specific types

=head1 SYNOPSIS

 use RDF::Server::Semantic::Atom::Types qw(Workspace Collection);

=head1 DESCRIPTION

=head1 TYPES

=head1 AUTHOR 
            
James Smith, C<< <jsmith@cpan.org> >>
      
=head1 LICENSE
    
Copyright (c) 2008  Texas A&M University.
    
This library is free software.  You can redistribute it and/or modify
it under the same terms as Perl itself.
            
=cut

