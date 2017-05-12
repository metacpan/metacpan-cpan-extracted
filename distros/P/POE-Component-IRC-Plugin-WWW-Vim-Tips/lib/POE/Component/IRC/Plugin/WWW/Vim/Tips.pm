package POE::Component::IRC::Plugin::WWW::Vim::Tips;

use 5.008_005;
use strict;
use warnings;

our $VERSION = '0.14';

use POE::Component::IRC::Plugin qw( :ALL );
use HTML::TreeBuilder::XPath;
use LWP::Simple qw(get);

sub new {
    my $package = shift;
    return bless {}, $package;
}

sub PCI_register {
    my ($self, $irc) = splice @_, 0, 2;

    $irc->plugin_register($self, 'SERVER', qw(public));
    return 1;
}

# This is method is mandatory but we don't actually have anything to do.
sub PCI_unregister {
    return 1;
}

sub S_public {
    my ($self, $irc) = splice @_, 0, 2;

    # Parameters are passed as scalar-refs including arrayrefs.
    my $nick    = (split /!/, ${$_[0]})[0];
    my $channel = ${$_[1]}->[0];
    my $msg     = ${$_[2]};

    my $reply =
        ($msg =~ /^!vimtips?\b/i)   ? $self->_get_vim_tip
      : ($msg =~ /^!emacstips?\b/i) ? 'use Vim'
      :                               '';
    if ($reply) {
        $irc->yield(privmsg => $channel => "$nick: $reply");
        return PCI_EAT_PLUGIN;
    }

    # Default action is to allow other plugins to process it.
    return PCI_EAT_NONE;
}

sub _get_vim_tip {
    my $content = get('http://twitter.com/vimtips');
    my $tree    = HTML::TreeBuilder::XPath->new_from_content($content);
    my @tips    = grep { s/\x{a0}/ /g; s/^\s*|\s*$//g; 1 }                #
      $tree->findvalues(
        './/div[@class=~/\bprofile-stream\b/]
          //p[@class=~/\btweet-text\b/]'
      );
    return $tips[rand @tips];
}

1;

__END__

=pod

=head1 NAME

POE::Component::IRC::Plugin::WWW::Vim::Tips - IRC plugin to fetch Vim tips


=head1 SYNOPSIS

    use strict;
    use warnings;

    use POE qw(Component::IRC  Component::IRC::Plugin::WWW::Vim::Tips);

    my $irc = POE::Component::IRC->spawn(
        nick    => 'nickname',
        server  => 'irc.freenode.net',
        port    => 6667,
        ircname => 'ircname',
    );

    POE::Session->create(package_states => [main => [qw(_start irc_001)]]);

    $poe_kernel->run;

    sub _start {
        $irc->yield(register => 'all');

        $irc->plugin_add('Vim-Tips' => POE::Component::IRC::Plugin::WWW::Vim::Tips->new);

        $irc->yield(connect => {});
    }

    sub irc_001 {
        $irc->yield(join => '#channel');
    }

=head1 DESCRIPTION

type !vimtip or !vimtips to get a random Vim tip, currenly fetched from L<http://twitter.com/vimtips>

here is a cool one-liner if you just want the Vim tip:

    perl -Ilib -MPOE::Component::IRC::Plugin::WWW::Vim::Tips
         -le 'print POE::Component::IRC::Plugin::WWW::Vim::Tips->new->_get_vim_tip'

=head1 AUTHOR

Curtis Brandt, C<< <curtis at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-poe-component-irc-plugin-vimtips at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=POE-Component-IRC-Plugin-WWW-Vim-Tips>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc POE::Component::IRC::Plugin::WWW::Vim::Tips


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=POE-Component-IRC-Plugin-WWW-Vim-Tips>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/POE-Component-IRC-Plugin-WWW-Vim-Tips>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/POE-Component-IRC-Plugin-WWW-Vim-Tips>

=item * Search CPAN

L<http://search.cpan.org/dist/POE-Component-IRC-Plugin-WWW-Vim-Tips/>

=back


=head1 ACKNOWLEDGEMENTS

Thanks to Graham Barr for guidance in my Perl work


=head1 LICENSE AND COPYRIGHT

Copyright 2013 Curtis Brandt.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;
