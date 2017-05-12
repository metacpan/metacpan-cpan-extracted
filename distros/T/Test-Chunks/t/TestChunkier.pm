package TestChunkier;
use Test::Chunks -Base;

const chunk_class => 'TestChunkier::Chunk';
const filter_class => 'TestChunkier::Filter';

our @EXPORT = qw(run_like_hell);

sub run_like_hell() { 
    (my ($self), @_) = find_my_self(@_);
    $self->run_like(@_);
}


package TestChunkier::Chunk;
use base 'Test::Chunks::Chunk';

sub el_nombre { $self->name(@_) }

chunk_accessor 'feedle';


package TestChunkier::Filter;
use base 'Test::Chunks::Filter';

sub foo_it {
    map {
        "foo - $_";
    } @_;
}
