package Regexp::Log::Progress::Database;

use strict;
use warnings;

our $VERSION = '0.01';

use base 'Regexp::Log';
use vars qw( %DEFAULT %FORMAT %REGEXP );

# reference: http://knowledgebase.progress.com/articles/Article/000031990
#            http://documentation.progress.com/output/ua/OpenEdge11_3/index.html#page/openedge/25dmadmch18_2.html

%DEFAULT = (
    format  => '%datetime%pid%tid%level%process%msgnum%message',
    capture => [qw( datetime pid tid level process msgnum message )],
);

%FORMAT = (
    ':default' => '%datetime%pid%tid%level%process%msgnum%message',
);

%REGEXP = (
    '%datetime' => '\[(?#=datetime)\d{4}/\d{2}/\d{2}@\d{2}:\d{2}:\d{2}\.\d+.\d{4}(?#!datetime)\]\s+',
    '%pid'      => 'P-(?#=pid)[\d|-]+(?#!pid)\s+',
    '%tid'      => 'T-(?#=tid)[\d|-]+(?#!tid)\s+',
    '%level'    => '(?#=level)[I|W|F|\d+](?#!level)\s+',
    '%process'  => '(?#=process).*(?#!process):\s+',
    '%msgnum'   => '\((?#=msgnum)[\d|-]+(?#!msgnum)\)\s+',
    '%message'  => '(?#=message).*(?#!message)',
);

1;


__END__

=head1 NAME

Regexp::Log::Progress::Database - a class to parse the Progress Database log file

=head1 SYNOPSIS

Please refer to L<Regexp::Log> for how to use and initialize this module.

=head1 DESCRIPTION

A Progress database log line is broken down into these fields:

 datetime pid tid level process msgnum message

The datetime field has the following format:

 yyyy/mm/dd@hh:mm:ss.mls-zone

This can be handled with this DateTime format: '%Y/%m/%d@%H:%M:%S.%N%z'

=over 4

=item Note: the mls part is not always a nice 3 digit number

=item Note: the tid may be negative

=item Note: the level may be I, W or F

=back

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
