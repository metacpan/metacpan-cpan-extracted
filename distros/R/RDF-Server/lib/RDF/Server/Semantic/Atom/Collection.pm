package RDF::Server::Semantic::Atom::Collection;

use Moose;

with 'RDF::Server::Semantic::Atom::Handler';
with 'RDF::Server::Role::Container';

use RDF::Server::Semantic::Atom::Types qw( CategoryCodeRef );

use RDF::Server::Types qw( Model );

use RDF::Server::Constants qw(:ns);

has 'model' => (
    is => 'ro',
    isa => Model,
    required => 1
);

has 'title' => (
    is => 'rw',
    isa => 'Str',
    required => 1
);

has 'accept' => (
    is => 'rw',
    isa => 'ArrayRef[Str]',
);

has '+handlers' => (
    isa => CategoryCodeRef
);

around handles_path => sub {
    my($method, $self, $prefix, $p, $must_exist) = @_;

    my($h, $path_info);

    unless(($h,$path_info) = $self -> $method($prefix, $p)) {
        return unless $self -> matches_path($p);

        my $fragment = substr($p, length($self -> path_prefix));
        $fragment =~ s{^/+}{};
  
        $h = $self -> model -> resource( [ $self -> model -> namespace, $fragment ] );
        $path_info = $fragment;
        return($h, $path_info) if !$must_exist || $h -> exists;
        return;
    }

    return($h, $path_info);
};

no Moose;

sub render {
    my($self, $formatter, $uri) = @_;

    return $formatter -> collection( %{ $self -> data( $uri ) } );
}

sub data {
    my($self, $uri_base) = @_;

    my $info = {   
        title => $self -> title,
        accept => $self -> accept,
    };

    my @handlers = @{ $self -> handlers -> () };
    if( @handlers ) {
        $info -> {categories} = [ ];

        foreach my $c ( @handlers ) {
            my $url = $uri_base . '/' . $c -> path_prefix;
            $url =~ s{/+}{/}g;
            push @{$info -> {categories}}, $c -> data( $url );
        }
    }

    return $info;
}

sub create {
    my($self, $formatter, $p, $content) = @_;
    # create new documents

    #print STDERR "create(", join(", ", @_), ")\n";

    if( $p eq '' ) {
        $p = $self -> model -> new_uuid;
    }

    my $resource = $self -> model -> resource(
        [ $self -> model -> namespace, $p ]
    );

    #print STDERR "resource: $resource at ", $resource->uri, "\n";

    #print STDERR "content: [$content]\n";

    $resource -> replace( $formatter, $content );
  
#    $resource -> add_triple(
#        undef,
#        [ ATOM_NS, 'category' ],
#        [ $self -> scheme, $self -> term ]
#    );

    return $resource;
}


1;

__END__

=pod

=head1 NAME

RDF::Server::Semantic::Atom::Collection - supports use of Atom collection documents

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

