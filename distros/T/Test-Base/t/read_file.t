use Test::Base;

sub fix {
    s/\bt\b/test/ if -e 'test';
    $_;
}

__END__
=== Filename is chomped automatically
--- file fix read_file
t/sample-file.txt
--- content
A sample of some text
in a sample file!

=== Filename is inline
--- file fix read_file: t/sample-file.txt
--- content
A sample of some text
in a sample file!
