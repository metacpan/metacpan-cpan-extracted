package RDF::Server::Semantic::Atom::Category;

use Moose;

with 'RDF::Server::Semantic::Atom::Handler';
with 'RDF::Server::Role::Container';

use RDF::Server::Types qw( Model );

use RDF::Server::Constants qw(:ns);

has term => (
    is => 'rw',
    isa => 'Str',
    required => 1,
);

has scheme => (
    is => 'rw',
    isa => 'Str',
    required => 1,
);

has '+path_prefix' => (
    lazy => 1,
    default => sub {
        (shift) -> term . '/';
    }
);

# the model that can return resource objects (entries)
has 'model' => (
    is => 'rw',
    isa => Model
);

around handles_path => sub {
    my($method, $self, $prefix, $p) = @_;

    # find Entry -- we don't have a set of handlers for this
    my($h, $path_info);

    unless(($h, $path_info) = $self -> $method($prefix, $p)) {
        return unless $self -> matches_path($p);

        my $fragment = substr($p, length($self -> path_prefix));
        $fragment =~ s{^/+}{};

        if( $self -> model -> has_triple( 
            [ $self -> model -> namespace, $fragment ], 
            [ ATOM_NS, 'category' ], 
            [ $self -> scheme, $self -> term ]
        ) ) {
            $h = $self -> model -> resource( [ $self -> model -> namespace, $fragment ] );
            $path_info = $fragment;
        }
    }

    return($h, $path_info);
};

no Moose;

sub render {
    my($self, $formatter, $uri) = @_;
    # produce an Atom document describing the collections (handlers)

    return $formatter -> category( %{ $self -> data( $uri ) } );
}

sub data {
    my($self, $uri) = @_;

    return +{
        term => $self -> term,
        scheme => $self -> scheme
    };
}

sub create {
    my($self, $formatter, $p, $content) = @_;
    # create new documents

    if( $p eq '' ) {
        $p = $self -> model -> new_uuid;
    }

    my $resource = $self -> model -> resource( 
        [ $self -> model -> namespace, $p ] 
    );

    $resource -> replace( $formatter,  $content );

    $resource -> add_triple(
        undef, 
        [ ATOM_NS, 'category' ],
        [ $self -> scheme, $self -> term ]
    );

    return $resource;
}

1;

__END__

=pod

=head1 NAME

RDF::Server::Semantic::Atom::Category - supports use of Atom category documents

=head1 SYNOPSIS

 package My::Server;

 interface 'REST';
 protocol 'HTTP';

 my $server = new My::Server
    handler => RDF::Server::Semantic::Atom::Collection -> new(
        uri_prefix => '/',
        handlers => [
            RDF::Server::Semantic::Atom::Category -> new (
                ...
            )
         ]
     )
 ;

=head1 DESCRIPTION

=head1 METHODS

=over 4

=item create

=item render

=item data

=back

=head1 AUTHOR 
            
James Smith, C<< <jsmith@cpan.org> >>
      
=head1 LICENSE
    
Copyright (c) 2008  Texas A&M University.
    
This library is free software.  You can redistribute it and/or modify
it under the same terms as Perl itself.
            
=cut

