package Rubyish::NilClass;
use strict;
use warnings;

use base qw(Rubyish::Object);
use Rubyish::Kernel;
use Rubyish::Syntax::def;

use overload
    'bool' => sub { },
#     '+0' => sub { 0 },
#     '""' => sub { '' };

def inspect { "nil" };
def nil { 1 };
def to_a { Array };
def to_f { 0.0 };
def to_i { 0 };
def to_s { String("") };


# cheat
def object_id { 4 };
{ no strict; *__id__ = *object_id; }

{
    my $obj = bless {}, __PACKAGE__;
    sub new {
        return $obj if defined $obj;
        $obj = bless {}, __PACKAGE__;
        return $obj;
    }
}

1;


=head1 NAME

Rubyish::NilClass - The NilClass implementation

=head1 SYNOPSIS

    nil->to_i
    nil->to_f
    nil->to_a

=head1 DESCRIPTION

This class defnes those instance methods availble for the singleton object C<nil>

=over 4

=item to_i

Always returns 0

=item to_f

Always returns 0.0

=item to_s

Always returns an empty string ""

=item to_a

Always returns []

=back

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



