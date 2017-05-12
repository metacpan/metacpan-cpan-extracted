package POE::Component::IRC::Plugin::WWW::CPANRatings::RSS;

use warnings;
use strict;

our $VERSION = '0.0106';

use POE qw/Component::WWW::CPANRatings::RSS/;
use POE::Component::IRC::Plugin qw( :ALL );
use utf8;

sub new {
    my $package = shift;
    my %args = @_;
    my $self = bless {}, $package;

    $self->{ +lc } = delete $args{ $_ }
        for keys %args;

    $self->{rate} ||= 60;
    $self->{ua}   ||= { timeout => 30 };
    $self->{file} = 'cpan_ratings.rss.storable'
        unless defined $self->{file};

    $self->{format}
    ||= 'rating: {:dist:} - {:rating:} - by {:creator:} [ {:link:} ]';

    $self->{channels} ||= [];
    $self->{response_event} ||= 'irc_cpanratings';
    $self->{auto} = 1
        unless defined $self->{auto};

    $self->{utf} = 1
        unless defined $self->{utf};

    $self->{max_ratings} = 5
        unless defined $self->{max_ratings};

    return $self;
}

sub PCI_register {
    my ($self, $irc) = splice @_, 0, 2;

    $self->{irc} = $irc;

    $self->{poco} = POE::Component::WWW::CPANRatings::RSS->spawn(
        debug => $self->{debug},
        ua    => $self->{ua},
    );

    $self->{SESSION_ID} = POE::Session->create(
        object_states => [
            $self => [qw(_start _shutdown ratings)],
        ],
    )->ID();

    return 1;
}

sub PCI_unregister {
    my ($self, $irc) = splice @_, 0, 2;

    $poe_kernel->call( $self->{SESSION_ID} => '_shutdown' );
    delete $self->{irc};
    return 1;
}

sub _start {
    my ($kernel, $self) = @_[KERNEL, OBJECT];
    $self->{SESSION_ID} = $_[SESSION]->ID();

    $kernel->refcount_increment( $self->{SESSION_ID}, __PACKAGE__ );

    $self->{poco}->fetch( {
            event  => 'ratings',
            repeat => $self->{rate},
            unique => 1,
            file   => $self->{file},
        }
    );

    return;
}

sub ratings {
    my ( $self, $in_ref ) = @_[ OBJECT, ARG0 ];
    if ( $in_ref->{error} ) {
        $self->{debug}
            and warn "Got ratings error: $in_ref->{error}\n";
        return;
    }

    my @ratings = @{ $in_ref->{ratings} || [] };
    for my $review ( splice @ratings, 0, $self->{max_ratings} ) {
        my $text = $self->{format};
        my $rating = $review->{rating};
        if ( $self->{utf} and $rating ne 'N/A' ) {
            $rating = $self->_make_utf_rating( $rating );
        }
        elsif ( $rating ne 'N/A' ) {
            $rating = "$rating/5";
        }
        $text =~ s/{:dist:}/$review->{dist}/g;
        $text =~ s/{:rating:}/$rating/g;
        $text =~ s/{:creator:}/$review->{creator}/g;
        $text =~ s/{:link:}/$review->{link}/g;

        if ( $self->{auto} ) {
            $self->{irc}->yield( ctcp => $_ => 'ACTION ' . $text )
                for @{ $self->{channels} };
        }
    }
    my %event_output =  %$in_ref;
    delete $event_output{unique};
    $event_output{rate} = delete $event_output{repeat};
    $self->{irc}->send_event( $self->{response_event} => \%event_output );
}

sub _shutdown {
    my ($kernel, $self) = @_[KERNEL, OBJECT];
    $self->{poco}->shutdown;
    $kernel->alarm_remove_all();
    $kernel->refcount_decrement( $self->{SESSION_ID}, __PACKAGE__ );
    return;
}

sub _make_utf_rating {
    my ( $self, $rating ) = @_;

    my $out = '●' x int $rating;
    $out .= '◐'
        if $rating - int $rating;
    $out .= '○' x (5 - length $out);

    return $out;
}

1;
__END__

=encoding utf8

=head1 NAME

POE::Component::IRC::Plugin::WWW::CPANRatings::RSS - announce CPAN ratings on IRC from RSS feed on http://cpanratings.perl.org/

=head1 SYNOPSIS

    #!/usr/bin/env perl

    use strict;
    use warnings;

    use POE qw(Component::IRC  Component::IRC::Plugin::WWW::CPANRatings::RSS);

    my $irc = POE::Component::IRC->spawn(
        nick        => 'CPANRatings',
        server      => 'irc.freenode.net',
        port        => 6667,
        ircname     => 'CPAN Ratings Bot',
    );

    POE::Session->create(
        package_states => [
            main => [ qw(_start irc_001 _default  irc_cpanratings) ],
        ],
    );

    $poe_kernel->run;

    sub irc_cpanratings {
        my $in_ref = $_[ARG0];
        use Data::Dumper;
        print Dumper $in_ref;
    }

    sub _start {
        $irc->yield( register => 'all' );

        $irc->plugin_add(
            'cpan_ratings' =>
                POE::Component::IRC::Plugin::WWW::CPANRatings::RSS->new(
                    channels => [ '#zofbot' ],
                )
        );

        $irc->yield( connect => {} );
    }

    sub irc_001 {
        $irc->yield( join => '#zofbot' );
    }


    * CPANRatings rating: String-String - ●○○○○ - by BKB [ http://cpanratings.perl.org/#4476 ]
    * CPANRatings rating: IWL - ●○○○○ - by BKB [ http://cpanratings.perl.org/#4474 ]
    * CPANRatings rating: String - ●○○○○ - by BKB [ http://cpanratings.perl.org/#4472 ]
    * CPANRatings rating: String-Buffer - ●○○○○ - by BKB [ http://cpanratings.perl.org/#4470 ]
    * CPANRatings rating: String-Strip - ●○○○○ - by BKB [ http://cpanratings.perl.org/#4468 ]
    * CPANRatings rating: Acme-Monta - N/A - by BKB [ http://cpanratings.perl.org/#4466 ]

=head1 DESCRIPTION

The module is L<POE::Component::IRC> plugin which uses
L<POE::Component::IRC::Plugin> for its base, thus can be loaded with
L<plugin_add()> method. The module provides means to announce new
reviews posted to L<http://cpanratings.perl.org/>

=head1 CONSTRUCTOR

=head2 C<new>

    # plain
    $irc->plugin_add(
        'cpan_ratings' =>
            POE::Component::IRC::Plugin::WWW::CPANRatings::RSS->new(
                channels => [ '#zofbot' ],
            )
    );

    # juicy
        $irc->plugin_add(
            'cpan_ratings' =>
                POE::Component::IRC::Plugin::WWW::CPANRatings::RSS->new(
                    channels    => [ '#zofbot' ],
                    rate        => 60;
                    ua          => { timeout => 30 },
                    file        => 'cpan_ratings.rss.storable',
                    format      => 'rating: {:dist:} - {:rating:} - by {:creator:} [ {:link:} ]',
                    max_ratings => 10,
                    response_event => 'irc_cpanratings';
                    auto        => 1,
                    utf         => 1,
                )
        );

Constructs and returns a POE::Component::IRC::Plugin::WWW::CPANRatings::RSS
object suitable to be fed to L<POE::Component::IRC>'s C<plugin_add()>
method. All of which are optional. You can change all of the arguments dynamically by
accessing them as keys in a hashref of the plugin object: C<<
$plug->{rate} = 1000; >> Possible arguments are as follows

=head3 C<channels>

    ->new( channels => [ '#zofbot' ], );

B<Semi-mandatory>, not specifying this argument will render the plugin
useless when C<auto> option is turned on, however you can still listen
to the events emited by the plugin. Takes an arrayref as a value which
must contain the channels where the plugin will announce new ratings.

=head3 C<rate>

    ->new( rate => 360, );

B<Optional>. Takes a positive integer as a value which specifies the
interval of C<rate> seconds between the checks for new ratings.
B<Defaults to:> C<60>

=head3 C<ua>

    ->new( ua => { timeout => 30 } );

B<Optional>. Takes a hashref as a value. That hashref will be directly
dereferenced into L<LWP::UserAgent> constructor. See L<LWP::UserAgent>'s
documentation for possible keys/values. B<Defaults to:>
C<< { timeout => 30 } >>

=head3 C<file>

    ->new( file => 'cpan_ratings.rss.storable' );

B<Optional>. Plugin stores already reported reviews/ratings into a file.
Using the C<file> argument, which takes a scalar as a value, you can
specify the file name for storage. B<Defaults to:>
C<cpan_ratings.rss.storable>

=head3 C<format>

    ->new( format => 'rating: {:dist:} - {:rating:} - by {:creator:} [ {:link:} ]', );

B<Optional>. When C<auto> argument (see below) is set to a true value
the plugin will announce new reviews into the C<channels>. The
C<format> argument, which takes a string as a value, specifies the
format of the output. Currently all the announcing is done via C</me>,
let me know if you want that configurable. Special character sequences
in the C<format> string will be replaced with respective data bits in the
following fashion:

    {:dist:}        - name of the distribution
    {:rating:}      - either the number or the stars (see C<utf>) rating
    {:creator:}     - name of the creator of the review
    {:link:}        - link to the review

The special sequences can be used any number of times if you so desire.
The B<format> argument B<defaults to:> <'rating: {:dist:} - {:rating:} - by {:creator:} [ {:link:} ]'>

=head3 C<max_ratings>

    ->new( max_ratings => 5 );

B<Optional>. The C<max_ratings> takes a positive integer as a value
and specifies the maximum number of ratings/reviews to report at a time.
Anything over that limit won't be reported at all; considering those
reviews don't pop up like mushrooms this shouldn't be a problem.
B<Defaults to:> C<5>

=head3 C<response_event>

    ->new( response_event => 'irc_cpanratings' );

B<Optional>. During its operation, the plugin will emit an event
I<every time the data is fetched>. The C<response_event> specifies the
name of the event to emit. B<Defaults to:> C<irc_cpanratings>

=head3 C<auto>

    ->new( auto => 1 );

B<Optional>. Takes either true or false values. When set to a true value
plugin will auto-announce new reviews into all the channels specified
in C<channels> argument. B<Defaults to:> C<1>

=head3 C<utf>

    ->new( utf => 1 );

B<Optional>. Takes either true or false values. When set to a true value
will use UTF-8 circles to represent the given rating (that is
what will replace the C<{:rating:}> sequence in the C<format> argument).
When set to a false value will use simple numbers. B<Defaults to:> C<1>

=head1 EMITED EVENTS

    $VAR1 = {
        'rate' => 60,
        'ratings' => [
            {
                'link' => 'http://cpanratings.perl.org/#4452',
                'comment' => 'One of the most useful Acme modules ever! Simply fantastic to show off without losing more than 5 seconds, a real masterpiece of meta-art. I\'d suggest ...',
                'creator' => 'Flavio Poletti',
                'dist' => 'Acme-EyeDrops',
                'rating' => '5'
            },
        ],
        'file' => 'cpan_ratings.rss.storable'
    };

The event handler setup to handle the C<response_event>, which defaults
to C<irc_cpanratings>, will receive input on I<every fetch>, thus
every C<rate> (see CONSTRUCTOR) seconds. The input will come in a form
of a hashref in C<$_[ARG0]>. The keys/values of that hashref are as follows.

=head2 C<ratings>

    'ratings' => [
        {
            'link' => 'http://cpanratings.perl.org/#4452',
            'comment' => 'One of the most useful Acme modules ever! Simply fantastic to show off without losing more than 5 seconds, a real masterpiece of meta-art. I\'d suggest ...',
            'creator' => 'Flavio Poletti',
            'dist' => 'Acme-EyeDrops',
            'rating' => '5'
        },
    ],

The C<ratings> key will contain a (possibly empty) arrayref of hashrefs
where each hashrefs represents a new
review. See C<WWW::CPANRatings::RSS>'s C<fetch()> method of explaination
of each of the keys/values of those hashrefs.

=head3 C<error>

    'error' => 'Network error: 500 Timeout',

If an error occured the C<error> key will be present and its value,
which will be a scalar, will contain the description of the error.

=head3 C<rate>

    'rate' => 60


The C<rate> key will contain the rate (in seconds) at which the plugin
fetches new data.

=head3 C<file>

    'file' => 'cpan_ratings.rss.storable'

The C<file> key will contain the filename of the file where the plugin
stores already reported reviews.

=head1 EXAMPLES

The C<examples/> directory of this distribution contains C<ratings_bot.pl>
which is a fully working CPAN Ratings announcing IRC bot.

=head1 AUTHOR

Zoffix Znet, C<< <zoffix at cpan.org> >>
(L<http://zoffix.com>, L<http://haslayout.net>)

=head1 BUGS

Please report any bugs or feature requests to C<bug-poe-component-irc-plugin-www-cpanratings-rss at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=POE-Component-IRC-Plugin-WWW-CPANRatings-RSS>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc POE::Component::IRC::Plugin::WWW::CPANRatings::RSS

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=POE-Component-IRC-Plugin-WWW-CPANRatings-RSS>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/POE-Component-IRC-Plugin-WWW-CPANRatings-RSS>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/POE-Component-IRC-Plugin-WWW-CPANRatings-RSS>

=item * Search CPAN

L<http://search.cpan.org/dist/POE-Component-IRC-Plugin-WWW-CPANRatings-RSS>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2008 Zoffix Znet, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

