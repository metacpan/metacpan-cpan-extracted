package Search::Sitemap::Pinger;
use strict; use warnings;
our $VERSION = '2.13';
our $AUTHORITY = 'cpan:JASONK';
use Moose;
use LWP::UserAgent;
use MooseX::Types::Moose qw( ArrayRef Str HashRef );
use MooseX::Types::URI qw( Uri );
use URI;
use Module::Find qw( usesub );
use Class::Trigger qw(
    before_submit after_submit
    before_submit_url after_submit_url
    success failure
);
use namespace::clean -except => [qw( meta add_trigger call_trigger )];

sub ALL_PINGERS { grep { $_ ne __PACKAGE__ } usesub( __PACKAGE__ ) }

has 'user_agent'    => (
    is      => 'rw',
    isa     => 'LWP::UserAgent',
    lazy    => 1,
    default => sub {
        my $self = shift;
        LWP::UserAgent->new(
            timeout     => 10,
            env_proxy   => 1,
        );
    },  
);      

sub submit {
    my $self = shift;
    my $cb = ( ref $_[0] eq 'CODE' ) ? shift : undef;

    for my $url ( @_ ) {
        my $submit_url = $self->submit_url_for( "$url" );
        my $response = $self->user_agent->get( $submit_url );
        if ( $response->is_success ) {
            if ( $cb ) { $cb->( success => $url, $response->content ) }
            $self->call_trigger( success => $url, $response->content );
        } else {
            if ( $cb ) { $cb->( failure => $url, $response->status_line ) }
            $self->call_trigger( failure => $url, $response->status_line );
        }
    }
}

__PACKAGE__->meta->make_immutable;
1;
__END__

=head1 NAME

Search::Sitemap::Pinger - Notify a specific search engines of sitemap updates

=head1 SYNOPSIS

This package and it's subclasses are for internal use.  The public interface
to them is L<Search::Sitemap::Ping>.
  
=head1 METHODS

=head2 ALL_PINGERS

Called as a class method (usually as C<Search::Sitemap::Pinger->ALL_PINGERS>)
returns a list of all the installed subclasses of L<Search::Sitemap::Pinger>.

=head2 new

Create a new L<Search::Sitemap::Pinger> object.

=head2 submit( [ $callback ], @urls );

Submit the urls to the search engine.  If the first argument is a code
reference, it will be used as a callback after each attempted URL submission.
The callback code reference will be passed either the word 'success' or the
word 'failure', followed by the url that was attempted, followed by either
the HTML content that accompanied a success or the HTTP error message that
accompanied a failure.

=head1 SEE ALSO

L<Search::Sitemap>

=head1 AUTHOR

Jason Kohles, E<lt>email@jasonkohles.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005-2009 by Jason Kohles

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

