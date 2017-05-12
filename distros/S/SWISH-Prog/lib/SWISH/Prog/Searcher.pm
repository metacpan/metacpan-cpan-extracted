package SWISH::Prog::Searcher;
use strict;
use warnings;
use base qw( SWISH::Prog::Class );
use Carp;
use Scalar::Util qw( blessed );

our $VERSION = '0.75';

__PACKAGE__->mk_accessors(
    qw(
        max_hits
        invindex
        qp_config
        ),
);

=head1 NAME

SWISH::Prog::Searcher - base searcher class

=head1 SYNOPSIS

 my $searcher = SWISH::Prog::Searcher->new(
                    invindex        => 'path/to/index',
                    max_hits        => 1000,
                );
                
 my $results = $searcher->search( 'foo bar' );
 while (my $result = $results->next) {
     printf("%4d %s\n", $result->score, $result->uri);
 }

=head1 DESCRIPTION

SWISH::Prog::Searcher is a base searcher class. It defines
the APIs that all SWISH::Prog storage backends adhere to in
returning results from a SWISH::Prog::InvIndex.

=head1 METHODS

=head2 init

Overrides base method.

=head2 invindex

A SWISH::Prog::InvIndex object or directory path. Required. Set in new().

May be a single value or an array ref of values (for searching multiple
indexes at once).

=head2 max_hits

The maximum number of hits to return. Optional. Default is 1000.

=head2 qp_config

Optional hashref passed to Search::Query::Parser->new().

=cut

sub init {
    my $self = shift;
    $self->SUPER::init(@_);

    $self->{max_hits} ||= 1000;

    # set up invindex
    if ( !$self->{invindex} ) {
        croak "invindex required";
    }

    # force into an array
    if ( ref $self->{invindex} ne 'ARRAY' ) {
        $self->{invindex} = [ $self->{invindex} ];
    }

    for my $invindex ( @{ $self->{invindex} } ) {
        if ( !blessed($invindex) ) {

            # assume a InvIndex in the same namespace as $self
            my $class = ref($self);
            $class =~ s/::Searcher$/::InvIndex/;
            eval "require $class";
            croak $@ if $@;
            $invindex = $class->new( path => $invindex, clobber => 0 );

            #warn "new invindex in $class";

        }
        $invindex->open_ro;
    }

    return $self;
}

=head2 search( I<query> )

Returns a SWISH::Prog::Results object.

=cut

sub search {
    croak "you must override search() in your subclass";
}

1;

__END__

=head1 AUTHOR

Peter Karman, E<lt>perl@peknet.comE<gt>

=head1 BUGS

Please report any bugs or feature requests to C<bug-swish-prog at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=SWISH-Prog>.  
I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc SWISH::Prog


You can also look for information at:

=over 4

=item * Mailing list

L<http://lists.swish-e.org/listinfo/users>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=SWISH-Prog>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/SWISH-Prog>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/SWISH-Prog>

=item * Search CPAN

L<http://search.cpan.org/dist/SWISH-Prog/>

=back

=head1 COPYRIGHT AND LICENSE

Copyright 2008-2009 by Peter Karman

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=head1 SEE ALSO

L<http://swish-e.org/>
