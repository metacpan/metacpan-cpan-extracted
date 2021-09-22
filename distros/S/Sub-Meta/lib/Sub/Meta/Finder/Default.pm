package Sub::Meta::Finder::Default;
use strict;
use warnings;

use Scalar::Util ();
use Types::Standard qw(Ref);

my $Callable = Ref['CODE'];

sub find_materials {
    my $sub = shift;

    return unless $Callable->check($sub);

    return {
        sub => $sub,
    }
}

1;
__END__

=encoding utf-8

=head1 NAME

Sub::Meta::Finder::Default - finder of default

=head1 SYNOPSIS

    use Sub::Meta::Creator;
    use Sub::Meta::Finder::Default

    my $creator = Sub::Meta::Creator->new(
        finders => [ \&Sub::Meta::Finder::Default::find_materials ],
    );

    sub hello {}

    my $meta = $creator->create(\&hello);
    # =>
    # Sub::Meta
    #   sub     \&hello,
    #   subname 'hello'

=head1 FUNCTIONS

=head2 find_materials

    sub find_materials() => Maybe[ Dict[sub => CodeRef] ]

=head1 LICENSE

Copyright (C) kfly8.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

kfly8 E<lt>kfly@cpan.orgE<gt>

=cut
