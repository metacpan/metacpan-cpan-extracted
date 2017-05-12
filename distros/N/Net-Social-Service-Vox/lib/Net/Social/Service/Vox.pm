package Net::Social::Service::Vox;

use strict;
use base qw(Net::Social::Service);
use LWP::Simple;
use XML::XPath;
use XML::XPath::XMLParser;
use IO::Scalar;
use Net::Social qw(:all);

use vars qw($VERSION);

$VERSION = "0.1";

=head1 NAME

Net::Social::Service::Vox - a Vox plugin for Net::Social

=head1 PARAMS

For reading C<Net::Social::Service::Vox> needs

=over 4

=item username

Your Vox username

=back

=cut

sub params {(
    read => {
        "username" => { required    => 1, 
                        description => "Your Vox UserName",
                    },
    },
)}

=head1 METHODS

=head2 friends

Returns your friends. It defines the keys C<id>, C<username>, C<name> and C<type>.

=cut


sub friends {
    my $self = shift;
    return () unless $self->{_logged_in};
    my $user = $self->{_details}->{username};
    my %friends;
    foreach my $reverse ((1, 0)) {
        # fetch all the people
        foreach my $friend ($self->_fetch_friends($user, $reverse)) {
            my $id = $friend->{id};
            # set up a 
            my $existing = $friends{$id} || { type => NONE };
            # now merge 
            foreach my $key (keys %$friend) {
                $existing->{$key} = $friend->{$key} unless defined $existing->{$key};
                # paying special attention to 'type'
                if ($key  eq 'type') {
                    $existing->{type} |= $friend->{type};
                }    
            }
            $friends{$id} = $existing;
        }

    }
    return values %friends;
}


sub _fetch_friends {
    my $self    = shift;
    my $user    = shift;
    my $reverse = shift;
    my $base    = "http://${user}.vox.com/profile/neighbors".(($reverse)?"/reverse":"");
    my $page    = 1;
    my @friends;

    while (1) {
        my $xml = get("$base/page/$page/");
        last unless defined $xml;
        $xml =~ s!<a class="user-uri"!<a!g; # HACK! 
        my @this;
        my $xp = XML::XPath->new( ioref => IO::Scalar->new(\$xml) );
        my $ns = eval { $xp->find('//div[@class="member pkg"]') };
        last if $@;
        for my $node ($ns->get_nodelist) {
            my $id     = $node->getAttribute('at:user-xid');
            my $name   = $node->getAttribute('at:screen-name');
            next unless defined $id;
            my ($link) = eval { $xp->find('*/p[@class="member-name"]/a', $node)->get_nodelist };
            next if $@;
            next unless defined $link;
            my $domain = $link->getAttribute('href');
            next unless $domain;
            my ($user) = ($domain =~ m!http://([^.]+)\.vox\.com!);
            next unless defined $user;
            my $person = { id => $id, name => $name, username => $user };
            $person->{type} = ($reverse)? FRIENDED_BY : FRIENDED;
            push @this, $person;
        }
        if (@this) {
            push @friends, @this;
        } else {
            last;
        }
        $page++;
    }
    return @friends;
}


=head1 AUTHOR

Simon Wistow <simon@thegestalt.org>

=head1 COPYRIGHT

Copyright, 2007 - Simon Wistow

Distributed under the same terms as Perl itself

=cut


1;
