package Sweat::ArticleHandler;

use warnings;
use strict;
use Moo;
use namespace::clean;
use utf8::all;

use Types::Standard qw( Str Maybe Int );

use Storable qw(freeze thaw);
use Path::Tiny;

has 'tempdir' => (
    is => 'ro',
    isa => sub { $_[0]->isa('Path::Tiny') },
    default => sub { Path::Tiny->tempdir( CLEANUP => 1 ) },
);

has 'next_filename' => (
    is => 'rw',
    isa => Int,
    default => 1,
);

has 'last_article_read' => (
    is => 'rw',
    isa => Int,
    default => 0,
);

sub add_article {
    my ($self, $article) = @_;
    my $file = path( $self->tempdir, $self->next_filename );
    $self->next_filename( $self->next_filename + 1 );

    $file->spew( freeze( $article ) );

#    warn "Writing about " . $article->title . " to $file.\n";
}

sub next_article {
    my $self = shift;

    my $next_filename = $self->last_article_read + 1;
    my $next_file = path( $self->tempdir, $next_filename );

    if ( -e $next_file ) {
#        warn "Loading from $next_file\n";
        $self->last_article_read( $self->last_article_read + 1 );
        return thaw( $next_file->slurp );
    }
    else {
#        warn "No file at $next_file, chief.\n";
        return undef;
    }
}

1;
