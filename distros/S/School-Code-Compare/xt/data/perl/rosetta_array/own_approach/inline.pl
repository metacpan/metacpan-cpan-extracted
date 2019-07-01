# this array is empty, can also be written like this: @a = ();
my @array;

# fill up the array
@array   = ('Hans', 'Boris', 'Jens', 'Hildrun', 'Meike', 'Jörg');
print $array[4];  # prints Meike

# square brackets givt a reference to an array
my $array_ref = ['Hans', 'Boris', 'Jens', 'Hildrun', 'Meike', 'Jörg'];
print $array_ref->[0];  # prints Hans
