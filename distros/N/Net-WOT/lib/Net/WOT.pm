package Net::WOT;
BEGIN {
  $Net::WOT::VERSION = '0.02';
}
# ABSTRACT: Access Web of Trust (WOT) API

use Carp;
use Moose;
use XML::Twig;
use LWP::UserAgent;
use namespace::autoclean;

# useragent to work with
has 'useragent' => (
    is         => 'ro',
    isa        => 'LWP::UserAgent',
    handles    => { ua_get => 'get' },
    lazy_build => 1,
);

# docs are at: http://www.mywot.com/wiki/API
has api_base_url => (
    is      => 'ro',
    isa     => 'Str',
    default => 'api.mywot.com',
);

has api_path => (
    is      => 'ro',
    isa     => 'Str',
    default => 'public_query2',
);

has version => (
    is      => 'ro',
    isa     => 'Num',
    default => 0.4,
);

has components => (
    is      => 'ro',
    isa     => 'HashRef[Str]',
    traits  => ['Hash'],
    default => sub { {
        0 => 'trustworthiness',
        1 => 'vendor_reliability',
        2 => 'privacy',
        4 => 'child_safety',
    } },

    handles => {
        get_component_name      => 'get',
        get_all_component_names => 'values',
    },
);

has reputation_levels => (
    is      => 'ro',
    isa     => 'HashRef[Str]',
    traits  => ['Hash'],
    default => sub { {
        80 => 'excellent',
        60 => 'good',
        40 => 'unsatisfactory',
        20 => 'poor',
         0 => 'very poor',
    } },

    handles => {
        get_reputation_description => 'get',
        get_reputation_levels      => 'keys',
    },
);

has confidence_levels => (
    is      => 'ro',
    isa     => 'HashRef[Str]',
    traits  => ['Hash'],
    default => sub { {
        45 => '5',
        34 => '4',
        23 => '3',
        12 => '2',
         6 => '1',
         0 => '0',
    } },

    handles => {
        get_confidence_level      => 'get',
        get_all_confidence_levels => 'values',
    },
);

# automatically create all reputation component attributes
foreach my $comp ( qw/
        trustworthiness
        vendor_reliability
        privacy
        child_safety
    / ) {
    foreach my $item ( qw/ score confidence / ) {
        my $attr_name = "${comp}_$item";
        has $attr_name => ( is => 'rw', isa => 'Int' );
    }

    has "${comp}_description" => ( is => 'rw', isa => 'Str' );
}

sub _build_useragent {
    my $self = shift;
    my $lwp  = LWP::UserAgent->new();

    return $lwp;
}

sub _create_link {
    my ( $self, $target ) = @_;
    my $version  = $self->version;
    my $api_base = $self->api_base_url;
    my $api_path = $self->api_path;
    my $link     = "http://$api_base/$version/$api_path?target=$target";

    return $link;
}

# <?xml version="1.0" encoding="UTF-8"?>
# <query target="google.com">
#     <application c="93" name="0" r="94"/>
#     <application c="92" name="1" r="95"/>
#     <application c="88" name="2" r="93"/>
#     <application c="88" name="4" r="93"/>
# </query>

sub _request_wot {
    my ( $self, $target ) = @_;
    my $link     = $self->_create_link($target);
    my $response = $self->ua_get($link);
    my $status   = $response->status_line;

    $response->is_success or croak "Can't get reputation: $status\n";

    return $response->content;
}

sub get_reputation {
    my ( $self, $target ) = @_;
    my $xml  = $self->_request_wot($target);
    my $twig = XML::Twig->new();

    $twig->parse($xml);

    my @children = $twig->root->children;
    foreach my $child (@children) {
        # checking a specific query
        my $component  = $child->att('name');
        my $confidence = $child->att('c');
        my $reputation = $child->att('r');

        my $component_name = $self->get_component_name($component);

        # component: 0
        # confidence: 34
        # reputation: 30
        # trustworthiness_reputation
        # trustworthiness_description
        # trustworthiness_confidence

        my $score_attr = "${component_name}_score";
        $self->$score_attr($reputation);

        my $conf_attr = "${component_name}_confidence";
        $self->$conf_attr($confidence);

        my @rep_levels = sort { $b <=> $a } $self->get_reputation_levels;
        my $desc_attr  = "${component_name}_description";

        foreach my $reputation_level (@rep_levels) {
            if ( $reputation >= $reputation_level ) {
                my $rep_desc
                    = $self->get_reputation_description($reputation_level);

                $self->$desc_attr($rep_desc);

                last;
            }
        }
    }

    return $self->_create_reputation_hash;
}

sub _create_reputation_hash {
    my $self = shift;
    my %hash = ();

    foreach my $component ( $self->get_all_component_names ) {
        foreach my $item ( qw/ score description confidence / ) {
            my $attr  = "${component}_$item";
            my $value = $self->$attr;

            $value and $hash{$component}{$item} = $value;
        }
    }

    return %hash;
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;



=pod

=head1 NAME

Net::WOT - Access Web of Trust (WOT) API

=head1 VERSION

version 0.02

=head1 SYNOPSIS

This module provides an interface to I<Web of Trust>'s API.

    use Net::WOT;

    my $wot = Net::WOT->new;

    # get all details
    my %all_details = $wot->get_reputation('example.com');

    # use specific details after get_reputations() method was called
    print $wot->privacy_score, "\n";

=head1 EXPORT

Fully object oriented, nothing is exported.

=head1 ATTRIBUTES

These are attributes that can be set during the initialization of the WOT
object. The syntax is:

    my $wot = Net::WOT->new(
        attr1 => 'value1',
        attr2 => 'value2',
    );

=head2 api_base_url

The basic url for the WOT API. Default: B<api.mywot.com>.

=head2 api_path

The path for the WOT API request. Default: B<public_query2>.

=head2 version

Version of the WOT API. Default: B<0.4>.

These are subroutines you probably don't want to change but can still read from.

B<Note:> Changing these might compromise the integrity of your information,
consider them as read-only.

=head2 trustworthiness_score

The trustworthiness score.

=head2 trustworthiness_confidence

The trustworthiness confidence.

=head2 trustworthiness_description

The trustworthiness description.

=head2 vendor_reliability_score

The vendor reliability score.

=head2 vendor_reliability_confidence

The vendor reliability confidence.

=head2 vendor_reliability_description

The vendor reliability description.

=head2 privacy_score

The privacy score.

=head2 privacy_confidence

The privacy confidence.

=head2 privacy_description

The privacy description.

=head2 child_safety_score

The child safety score.

=head2 child_safety_confidence

The child safety confidence.

=head2 child_safety_description

The child safety description.

=head1 SUBROUTINES/METHODS

=head2 get_reputation

Get reputation.

=head2 ua_get

This is a shorthand to reach an internal useragent I<get> command. Why would you
want it? Who knows? It's there.

=head2 get_component_name

Retrieves a component name from the index number of it. For example:

    my $name = $wot->get_component_name(2);
    # $name = 'privacy'

=head2 get_all_component_names

Returns a list of all component names.

=head2 get_reputation_description

Retrieves a reputation description from a certain level threshold. For example:

    my $threshold   = 60;
    my $description = $wot->get_reputation_description;

    # $description = 'good'

=head2 get_reputation_levels

Returns a list of all reputation levels.

=head2 get_confidence_level

Retrieves a confidence level from a certain threshold. For example:

    my $confidence_level = $wot->get_confidence_level(12);
    # $confidence_level = '2'

=head2 get_all_confidence_levels

Returns a list of all confidence levels.

=head1 AUTHOR

Sawyer X, C<< <xsawyerx at cpan.org> >>

=head1 BUGS

Please report bugs and other issues on the bugtracker:

L<http://github.com/xsawyerx/net-wot/issues>

=head1 SUPPORT

Hopefully.

=head1 LICENSE AND COPYRIGHT

Copyright 2010 Sawyer X.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=head1 AUTHOR

  Sawyer X <xsawyerx@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Sawyer X.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

