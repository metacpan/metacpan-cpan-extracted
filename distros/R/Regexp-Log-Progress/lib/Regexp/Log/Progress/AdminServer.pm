package Regexp::Log::Progress::AdminServer;

use strict;
use warnings;

our $VERSION = '0.01';

use base 'Regexp::Log';
use vars qw( %DEFAULT %FORMAT %REGEXP );

# \[(\d{1,2}/\d{1,2}/\d{2} \d{1,2}:\d{1,2}:\d{2} \w{2})\]\s+\[(\d+)\]\s+\[(\w+)\]\s+(.*)\((\d+)\)

%DEFAULT = (
    format  => '%datetime%level%facility%message%msgnum',
    capture => [qw( datetime level facility message msgnum )],
);

%FORMAT = (
    ':default'  => '%datetime%level%facility%message%msgnum',
    ':nomsgnum' => '%datetime%level%facility%message',
);

%REGEXP = (
    '%datetime' => '\[(?#=datetime)\d{1,2}/\d{1,2}/\d{2} \d{1,2}:\d{1,2}:\d{2} \w{2}(?#!datetime)\]\s+',
    '%level'    => '\[(?#=level)\d+(?#!level)\]\s+',
    '%facility' => '\[(?#=facility)[-|\w]+(?#!facility)\]\s+',
    '%message'  => '(?#=message).*(?#!message)',
    '%msgnum'   => '\((?#=msgnum)\d+(?#!msgnum)\)',
);

1;

__END__

=head1 NAME

Regexp::Log::Progress::AdminServer - a class to parse the Progress Admin Server log file

=head1 SYNOPSIS

Please refer to L<Regexp::Log> for how to use and initialize this module.

=head1 DESCRIPTION

A Progress Admin Server log line is broken down into these fields:

 datetime level facility message msgnum

Not all lines have a msgnum field. To handle those lines you can specify a 
format of ':nomsgnum' to new(). The datetime field has the following format:

 mm/dd/yy hh:mm:ss PM/AM

This can be handled with this DateTime format: '%m/%d/%y %l:%M:%S %p'

=head1 SEE ALSO

=over 4

=item L<Regexp::Log::Progress>

=back

=head1 AUTHOR

Kevin L. Esteb, E<lt>kesteb@wsipc.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014 by WSIPC

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
