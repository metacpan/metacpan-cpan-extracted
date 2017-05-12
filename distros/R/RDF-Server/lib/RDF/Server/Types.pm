package RDF::Server::Types;

use MooseX::Types -declare => [qw(
    Handler Resource Model
    Renderable Mutable Container
    Exception
    Protocol Interface Semantic Formatter
    UUID
)];

use MooseX::Types::Moose qw(
    Object
    ClassName
    Str
    Any
);


###
# Base classes
###

subtype Handler,
    as Object,
    where { RDF::Server::Types::_does_role($_, 'RDF::Server::Role::Handler' ) },
    message { "Object isn't a Handler" };

subtype Resource,
    as 'Object|ClassName',
    where { RDF::Server::Types::_does_role($_, 'RDF::Server::Role::Resource' ) },
    message { "Object isn't a Entry" };

subtype Model,
    as 'Object|ClassName',
    where { RDF::Server::Types::_does_role($_, 'RDF::Server::Role::Model' ) },
    message { "Object isn't a Model" };

subtype Exception,
    as Object,
    where { $_ -> isa('RDF::Server::Exception') },
    message { "Object isn't an Exception" };


###
# Roles
###

subtype Renderable,
    as 'Object|ClassName',
    where { RDF::Server::Types::_does_role($_, 'RDF::Server::Role::Renderable' ) },
    message { "Object isn't Renderable" };

subtype Container,
    as Renderable,
    where { RDF::Server::Types::_does_role($_, 'RDF::Server::Role::Container' ) },
    message { "Object isn't a Container" };

subtype Mutable,
    as Renderable,
    where { RDF::Server::Types::_does_role($_, 'RDF::Server::Role::Mutable' ) },
    message { "Object isn't Mutable" };



subtype Protocol,
    as ClassName,
    where { RDF::Server::Types::_does_role($_, 'RDF::Server::Protocol' ) },
    message { "Class isn't a Protocol" };

subtype Interface,
    as ClassName,
    where { RDF::Server::Types::_does_role($_, 'RDF::Server::Interface' ) },
    message { "Class isn't an Interface" };

subtype Semantic,
    as ClassName,
    where { RDF::Server::Types::_does_role($_, 'RDF::Server::Semantic' ) },
    message { "Class isn't a Semantic" };

subtype Formatter,
    as ClassName,
    where { RDF::Server::Types::_does_role($_, 'RDF::Server::Formatter' ) },
    message { "Class isn't a Formatter" };


subtype UUID,
    as Str,
    where { m{^[0-9a-f]{8}(-[0-9a-f]{4}){3}-[0-9a-f]{12}$}i },
    message { "String isn't a uuid" };


###
# coercions
###

coerce Model,
    from HashRef =>
    via {
        my($eh_config) = @_;

        my $eh_class = delete $eh_config->{class};
         #print STDERR "eh_class: $eh_class\n";
        eval {
            Class::MOP::load_class('RDF::Server::Model::' . $eh_class);
            $eh_class = 'RDF::Server::Model::' . $eh_class;
        };
        if( $@ ) {
            eval {
                Class::MOP::load_class($eh_class);
            };
            if( $@ ) {
                Carp::confess qq{Unable to load $eh_class or RDF::Server::Model::$eh_class};
            }
        }

        $eh_class -> new( %$eh_config );
    };

###
# support functions
###

sub _does_role {
    my( $class, $role ) = @_;

    #print STDERR "does role: $class ? $role\n";
    my $ret = 0;
    eval {
        $ret = $class -> can('meta') && $class -> meta && $class -> meta -> does_role( $role );
    };

    return 0 if $@;
    return $ret;
}

1;

__END__

=pod

=head1 NAME

RDF::Server::Types - Moose types used by the RDF::Server framework

=head1 SYNOPSIS

 use RDF::Server::Types qw( Mutable );

 if( is_Mutable( $handler ) ) { ... }

=head1 DESCRIPTION

This module bundles together useful types.

=head1 TYPES

=head2 Handlers

=over 4

=item Renderable

=item Container

=item Mutable

=back

=head2 Responsibilities

=over 4

=item Interface

=item Protocol

=item Exception

=back

=head1 AUTHOR 
            
James Smith, C<< <jsmith@cpan.org> >>
      
=head1 LICENSE
    
Copyright (c) 2008  Texas A&M University.
    
This library is free software.  You can redistribute it and/or modify
it under the same terms as Perl itself.
            
=cut

