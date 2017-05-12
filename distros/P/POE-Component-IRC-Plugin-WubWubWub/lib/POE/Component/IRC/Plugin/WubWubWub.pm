package POE::Component::IRC::Plugin::WubWubWub;

use warnings;
use strict;
use POE::Component::IRC::Plugin qw(:ALL);

sub new {
        my $package = shift;
        my $args = shift;
        my $self = {
                threshold => 0.5, #Threshold to limit unnecessary wubs.
                period    => 30,  #A time period to rate limit wubs.
                last_wub  => 0,
                max_wubs =>  20,  #maximum amount of wubs in one message
                min_wubs =>  5,   #minimum amount of wubs in one message.
                wub_str  => "WUB", #wubstr
        };
        $self->{threshold} ||= $args->{threshold};
        $self->{threshold} = 0.5 if $self->{threshold} >= 1 or $self->{threshold} <= 0; #sanity check lol.
        $self->{period}    ||= $args->{period};
        $self->{period}    = 30  if $self->{period} <= 0;                                       #same
        $self->{max_wubs}  ||= $args->{max_wubs};
        $self->{max_wubs}  = 20  if $self->{max_wubs} <= 0;                                     #same, chap.
        $self->{min_wubs}  ||= $args->{min_wubs};
        $self->{min_wubs}  = 5 if $self->{min_wubs} <= 0;                                       #no sense in having 0 as minimum amirite
        $self->{min_wubs}  = $self->{max_wubs} - 1 if $self->{min_wubs} > $self->{max_wubs};    #don't want minimum > maximum
        $self->{max_wubs}  = $self->{min_wubs} + 5 if $self->{min_wubs} > $self->{max_wubs};    #same except different.
        $self->{wub_str}   ||= $args->{wub_str};
        return bless $self, $package;
}

sub S_public {
        my($self, $irc) = splice @_, 0, 2;
        my $channel = ${ $_[0] }->[0];
        my $cur_time = time;
        my $old_time = $self->{last_wub};
        my $chance = rand;
        my $retval = PCI_EAT_NONE;
        if($cur_time - $old_time > $self->{period} &&
           $chance > $self->{threshold}) {
                        my $repetitions = (int rand($self->{max_wubs}-$self->{min_wubs})+$self->{min_wubs});
                        my $wubstr = $self->{wub_str}x$repetitions;
                        $irc->yield(privmsg => $channel => $wubstr);
                        $self->{last_wub} = time;
                        $retval = PCI_EAT_PLUGIN;
        }

        return $retval;
}

1;


=head1 NAME

POE::Component::IRC::Plugin::WubWubWub - Wubbalize your IRC bots!

=head1 VERSION

Version 0.1

=cut

our $VERSION = '0.1';


=head1 SYNOPSIS

This plugin was designed to make your IRC bots 1000x cooler by integrating
this strange phenomenon referred to as dubstep into them. The manner in
which it achieves this, is of course, by randomly WUBBING into your chat rooms!

    use POE::Component::IRC;
    use POE::Component::IRC::Plugin::WubWubWub;

    my $WubWubWub = POE::Component::IRC::Plugin::WubWubWub->new({ 
			#options, documented below
    });
    $irc->plugin_add( 'WubWubWub', $WubWubWUb );
    ...

=head1 METHODS

=over 4

=item B<new>

Creates a new WubWubWub object. View the arguments below to grok everything
you could ever need to know. Calling syntax expects a hashref of arguments.

=back

=head1 ARGUMENTS

=over 4

=item B<threshold>

A threshold at which, when exceeded, will tell your bot it's okay to wub.
Defaults to 0.5; should be 0 < threshold < 1.

=item B<period>

A rate limiting mechanism in seconds; if the bot detects that it's been
less than the amount of seconds you specify, it'll stay quiet,
Defaults to 30 seconds. 

=item B<min_wubs>

The minimum amount of wubs to send at any given moment when wubs are to be sent!
Defaults to be 5. Should be 0 < min_wubs < max_wubs

=item B<max_wubs>

The maximum amount of wubs to send at any given moment when wubs are to be sent!
Defaults to be 20. Should be max_wubs > min_wubs > 0.

=item B<wub_str>

The string to emit to the channel. Defaults to WUB.

=back

=head1 AUTHOR

Gary Warman, C<< <sirmxe at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-poe-component-irc-plugin-wubwubwub at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=POE-Component-IRC-Plugin-WubWubWub>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.



=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc POE::Component::IRC::Plugin::WubWubWub


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=POE-Component-IRC-Plugin-WubWubWub>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/POE-Component-IRC-Plugin-WubWubWub>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/POE-Component-IRC-Plugin-WubWubWub>

=item * Search CPAN

L<http://search.cpan.org/dist/POE-Component-IRC-Plugin-WubWubWub/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2012 Gary Warman.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of POE::Component::IRC::Plugin::WubWubWub
