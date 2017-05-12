package RDF::Server::Semantic::RDF;

use Moose::Role;

with 'RDF::Server::Semantic';

use Class::MOP ();
use Moose::Util::TypeConstraints;
use MooseX::Types::Moose qw( HashRef ArrayRef );

use RDF::Server::Types qw( Handler Model );
use RDF::Server::Semantic::RDF::Types qw( :all );
use RDF::Server::Semantic::RDF::Handler;
use RDF::Server::Semantic::RDF::Collection;

has '+handler' => (
    coerce => 1,
    isa => RDFHandler
);

sub build_rdfic_handler {
    my( $semantic, $config ) = @_;

    $semantic = $semantic -> meta -> name;
    # we expect $config -> [0] to tell us the top-level type
    my($info, $type);

    if( is_ArrayRef( $config ) ) {
        return "${semantic}::Collection" -> new(
            path_prefix => undef,
            handlers => [
                map { $semantic -> build_rdfic_handler( $_ ) } @$config
            ]
        );
    }

    my %c = %$config;

    $c{model} = $c{model} -> [0]
        if is_ArrayRef( $c{model} )
           && @{$c{model}} == 1
           && is_HashRef( $c{model} -> [0] );
    
    my $class = "${semantic}::Handler";
    return $class -> new( %c );
}

1;

__END__

=head1 NAME

RDF::Server::Semantic::RDF - RDF semantic for the RDF::Server framework

=head1 SYNOPSIS

 package My::Server;

 semantic 'RDF';

=head1 DESCRIPTION

The RDF semantic is the simplest semantic, associating a complete RDF
document with each URL.  Onle RDF models are supported.

=head1 METHODS

=over 4

=item build_rdfic_handler

Based on the data structure passed into the C<new> method, this builds 
the internal object structure used by the server.  This method expects
the C<handler> attribute to reference an array reference of hash references,
one per RDF model.  If only one RDF model is being served, the C<handler>
attribute can point to its hash definition instead of the array reference.

=back

=head1 AUTHOR
    
James Smith, C<< <jsmith@cpan.org> >>
    
=head1 LICENSE
  
Copyright (c) 2008  Texas A&M University.

This library is free software.  You can redistribute it and/or modify
it under the same terms as Perl itself.
    
=cut
