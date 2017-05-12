# $File: //depot/OurNet-Query/lib/Bundle/Query.pm $ $Author: autrijus $
# $Revision: #1 $ $Change: 1925 $ $DateTime: 2001/09/28 15:12:40 $

package Bundle::Query;

$VERSION = '0.01';

1;

__END__

=head1 NAME

Bundle::Query - OurNet::Query, OurNet::FuzzyIndex, and prerequisites

=head1 SYNOPSIS

C<perl -MCPAN -e 'install Bundle::Query'>

=head1 CONTENTS

# Below is a bunch of helpful dependency diagrams.

# the Query trunk

URI
MIME::Base64
Net::FTP
HTML::HeadParser
Digest::MD5
HTTP::Request::Common

LWP::Parallel

AppConfig
Template

OurNet::Query

# the FuzzyIndex trunk

DB_File

OurNet::FuzzyIndex

=head1 DESCRIPTION

This bundle includes all that's needed to run the Query Suite.

=head1 AUTHORS

Autrijus Tang <autrijus@autrijus.org>.

=head1 COPYRIGHT

Copyright 2001 by Autrijus Tang <autrijus@autrijus.org>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>

=cut
