package Search::Sitemap::Ping;
use strict; use warnings;
our $VERSION = '2.13';
our $AUTHORITY = 'cpan:JASONK';
use Moose;
use Search::Sitemap::Pinger;
use Class::Trigger qw(
    progress success failure
    before_submit after_submit
    before_engine after_engine
);
use MooseX::Types::Moose qw( ArrayRef );
use namespace::clean -except => [qw( meta add_trigger call_trigger )];

has 'urls'  => (
    is          => 'rw',
    isa         => ArrayRef,
    lazy        => 1,
    auto_deref  => 1,
    default     => sub { [] },
);

has 'engines'   => (
    is          => 'rw',
    isa         => ArrayRef['Search::Sitemap::Pinger'],
    auto_deref  => 1,
    lazy        => 1,
    default     => sub { [
        map { $_->new } Search::Sitemap::Pinger->ALL_PINGERS
    ] },
);

sub BUILDARGS {
    my $class = shift;
    my @urls = ();
    while ( @_ && $_[0] =~ m{^https?://} ) { push( @urls, shift ) }
    my $args = $class->SUPER::BUILDARGS( @_ );
    push( @{ $args->{ 'urls' } ||= [] }, @urls );
    return $args;
}

sub submit {
    my $self = shift;

    $self->call_trigger( 'before_submit' );
    my $total = @{ $self->urls } * @{ $self->engines };
    my $attempt = 0;
    my $success = 0;
    my $failure = 0;
    my $progress = sub {
        my $percent = sprintf( '%.02f', ( $attempt / $total ) * 100 );
        $self->call_trigger( 'progress',
            $percent, $total, $attempt, $success, $failure
        );
    };
    $progress->();
    for my $engine ( $self->engines ) {
        my @urls = $self->urls;
        $self->call_trigger( 'before_engine', $engine, \@urls );
        next unless @urls;
        $engine->submit( sub {
            my ( $status, $url, $msg ) = @_;
            $attempt++;
            if ( $status eq 'success' ) {
                $success++;
            } else {
                $failure++;
            }
            unless ( $progress->() ) {
                if ( $status eq 'failure' ) {
                    warn "Submitting $url to $engine failed: $msg\n";
                }
            }
        }, @urls );
        $self->call_trigger( 'after_engine', $engine );
    }
    $self->call_trigger( 'after_submit' );
}

__PACKAGE__->meta->make_immutable;
1;
__END__

=head1 NAME

Search::Sitemap::Ping - Notify search engines of sitemap updates

=head1 SYNOPSIS

  use Search::Sitemap::Ping;
  
  my $ping = Search::Sitemap::Ping->new(
    'http://www.jasonkohles.com/sitemap.gz',
  );
  
  $ping->submit;
  
  for my $url ( $ping->urls ) {
      print "$url\n";
      for my $engine ( $ping->engines ) {
          printf( "    %25s %s\n", $engine, $ping->status( $url, $engine ) );
      }
  }

=head1 DESCRIPTION

This module makes it easy to notify search engines that your sitemaps, or
sitemap indexes, have been updated.  See L<Search::Sitemap> and
L<Search::Sitemap::Index> for tools to help you create sitemaps and indexes.

=head1 METHODS

=head2 new

Create a new L<Search::Sitemap::Ping> object.

=head2 add_url( @urls )

Add one or more urls to the list of URLs to submit.

=head2 urls

Return the list of urls that will be (or were) submitted.

=head2 add_engine( @engines )

Add one or more search engines to the list of search engines to submit to.

=head2 engines

Return the list of search engines that will be (or were) submitted to.

=head2 submit

Submit the urls to the search engines, returns the number of successful
submissions.  This module uses L<LWP::UserAgent> for the web-based submissions,
and will honor proxy settings in the environment.  See L<LWP::UserAgent> for
more information.

=head2 status( $url [, $engine ] )

Returns the status of the indicated submission.  The URL must be specified,
If an engine is specified it will return just the status of the submission
to that engine, otherwise it will return a hashref of the engines that the url
will be (or was) submitted to, and the status for each one.

The status may be one of:

=over 4

=item * undef or empty string

Not submitted yet.

=item * 'SUCCESS'

Succesfully submitted.  Note that this just means it was successfully
transferred to the search engine, if there are problems in the file the
search engine may reject it later when it attempts to use it.

=item * HTTP Error String

In case of an error, the error string will be provided as the status.

=back

=head1 MODULE HOME PAGE

The home page of this module is
L<http://www.jasonkohles.com/software/Search-Sitemap>.  This is where you
can always find the latest version, development versions, and bug reports.  You
will also find a link there to report bugs.

=head1 SEE ALSO

L<Search::Sitemap>

=head1 AUTHOR

Jason Kohles, E<lt>email@jasonkohles.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005-2009 by Jason Kohles

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

