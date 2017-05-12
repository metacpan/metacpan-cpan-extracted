package MooseX::Types::IO;

use warnings;
use strict;

our $VERSION   = '0.04';
our $AUTHORITY = 'cpan:FAYLAND';

use IO qw/File Handle/;
use IO::String;

use MooseX::Types::Moose qw/Str ScalarRef FileHandle ArrayRef Object/;
use namespace::clean;
use MooseX::Types -declare => [qw( IO )];

subtype IO, as Object;

coerce IO,
    from Str,
        via {
            my $fh = new IO::File; $fh->open($_); return $fh;
        },
    from ScalarRef,
        via {
            IO::String->new($$_);
        },
    from ArrayRef[FileHandle|Str],
        via {
            IO::Handle->new_from_fd( @$_ );
        };

require MooseX::Types::IO_Global;

1;
__END__

=head1 NAME

MooseX::Types::IO - L<IO> related constraints and coercions for Moose

=head1 SYNOPSIS

    package Foo;

    use Moose;
    use MooseX::Types::IO 'IO';

    has io => (
        isa => IO,
        is  => "rw",
        coerce => 1,
    );

    # later
    my $str = "test for IO::String\n line 2";
    my $foo = Foo->new( io => \$str );
    my $io  = $foo->io; # IO::String
    # or
    my $filename = "file.txt";
    my $foo = Foo->new( io => $filename );
    my $io  = $foo->io; # IO::File
    # or
    my $foo = Foo->new( io => [ $fh, '<' ] );
    my $io  = $foo->io; # IO::Handle

=head1 DESCRIPTION

This module packages one L<Moose::Util::TypeConstraints> with coercions,
designed to work with the L<IO> suite of objects.

=head1 CONSTRAINTS

=over 4

=item B<Str>

    my $fh = new IO::File;
    $fh->open($_);

L<IO::File> object.

=item B<ScalarRef>

    IO::String->new($$_);

L<IO::String> object.

=item B<ArrayRef[FileHandle|Str]>

    IO::Handle->new_from_fd( @$_ );

L<IO::Handle> object.

=back

=head1 SEE ALSO

L<Moose>, L<MooseX::Types>, L<MooseX::Types::IO::All>, L<IO::Hanlde>, L<IO::File>, L<IO::String>

=head1 AUTHOR

Fayland Lam, C<< <fayland at gmail.com> >>

=head1 ACKNOWLEDGEMENTS

The L<Moose> Team

Rafael Kitover (rkitover) for the patches on RT 46194

=head1 COPYRIGHT & LICENSE

Copyright 2008 Fayland Lam, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
