package Quote::Reference;

use warnings;
use strict;

use Filter::Simple;

=head1 NAME

Quote::Reference - Create array refs with qwr(...), hash refs with qhr{...}

=cut

our $VERSION = '1.0.4';

=head1 SYNOPSIS

    use Quote::Reference;

    # Set $foo = ['this','is','an','array','reference']; 
    my $foo = qwr( this is an array reference ); 

    # Set $bar = {
    #     'red' => 'FF0000',
    #     'green' => '00FF00',
    #     'blue' => '0000FF'
    # }
    my $bar = qhr{
        red    FF0000
        green  00FF00
        blue   0000FF
    };

=head1 DESCRIPTION

This module uses source filtering to allow creating hash and array references
just as easily and clean as using qw(...).

The following new quotelike operators are created:

=head2 qwr(...)

This behaves in the same way as qw(...) except that it returns an array
reference instead of a list.

Mnemonic: qw that returns a reference

=head2 qhr(...)

This behaves in the same way as qw(...) except that it returns a hash
reference instead of a list.

Mnemonic: quote for hash references

=head1 CAVEATS

Since this module is based on source filtering, if you have the strings 'qwr'
or 'qhr' anywhere in your code, you will get unexpected results.

=head1 FAQ

=over 4

=item Why?  Seems pointless.

I originally created this module as an experiment to familiarize myself with
creating a CPAN module.  With that in mind, I chose something silly and
limited in scope.  I don't expect anyone'll actually use it.  :)

=back

=cut

FILTER_ONLY
    code_no_comments => sub {s/ qwr  \(  (.*?) \) /[ qw($1) ]/gsx},
    code_no_comments => sub {s/ qwr  \{  (.*?) \} /[ qw{$1} ]/gsx},
    code_no_comments => sub {s/ qwr  \[  (.*?) \] /[ qw[$1] ]/gsx},
    code_no_comments => sub {s/ qwr  \<  (.*?) \> /[ qw<$1> ]/gsx},
    code_no_comments => sub {s/ qwr (\S) (.*?) \1 /[ qw$1$2$1 ]/gsx},
    code_no_comments => sub {s/ qhr  \(  (.*?) \) /{ qw($1) }/gsx},
    code_no_comments => sub {s/ qhr  \{  (.*?) \} /{ qw{$1} }/gsx},
    code_no_comments => sub {s/ qhr  \[  (.*?) \] /{ qw[$1] }/gsx},
    code_no_comments => sub {s/ qhr  \<  (.*?) \> /{ qw<$1> }/gsx},
    code_no_comments => sub {s/ qhr (\S) (.*?) \1 /{ qw$1$2$1 }/gsx},
    all              => sub {
        $Quote::Reference::DEBUG || return;
        print STDERR $_;
    },
;

=head1 AUTHOR

Anthony Kilna, C<< <anthony at kilna.com> >> - L<http://anthony.kilna.com>

=head1 BUGS

Please report any bugs or feature requests to C<bug-quote-reference at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Quote-Reference>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Quote::Reference

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Quote-Reference>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Quote-Reference>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Quote-Reference>

=item * Search CPAN

L<http://search.cpan.org/dist/Quote-Reference>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2012 Kilna Companies.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;    # End of Quote::Reference
