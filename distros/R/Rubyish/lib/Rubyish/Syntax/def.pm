package Rubyish::Syntax::def;

use base 'Devel::Declare::MethodInstaller::Simple';

sub import {
    my $class = shift;
    my $caller = caller;

    my $arg = shift;

    $class->install_methodhandler(
        into            => $caller,
        name            => 'def',
    );
}

sub parse_proto {
    my $ctx = shift;
    my ($proto) = @_;
    my $inject = 'my ($self';
    if (defined $proto) {
        $inject .= ", $proto" if length($proto);
        $inject .= ') = @_; ';
    }
    else {
        $inject .= ') = shift;';
    }
    return $inject;
}

1;

__END__

=head1 NAME

Rubyish::Syntax::def - Inject "def" into your package.

=head1 SYNOPSIS

    package HelloWorld;
    use Rubyish::Syntax::def;

    # define a method
    def hi {
        print "Hello World"
    }

    # define a method with arguments
    def hey($you) {
        print "Hey $you";
    }

=head1 DESCRIPTION

This module injects a C<def> keyword into your current name space, and make it
work like the function of "def" in Ruby language.

The simpliest usage looks like this:

    def hi {
      print "Hello World"
    }

C<def> auto inject a local variable C<$self> into the body of sub, so
here's what really happened:

   sub hi {
     my ($self) = @_;
     print "Hello World"
   }

At this point it doesn't work well under "main" package yet.

Furthermore, you may define methods with arguments listed:

    def hi($nick) {
      print "Hello, $nick";
    }

And this is what's really done:

    sub hi {
      my ($self, $nick) = @_;
      print "Hello, $nick";
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


