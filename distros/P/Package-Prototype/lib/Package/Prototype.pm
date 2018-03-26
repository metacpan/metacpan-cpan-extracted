package Package::Prototype;
use strict;
use warnings;

our $VERSION = "0.01";

use XSLoader;
XSLoader::load(__PACKAGE__, $VERSION);

1;
__END__

=encoding utf-8

=head1 NAME

Package::Prototype - Super easily to create prototype object

=head1 SYNOPSIS

    use strict;
    use warnings;
    use Data::Dumper;
    use feature 'say';
    use Package::Prototype;

    my $obj = Package::Prototype->bless({
            foo => 10,
            bar => "Hello",
            baz => sub {
                my ($self, $arg) = @_;
                say "$arg, World";
            },
            # It do not create a method if key is started at '_'
            _data => "internal data"
        });

    say "\$obj classname: " . ref $obj;
    say Dumper $obj;
    say $obj->foo;        # 10
    say $obj->bar;        # "Hello"
    $obj->baz($obj->bar); # "Hello, World"

    my $obj2 = Package::Prototype->bless({
            hoge => [1..10],
            fuga => {abc => "def"}
        }, 'CLASS');

    say "\$obj2 classname: " . ref $obj2;

    # reference
    my $a = $obj2->hoge;
    my $h = $obj2->fuga;

    # wantarray
    my @a = $obj2->hoge;
    my %h = $obj2->fuga;

    $obj2->prototype(bow => sub { say "Bow!!" }, nyao => sub { say "Nyao!!" });
    $obj2->prototype(baw => 10, nyan => "nyan");
    $obj2->nyao(); # "Nyao!!"
    $obj2->bow();  # "Bow!!"
    say "bow: " . $obj2->baw . " nyan: " . $obj2->nyan;

=head1 DESCRIPTION

Package::Prototype can create prototype object like javascript.

This module can provide anonymous packages which are independent of the main namespace if not 
specified by classname. Also, available as an object instance.

=head1 METHODS

=over 2

=item C<< bless($ref :HashRef[, $classname :Str]) >>

Create a new anonymous package and an instance. The optional C<$clasname> argument sets the
stash's name. C<$classname> default is C<__ANON__>.

That instance also provide a method that will return values corresponding to keys that do not
start with '_'.

    my $obj = Package::Prototype->bless({
        foo => 10,
        bar => sub { say $_[1] },

        # It do not create a method if key is started at '_'
        _data => "internal data"
    });

    say $obj->foo; # 10
    say $obj->bar("Hello");

    # $obj->_data is not provided

=item C<< prototype($key :Str => $val :Any, ...) >>

This method can be used from the generated instance. By using this, it is possible to add new methods easily.

    $obj->prototype(add => sub {
        my $self = shift;
        return $_[0] + $_[1];
    });

    $obj->add(3, 5); # 8

=back

=head1 SEE ALSO

L<Package::Anon>

L<Plack::Util::Prototype>

=head1 LICENSE

Copyright (C) K.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

K E<lt>x00.x7f@gmail.comE<gt>

=cut

