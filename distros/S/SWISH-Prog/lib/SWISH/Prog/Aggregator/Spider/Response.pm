package SWISH::Prog::Aggregator::Spider::Response;
use strict;
use warnings;
use base qw( SWISH::Prog::Class );
use Carp;
use Data::Dump qw( dump );
use Search::Tools::UTF8;
use HTML::LinkExtor;
use URI;
use HTML::Tagset;
use HTML::HeadParser;

our $VERSION = '0.75';

__PACKAGE__->mk_accessors(
    qw(
        http_response
        link_tags
        )
);

=pod

=head1 NAME

SWISH::Prog::Aggregator::Spider::Response - spider response

=head1 SYNOPSIS

 use SWISH::Prog::Aggregator::Spider::UA;
 my $ua = SWISH::Prog::Aggregator::Spider::UA->new;
 my $response = $ua->get('http://swish-e.org/');
 my $http_response = $response->http_response;
 
 # $ua isa LWP::RobotUA subclass
 # $response isa SWISH::Prog::Aggregator::Spider::Response
 # $http_response isa HTTP::Response

=head1 DESCRIPTION

SWISH::Prog::Aggregator::Spider::Response wraps the
HTTP::Response class and provides some convenience methods.

=head1 METHODS

=cut

=head2 init

Override internal constructor setup method.

=cut

sub init {
    my $self = shift;
    $self->SUPER::init(@_);

    # TODO set by our UA. duplicate?
    #$self->{link_tags} ||= { a => 1, frame => 1, iframe => 1, };
    return $self;
}

=head2 http_response

Returns internal HTTP::Response object.

=cut

=head2 success

Shortcut for $response->http_response->is_success.

=cut

sub success {
    return shift->http_response->is_success;
}

=head2 status

Shortcut for $response->http_response->code.

=cut

sub status {
    return shift->http_response->code;
}

=head2 ct

Shortcut for $response->response->header('content-type').
Any encoding will be stripped from the returned string.

=cut

sub ct {
    my $self = shift;
    my $ct   = $self->http_response->header('content-type');
    $ct =~ s/;.+// if $ct;
    return $ct;
}

=head2 is_html

Returns true if ct() looks like HTML or XHTML.

=cut

sub is_html {
    my $self = shift;
    my $ct   = $self->ct;
    return defined $ct
        && ( $ct eq 'text/html' || $ct eq 'application/xhtml+xml' );
}

=head2 content

Shortcut for $response->http_response->decoded_content.

=cut

sub content {
    return shift->http_response->decoded_content;
}

=head2 links

Returns array of href targets in content(). Parsed
using HTML::LinkExtor.

=cut

sub links {
    my $self          = shift;
    my @links         = ();
    my $http_response = $self->http_response;
    my $debug         = $self->debug;

    if ( $http_response and $self->is_html ) {
        my $le   = HTML::LinkExtor->new();
        my $base = $http_response->base;
        $le->parse( $self->content );

        my %skipped_tags;

        for my $link ( $le->links ) {
            my ( $tag, %attr ) = @$link;

            # which tags to use
            my $attr = join ' ', map {qq[$_="$attr{$_}"]} keys %attr;

            $debug and SWISH::Prog::Utils->write_log(
                uri => $base,
                msg => "extracted tag '<$tag $attr>'"
            );

            if ( !exists $self->link_tags->{$tag} ) {
                $debug
                    and SWISH::Prog::Utils->write_log(
                    uri => $base,
                    msg => "skipping tag '<$tag $attr>', not on whitelist"
                    );
                next;
            }

            # Grab which attribute(s) which might contain links for this tag
            my $links = $HTML::Tagset::linkElements{$tag};
            $links = [$links] unless ref $links;

            my $found = 0;

            # check each attribute to see if a link exists
            for my $attribute (@$links) {
                if ( $attr{$attribute} ) {

                    # strip any anchors as noise
                    $attr{$attribute} =~ s/#.*//;

                    my $u = URI->new_abs( $attr{$attribute}, $base );
                    push @links, $u;
                    $debug
                        and SWISH::Prog::Utils->write_log(
                        uri => $base,
                        msg => "added '$u' to links",
                        );
                    $found++;
                }
            }

            if ( !$found && $debug ) {
                SWISH::Prog::Utils->write_log(
                    uri => $base,
                    msg => "tag <$tag $attr> has no links or is a duplicate",
                );
            }

        }

        $debug
            and SWISH::Prog::Utils->write_log(
            uri => $base,
            msg => sprintf( "found %d links", scalar @links ),
            );

    }
    return @links;
}

=head2 link_tags( I<hashref> )

Set hashref of tags considered valid "links". Used by the links()
method.

=cut

=head2 title

Returns document title, verifying that UTF-8
flag is set correctly on the response content.

=cut

sub title {
    my $self = shift;
    return unless $self->is_html;

    my $p = HTML::HeadParser->new;

    # HTML::HeadParser throws warning if utf-8 flag is not on for utf-8 bytes.
    # So we trust the content-type header and
    # verify that the utf-8 flag is on.
    if ( $self->http_response->header('content-type') =~ m/utf-8/i ) {
        $p->parse( to_utf8( $self->content ) );
    }
    else {
        $p->parse( $self->content );
    }
    return $p->header('Title');
}

# delegate all other method calls the the http_response object.
# cribbed from HTTP::Message
our $AUTOLOAD;

sub AUTOLOAD {
    my $method = substr( $AUTOLOAD, rindex( $AUTOLOAD, '::' ) + 2 );

    # We create the function here so that it will not need to be
    # autoloaded the next time.
    no strict 'refs';
    *$method = sub {
        local $Carp::Internal{ +__PACKAGE__ } = 1;
        shift->http_response->$method(@_);
    };
    goto &$method;
}

sub DESTROY { }    # avoid AUTOLOADing it

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
