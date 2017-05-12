package POE::Component::WWW::OhNoRobotCom::Search;

use warnings;
use strict;

our $VERSION = '0.002';

use Carp;
use WWW::OhNoRobotCom::Search;
use POE;
use base 'POE::Component::NonBlockingWrapper::Base';

sub _methods_define {
    return ( search => '_wheel_entry' );
}

sub search {
    $poe_kernel->post( shift->{session_id} => search => @_ );
}

sub _prepare_wheel {
    my ( $self, $args ) = @_;
    $self->{_robo} = WWW::OhNoRobotCom::Search->new(
        %{ $self->{obj_args} || {} }
    );
}

sub _check_args {
    my ( $self, $args_ref ) = @_;
    defined $args_ref->{term}
        or carp 'Missing `term` argument'
        and return;
}

sub _process_request {
    my ( $self, $in_ref ) = @_;
    my @search_args;
    for ( qw(comic_id  include  max_results  lucky) ) {
        exists $in_ref->{$_}
            and push @search_args, $_, $in_ref->{$_};
    }

    my $out_ref = $self->{_robo}->search( $in_ref->{term}, @search_args );

    if ( defined $out_ref ) {
        $in_ref->{results} = $out_ref;
    }
    else {
        $in_ref->{error} = $self->{_robo}->error;
    }
}

1;
__END__

=encoding utf8

=head1 NAME

POE::Component::WWW::OhNoRobotCom::Search - non-blocking POE based wrapper around WWW::OhNoRobotCom::Search module

=head1 SYNOPSIS

    use strict;
    use warnings;

    use POE qw(Component::WWW::OhNoRobotCom::Search);

    my $poco = POE::Component::WWW::OhNoRobotCom::Search->spawn;

    POE::Session->create(
        package_states => [ main => [qw(_start results )] ],
    );

    $poe_kernel->run;

    sub _start {
        $poco->search( {
                term     => 'foo',
                comic_id => 56, # XKCD comics
                event    => 'results',
            }
        );
    }

    sub results {
        my $in_ref = $_[ARG0];

        exists $in_ref->{error}
            and die "ZOMG! ERROR!: $in_ref->{error}";

        print "Results for XKCD comic search are as follows:\n";

        keys %{ $in_ref->{results} };
        while ( my ( $uri, $title ) = each %{ $in_ref->{results} } ) {
            print "$title [ $uri ]\n";
        }

        $poco->shutdown;
    }

Using event based interface is also possible of course.

=head1 DESCRIPTION

The module is a non-blocking wrapper around L<WWW::OhNoRobotCom::Search>
which provides interface to L<http://www.ohnorobot.com/> search

=head1 CONSTRUCTOR

=head2 spawn

    my $poco = POE::Component::WWW::OhNoRobotCom::Search->spawn;

    POE::Component::WWW::OhNoRobotCom::Search->spawn(
        alias => 'robo',
        obj_args => {
            timeout => 10,
        },
        options => {
            debug => 1,
            trace => 1,
            # POE::Session arguments for the component
        },
        debug => 1, # output some debug info
    );

The C<spawn> method returns a
POE::Component::WWW::OhNoRobotCom::Search object. It takes a few arguments,
I<all of which are optional>. The possible arguments are as follows:

=head3 alias

    POE::Component::WWW::OhNoRobotCom::Search->spawn(
        alias => 'robo'
    );

B<Optional>. Specifies a POE Kernel alias for the component.

=head3 obj_args

    POE::Component::WWW::OhNoRobotCom::Search->spawn(
        obj_args => {
            timeout => 10,
        }
    );

B<Optional>. The C<obj_args> argument takes a hashref as a value which
will be dereferenced directly into L<WWW::OhNoRobotCom::Search> constructor.
See documentation for L<WWW::OhNoRobotCom::Search> for more details.
B<Defaults to:> empty (default L<WWW::OhNoRobotCom::Search> constructor)

=head3 options

    my $poco = POE::Component::WWW::OhNoRobotCom::Search->spawn(
        options => {
            trace => 1,
            default => 1,
        },
    );

B<Optional>.
A hashref of POE Session options to pass to the component's session.

=head3 debug

    my $poco = POE::Component::WWW::OhNoRobotCom::Search->spawn(
        debug => 1
    );

When set to a true value turns on output of debug messages. B<Defaults to:>
C<0>.

=head1 METHODS

=head2 search

    $poco->search( {
            event       => 'event_for_output',
            term        => 'foo',
            comic_id    => 56,
            include     => [ qw(all_text meta) ],
            max_results => 20,
            lucky       => 1,
            _blah       => 'pooh!',
            session     => 'other',
        }
    );

Takes a hashref as an argument, does not return a sensible return value.
See C<search> event's description for more information.

=head2 session_id

    my $poco_id = $poco->session_id;

Takes no arguments. Returns component's session ID.

=head2 shutdown

    $poco->shutdown;

Takes no arguments. Shuts down the component.

=head1 ACCEPTED EVENTS

=head2 search

    $poe_kernel->post( robo => search => {
            event       => 'event_for_output',
            term        => 'foo',
            comic_id    => 56,
            include     => [ qw(all_text meta) ],
            max_results => 20,
            lucky       => 1,
            _blah       => 'pooh!',
            session     => 'other',
        }
    );

Instructs the component to perform the search. Takes a hashref as an
argument, the possible keys/value of that hashref are as follows:

=head3 event

    { event => 'results_event', }

B<Mandatory>. Specifies the name of the event to emit when results are
ready. See OUTPUT section for more information.

=head3 term

    { term  => 'foo' }

B<Mandatory>. Specifies the term to search for.

The first argument (mandatory) is the term you want to search. The other,
optional, arguments are given in a key/value fashion and are as follows:

=head3 comic_id

    { comic_id => 56 }

B<Optional>.
The C<comic_id> argument takes a scalar as a value which should be a
comic ID number or an empty string which indicates that search should be
done on all comics. To obtain the comic ID number go to
L<http://www.ohnorobot.com/index.pl?show=advanced>, "View Source" and search
for the name of the comic, when you'll find an <option> the C<value="">
attribute of that option will be the number you are looking for. Idealy,
it would make sense to make the C<search()> method/event
accepts names instead
of those numbers, but there are just too many (500+) different comics sites
and new are being added, blah blah. B<Defaults to:>
empty string, meaning search through all the comics.

=head3 include

    { include => [ qw(all_text meta) ] }

B<Optional>.
Specifies what kind of "things" to include into consideration when
performing the search. Takes an arrayref as an argument. B<Defaults to:> all
possible elements included which are as follows:

=over 10

=item all_text

Include I<All comic text>.

=item scene

Include I<Scene descriptions>.

=item sound

Include I<Sound effects>.

=item speakers

Include I<Speakers' names>

=item link

Include I<Link text>.

=item meta

Include I<Meta information>

=back

=head3 max_results

    { max_results => 30 }

B<Optional>.
The number of results displayed on L<http://www.ohnorobot.com> is 10, the
object will send out several requests if needed to obtain the
number of results specified in the C<max_results> argument. Don't use
extremely large values here, as the amount of requests will B<NOT> be
C<max_results / 10> because results are often repeating and the object
will count only unique URIs on the results page. B<Defaults to:> C<10>
(this does not necessarily mean that the object will send only one request).

=head3 lucky

    { lucky => 1 }

ARE YOU FEELING LUCKY?!!? If so, the C<lucky> argument, when set to a
B<true> value, will "press" the I<Let the robot decide> button on
L<http://www.ohnorobot.com> and the C<search> method/event will fetch
a poiting to the comic which the *ahem* "robot" thinks is what you
want. B<Note:> when using the C<lucky> argument the C<search()> method
will error out (see "OUTPUT" section below)
if nothing was found. B<Defaults to:> a false value (no feelin' lucky :( )

=head3 session

    { session => 'other' }

    { session => $other_session_reference }

    { session => $other_session_ID }

B<Optional>. Takes either an alias, reference or an ID of an alternative
session to send output to.

=head3 user defined

    {
        _user    => 'random',
        _another => 'more',
    }

B<Optional>. Any keys starting with C<_> (underscore) will not affect the
component and will be passed back in the result intact.

=head2 shutdown

    $poe_kernel->post( robo => 'shutdown' );

Takes no arguments. Tells the component to shut itself down.

=head1 OUTPUT

    $VAR1 = {
          'comic_id' => 56,
          'term' => 'foo',
          'results' => {
                'http://xkcd.com/240/' => 'Dream Girl',
                'http://xkcd.com/351/' => 'Trolling',
                'http://xkcd.com/261/' => 'Regarding Mussolini',
                'http://xkcd.com/319/' => 'Engineering Hubris',
                'http://xkcd.com/389/' => 'Keeping Time',
                'http://xkcd.com/356/' => 'Nerd Sniping',
                'http://xkcd.com/233/' => 'A New CAPTCHA Approach'
            },
            _foo => 'blah'
    };

The event handler set up to handle the event which you've specified in
the C<event> argument to C<search()> method/event will recieve input
in the C<$_[ARG0]> in a form of a hashref. The possible keys/value of
that hashref are as follows:

=head2 results

    'results' => {
        'http://xkcd.com/240/' => 'Dream Girl',
        'http://xkcd.com/351/' => 'Trolling',
        'http://xkcd.com/261/' => 'Regarding Mussolini',
        'http://xkcd.com/319/' => 'Engineering Hubris',
        'http://xkcd.com/389/' => 'Keeping Time',
        'http://xkcd.com/356/' => 'Nerd Sniping',
        'http://xkcd.com/233/' => 'A New CAPTCHA Approach'
    },

The C<results> key will contain a (possibly empty) hashref with keys
being links to the comics found in the search and values being their titles.

=head2 error

    { error => 'Some error' }

If an error occured during the search (or nothing was found for "lucky"
search) C<results> key will not be present and instead C<error> key
will be present containing an error message explaining the reason for
failure.

=head2 arguments passed to search

    {
        'comic_id' => 56,
        'term' => 'foo',
    }

Valid arguments (C<comic_id>, C<term>, etc) will also be present in the
response hashref.

=head2 user defined

    { '_blah' => 'foos' }

Any arguments beginning with C<_> (underscore) passed into the C<search()>
event/method will be present intact in the result.

=head1 SEE ALSO

L<POE>, L<WWW::OhNoRobotCom::Search>

=head1 AUTHOR

Zoffix Znet, C<< <zoffix at cpan.org> >>
(L<http://zoffix.com>, L<http://haslayout.net>)

=head1 BUGS

Please report any bugs or feature requests to C<bug-poe-component-www-ohnorobotcom-search at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=POE-Component-WWW-OhNoRobotCom-Search>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc POE::Component::WWW::OhNoRobotCom::Search

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=POE-Component-WWW-OhNoRobotCom-Search>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/POE-Component-WWW-OhNoRobotCom-Search>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/POE-Component-WWW-OhNoRobotCom-Search>

=item * Search CPAN

L<http://search.cpan.org/dist/POE-Component-WWW-OhNoRobotCom-Search>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2008 Zoffix Znet, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
