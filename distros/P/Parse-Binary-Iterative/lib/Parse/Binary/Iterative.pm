package Parse::Binary::Iterative;
use 5.006;
use strict;
no strict 'refs';
use warnings;
use Carp;
our $VERSION = '1.00';
use base qw(Class::Data::Inheritable Class::Accessor);
use UNIVERSAL::require;

__PACKAGE__->mk_accessors("parent");
__PACKAGE__->mk_classdata($_) for ("FORMAT", "init_done");
__PACKAGE__->init_done(0);
__PACKAGE__->FORMAT([ Data => "a*" ]);

sub new {
    my ($class, $data) = @_;
    $class->_init();
    my $self = bless { }, $class;

    # Now call all the readers in turn
    my @format = @{$class->FORMAT};
    while (my ($key, $val) = splice(@format, 0, 2)) {
        my $method = "read_$key";
        $self->$method($data);
    }
    return $self;
}

sub _init {
    my $class = shift;
    return if $class->init_done(); 
    $class->init_done(1);
    my @format = @{$class->FORMAT};
    while (my ($key, $val) = splice(@format, 0, 2)) {
        $class->mk_ro_accessors($key);
        $class->mk_reader($key, $val);
    }
}

sub mk_reader {
    my ($class, $key, $pattern) = @_;
    
    *{"${class}::read_".$key} = sub {
        my ($self, $data) = @_;
        my @things;
        if (ref $pattern) { # XXX We need to do stuff with @$pattern
            if (@{$pattern} == 2 and ref $pattern->[1] eq "CODE") {
                my $p1 = $pattern->[0];
                @things = $pattern->[1]->(
                    unpack($p1, $class->_extract($p1, $data))
                );
            } else {
                my $key_class = $key;
                $key_class =~ s/_/::/g; $key_class->require;
                @things = $key_class->new($data); 
                $_->parent($self) for @things;
            }
        } else { 
            @things = unpack($pattern, $class->_extract($pattern, $data))
        }
        $self->{$key} = @things == 1 ? $things[0] : \@things;
    }
}

sub _extract {
    my ($self, $pattern, $data) = @_;
    if ($pattern =~ /\*/) { local $/; my $x = <$data>; return $x };

    my $len = length(pack($pattern, 0));
    if (ref $data eq "SCALAR") {
        return substr($$data, 0, $len, "");
    } elsif (ref $data eq "GLOB" or UNIVERSAL::isa($data, "IO::Handle")) {
        my $buf;
        croak "Run out of data!" if !read(*$data, $buf, $len) == $len;
        return $buf;
    } else {
        croak "Can't read from data handle, don't know what it is";
    }
}
1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Parse::Binary::Iterative - Parse binary structures

=head1 SYNOPSIS

A simple structure:

    package Simple;
    use base 'Parse::Binary::Iterative';
    __PACKAGE__->FORMAT([
        One => "A",
        Two => "V",
        Three => "d",
    ]);

A structure relying on another structure:

    package IconFile;
    use base 'Parse::Binary::Iterative';
    __PACKAGE__->FORMAT([
    Magic       => 'a2',
    Type        => 'v',
    Count       => 'v',
    Icon        => [], # This links to another structure
    Data        => 'a*',
    ]);

    package Icon;
    use base 'Parse::Binary::Iterative';
    __PACKAGE__->FORMAT([
    Width       => 'C',
    Height      => 'C',
    ColorCount  => 'C',
    Reserved    => 'C',
    Planes      => 'v',
    BitCount    => 'v',
    ImageSize   => 'V',
    ImageOffset => 'v',
    ]);

Reading data:

    open IN, "something.ico";
    my $iconfile = IconFile->new(\*IN);
    my $icons = $iconfile->Count;
    my $width = $iconfile->Icon->Width;

=head1 DESCRIPTION

This module is more or less a reproduction of L<Parse::Binary> with
slightly less functionality, more documentation and some tests, and
with the ability to read data sequentially from a filehandle instead
of having to slurp it all in at once.

=head2 USAGE

You use this module by subclassing it and creating classes which
represent the structures you're trying to unpack. As shown in the
examples above, you need to set the C<FORMAT> class data accessor
to an array reference; this should contain pairs of accessor names
and formats suitable for feeding to C<unpack>. 

If you want to do more complex stuff with your data format, use an array
reference instead of a Perl format. This allows you to do the following:
(This list will grow in future versons.)

=over 3

=item *

If the array is two elements and the second is a code reference, the
the first will be taken as an unpack format, and then the reader will
"transform" the result of the unpack by passing it to the code
reference.

=item *

If you want to "contract out" unpacking to a sub-structure, (see
C<Parse::Binary>) use an empty array reference instead of a format, and the
name of the accessor will be taken as a class name to use instead. 

=cut

When a substructure is used, the accessor returns the object processed
by the substructure unpacker as you would expect; this object also has
a C<parent> accessor, which refers back to the higher-level structure.
So, for instance:

    package IconFile;
    sub Data {
        my ($self) = @_;
        substr($self->parent->Data, $self->ImageOffset, $self->ImageSize);
    }

This allows you to "reach back" into the original structure and manipulate
its data.

Forthcoming versions will have the ability to unpack multiple substructures,
as L<Parse::Binary> currently does. But I don't think I need that right now.

=head1 SEE ALSO

L<Parse::Binary>

=head1 AUTHOR

Simon Cozens

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Simon Cozens

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.


=cut
