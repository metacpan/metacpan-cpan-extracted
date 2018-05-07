package Search::Tools::ArgNormalizer;
use Moo::Role;
use Carp;
use Scalar::Util qw( blessed );
use Data::Dump qw( dump );

our $VERSION = '1.007';

sub BUILDARGS {
    my $self  = shift;
    my %args  = @_;
    my $q     = delete $args{query};
    my $debug = delete $args{debug};
    if ( !defined $q ) {
        confess "query required";
    }
    if ( !ref($q) ) {
        require Search::Tools::QueryParser;
        $args{query} = Search::Tools::QueryParser->new(
            debug => $debug,
            map { $_ => delete $args{$_} }
                grep { $self->queryparser_can($_) } keys %args
        )->parse($q);
    }
    elsif ( ref($q) eq 'ARRAY' ) {
        carp "query ARRAY ref deprecated as of version 0.24";
        require Search::Tools::QueryParser;
        $args{query} = Search::Tools::QueryParser->new(
            debug => $debug,
            map { $_ => delete $args{$_} }
                grep { $self->queryparser_can($_) } keys %args
        )->parse( join( ' ', @$q ) );
    }
    elsif ( blessed($q) and $q->isa('Search::Tools::Query') ) {
        $args{query} = $q;
    }
    else {
        confess
            "query param required to be a scalar string or Search::Tools::Query object";
    }
    $args{debug} = $debug;    # restore so it can be passed on
                              #dump \%args;
    return \%args;
}

sub queryparser_can {
    my $self = shift;
    my $attr = shift or confess "attr required";
    my $can  = Search::Tools::QueryParser->can($attr);

   #warn
   #    sprintf( "QueryParser->can(%s)==%s\n", $attr, ( $can || '[undef]' ) );

    return $can;
}

1;

__END__

=head1 NAME

Search::Tools::ArgNormalizer - Moo role for BUILDARGS

=head1 SYNOPSIS

 package MyTools;
 use Moo;
 with 'Search::Tools::ArgNormalizer';

=head1 DESCRIPTION

Moo::Role-based class for consistent BUILDARGS.

=head1 METHODS

=head2 queryparser_can( I<attribute> )

Simple wrapper around Search::Tools::QueryParser->can( I<attribute> )

=head2 BUILDARGS

Moo built-in method called by new(). This method standardizes new() params
across many Search::Tools::* classes.

=head1 BUGS

Please report any bugs or feature requests to C<bug-search-tools at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Search-Tools>.  
I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Search::Tools


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Search-Tools>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Search-Tools>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Search-Tools>

=item * Search CPAN

L<http://search.cpan.org/dist/Search-Tools/>

=back

=head1 COPYRIGHT

Copyright 2006-2009, 2014 by Peter Karman.

This package is free software; you can redistribute it and/or modify it under the 
same terms as Perl itself.

=head1 SEE ALSO

HTML::HiLiter, SWISH::HiLiter, L<Moo>, L<Class::XSAccessor>, L<Text::Aspell>

=cut
