package OurNet::Query;
require 5.005;

$OurNet::Query::VERSION = '1.22';

use strict;

use OurNet::Site;
use HTTP::Request::Common;
use LWP::Parallel::UserAgent;

=head1 NAME

OurNet::Query - Perform scriptable queries via LWP

=head1 SYNOPSIS

    use OurNet::Query;

    # Set query parameters
    my ($query, $hits) = ('autrijus', 10);
    my @sites = ('Altavista', 'InfoSeek', 'Yahoo', 'Excite');
    my %found;

    # Generate a new Query object
    my $bot = OurNet::Query->new($query, $hits, @sites);

    # Perform a query
    my $found = $bot->begin(\&callback, 30); # Timeout after 30 seconds

    print '*** ' . ($found ? $found : 'No') . ' match(es) found.';

    sub callback {
        my %entry = @_;
        my $entry = \%entry;

        unless ($found{$entry{'url'}}) {
            print "*** [$entry->{'title'}]" .
                     " ($entry->{'score'})" .
                   " - [$entry->{'id'}]\n"  .
             "    URL: [$entry->{'url'}]\n";
        }

        $found{$entry{'url'}}++;
    }

=head1 DESCRIPTION

OurNet::Query provides an easy interface to perform multiple queries
to internet services, and "wrap" them into your own format at once.
The results are processed on-the-fly and are returned via callback
functions.

=cut

# ---------------
# Variable Fields
# ---------------
use fields qw/callback pua timeout query sites bots hits found/;

# -----------------
# Package Constants
# -----------------
use constant ERROR_QUERY_NEEDED    => __PACKAGE__ . ' needs a query';
use constant ERROR_HITS_NEEDED     => __PACKAGE__ . ' needs sufficient hits';
use constant ERROR_SITES_NEEDED    => __PACKAGE__ . ' needs one or more sites';
use constant ERROR_CALLBACK_NEEDED => __PACKAGE__ . ' needs a callback function';
use constant ERROR_PROTOCOL_UNDEF  => __PACKAGE__ . ' cannot use the protocol';

# -------------------------------------
# Subroutine new($query, $hits, @sites)
# -------------------------------------
sub new {
    my $class = shift;
    my $self  = ($] > 5.00562) ? fields::new($class)
                               : do { no strict 'refs';
                                      bless [\%{"$class\::FIELDS"}], $class };

    $self->{'query'} = shift  or (warn(ERROR_QUERY_NEEDED), return);
    $self->{'hits'}  = shift  or (warn(ERROR_HITS_NEEDED),  return);
    $self->{'sites'} = [ @_ ] or (warn(ERROR_SITES_NEEDED), return);
    $self->{'pua'}   = LWP::Parallel::UserAgent->new();

    return $self;
}

# ---------------------------------------------
# Subroutine begin($self, \&callback, $timeout)
# ---------------------------------------------
sub begin {
    my $self = shift;

    $self->{'callback'} = ($_[0] ? $_[0] : $self->{'callback'})
        or (warn(ERROR_CALLBACK_NEEDED), return);
    $self->{'timeout'}  = ($_[1] ? $_[1] : $self->{'timeout'});
    $self->{'pua'}->initialize();

    foreach my $count (0 .. $#{$self->{'sites'}}) {
        $self->{'bots'}[$count] = OurNet::Site->new($self->{'sites'}[$count]);

        my $siteurl = $self->{'bots'}[$count]->geturl($self->{'query'}, $self->{'hits'});

        my $request = ($siteurl =~ m|^post:(.+?)\?(.+)|)
                    ? POST("http:$1", [split('[&;=]', $2)])
                    : GET($siteurl)
            or (warn(ERROR_PROTOCOL_UNDEF), return);

        # Closure is not something that most Perl programmers need
        # trouble themselves about to begin with. (perlref.pod)
        $self->{'pua'}->register($request, sub {
            $self->{'bots'}[$count]->callme($self, $count,
                                            $_[0], \&callmeback);
            return;
        });
    }

    $self->{'found'} = 0;
    $self->{'pua'}->wait($self->{'timeout'});

    return $self->{'found'};
}

# --------------------------------------
# Subroutine callmeback($self, $himself)
# --------------------------------------
sub callmeback {
    my ($self, $himself) = @_;

    foreach my $entry (@{$himself->{'response'}}) {
    	if (exists($entry->{'url'})) {
            &{$self->{'callback'}}(%{$entry});
            delete($entry->{'url'});

            $self->{'found'}++;
        }
    }
}

1;

=head1 SEE ALSO

L<OurNet::Site>

=head1 AUTHORS

Autrijus Tang E<lt>autrijus@autrijus.org>

=head1 COPYRIGHT

Copyright 2001 by Autrijus Tang E<lt>autrijus@autrijus.org>.

All rights reserved.  You can redistribute and/or modify
this module under the same terms as Perl itself.

=cut
