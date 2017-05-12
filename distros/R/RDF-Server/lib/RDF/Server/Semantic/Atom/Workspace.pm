package RDF::Server::Semantic::Atom::Workspace;

use Moose;

with 'RDF::Server::Semantic::Atom::Handler';
with 'RDF::Server::Role::Renderable';

use RDF::Server::Constants qw( :ns );

use RDF::Server::Semantic::Atom::Types qw( CollectionCodeRef );

has '+handlers' => (
   isa => CollectionCodeRef
);

has title => (
    is => 'rw',
    isa => 'Str',
    required => 1
);

no Moose;

sub render {
    my($self, $formatter, $uri) = @_;

    my $url_base = $uri . '/';
    $url_base =~ s{/+}{/};
    # produce an Atom document describing the collections (handlers)
    return $formatter -> workspace( %{ $self -> data($url_base) } );
}

sub data {
    my($self, $url_base) = @_;

    my $info = {
        title => $self -> title,
    };

    my @handlers = @{$self -> handlers -> ()};

    if( @handlers ) {
        $info -> {collections} = [ ];
        foreach my $c ( @handlers ) {
            my $i = $c -> data($url_base);
            my $link = $url_base . '/' . $c -> path_prefix;
            $link =~ s{/+}{/}g;
            $i -> {link} = $link;
            push @{$info -> {collections}}, $i;
        }
    }

    return $info;
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
 semantic 'Atom';

 my $server = new My::Server
    handler => RDF::Server::Semantic::Atom::Workspace -> new(
        uri_prefix => '/',
        handlers => [
            RDF::Server::Semantic::Atom::Collection -> new (
                ...
            )
         ]
     )
 ;

=head1 DESCRIPTION

=head1 METHODS

=over 4

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

