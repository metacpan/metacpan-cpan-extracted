use strict;
use warnings;

use autodie;

sub _slurp
{
    my $filename = shift;

    open my $in, '<', $filename
        or die "Cannot open '$filename' for slurping - $!";

    local $/;
    my $contents = <$in>;

    close($in);

    return $contents;
}

use File::Path qw(mkpath);

sub _gen_help
{
    my $dir = "lib/SVN/RaWeb/Light";
    mkpath ($dir);

open my $out_fh, ">", "$dir/Help.pm";
print {$out_fh} <<"EOF";
package SVN::RaWeb::Light::Help;

use strict;
use warnings;

\=head1 NAME

SVN::RaWeb::Light::Help - Generate the Help HTML for SVN::RaWeb::Light.

\=head1 SYNOPSIS

Warning! This moduls is auto-generated.

\=head1 FUNCTIONS

\=head2 print_data()

Prints the HTML data to the standard output.

\=head1 AUTHOR

Shlomi Fish, L<http://www.shlomifish.org/> .

\=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004 by Shlomi Fish

This library is free software; you can redistribute it and/or modify
it under the terms of the MIT/X11 license.

\=cut

sub print_data
{
    local \$/;
    print <DATA>;
}

1;
EOF

    print {$out_fh} "__DATA__\n";

    print {$out_fh} _slurp("docs/Help.html");
    close ($out_fh);
}

1;

