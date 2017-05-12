package Net::AnimeNewsNetwork::Encyclopedia;
use 5.10.0;
use strict;
use warnings;
use Moo;
use Data::Validator;
use URI;
use LWP::Simple;
use XML::Simple;

our $VERSION = "0.02";
our $URL = 'http://cdn.animenewsnetwork.com/encyclopedia';

has url => (
    is      => 'ro',
    default => $URL,
);

sub get_reports {
    state $rule = Data::Validator->new(
        id    => 'Int',
        type  => 'Str',
        nskip => { isa => 'Int', optional => 1 },
        nlist => { isa => 'Int', optional => 1 },
        name  => { isa => 'Str', optional => 1 },
    )->with('Method');
    my ($self, $args) = $rule->validate(@_);

    my $content = $self->_get("/reports.xml", $args);
    return XMLin($content);
}

sub get_details {
    state $rule = Data::Validator->new(
        anime    => { isa => 'Int', xor => [qw/manga title/] },
        manga    => { isa => 'Int', xor => [qw/anime title/] },
        title    => { isa => 'Int', xor => [qw/anime manga/] },
    )->with('Method');
    my ($self, $args) = $rule->validate(@_);

    my $content = $self->_get("/api.xml", $args);
    return XMLin($content);
}

sub _get {
    my ($self, $path, $query) = @_;
    my $uri = URI->new($self->url . $path);
    $uri->query_form($query);
    return get($uri);
}

1;
__END__

=encoding utf-8

=head1 NAME

Net::AnimeNewsNetwork::Encyclopedia - Client library of the AnimeNewsNetwork Encyclopedia API

=head1 SYNOPSIS

    use Net::AnimeNewsNetwork::Encyclopedia;
    
    my $ann = Net::AnimeNewsNetwork::Encyclopedia->new();
    $ann->get_reports(id => 155, type => 'anime');
    $ann->get_details(anime => 4658);

=head1 DESCRIPTION

Net::AnimeNewsNetwork::Encyclopedia is a simple client library of the AnimeNewsNetwork Encyclopedia API. 

L<http://www.animenewsnetwork.com/encyclopedia/api.php>

=head1 LICENSE

Copyright (C) Ryosuke IWANAGA.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Ryosuke IWANAGA E<lt>riywo.jp@gmail.comE<gt>

=cut

