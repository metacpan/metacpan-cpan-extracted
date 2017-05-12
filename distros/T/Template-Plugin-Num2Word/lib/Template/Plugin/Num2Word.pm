package Template::Plugin::Num2Word;

use warnings;
use strict;
use 5.008000;
use base qw(Template::Plugin::VMethods);
use vars qw(@SCALAR_OPS);

use Lingua::Num2Word;
@SCALAR_OPS = qw(to_word);

our $VERSION = '0.30';

sub to_word {
    my $str = shift;
    my $lang = shift || "en";
    my $n = Lingua::Num2Word->new;
    scalar Lingua::Num2Word::cardinal($lang, $str);
}

# Module implementation here

1; # Magic true value required at end of module
__END__

=head1 NAME

Template::Plugin::Num2Word - Convert numbers to words in Template.

=head1 VERSION

This document describes Template::Plugin::Num2Word version 0.0.1

=head1 SYNOPSIS

In your template code

    [% USE Num2Word %]

    [% num_of_indians.to_word %] little Indians.


=head1 DESCRIPTION

This module is a Template Toolkit plugin that provides a C<to_word>
vmethod so it'll be very easy to convert from number to words.

=head1 INTERFACE 

=over

=item to_word

Objective interface that's called when people calls 'to_word' vmethod
in the template code. Currently it can convert numbers into English
words, different language support could be added.

The behaviour will be unexpected if your scalar is not a number.
Please be sure to take care of that.

=back

=head1 CONFIGURATION AND ENVIRONMENT

Template::Plugin::Num2Word requires no configuration files or environment variables.

=head1 DEPENDENCIES

L<Lingua::Num2Word>.

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-template-plugin-num2word@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 AUTHOR

Kang-min Liu  C<< <gugod@gugod.org> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2007, Kang-min Liu C<< <gugod@gugod.org> >>.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
