# Each filter should have access to chunks/chunk internals.
use Test::Chunks;

plan tests => 20 * 2;

run {};

package Test::Chunks::Filter;
use Test::More;
use Spiffy ':XXX';

sub foo {
    my $self = shift;
    my $value = shift;
    
# Test access to Test::Chunks::Filter object.
    ok ref($self), 
       '$self is an object';
    is ref($self), 
       'Test::Chunks::Filter', 
       '$self is a Test:Chunks::Filter object';
    like $value,
         qr/^This is some .*text.\z/,
         'Filter value is correct';   

# Test access to Test::Chunks::Chunk object.
    my $chunk = $self->chunk;
    is ref($chunk), 
       'Test::Chunks::Chunk', 
       'Have a reference to our chunk object';

    ok not($chunk->is_filtered),
       'Chunk is not completely filtered yet';

    my $name = shift || 'One';
    is $chunk->name,
       $name,
       'name is correct';

    my $description = shift || 'One';
    is $chunk->description,
       $description,
       'description is correct';

    my $original = shift || "This is some text.\n";
    is $chunk->original_values->{xxx},
       $original,
       'Access to the original value';

    my $seq_num = shift || 1;
    cmp_ok $chunk->seq_num,
           '==',
           $seq_num,
           'Sequence number (seq_num) is correct';

    my $array_xxx = shift || ["This is some text."];
    is_deeply $chunk->{xxx},
              $array_xxx,
             'Test raw content of $chunk->{xxx}';

    my $method_xxx = shift || "This is some text.";
    is $chunk->xxx,
       $method_xxx,
       'Test method content of $chunk->xxx';

# Test access to Test::Chunks object.
    my $chunks = $chunk->chunks_object;
    my $chunk_list = $chunks->chunk_list;
    is ref($chunk_list), 
       'ARRAY',
       'Have an array of all chunks';

    is scalar(@$chunk_list), 
       '2',
       'Is there 2 chunks?';

    is $chunks->chunk_class,
       "Test::Chunks::Chunk",
       'chunk class';

    is $chunks->filter_class,
       "Test::Chunks::Filter",
       'filter class';

    is_deeply
       $chunks->{_filters},
       [qw(norm trim)],
       'default filters are ok';

    is $chunks->chunk_delim,
       '===',
       'chunk delimiter';

    is $chunks->data_delim,
       '---',
       'data delimiter';

    my $spec = <<END;
=== One
--- xxx chomp foo
This is some text.
=== Two
This is the 2nd description.
Right here.

--- xxx chomp bar
This is some more text.

END
    is $chunks->spec,
       $spec,
       'spec is ok';

    is $chunk_list->[$seq_num - 1],
       $chunk,
       'test chunk ref in list';
}

sub bar {
    my $self = shift;
    my $value = shift;
    $self->foo($value,
        'Two',
        "This is the 2nd description.\nRight here.",
        "This is some more text.\n\n",
        2,
        ["This is some more text."],
        "This is some more text.",
    );
}

__END__
=== One
--- xxx chomp foo
This is some text.
=== Two
This is the 2nd description.
Right here.

--- xxx chomp bar
This is some more text.

