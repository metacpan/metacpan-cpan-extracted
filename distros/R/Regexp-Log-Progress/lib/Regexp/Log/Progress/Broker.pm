package Regexp::Log::Progress::Broker;

use strict;
use warnings;

our $VERSION = '0.01';

use base 'Regexp::Log';
use vars qw( %DEFAULT %FORMAT %REGEXP );

%DEFAULT = (
    format  => '%datetime%pid%tid%level%process%facility%message',
    capture => [qw( datetime pid tid level process facility message msgnum )],
);

%FORMAT = (
    ':default'  => '%datetime%pid%tid%level%process%facility%message',
);

%REGEXP = (
    '%datetime' => '\[(?#=datetime)\d{2}/\d{2}/\d{2}@\d{2}:\d{2}:\d{2}\.\d+.\d{4}(?#!datetime)\]\s+',
    '%pid'      => 'P-(?#=pid)[\d|-]+(?#!pid)\s+',
    '%tid'      => 'T-(?#=tid)[\w|\d|-]+(?#!tid)\s+',
    '%level'    => '(?#=level)[I|W|F|\d+](?#!level)\s+',
    '%process'  => '(?#=process)[\w|-]+(?#!process)\s+',
    '%facility' => '(?#=facility)[\w|-]+(?#!facility)\s+',
    '%message'  => '(?#=message).*(?#!message)',
    '%msgnum'   => '\((?#=msgnum)\d+(?#!msgnum)\)',
);

1;

__END__

=head1 NAME

Regexp::Log::Progress::Broker - a class to parse the Progress Broker log file

=head1 SYNOPSIS

Please refer to L<Regexp::Log> for how to use and initialize this module.

=head1 DESCRIPTION

A Progress Broker log line is broken down into these fields:

 datetime pid tid level process facility message msgnum

Not all lines have a msgnum field. To handle those lines you can specify a 
format of ':nomsgnum' to new(). The datetime field has the following format:

 yy/mm/dd@hh:mm:ss.mls-zone

This can be handled with this DateTime format: '%y/%m/%d@%H:%M:%S.%N%z'

=over 4

=item Note: the tid field may contain dashes and alphnumeric characters

=item Note: the process and facility fields may be dashes

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
