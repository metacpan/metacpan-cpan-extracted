package Rubyish::Syntax::class;
use Devel::Declare;

sub class { $_[0]->(); };

sub import {
    my ($class) = @_;
    my $caller = caller;

    {
        no strict;
        *{"${caller}::class"} = \&class;
    }

    Devel::Declare->setup_for(
        $caller => {
            'class' => [
                DECLARE_PACKAGE,
                sub {
                    my ($usepack, $use, $inpack, $name, $proto, $is_block) = @_;
                    return (sub (&) { shift; }, undef, "package ${name}; use Rubyish;");
                }
            ]
        }
    );
};

1;

__END__

=head1 NAME

Rubyish::Syntax::class - Define a new class with "class"

=head1 SYNOPSIS

    class Foo {
        def hi {
            print "Hello World"
        }
    }

    Foo->can("new"); # true
    Foo->can("hi");  # true

=head1 DESCRIPTION

This module injects a C<class> keyword into your current name space,
and make it declare a new L<Rubyish::Class>.

The simpliest usage looks like this:

    class MyClass {

    }

C<def> is also injected:

    class MyClass {
        def hi {
            print "Hello";
        }
    }

If you're interested in how this is done, read the source code of this
file, or ask L<Devel::Declare> people. Or read the tests of
L<Devel::Declare>.

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


