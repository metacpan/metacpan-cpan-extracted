#!/usr/bin/env perl
use strict;
use warnings;
use utf8;

use OrePAN2::Server::CLI;
OrePAN2::Server::CLI->new(@ARGV)->run;

__END__

=head1 NAME

orepan2-server.pl - OrePAN2::Server launcher

=head1 SYNOPSIS

    % orepan2-server.pl [options]
        --delivery-dir=s     # a directory tar files of dist to be stored.       (Default: orepan)
        --delivery-path=s    # URL path behaves as cpan-mirror                   (Default: /orepan)
        --authenquery-path=s # URL path of the dist uploader                     (Default: /authenquery)
        --compress-index     # 02packages.details.txt is to be compressed or not (Defualt: true)

=head1 DESCRIPTION

OrePAN2::Server launcher.

=head1 Note

You can't use plackup, but you can set plackup's options like this.

    orepan2-server.pl -p 5888 -E production -S Starlet    

=head1 SEE ALSO

L<plackup>, L<Plack::Runner>

=head1 LICENSE

Copyright (C) Hiroyuki Akabane.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Hiroyuki Akabane E<lt>hirobanex@gmail.comE<gt>

Songmu E<lt>y.songmu@gmail.comE<gt>

