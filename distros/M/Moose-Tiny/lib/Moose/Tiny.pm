package Moose::Tiny;
use strict;
our $VERSION = '0.04';
use Moose();

use Moose::Exporter;

my ( $isub, $usub ) = Moose::Exporter->build_import_methods( also => 'Moose' );

{
    no strict 'refs';
    *{ __PACKAGE__ . '::unimport' } = $usub;
}


sub import {
    my $CALLER = caller();
    my $pkg    = shift;
    my $meta   = Moose::Meta::Class->initialize($CALLER);
    for my $name (@_) {
        die q[Invalid accessor name 'undef'] unless defined $name;
        die qq[Invalid accessor name '$name'] if ref $name;
        die qq[Invalid accessor name '$name'] unless $name =~ /^[^\W\d]\w*$/s;   
        $meta->add_attribute( $name => { is => 'ro' } );
    }
    @_ = ( $pkg, grep { /^-/ } @_ );
    goto $isub;
}

no Moose;    # unimport moose features
1;           # Magic true value required at end of module
__END__

=head1 NAME

Moose::Tiny - Why Should Object::Tiny get all the Fun


=head1 VERSION

This document describes Moose::Tiny version 0.0.3


=head1 SYNOPSIS

    # Define a class
    package Foo;

    use Moose::Tiny qw{ bar baz };

    1;


    # Use the class
    my $object = Foo->new( bar => 1 );

    print "bar is " . $object->bar . "\n";
  

=head1 DESCRIPTION

I was looking at Object::Tiny and thought, wow I bet I could do that really
easily with Moose. I was right.

=head1 INTERFACE 

None. Moose::Tiny currently exports what Moose itself exports. Simply call it
with a list of attribute names and it will create read only accessors for you.

    use Moose::Tiny qw(foo bar);
    
or a larger list

    use Moose::Tiny qw(
        item_font_face
        item_font_color
        item_font_size
        item_text_content
        item_display_time
        seperator_font_face
        seperator_font_color
        seperator_font_size
        seperator_text_content
    )

This will create a bunch of simple accessors, and set the inheritance to be
the child of Moose::Object, just like if you'd created them with Moose itself.
It will also make your class immutable for performance reasons (and because if
you're using this you probably don't care).

=head1 WHY?

Well I was looking at Object::Tiny's docs and realized that Moose wasn't even
in the argument. I felt bad. So I decided hey I could make this work.

Object::Tiny has a bunch of statistics to show why it is better than
Class::Accessor::Fast. Here are some statistics of our own.

=over

=item Moose::Tiny is 8% shorter to type than Object::Tiny

That's right, Moose is one less letter than Object, and since otherwise the
APIs are identical that's an 8% savings overall.

=item Moose::Tiny brings you the full power of Moose

If you buy now you get C<with>, C<around>, C<after>, C<before> and several
other goodies as well! Call now operators are standing by.

=back

Really that's all I got. Since you get all the Moose metaobject goodness our
memory footprint is probably a fair bit larger ... but hey 8% savings when
you're typing the code out!

=head1 CAVEATS

Moose works differently from Object::Tiny. Most importantly moose won't
auto-vivify attribute slots, so if you don't define it in the command line it
won't exist in the instance data structure, even if you pass a value to new();
Object::Tiny doesn't document this behavior but it is tested.

Also attribute slots in Moose are always created even if they're undefined.
This behavior *may* change in the future, it's undocumented in Moose, but
Object::Tiny expect that if you haven't populated an attribute, that attribute
doesn't exist in the instance data structure. This is also not really
documented, but is tested for.

Alias has reported some more caveats:

=head2 Installation 

    Moose::Tiny has a number of recursive dependencies (and a few more
    build_requires deps not shown) with non-perfect cpan testers results (72%
    aggregate success installing).

Moose::Tiny has all of the build requirements of Moose itself. Be prepared to
install everything listed in
http://cpandeps.cantrell.org.uk/?module=Moose%3A%3ATiny

=head2 Memory 

    Moose::Tiny uses 4.5 megabytes of memory. This is around 550 times larger
    than Object::Tiny, or a more impressive sounding 55,000% larger :)

=head2 Startup 

    Moose::Tiny takes around a second to load up on the virtual I'm currently
    working in. Granted that's also in the debugger, so it's WAY slower than
    it could be, but Object::Tiny does not take any noticable time to load,
    even in the same scenario.

This is also an overhead cost from Moose. Neither have been reccomended for
use in a critical situation where you are constantly restarting the perl
process (eg. CGI). If you find yourself in this situation either try to use a
persistant environment (pperl, mod_perl, fastcgi) or try Object::Tiny. On the
plus side, our API is 100% compatible so you can switch bak and forth easily.

=head2 Benchmarks

    Benchmarking constructor plus accessors...
              Rate moose  tiny
    moose  94607/s    --  -56%
    tiny  213675/s  126%    --

    Benchmarking constructor alone...
              Rate moose  tiny
    moose 136799/s    --  -68%
    tiny  421941/s  208%    --

    Benchmarking accessors alone...
           Rate moose  tiny
    moose 485/s    --  -19%
    tiny  599/s   23%    --

=head1 DEPENDENCIES

Moose obviously.

=head1 INCOMPATIBILITIES

Some people's sense of humor.

=head1 BUGS AND LIMITATIONS

Please report any bugs or feature requests to
C<bug-moose-tiny@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 AUTHOR

Chris Prather  C<< <perigrin@cpan.org> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2007 - 2009 Chris Prather C<< <chris@prather.org> >>. Some
rights reserved.

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
