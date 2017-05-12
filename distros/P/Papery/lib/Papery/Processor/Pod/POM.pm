package Papery::Processor::Pod::POM;

use strict;
use warnings;

use Papery::Processor;
our @ISA = qw( Papery::Processor );

use Pod::POM;

sub process {
    my ( $self, $pulp ) = @_;

    # parse the pod
    my $parser = Pod::POM->new( meta => 1 );
    my $pom = $parser->parse_text( $pulp->{meta}{_text} )
        or die $parser->error();

    # process the pod
    my $class = $pulp->{meta}{pod_pom_view} || 'Pod::POM::View::HTML';
    eval "use $class; 1;" or die $@;
    my $view = $class->new();
    my $content = $view->print($pom);

    # post-process the output of HTML views
    if ( $view->isa( 'Pod::POM::View::HTML' ) ) {
        $content =~ s{</?(?:body|html)[^>]*>}{}g;
    }

    # merge the metadata and content
    $pulp->merge_meta( $pom->metadata );
    $pulp->{meta}{_content} = $content;
    $pulp->{meta}{_pod_pom} = $pom;

    return $pulp;
}

1;

__END__

=head1 NAME

Papery::Processor::Pod::POM - Papery processor based on Pod::POM

=head1 SYNOPSIS

    # _config.yml
    _processors:
      pod: Pod::POM

    # metadata
    _processor: Pod::POM

=head1 DESCRIPTION

C<Papery::Processor::Pod::POM> will process the C<_text> of a C<Papery::Pulp>
object as POD, and put HTML in the C<_content>, using C<Pod::POM> for
parsing the POD, and by default C<Pod::POM::View::HTML> to turn it into
HTML.

=head1 METHODS

This class provides a single method:

=over 4

=item process( $pulp )

Analyze the C<_text> metadata, and update the C<$pulp> metadata and
C<_content>.

If the C<pod_pom_view> metadata key exists, it is assumed to contain
the name of a C<Pod::POM::View> class, that will be used instead to
produce the C<_content> metadata.

The intermediate C<Pod::POM> object returned by the C<Pod::POM> parser
is stored in the C<_pod_pom> metadata key.

=back

=head1 AUTHOR

Philippe Bruhat (BooK), C<< <book at cpan.org> >>

=head1 COPYRIGHT

Copyright 2010 Philippe Bruhat (BooK), all rights reserved.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

