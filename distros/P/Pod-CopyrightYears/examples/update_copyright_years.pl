#!/usr/bin/env perl

use strict;
use warnings;

use File::Temp;
use IO::Barf qw(barf);
use Pod::CopyrightYears;

my $content = <<'END';
package Example;
1;
__END__
=pod

=head1 LICENSE AND COPYRIGHT

© 1977 Michal Josef Špaček

=cut
END

# Temporary file.
my $temp_file = File::Temp->new->filename;

# Barf out.
barf($temp_file, $content);

# Object.
my $obj = Pod::CopyrightYears->new(
        'pod_file' => $temp_file,
);

# Change years.
$obj->change_years(1987);

# Print out.
print $obj->pod;

# Unlink temporary file.
unlink $temp_file;

# Output:
# package Example;
# 1;
# __END__
# =pod
# 
# =head1 LICENSE AND COPYRIGHT
# 
# © 1977-1987 Michal Josef Špaček
# 
# =cut