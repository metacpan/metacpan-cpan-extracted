package Bookshop::Controller::Books;
use strict;
use warnings;

my %BOOKS = (
    1 => { id => 1, title => 'Dune',             author => 'Frank Herbert',  year => 1965 },
    2 => { id => 2, title => 'The Dispossessed', author => 'Ursula K. Le Guin', year => 1974 },
    3 => { id => 3, title => 'Hyperion',         author => 'Dan Simmons',    year => 1989 },
);
my $NEXT = 4;

sub search {
    my ($c) = @_;
    my $q = lc($c->param('q') // '');
    my @hits = grep { index(lc "$_->{title} $_->{author}", $q) >= 0 }
               map { $BOOKS{$_} } sort { $a <=> $b } keys %BOOKS;
    $c->mcp_log('info', { searched => $q, found => scalar @hits });
    return { books => \@hits };
}

sub show {
    my ($c) = @_;
    my $book = $BOOKS{ $c->param('id') // '' } or return [404, ['Content-Type' => 'text/plain'], ['no such book']];
    return $c->json($book);
}

sub catalog {
    my ($c) = @_;
    return [ map { "$_->{id}: $_->{title}" } map { $BOOKS{$_} } sort { $a <=> $b } keys %BOOKS ];
}

sub add {
    my ($c) = @_;
    my $id = $NEXT++;
    $BOOKS{$id} = { id => $id, title => $c->param('title'), author => $c->param('author'),
                    year => $c->param('year') };
    $c->mcp_resource_updated('books://catalog');
    return $c->json($BOOKS{$id});
}

sub recommend {
    my ($c) = @_;
    my $mood = $c->param('mood');
    return [
        { role => 'user', content => "Recommend one book from books://catalog for someone who wants $mood. Say why in two sentences." },
    ];
}

1;
