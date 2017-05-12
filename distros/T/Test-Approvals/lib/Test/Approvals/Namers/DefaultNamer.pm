package Test::Approvals::Namers::DefaultNamer;

use strict;
use warnings FATAL => qw(all);

{
    use version; our $VERSION = qv('v0.0.5');

    use Moose;
    use File::Spec;
    use FindBin::Real qw(Bin Script);

    has 'directory', is => 'ro', isa => 'Str', default => Bin();
    has 'name', is => 'ro', isa => 'Str';

    sub get_filename {
        my ( $self, $extension, $type ) = @_;
        my $file = Script();
        my $test = $self->name();
        my $dir  = $self->directory;
        $extension =~ s{^[.]}{}mixs;
        $test =~ s{[.]$}{}mixs;

        my $full_filename = "$file.$test.$type.$extension";
        $full_filename =~ s/\s/_/gmisx;
        $full_filename = lc $full_filename;
        return File::Spec->catfile( $dir, $full_filename );
    }

    sub get_approved_file {
        my ( $self, $extension ) = @_;
        return get_filename( $self, $extension, 'approved' );

    }

    sub get_received_file {
        my ( $self, $extension ) = @_;
        return get_filename( $self, $extension, 'received' );
    }
}

1;
__END__
=head1 NAME

Test::Approvals::Namers::DefaultNamer - Default algorithm for generating names

=head1 VERSION

This documentation refers to Test::Approvals::Namers::DefaultNamer version v0.0.5

=head1 SYNOPSIS

    # C:/usr/example.pl

    use Test::Approvals::Namers::DefaultNamer;

    my $n = Test::Approvals::Namers::DefaultNamer->new(
        directory => 'c:\tmp',
        name      => 'foo'
    );

    my $x = $n->get_approved_file('txt'); # C:\tmp\example.pl.foo.approved.txt
    my $y = $n->get_received_file('txt'); # C:\tmp\example.pl.foo.received.txt

    # Cleans the input when necessary
    my $o = Test::Approvals::Namers::DefaultNamer->new(
        directory => 'c:/tmp/',
        name      => 'foo.'
    );

    # Still C:\tmp\example.pl.foo.received.txt
    my $z = $o->get_received_file('.txt'); 

    # Uses current script directory by default
    my $p = Test::Approvals::Namers::DefaultNamer->new( name => 'foo' );

    # Now C:\usr\example.pl.foo.approved.txt
    my $a = $p->get_approved_file('txt'); 

=head1 DESCRIPTION

The DefaultNamer class contains an algorithm for generating names for files
to store test results in.  It also provides easy access to the name of the 
test it is associated with.

=head1 SUBROUTINES/METHODS

=head2 get_approved_file

    my $n = Test::Approvals::Namers::DefaultNamer->new(
        directory => 'c:\tmp',
        name      => 'foo'
    );
    my $path = $n->get_approved_file('txt');

Generate the full path to the approved file.  In the example above $path will
be assigned: 'C:\tmp\<script>.foo.approved.txt', where <script> is the name of
the caller's script (similar to the output of FindBin::Real::Script)

=head2 get_received_file

    my $n = Test::Approvals::Namers::DefaultNamer->new(
        directory => 'c:\tmp',
        name      => 'foo'
    );
    my $path = $n->get_received_file('txt');

Generate the full path to the received file.  In the example above $path will
be assigned: 'C:\tmp\<script>.foo.received.txt', where <script> is the name of
the caller's script (similar to the output of FindBin::Real::Script)

=head2 get_filename

    my $n = Test::Approvals::Namers::DefaultNamer->new(
        directory => 'c:\tmp',
        name      => 'foo'
    );
    my $path = $n->get_filename('txt', 'bar');

Generate the full path to the requested file of the requested type.  In the 
example above $path will be assigned: 'C:\tmp\<script>.foo.bar.txt', where 
<script> is the name of the caller's script (similar to the output of 
FindBin::Real::Script)

=head1 DIAGNOSTICS

None at this time.

=head1 CONFIGURATION AND ENVIRONMENT

None.

=head1 DEPENDENCIES

=over

    File::Spec
    FindBin::Real
    Moose
    version

=back

=head1 INCOMPATIBILITIES

None known.

=head1 BUGS AND LIMITATIONS

None known.

=head1 AUTHOR

Jim Counts - @jamesrcounts

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2013 Jim Counts

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    L<http://www.apache.org/licenses/LICENSE-2.0>

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

