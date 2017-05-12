package String::Incremental::Types;
use 5.008005;
use strict;
use warnings;
use MouseX::Types -declare => [qw(
    Char
    CharOrderStr
    CharOrderArrayRef
)];
use MouseX::Types::Mouse qw( Str ArrayRef );

subtype Char, as Str, where {
    /^\S$/;
};

subtype CharOrderStr, as Str, where {
    my $val = shift;
    my %c;
    ( grep $c{$_}++, ( split //, $val ) ) ? 0 : 1;
};

subtype CharOrderArrayRef, as ArrayRef, where {
    my $val = shift;
    my %c;
    ( grep $c{$_}++, @$val ) ? 0 : 1;
};

1;
__END__

=encoding utf-8

=head1 NAME

String::Incremental::Types

=head1 SYNOPSIS

    use String::Incremental::Types qw( CharOrderStr CharOrderArrayref );

=head1 LICENSE

Copyright (C) issm.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

issm E<lt>issmxx@gmail.comE<gt>

=cut
