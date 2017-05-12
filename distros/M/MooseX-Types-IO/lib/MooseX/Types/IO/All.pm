package MooseX::Types::IO::All;

use warnings;
use strict;

our $VERSION   = '0.04';
our $AUTHORITY = 'cpan:FAYLAND';

use IO::All;

use MooseX::Types::Moose qw/Str ScalarRef FileHandle ArrayRef/;
use namespace::clean;
use MooseX::Types -declare => [qw( IO_All )];
use Fcntl 'SEEK_SET';

my $global = class_type 'IO::All';
subtype IO_All, as 'IO::All';

coerce IO_All,
    from Str,
        via {
            io $_;
        },
    from ScalarRef,
        via {
            my $s = io('$');
            $s->print($$_);
            $s->seek(0, SEEK_SET);
            return $s;
        };

$global->coercion(IO_All->coercion);

1;
__END__

=head1 NAME

MooseX::Types::IO::All - L<IO::All> related constraints and coercions for Moose

=head1 SYNOPSIS

    package Foo;

    use Moose;
    use MooseX::Types::IO::All 'IO_All';

    has io => (
        isa => IO_All,
        is  => "rw",
        coerce => 1,
    );

    # later
    my $str = "test for IO::String\n line 2";
    my $foo = Foo->new( io => \$str );
    my $io  = $foo->io; # IO::All::String
    # or
    my $filename = "file.txt";
    my $foo = Foo->new( io => $filename );
    my $io  = $foo->io; # IO::All

=head1 DESCRIPTION

This module packages one L<Moose::Util::TypeConstraints> with coercions,
designed to work with the L<IO::All> suite of objects.

=head1 CONSTRAINTS

=over 4

=item B<Str>

    io $_;

L<IO::All> object.

=item B<ScalarRef>

    my $s = io('$');
    $s->print($$_);

L<IO::All::String> object. so generally u need

    ${ $s->string_ref } # the content

instead of ->all or ->slurp

=back

=head1 SEE ALSO

L<Moose>, L<MooseX::Types>, L<MooseX::Types::IO>, L<IO::All>

=head1 AUTHOR

Fayland Lam, C<< <fayland at gmail.com> >>

=head1 ACKNOWLEDGEMENTS

The L<Moose> Team

=head1 COPYRIGHT & LICENSE

Copyright 2008 Fayland Lam, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
