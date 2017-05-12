#
# This file is part of Net-Mogade
#
# This software is copyright (c) 2011 by Gavin Mogan.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
package Net::Mogade;

# ABSTRACT: Perl Wrapper for the mogade.com leaderboard/scores service

use strict;
use warnings;

our $VERSION = "0.01";

use LWP::UserAgent;
use HTTP::Headers;
use HTTP::Request::Common qw(GET POST);
use LWP::ConnCache;
use Digest::SHA1;
use Params::Validate qw(validate);

use Carp;
use JSON::Any;

use fields qw(
    base
    key
    secret
);


use constant {
    SCOPE_DAILY => 1,
    SCOPE_WEEKLY => 2,
    SCOPE_OVERALL => 3,
    SCOPE_YESTERDAY => 4,
};

our $connectionCacheLimit = 50;
our $json = JSON::Any->new(utf8=>1);

{
    my $cache;
    sub _getCache
    {
        $cache ||= LWP::ConnCache->new( total_capacity => $connectionCacheLimit );
        return $cache;
    }
}

sub new 
{
    my $self = shift;
    my %args = @_;
    unless (ref $self) {
        $self = fields::new($self);
    }
    @$self{keys %args} = values %args;
    $self->{base} ||= 'http://api2.mogade.com/api/gamma/';
    return $self;
}

sub _generateCgiWithSig
{
    my $self = shift;
    my %args = @_;

    my @array;
    foreach my $key (sort keys %args)
    {
        push @array, $key, $args{$key};
    }
    my $sig = join('|', @array, $self->{secret});

    push @array, 'sig', Digest::SHA1::sha1_hex($sig);
    return \@array;
}

sub _post
{
    my $self = shift;
    my $urlSegment = shift;
    my %args = @_;

    my $agent = LWP::UserAgent->new();
    $agent->agent("Net::Mogade/$Net::Mogade::VERSION");

    my @headers;
    if (1)
    {
        push @headers, Connection => "Keep-Alive";
        $agent->conn_cache(_getCache());
    }
    my $url = URI->new($self->{base} . $urlSegment);

    my $request = POST $url, $self->_generateCgiWithSig(%args), @headers;
    my $response = $agent->request($request);
    croak "HTTP Error trying to talk to $url: ", $response->content unless $response->is_success();
    return $response;
}

sub _get
{
    my $self = shift;
    my $urlSegment = shift;
    my %args = @_;
    
    my $agent = LWP::UserAgent->new();
    $agent->agent("Net::Mogade/$Net::Mogade::VERSION");

    my @headers;
    if (1)
    {
        push @headers, Connection => "Keep-Alive";
        $agent->conn_cache(_getCache());
    }
    my $url = URI->new($self->{base} . $urlSegment);
    $url->query_form($url->query_form(), %args);

    my $request = GET $url, @headers;
    my $response = $agent->request($request);
    croak "HTTP Error trying to talk to $url: ", $response->content unless $response->is_success();
    return $response;
}

sub ranks
{
    my $self = shift;
    my %args = @_;
    validate( @_, {
            lid => 1,
            userkey => 1,
            username => 1,
            scope => 0,
    });

    my $response = $self->_get("ranks", %args);
    return $json->jsonToObj($response->content);
}

sub scoreSave
{
    my $self = shift;
    my %args = @_;
    validate( @_, {
            lid => 1,
            points => 1,
            userkey => 1,
            username => 1,
            data => {
                type => Params::Validate::SCALAR,
                optional => 1,
                callbacks => {           # ... and smaller than 50 characters
                    'max 50 characters' => sub { length shift() <= 50 },
                },
            }
    });

    my $response = $self->_post("scores", %args, key => $self->{key});
    return $json->jsonToObj($response->content);
}

sub scoreGet
{
    my $self = shift;
    my %args = @_;
    validate( @_, {
            lid => 1,
            userkey => {
                type => Params::Validate::SCALAR,
                optional => 1,
                depends => ['username']
            },
            username => {
                type => Params::Validate::SCALAR,
                optional => 1,
                depends => ['userkey']
            },
            scope => 0,
            page => 0,
            record => 0,
    });

    my $response = $self->_get("scores", %args);
    return $json->jsonToObj($response->content);
}


## Achievements

sub achievementGrant
{
    my $self = shift;
    my %args = @_;
    validate( @_, {
            aid => 1,
            userkey => 1,
            username => 1,
    });

    my $response = $self->_post("achievements", %args, key => $self->{key});
    return $json->jsonToObj($response->content);
}


sub achievementGet
{
    my $self = shift;
    my %args = @_;
    validate( @_, {
            userkey => 1,
            username => 1,
    });

    my $response = $self->_get("achievements", %args, key => $self->{key});
    return $json->jsonToObj($response->content);
}

## Log Error
sub logError
{
    my $self = shift;
    my %args = @_;
    validate( @_, {
            subject => {
                type => Params::Validate::SCALAR,
                optional => 0,
                callbacks => {           # ... and smaller than 150 characters
                    'max 150 characters' => sub { length shift() <= 150 },
                },
            },
            details => {
                type => Params::Validate::SCALAR,
                optional => 1,
                callbacks => {           # ... and smaller than 2000 characters
                    'max 2000 characters' => sub { length shift() <= 2000 },
                },
            }
    });

    $self->_post("errors", %args, key => $self->{key});
    return 1;
}

## Log Start
sub logStart
{
    my $self = shift;
    my %args = @_;
    validate( @_, {
            userkey => 1,
    });

    $self->_post("stats", %args, key => $self->{key});
    return 1;
}

1;



=pod

=head1 NAME

Net::Mogade - Perl Wrapper for the mogade.com leaderboard/scores service

=head1 VERSION

version 0.001

=head1 SYNOPSIS

 my $obj = Net::Mogade->new(
     key => '4edd1d4cd1798f5d86000003',
     secret => 'Yl=>yBmUNS6FuNUy[]NnBu8',
 );

 warn Dumper $obj->scoreGet(lid=>'4edd31e9d1798f1639000001', scope=>Net::Mogade::SCOPE_YESTERDAY);

=head1 NAME

Net::Mogade - Perl wrapper for the mogade.com leaderboard/scores service

=head1 CONSTANTS

=head2 SCOPE_DAILY

 Constant for daily scores. Mostly for scoresGet and ranks.

=head2 SCOPE_WEEKLY

 Constant for weekly scores. Mostly for scoresGet and ranks.

=head2 SCOPE_OVERALL

 Constant for overall scores. Mostly for scoresGet and ranks.

=head2 SCOPE_YESTERDAY

 Constant for yesterday scores. Mostly for scoresGet and ranks.

=head1 METHODS 

=head2 new(key=>'key', secret=>'secret', [base=>'http://other/location'])

Creates a new Net::Mogade object. Options:

=over 4

=item * C<key> 

 Key provided by mogade

=item * C<secret>

 Secret provided by mogade - Keep secret

=item * C<base> (optional) 

 Base url to mogade api. Default is mogade.com's api servers

=back

=head2 ranks(lid=>'', userkey=>'', username=>'', [scope=>SCOPE_DAILY])

Get a player's current rank by providing a leaderboard(C<lid>) C<username> and C<userkey>. Optionally provide scopes. Will return all scopes unless one is specified.

=head2 scoreSave(lid => '', points => '', userkey => '', username => '', [data => ''])

Updates a users score for a given leaderboard(C<lid>), C<username> and C<userkey>. data is an optional 50 character string that will be stored and returned when scores are retrieved.

=head2 scoreGet(lid => '', [userkey => '', username=>''], [scope=>SCOPE_DAILY], [page => 0], [record => 20])

Retrieves scores for a given leaderboard (C<lid>). If C<username> and C<userkey> is provided, it will try to return the data (by C<page>) surrounding the user. C<record> controls how many are returned. C<page> controls which page offset gets returned.
Most can be mixed and matched.

=head2 achievementGrant(aid=>'', username=>'', userkey=>'')

Gives a C<username> and C<userkey> pair an achievement(C<aid>)

=head2 achievementGet(username=>'', userkey=>'')

Retrieves achievements for a given C<username> and C<userkey>

=head2 logError(subject=>'', [details=>''])

Logs an error to the mogade servers. C<subject> is the string that gets shown, C<details> is optional amount of extra data that can be provided

=head2 logStart(userkey=>'')

Records a game startup for a given C<userkey>

=head1 AUTHORS

Gavin Mogan E<lt>halkeye@cpan.orgE<gt>

=head1 SEE ALSO

L<http://mogade.com/manage/api>

=head1 AUTHOR

Gavin Mogan <gavin@kodekoan.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Gavin Mogan.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

