package Net::Async::Spotify::Object::General;

use strict;
use warnings;

our $VERSION = '0.002'; # VERSION
our $AUTHORITY = 'cpan:VNEALV'; # AUTHORITY

use Future::AsyncAwait;
use Log::Any qw($log);
use Syntax::Keyword::Try;

=head1 NAME

    Net::Async::Spotify::Object::General - Default representation of unmapped Spotify API Response Objects

=head1 DESCRIPTION

Default representation of unmapped Objects. where L</data> will contain a hash of the returned response.
Without specifying field names.

=head1 METHODS

=cut

sub new {
    my ( $class, %data ) = @_;

    my $self = bless {}, $class;
    $self->{data} = \%data;
    return $self;

}

=head2 data

Contains all the decoded hash response, without any of the fields defined as methods.
More like full raw content of Spotify API response.

=cut

sub data { shift->{data} }

1;
