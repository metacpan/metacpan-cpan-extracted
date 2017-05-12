package RDF::Server::Semantic::Atom;

use Moose::Role;

with 'RDF::Server::Semantic';

use Class::MOP ();
use Moose::Util::TypeConstraints;
use MooseX::Types::Moose qw( HashRef ArrayRef );

use RDF::Server::Types qw( Handler Model );
use RDF::Server::Semantic::Atom::Types qw( AtomHandler );

has '+handler' => (
    coerce => 1,
    isa => AtomHandler
);

{

my %info = (
    service => {
        class => 'Service',
        children => 'workspaces',
        child => 'workspace',
    },
    workspace => {
        class => 'Workspace',
        children => 'collections',
        child => 'collection',
    },
    collection => {
        class => 'Collection',
        children => 'categories',
        child => 'category'
    },
    category => {
        class => 'Category',
    },
);

sub build_atomic_handler {
    my( $semantic, $config ) = @_;

    $semantic = $semantic -> meta -> name;
    # we expect $config -> [0] to tell us the top-level type
    my($info, $type);

    if( is_ArrayRef( $config ) ) {
        $type = $config -> [0];
    }
    else { # expect HashRef
        $type = delete $config -> {type};
    }

    $info = $info{ $type };

    if( !defined $info ) {
        confess "Unknown Atom ($semantic) document type: $type";
    }

    my $class = $semantic . '::' . $info -> {'class'};

    Class::MOP::load_class($class);

    my %c;
    if( is_ArrayRef( $config ) ) {
        %c = %{$config -> [1]};
    }
    else {
        %c = %{ $config };
    }

    $c{model} = $c{model} -> [0]
        if is_ArrayRef( $c{model} ) 
           && @{$c{model}} == 1 
           && is_HashRef( $c{model} -> [0] );
    
    if( is_HashRef( $c{model} ) ) {
        my %eh_config = %{delete $c{model}};
        my $eh_class = delete($eh_config{class});
        eval {
            Class::MOP::load_class('RDF::Server::Model::' . $eh_class);
            $eh_class = 'RDF::Server::Model::' . $eh_class;
        };
        if( $@ ) {
            eval {
                Class::MOP::load_class($eh_class);
            };
            if( $@ ) {
                confess "Unable to load $eh_class or RDF::Server::Model::$eh_class";
            }
        }

        if( is_Model( $eh_class ) ) {
            $c{model} = $eh_class -> new( %eh_config );
        }
        else {
            confess "$eh_class isn't a Model";
        }
    }

    if( $info -> {'children'} ) {
        my $handlers = delete $c{$info -> {'children'}} || delete $c{$info -> {'child'}};
        if( defined $info -> {'children'} ) {
            $c{handlers} = [
                map { $semantic -> build_atomic_handler( [ 
                    $info -> {'child'}, 
                    { model => $c{model}, %$_ }
                ] ) } @$handlers
            ];
        }
    }

    delete $c{model} unless defined $c{model};

    return $class -> new(
        %c
    );
}

}

1;

__END__

=pod

=head1 NAME

RDF::Server::Semantic::Atom - RDF service with Atom-ic semantics

=head1 SYNOPSIS

 package My::Server;

 semantic 'Atom';

 ---

 my $server = My::Server -> new(
      handler => [ workspace => {
          collections => [
              { entry_handler => { },
                categories => [ ]
              }
          ]
      ]
  );

=head1 DESCRIPTION

The Atom semantic module modifies the server configuration by adding an
ArrayRef to Handler coercion that allows configuration from plain text
files without Perl code.  The Atom semantic assumes a heirarchy of document
types: Services :> Workspaces :> Collections :> Categories :> Entries.
Collections can also manage Entries without Categories.

The top-level handler can be any of the available Atom document types, but
sub-handlers are expected to be the proper child type.

=head1 SERVER CONFIGURATION

The Atom semantic allows you to configure the top-level handler by setting it
to an array reference.  The semantic will coerce it into the proper set of
objects working within the Atom semantic space.

The top level handler should be one of C<service>, C<workspace>, or 
C<collection>.  You can also use C<category>, but categories are of 
limited use at the top level.

The Atom specification defines a clear heirarchy of documents:
services contain workspaces, workspaces contain collections, and collections
contain categories and entries.

=over 4

=item service

A service is a collection of workspaces.

=item workspace

=item collection

=item category

=item model

=back

=head1 METHODS

=over 4

=item build_atomic_handler ($config)

The Atom semantic defines a subtype of the Handler type and a coercion that
uses build_atomic_handler.  This method manages the conversion from an 
array reference to a handler object appropriate for the server's 
interface role.

If you subclass the Atom semantic, you will need to provide additional
classes for Service, Workspace, Collection, and Category.  For example,
if you create My::Semantic, then you will also need to create
My::Semantic::Service, My::Semantic::Workspace, etc.  These can be subclasses
of the equivalent classes provided by the stock Atom semantic.

This method assumes the following relationships in the configuration being
coerced:

 Handler Type   Child Type   Entries   Child Configuration
 ------------   ----------   -------   -------------------
 service        workspace              workspaces
 workspace      collection             collections
 collection     category        X      categories
 category                       X

=back

=head1 SEE ALSO

L<RDF::Server::Style::Atom::Service>,
L<RDF::Server::Style::Atom::Workspace>,
L<RDF::Server::Style::Atom::Collection>,
L<RDF::Server::Style::Atom::Category>

=head1 AUTHOR 
            
James Smith, C<< <jsmith@cpan.org> >>
      
=head1 LICENSE
    
Copyright (c) 2008  Texas A&M University.
    
This library is free software.  You can redistribute it and/or modify
it under the same terms as Perl itself.
            
=cut
