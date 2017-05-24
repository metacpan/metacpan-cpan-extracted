package MooX::LazierAttributes;

use strict;
use warnings;
use Scalar::Util qw/reftype blessed/;
use MooX::ReturnModifiers qw/return_modifiers/;

our $VERSION = '1.01';

use constant ro       => 'ro';
use constant is_ro    => ( is => ro );
use constant rw       => 'rw';
use constant is_rw    => ( is => rw );
use constant nan      => undef;
use constant lzy      => ( lazy => 1 );
use constant bld      => ( builder => 1 );
use constant lzy_bld  => ( lazy_build => 1 );
use constant trg      => ( trigger => 1 );
use constant clr      => ( clearer => 1 );
use constant req      => ( required => 1 );
use constant lzy_hash => ( lazy => 1, default => sub { {} });
use constant lzy_array => ( lazy => 1, default => sub { [] });

sub import {
    my ($package, @export) = @_;
    my $target    = caller;
    my %modifiers = return_modifiers($target);

    my $attributes = sub {
        my @attr = @_;
        while (@attr) {
            my @names = ref $attr[0] eq 'ARRAY' ? @{ shift @attr } : shift @attr;
            my @spec = @{ shift @attr };
            
            push @spec, delete $spec[2]->{default}; 
            for (@names) {
                unshift @spec, 'set' if $_ =~ m/^\+/ and ( !$spec[0] || $spec[0] ne 'set' );
                unshift @spec, ro unless ref \$spec[0] eq 'SCALAR' and $spec[0] =~ m/^ro|rw|set$/;
                $modifiers{has}->( $_, construct_attribute(@spec) );
            }
        }
    };

    { 
        no strict 'refs'; 
        ${"${target}::"}{$_} = ${"${package}::"}{$_}
          foreach (scalar @export ? @export : qw/ro is_ro rw is_rw nan lzy bld lzy_bld trg clr req lzy_hash lzy_array/);
        *{"${target}::attributes"} = $attributes; 
    }

    return 1;
}

sub construct_attribute {
    my @spec = @_;
    my %attr = ();
    $attr{is} = $spec[0] unless $spec[0] eq 'set';
   
    if ( ref $spec[1] eq 'Type::Tiny' ) { 
        $attr{isa} = $spec[1];
        $spec[1] = pop @spec;
    } 
    
    $attr{default} = ref $spec[1] eq 'CODE' ? $spec[1] : sub { _clone( $spec[1] ) }
        if defined $spec[1];

    $attr{$_} = $spec[2]->{$_} foreach keys %{ $spec[2] };
    return %attr;
}

sub _clone {
    my ($to_clone) = @_;
    my $blessed = blessed $to_clone;
    my $clone   = _deep_clone($to_clone);
    return $blessed ? bless $clone, $blessed : $clone;
}

sub _deep_clone {
    my ($to_clone) = @_;
    my $rt = reftype($to_clone) || reftype(\$to_clone);
    $rt eq 'SCALAR' and return $to_clone;
    $rt eq 'HASH'   and return { map +( $_ => _clone( $to_clone->{$_} ) ), keys %$to_clone };
    $rt eq 'ARRAY'  and return [ map _clone($_), @$to_clone ];
    return $to_clone;
}

1;

__END__

=head1 NAME

MooX::LazierAttributes - Lazier Attributes.

=head1 VERSION

Version 1.01

=cut

=head1 SYNOPSIS

    package Hello::World;
    
    use Moo;
    use MooX::LazierAttributes;

    attributes (
        one   => [], # defaults to be ro
        two   => [{}],
        three => [sub { My::Thing->new() }, { lzy, }],
        [qw/four five six/] => [rw, 'ruling the world'],
    );

    has seven => ( is_ro, lzy, default => sub { [qw/a b c/] });

    .....

    my $hello = Hello::World->new({ 
        one => 1,
        two => { three => 'four' },   
    });

    $hello->one;    # 1
    $hello->two;    # { three => 'four' }
    $hello->three;  # $obj

    ... Extending .....

    `package Extends::Hello::World;

    use Moo;
    use MooX::LazierAttributes;

    extends 'Hello::World';
    
    attributes (
        '+one' => ['hey'],
        '+two' => [[qw/why are you inside/]],
        [qw/+four +five +six/] => ['well the sun it hurts my eyes'],
    );

    my $hello = Extends::Hello::World->new();

    $hello->one;    # hey
    $hello->two;    # ['why', 'are', 'you', 'inside'],
    $hello->four;   # well the sun it hurts my eyes

    ... What if I like Types ...

    package Hello::World;
    
    use Moo;
    use MooX::LazierAttributes qw/is_ro rw lzy bld/;
    use Types::Standard qw/Str HashRef ArrayRef Object/;

    attributes (
        one   => [Str], # defaults to be ro
        two   => [HashRef],
        three => [Object, { lzy, bld }],
        [qw/four five six/] => [rw, Str, { default => 'ruling the world' }],
    );

    has seven => ( is_ro, lzy, isa => ArrayRef, default => sub { [qw/a b c/] });

    sub _build_three { 
        return My::Thing->new();
    }

    ... Moo -> Moose ...

    package Hello::World;
    
    use Moose;
    use MooX::LazierAttributes qw/is_ro rw lzy bld/;
    use Types::Standard qw/Str HashRef ArrayRef Object/;

    attributes (
        one   => [Str], # defaults to be ro
        two   => [HashRef],
        three => [Object, { lzy, bld }],
        [qw/four five six/] => [rw, Str, { default => 'ruling the world' }],
    );

    has seven => ( is_ro, lzy, isa => ArrayRef, default => sub { [qw/a b c/] });

    sub _build_three { 
        return My::Thing->new();
    }

=head1 EXPORT

=head2 attributes

I'm a list, my content gets transformed into Moo Attributes. My keys can either be a scalar or an array reference of scalars, 
they are used as the (*has*) name when constructing the Attributes.
    
    one => [],
    [qw/two three/] => []
    ...
    has one => ( is => 'ro' );
    has [qw/two three/] => ( is => 'ro' );

My value has to be an array reference, which can contain 3 indexes. If I was to write a read-write attribute that 
had a type constraint was lazy and also had a builder. It would look something like this.

    attributes (
        example => [ rw, ArrayRef, { lzy, bld } ],
    );
    
    ....
    
    has example => (
        is => 'rw',
        isa => ArrayRef,
        lazy => 1,
        builder => 1,
    );

The values first index - *is* - can only ever be ro/rw. A lot of the time you only actually want read-only so we can default that.
I'll show you Another example this time we have a read-only attribute, that has a type constraint and is required.

    attributes (
        example => [ Str, { req } ]
    )
    
    ....
    
    has example => (
        is => 'ro',
        isa => Str,  
        required => 1,
    );

As you can see we have dropped the first index (*is*). The last index the [1] above and [2] in my first 
example must always be a hash reference that conforms to Moo attribute Standards. This module exports 
constants that try to make filling this reference less repetitive. Sometimes you may not always need extra,
Moo Magic - a read-only attribute with just a type constraint.

    attributes (
        example => [ArrayRef],
    );

    ....
    
    has example => (
        is => 'ro',
        isa => ArrayRef
    );

And just a read-only attribute...
    
    attributes (
        example => [],
    );

=head2 Constants

When you *use* L<MooX::LazierAttributes> by default It will export the following constants.

You can restrict which constants get imported the same way you would with any other Exporter.

    use MooX::LazierAttributes qw/ro rw lzy bld/;

=head3 ro

'ro'

=head3 is_ro

( is => 'ro' )

=head3 rw

'rw'

=head3 is_rw

( is => 'rw' )

=head3 nan

undef

=head3 lzy;

( lazy => 1 )

=head3 bld

( builder => 1 )

=head3 lzy_bld 

( lazy_build => 1 ),

=head3 trg

( tigger => 1 ),

=head3 req

( required => 1 ),

=head3 lzy_hash

( lazy => 1, default => sub { {} } )

=head3 lzy_array

( lazy => 1, default => sub { [] } )

=head1 Acknowledgements

One would like to Acknowledge Haarg for taking the time to read my code and pointing me in the right direction.

=head1 More than one way

You may also be interested in - L<MooseX::Has::Sugar>. 

=head1 AUTHOR

Robert Acock, C<< <thisusedtobeanemail at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-moox-lazierattributes at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=MooX-LazierAttributes>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc MooX::LazierAttributes

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=MooX-LazierAttributes>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/MooX-LazierAttributes>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/MooX-LazierAttributes>

=item * Search CPAN

L<http://search.cpan.org/dist/MooX-LazierAttributes/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2017 Robert Acock.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1; # End of MooX::LazierAttributes
