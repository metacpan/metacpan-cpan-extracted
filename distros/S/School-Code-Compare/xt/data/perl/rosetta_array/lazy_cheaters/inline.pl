# an empty array
my @empty;
my @empty_too = ();

# This is a normal array in Perl
my @array   = ('This', 'That', 'And', 'The', 'Other');
print $array[2];

# This is an array stored a reference
my $ref = ['This', 'That', 'And', 'The', 'Other'];
print $ref->[2];
