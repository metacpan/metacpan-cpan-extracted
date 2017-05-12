package RDF::Server::Role::Handler;

use Moose::Role;

has path_prefix => (
    is => 'rw',
    isa => 'Maybe[Str]',
);

has handlers => (
    is => 'rw',
    isa => 'CodeRef',
    coerce => 1,
);

no Moose::Role;

sub matches_path { 
    my($self, $p) = @_;

    $p = "$p/";
    $p =~ s{/+}{/}g;
    $p =~ s{^/}{};

    my $u = $self -> path_prefix;
    $u = "$u/";
    $u =~ s{/+}{/}g;
    $u =~ s{^/}{};

    ##print STDERR $self -> meta -> name, ": [$p] cmp [$u]\n";

    return($u ? $u : "/") if index($p, $u) == 0;
    return "/$u" if index($p, '/' . $u) == 0;
}

sub handles_path {
    my($self, $prefix, $p, @rest) = @_;

    my($h,$path_info);

    #print STDERR "prefix: $prefix; p: $p\n";
    if(defined $self -> path_prefix) {
        my $matched_prefix;
        if( $matched_prefix = $self -> matches_path($p) ) {
            my $fragment = length($matched_prefix) <= length($p) ? substr($p, length($matched_prefix)) : '';
            return( $self, '' ) if $fragment =~ m{^/?$};

            return unless defined $self -> handlers;
            $prefix = $prefix . $self -> path_prefix;
            foreach my $c ( @{ $self -> handlers -> () } ) {
                ($h, $path_info) = $c -> handles_path( $prefix, $fragment, @rest );
                return($h, $path_info) if $h;
            }
        }
    }
    else {
        return unless defined $self -> handlers;
        foreach my $c ( @{ $self -> handlers -> () } ) {
            ($h, $path_info) = $c -> handles_path( $prefix, $p, @rest );
            return($h, $path_info) if $h;
        }
    }
    return ;
}


1;

__END__

=pod

=head1 NAME

RDF::Server::Role::Handler - manages handling part of a URL path

=head1 SYNOPSIS

 package My::Handler

 use Moose;

 with 'RDF::Server::Role::Handler';
 with 'RDF::Server::Role::Renderable';

 sub render { ... }

=head1 DESCRIPTION

A URL handler maps URL paths to handler objects.

=head1 CONFIGURATIOn

=over 4

=item path_prefix : Str

=back

=head1 METHODS

=over 4

=item handles_path ($)  (required)

Returns the object that is responsible for handling the request and providing
any response.

=item matches_path ($)

True if the given path is prefixed by the handler's C<path_prefix>.

=back

=head1 AUTHOR

James Smith, C<< <jsmith@cpan.org> >>

=head1 LICENSE

Copyright (c) 2008  Texas A&M University.

This library is free software.  You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
