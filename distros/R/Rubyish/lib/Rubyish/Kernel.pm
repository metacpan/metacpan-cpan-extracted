=head1

Rubyish::Kernel - Kernel (module)

=cut

package Rubyish::Kernel;
use strict;
use Rubyish::Hash;
use Rubyish::Array;
use Rubyish::String;

use Sub::Exporter;
Sub::Exporter::setup_exporter({
    exports => [qw(Array String Hash puts)],
    groups  => { default => [qw(Array String Hash puts)] },
});

sub String {
    Rubyish::String->new($_[0]);
}

sub Array {
    Rubyish::Array->new($_[0]);
}

sub Hash {
    Rubyish::Hash->new($_[0]);
}

sub puts {
    print map { ref($_) =~ /Rubyish/ ? $_->inspect : $_ } @_;
    print "\n";
}

1;

=head1 NAME

Rubyish::Kernel - The Kernel implementation

=head1 SYNOPSIS

    use Rubyish::Kernel;

    my $arr = Array[1..3];

    puts "Hello world";

=head1 DESCRIPTION

This module exports several convienent sub-routines to make your
program looks rubyish. Several of them might be re-organized into a
more proper place.

=over 4

=item puts

The C<print> in ruby.

=item Array

The C<Rubyish::Array> constructor. The standard usage is like:

    my $arr1 = Array[1..3];
    my $arr2 = Array[qw(a b c)];

=item Hash

The C<Rubyish::Hash> constructor. The standard usage is like:

    my $h = Hash({ a => 1, b => 2 });

    $h->fetch("a"); # returns 1

=item String

The L<Rubyish::String> constructor. Use it like:

    my $str1 = String("food");
    my $str2 = $str1->gsub(qr/oo/, "nor");

    puts $str2; # "fnord"

=back

=head1 SEE ALSO

L<Rubyish::String>, L<Rubyish::Array>, L<Rubyish::Hash> for the full
reference of their instance methods.

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
