use lib 'lib';
use lib '../lib';
use 5.006;
use strict;
use warnings;
use Test::More tests => 3;
use Perlmazing;

my $file = 'test_file.txt';
my $copy = 'test_copy.txt';
my $message = 'Hello world!';
if (-f $file) {
	unlink($file) or die "Cannot delete $file: $!";
}
if (-f $copy) {
	unlink($copy) or die "Cannot delete $copy: $!";
}
open my $out, '>', $file or dir "Cannot create $file: $!";
print $out $message;
close $out;
is copy($file, $copy), 1, 'copy';
open my $in, '<', $copy or die "Cannot open $copy: $!";
my $content = join '', <$in>;
close $in;
is $message, $content, 'copy content';
open my $copied, '>', $copy or die "Cannot write to $copy: $!";
print $copied "Goodbye world!";
close $copied;
open my $original, '<', $file or die "Cannot read $file: $!";
my $old_content = join '', <$original>;
close $original;
is $old_content, $message, 'original content';
