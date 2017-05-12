package Bundle::PerlPoint;

1

__END__

=head1 NAME

Bundle::PerlPoint - A bundle to install PerlPoint related modules

=head1 SYNOPSIS

 perl -MCPAN -e 'install Bundle::PerlPoint'

=head1 CONTENTS

Getopt::ArgvFile       - Used for startup option files

Storable               - Needed by PerlPoint::Parser

Digest::SHA1           - Needed by PerlPoint::Parser

Digest::MD5            - Needed by PerlPoint::Converters test suite

Test::Harness          - Needed for PerlPoint test suites

Test::Simple           - Provides Test::More

PerlPoint::Parser      - PerlPoint parser package

PerlPoint::Converters  - PerlPoint converters pp2html, pp2latex

=head1 DESCRIPTION

This bundle defines all required modules for the PerlPoint package.

=head1 AUTHOR

Lorenz Domke <lorenz.domke@gmx.de>

=cut
