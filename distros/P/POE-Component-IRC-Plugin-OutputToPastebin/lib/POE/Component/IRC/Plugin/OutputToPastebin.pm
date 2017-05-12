package POE::Component::IRC::Plugin::OutputToPastebin;

use warnings;
use strict;

our $VERSION = '0.002';

use Carp;
use POE::Component::IRC::Plugin qw(:ALL);
use POE qw(Component::WWW::Pastebin::Bot::Pastebot::Create);

sub new {
    my $class = shift;
    croak "Must have even number of arguments to new()"
        if @_ & 1;

    my %args = @_;
    $args{ +lc } = delete $args{ $_ } for keys %args;
    %args = (
        max_tries   => 3,
        trigger     => '[irc_to_pastebin]',
        pastebins   => [ qw(http://p3m.org/pfn) ],
        timeout     => 20,
        debug       => 0,
        %args,
    );
    $args{_site_iterator} = 0;
    return bless \%args, $class;
}

sub PCI_register {
    my ( $self, $irc ) = @_;
    $self->{irc} = $irc;

    $irc->plugin_register( $self, 'USER', qw(privmsg notice) );
    $irc->{session_id} = POE::Session->create(
        object_states => [
            $self   => [ qw(_start  _shutdown  _paste_it  _pasted) ],
        ],
    )->ID;

    return 1;
}

sub _start {
    my ( $kernel, $self ) = @_[KERNEL, OBJECT];
    $self->{session_id} = $_[SESSION]->ID;
    $kernel->refcount_increment( $self->{session_id} => __PACKAGE__ );

    $self->{poco}
    = POE::Component::WWW::Pastebin::Bot::Pastebot::Create->spawn(
        obj_args => { timeout => $self->{timeout} },
        debug    => $self->{debug},
    );
}

sub U_privmsg { shift->_process( @_ ); }
sub U_notice  { shift->_process( @_ ); }

sub _process {
    my ( $self, $irc, $out_ref ) = @_;

    my ( $pre_text, $to_paste ) = split /\Q$self->{trigger}/, $$out_ref, 2;

    if ( defined $to_paste and length $to_paste ) {
        $poe_kernel->post(
            $self->{session_id} => _paste_it => $pre_text, $to_paste, 0
        );

        return PCI_EAT_ALL;
    }

    return PCI_EAT_NONE;
}

sub _paste_it {
    my ( $self, $pre_text, $to_paste, $try ) = @_[ OBJECT, ARG0..$#_];

    $self->{_site_iterator} = 0
        if $#{ $self->{pastebins} } < ++$self->{_site_iterator};

    $self->{poco}->paste( {
            site    => $self->{pastebins}[ $self->{_site_iterator} ],
            event   => '_pasted',
            content => $to_paste,
            _pre    => $pre_text,
            _try    => $try,
        }
    );
}

sub _post_irc_message {
    my ( $self, $message ) = @_;
    $poe_kernel->post( $self->{irc} => quote => $message );
}

sub _pasted {
    my ( $self, $in_ref ) = @_[OBJECT, ARG0];
    if ( $in_ref->{error} ) {
        $self->{debug} and carp "Paster error: $in_ref->{error}";

        if ( ++$in_ref->{_try} > $self->{max_tries} ) {
            $self->_post_irc_message("$in_ref->{_pre} [paster error]");
        }
        else {
            $poe_kernel->post(
                $self->{session_id} => _paste_it =>
                @$in_ref{ qw(_pre content _try) }
            );
        }
    }
    else {
        $self->{debug} and carp "Pasted, got uri $in_ref->{uri}";

        $self->_post_irc_message( "$in_ref->{_pre}$in_ref->{uri}" );
    }
}

sub PCI_unregister {
    my ( $self, $irc ) = @_;
    $poe_kernel->call( $self->{session_id} => '_shutdown' );
    delete $self->{irc};
    return 1;
}

sub _shutdown {
    my ( $kernel, $self ) = @_[KERNEL, OBJECT];
    $self->{poco}->shutdown;
    $kernel->alarm_remove_all;
    $kernel->refcount_decremenet( $self->{session_id} => __PACKAGE__ );
    return;
}


1;
__END__

=encoding utf8

=head1 NAME

POE::Component::IRC::Plugin::OutputToPastebin - easily pastebin output from your bot

=head1 SYNOPSIS

    use strict;
    use warnings;

    use POE qw(Component::IRC  Component::IRC::Plugin::OutputToPastebin);

    my $irc = POE::Component::IRC->spawn(
        nick        => 'PasterBot',
        server      => 'irc.freenode.net',
        port        => 6667,
        ircname     => 'Paster BOT',
    );

    POE::Session->create(
        package_states => [
            main => [ qw(_start irc_001 irc_public) ],
        ],
    );

    $poe_kernel->run;

    sub _start {
        $irc->yield( register => 'all' );

        $irc->plugin_add(
            'Paster' =>
                POE::Component::IRC::Plugin::OutputToPastebin->new
        );

        $irc->yield( connect => {} );
    }

    sub irc_001 { $irc->yield( join => '#zofbot' ) }

    sub irc_public {
        $irc->yield( privmsg => '#zofbot' =>
            'OH HAI! [irc_to_pastebin]this text to pastebin'
        );
        $irc->yield( notice => 'Zoffix' =>
            'BLEH! [irc_to_pastebin]this text to pastebin as well'
        );
    }

    <Zoffix> foos
    <PasterBot> OH HAI!  http://erxz.com/pb/8028
    -PasterBot- BLEH!  http://p3m.org/pfn/714

=head1 DESCRIPTION

The module provides means to pastebin the output from your bot (by
output is ment C<privmsg> and C<notice> messages) by inserting special
"trigger" into the message.

=head1 CONSTRUCTOR

=head2 C<new>

    $irc->plugin_add(
        'PasterPlain' =>
            POE::Component::IRC::Plugin::OutputToPastebin->new
    );

    $irc->plugin_add(
        'PasterJuicy' =>
            POE::Component::IRC::Plugin::OutputToPastebin->new(
                max_tries   => 3,
                timeout     => 20,
                trigger     => '[irc_to_pastebin]',
                pastebins   => [ qw(http://p3m.org/pfn) ],
                debug       => 1,
            )
    );

Contructs a plugin object suitable to be fed to the everhungry
L<POE::Component::IRC>'s C<plugin_add()> method. Takes a bunch of arguments
in key/value pairs but all of them are optional. Possible arguments
are as follows:

=head3 C<trigger>

    ->new( trigger => '[send_stuff_after_this_to_pastebin]', );

B<Optional>. Any C<privmsg> or C<notice> messages sent by the bot which
contain C<trigger> in them will be split on the C<trigger> and anything
after the C<trigger> will be pasted into the pastebin and replaced by
the URI pointing to the pasted content. In other words if your C<trigger>
is C<(trigger)> and your do
C<< $irc->yield( privmsg => '#zofbot' => 'blah (trigger) foos' ); >>
then the actual message sent to channel C<#zofbot> will be
C<blah http://erxz.com/pb/8028> where the URI will be pointing to the
pastebin page containing pasted text C< foos>. B<Defaults to:>
C<[irc_to_pastebin]> (note the square brackets)

=head3 C<pastebins>

    ->new( pastebins => [ qw(http://p3m.org/pfn http://erxz.com/pb) ], );

B<Optional>. The C<pastebins> argument takes an arrayref of URIs each
pointing to pastebin sites powered by L<Bot::Pastebot>. Plugin will
automatically iterate over specified list of pastebins on every paste
request. B<Defaults to:> C<[ qw(http://p3m.org/pfn) ]>

=head3 C<max_tries>

    ->new( max_tries => 3 )

B<Optional>. If while pasting the content an error occured plugin will retry pasting
into the next pastebin specified in C<pastebins> argument. It will be
retrying until it succeeds or until it tried C<max_tries> times. If
C<max_tries> limit is reached and plugin still could not paste your
content instead of pastebin's URI you'll get C<[paster error]> in output
message. B<Defaults to:> C<3>

=head3 C<timeout>

    ->new( timeout => 20 );

B<Optional>. The C<timeout> argument specifies L<LWP::UserAgent>
C<timeout> setting to use for pasting. B<Defaults to:> C<20> seconds.

=head3 C<debug>

    ->new( debug => 1 );

B<Optional>. When C<debug> argument is set to true value plugin will
C<carp()> out some debugging information. B<Defaults to:> C<0>

=head1 AUTHOR

Zoffix Znet, C<< <zoffix at cpan.org> >>
(L<http://zoffix.com>, L<http://haslayout.net>)

=head1 BUGS

Please report any bugs or feature requests to C<bug-poe-component-irc-plugin-outputtopastebin at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=POE-Component-IRC-Plugin-OutputToPastebin>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc POE::Component::IRC::Plugin::OutputToPastebin

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=POE-Component-IRC-Plugin-OutputToPastebin>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/POE-Component-IRC-Plugin-OutputToPastebin>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/POE-Component-IRC-Plugin-OutputToPastebin>

=item * Search CPAN

L<http://search.cpan.org/dist/POE-Component-IRC-Plugin-OutputToPastebin>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2008 Zoffix Znet, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

