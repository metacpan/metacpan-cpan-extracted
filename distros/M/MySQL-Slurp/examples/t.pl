package unmain;
use IO::File;
use Moose;

    has 'file' => (
                is      => 'rw' ,
                isa     => 'IO::File' ,
                default => sub { IO::File->new( ">test.out" ); }
    );


package main;

my $h = unmain->new;

print ref $h->file;
my $fh = $h->file;
print {$h->file} "hello\n";
