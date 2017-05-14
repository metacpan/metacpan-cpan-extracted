# $Id: /mirror/Senna-Perl/lib/Senna.pm 6103 2007-03-16T16:45:50.914799Z daisuke  $
#
# Copyright (c) Daisuke Maki <dmaki@cpan.org>
# All rights reserved.

package Senna;
use strict;
use vars qw($VERSION);

BEGIN
{
    $VERSION = '0.51';
    if ($] > 5.006) {
        require XSLoader;
        XSLoader::load(__PACKAGE__, $VERSION);
    } else {
        require DynaLoader;
        @Senna::ISA = ('DynaLoader');
        __PACKAGE__->bootstrap();
    }
}

use Senna::Constants;
use Senna::Index;
use Senna::OptArg::Select;
use Senna::Query;
use Senna::Record;
use Senna::Records;
use Senna::RC;
use Senna::Snippet;
use Senna::Symbol;
use Senna::Values;

1;

__END__

=head1 NAME

Senna - Perl Interface To Senna Fulltext Search Engine

=head1 SYNOPSIS

  use Senna;

=head1 DESCRIPTION

Senna is a fast, embeddable search engine that allows fulltext search
capabilities (http://qwik.jp/senna). 

Please note that version 0.50 and upwards breaks compatibility with previous
versions of this module, and only supports libsenna 0.8.0+. 

Below is a list of modules. Please refer to the documentation on each page
for more comprehensive usage.

=head2 L<Senna::Index|Senna::Index>

=head2 L<Senna::Constants|Senna::Constants>

=head2 L<Senna::RC|Senna::RC>

=head2 L<Senna::Records|Senna::Records>

=head2 L<Senna::Record|Senna::Record>

=head2 L<Senna::Query|Senna::Query>

=head2 L<Senna::Set|Senna::Set>

=head2 L<Senna::Symbol|Senna::Symbol>

=head2 L<Senna::Snippet|Senna::Snippet>

=head2 L<Senna::Values|Senna::Values>

=head2 L<Senna::OptArg::Select|Senna::OptArg::Select>

=head2 L<Senna::OptArg::Sort|Senna::OptArg::Sort>

=head1 CAVEATS

Portions of this module that interact with the "Advanced API" from libsenna
aren't too well tested. If you encounter any problems, please send me
minimal test cases that displays the problem.

=head1 AUTHOR

Copyright (C) 2005-2006 by Daisuke Maki <dmaki@cpan.org>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

Development funded by Brazil Ltd. E<lt>http://dev.razil.jp/project/senna/E<gt>

=head1 SEE ALSO

http://qwik.jp/senna - Senna Development Homepage

=cut
