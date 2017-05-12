#!/usr/bin/perl -w
use strict;

use Regexp::Log::Common;
use IO::File;

my $foo = Regexp::Log::Common->new(format  => ':common');
my @fields = $foo->capture;
my $re = $foo->regexp;

my %files;
my %ips;

my @files = ('videos-access.log','videos-access.log.1');
for my $file (@files) {
    my $fh = IO::File->new($file,'r')	or die "Cannot open file [$file]: $!\n";
    while (<$fh>) {
        my %data;
        @data{@fields} = /$re/;    # no need for /o, it's a compiled regexp

        my ($path) = ($data{req} =~ /^\w+\s+(.*?)\s+HTTP/);
        next    unless($path);
        next    if($path =~ m!(robots.txt|favicon.ico|style.css|thieves.png)!);     # specific files
        next    if($path =~ m!^/((2006|2007)/?)?$!);                                # specific directories

        $files{$path}++;
        $ips{$data{host}}++;
    }
}

print  "Files:\n";
printf "%4d %s\n",  scalar(keys %files), 'Entries';
printf "%4d %s\n", $files{$_}, $_   for(sort {$files{$b} <=> $files{$a}} keys %files);

print  "\nIPs:\n";
printf "%4d %s\n",  scalar(keys %ips), 'Entries';
#printf "%4d %s\n", $ips{$_}, $_     for(sort {$ips{$b} <=> $ips{$a}} keys %ips);

__END__

=head1 NAME

logparser.pl - A simple log parser

=head1 SYNOPSIS

  perl logparser.pl

=head1 DESCRIPTION

This example file was written to parse the log files for my Conference Videos
website (http://videos.grango.org). It uses the default configuration for
common log files and extracts the files for the request and the remotehost IP
address to provide some stats.

=head1 AUTHOR

  Barbie <barbie@cpan.org>
  for Miss Barbell Productions, L<http://www.missbarbell.co.uk>

=head1 COPYRIGHT AND LICENSE

  Copyright © 2005-2007 Barbie for Miss Barbell Productions.

  This distribution is free software; you can redistribute it and/or
  modify it under the Artistic Licence v2.

=cut

