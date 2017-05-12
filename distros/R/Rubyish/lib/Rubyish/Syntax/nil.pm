package Rubyish::Syntax::nil;

use strict;
use Sub::Exporter;
Sub::Exporter::setup_exporter({
    exports => ['nil'],
    groups => {
        default => ['nil']
    }
});

use Rubyish::NilClass;

sub nil { Rubyish::NilClass->new }

1;

__END__

=head1 NAME

Rubyish::Syntax::nil - Gives you a nil object.

=head1 SYNOPSIS

    use Rubyish::Syntax::nil;

    my $a = nil;

    # Methods of nil
    my $empty_array  = nil->to_a;
    my $empty_string = nil->to_s;
    my $zero   = nil->to_i;
    my $zero_f = nil->to_f;

=head1 DESCRIPTION

This module exports a C<nil> bareword that works almost like Ruby
C<nil>. It represents the singleton object of L<Rubyish::NilClass>.
It means false under boolean context, 0 when being numerified, "" when
stringified, [] when converted to an array.

It also keep the behaviour that nil always referes to the same,
singleton object whenever it's used in the program.

=head1 METHODS

The C<nil> object has following instance methods:

=over 4

=item nil

Always returns a true value.

=item to_a

Always returns an empty L<Rubyish::Array>.

=item to_f

Always returns 0.0.

=item to_i

Always returns 0.

=item to_s

Always returns an empty L<Rubyish::String>.

=back

=head1 SEE ALSO

L<Rubyish::NilClass> for the implementation of these methods.

=head1 AUTHOR

Kang-min Liu  C<< <gugod@gugod.org> >>, shelling C<shelling@cpan.org>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2008,2009, Kang-min Liu C<< <gugod@gugod.org> >>.

This is free software, licensed under:

    The MIT (X11) License

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


