#!perl -T

use strict;
use warnings;
use autodie;
use Test::More;

use constant PROBLEM_PATH => 'lib/Project/Euler/Problem/';


my @files;
opendir (my $dir, PROBLEM_PATH);
while (( my $filename = readdir($dir) )) {
    push @files, $filename  if  $filename =~ / \A p \d+ \.pm \z /xmsi;
}

plan tests => (scalar @files * 1) + 3;
diag('Check for default boilercode or template code');


sub not_in_file_ok {
    my ($type, $filename, %regex) = @_;
    open( my $fh, '<', $filename )
        or die "couldn't open $filename for reading: $!";

    my %violated;

    while (my $line = <$fh>) {
        while (my ($desc, $regex) = each %regex) {
            if ($line =~ $regex) {
                push @{$violated{$desc}||=[]}, $.;
            }
        }
    }

    if (%violated) {
        fail("$filename contains $type text");
        diag "$_ appears on lines @{$violated{$_}}" for keys %violated;
    } else {
        pass("$filename contains no $type text");
    }
}





not_in_file_ok('boilerplate', README =>
"The README is used..."       => qr/The README is used/,
"'version information here'"  => qr/to provide version information/,
);

not_in_file_ok('boilerplate', Changes =>
"placeholder date/time"       => qr(Date/time)
);

not_in_file_ok('boilerplate', 'lib/Project/Euler.pm' =>
    'the great new $MODULENAME'   => qr/ - The great new /,
    'boilerplate description'     => qr/Quick summary of what the module/,
    'stub function definition'    => qr/function[12]/,
);


for  my $module_name  (@files) {
    not_in_file_ok('template', PROBLEM_PATH . $module_name =>
        '### TEMPLATE ###'   => qr/### TEMPLATE ###/,
    );
}
