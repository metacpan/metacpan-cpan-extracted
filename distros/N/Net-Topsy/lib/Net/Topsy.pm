# This is for PAUSE
package Net::Topsy;

use MooseX::Declare;

class Net::Topsy with Net::Topsy::Role::API {
    use Carp qw/croak confess/;
    use Moose;
    use URI::Escape;
    use JSON::Any qw/XS DWIW JSON/;
    use Data::Dumper;
    use LWP::UserAgent;
    use Net::Topsy::Result;
    our $VERSION = '0.03';
    $VERSION = eval $VERSION;

    use namespace::autoclean;

    has useragent_class => ( isa => 'Str', is => 'ro', default => 'LWP::UserAgent' );
    has useragent_args  => ( isa => 'HashRef', is => 'ro', default => sub { {} } );
    has ua              => ( isa => 'Object', is => 'rw' );
    has key             => ( isa => 'Str', is => 'rw', required => 0 );
    has format          => ( isa => 'Str', is => 'rw', required => 1, default => '.json' );
    has base_url        => ( isa => 'Str', is => 'ro', default => 'http://otter.topsy.com' );
    has useragent       => ( isa => 'Str', is => 'ro', default => "Net::Topsy/$VERSION (Perl)" );

    method BUILD {
        $self->ua($self->useragent_class->new(%{$self->useragent_args}));
        $self->ua->agent($self->useragent);

        my @api_methods = keys %{$self->API->{$self->base_url}};

        for my $method (@api_methods) {
            Net::Topsy->meta->make_mutable;
            Net::Topsy->meta->add_method( substr($method, 1) , sub {
                my ($self, $params) = @_;
                $params ||= {};
                return $self->_topsy_api($params, $method);
            });
            Net::Topsy->meta->make_immutable;
        }
    }

    method _topsy_api ($params, $route) {
        die 'no route to _topsy_api!' unless $route;

        $self->_validate_params($params, $route);
        my $url = $self->_make_url($params, $route);
        return $self->_handle_response( $self->ua->get( $url ) );
    }

    method _validate_params ($params, $route) {
        my %topsy_api = %{$self->API};

        my $api_entry = $topsy_api{$self->base_url}{$route}
            || croak "$route is not a topsy api entry";

        my @required = grep { $api_entry->{args}{$_} } keys %{$api_entry->{args}};

        if ( my @missing = grep { !exists $params->{$_} } @required ) {
            croak "$route -> required params missing: @missing";
        }

        if ( my @undefined = grep { $params->{$_} eq '' } keys %$params ) {
            croak "params with undefined values: @undefined";
        }

        my %unexpected_params = map { $_ => 1 } keys %$params;
        delete $unexpected_params{$_} for keys %{$api_entry->{args}};
        if ( my @unexpected_params = sort keys %unexpected_params ) {
            # topsy seems to ignore unexpected params, so don't fail, just diag
            print "# unexpected params: @unexpected_params\n" if $self->print_diags;
        }

    }

    method _make_url ($params,$route) {
        $route  = $self->base_url . $route . $self->format;
        my $url = $route . "?beta=" . ($self->key || '');
        while( my ($k,$v) = each %$params) {
            $url .= "&$k=" . uri_escape($v) . "&" if defined $v;
        }
        #warn "requesting $url";
        return $url;
    }

    method _handle_response ( $response ) {
        if ($response->is_success) {

            my $perl = $self->_from_json( $response->content );

            my $result = Net::Topsy::Result->new(
                            response => $response,
                            json     => $response->content,
                            perl     => $perl,
            );
            return $result;
        } else {
            die $response->status_line;
        }
    }

    method _from_json ($json) {
        my $perl = eval { JSON::Any->from_json($json) };
        confess $@ if $@;
        return $perl;
    }

}
=head1 NAME

Net::Topsy - Perl Interface to the Otter API to Topsy.com

=head1 VERSION

Version 0.03

=cut


=head1 SYNOPSIS

    use Net::Topsy;

    my $topsy   = Net::Topsy->new( { key => $beta_key } );
    my $search1 = $topsy->search( { q => 'perl' } );
    my $search2 = $topsy->search( { q => 'lolcats', page => 3, perpage => 20 } );


All API methods take a hash reference of CGI parameters.  These will be
URI-escaped, so that does not have to be done before calling these methods.

Expect this API to change when Topsy is out of beta.  Unknown parameters are
currently ignored by Topsy, but that could change at any time.

=head1 METHODS

=over

=item authorinfo

=item authorsearch

=item credit

=item linkposts

=item profilesearch

=item related

=item stats

=item search

    my $search = $topsy->search( { q => 'perl', window => 'd' } );

Takes mandatory parameter "q", a string to search for, and the optional
parameter "window", which defaults to "a". Valid options for the "window"
parameter are: "auto" lets Topsy to pick the best window, "h" last hour,
"d" last day, "w" last week, "m" last month, "a" all time.

=item searchcount

=item tags

=item trackbacks

=item trending

    my $trends = $topsy->trending( { perpage => 5 } );

This method takes optional "perpage" argument and returns a Net::Topsy::Result object.

=item urlinfo

=back

=head1 AUTHOR

Jonathan Leto, C<< <jonathan at leto.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-net-topsy at rt.cpan.org>,
or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Net::Topsy>.  I will be
notified, and then you'll automatically be notified of progress on your bug as I
make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Net::Topsy

For documentation about the Otter API to Topsy.com : L<http://code.google.com/p/otterapi> .

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Net::Topsy>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Net::Topsy>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Net::Topsy>

=item * Search CPAN

L<http://search.cpan.org/dist/Net::Topsy>

=back


=head1 ACKNOWLEDGEMENTS

Many thanks to Marc Mims <marc@questright.com>, the author of Net::Twitter, for the
Mock::LWP::UserAgent module that mocks out LWP::UserAgent for the tests. Thanks
to Richard Soderberg <rs@topsy.com> for various bugfixes.

=head1 COPYRIGHT & LICENSE

Copyright 2009 Jonathan Leto <jonathan@leto.net>, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1;
