package Test::Approvals::Writers::TextWriter;

use strict;
use warnings FATAL => qw(all);

{
    use Moose;
    use Carp;
    use English qw(-no_match_vars);
    use version; our $VERSION = qv('v0.0.5');

    has result         => ( is => 'ro', isa => 'Maybe[Str]', default => q{} );
    has file_extension => ( is => 'ro', isa => 'Str',        default => 'txt' );

    sub write_to {
        my ( $self, $path ) = @_;
        open my $file, '>', $path
          or croak "Could not open $path for writing: $OS_ERROR";
        $self->print_to($file)
          or croak "Could not write to $path: $OS_ERROR";
        close $file or croak "Could not close $path after writing: $OS_ERROR";

        return $path;
    }

    sub print_to {
        my ( $self, $h ) = @_;
        my $result = $self->result // q{};
        return $h->print($result);
    }
}
__PACKAGE__->meta->make_immutable;

1;
__END__
=head1 NAME

Test::Approvals::Writers::TextWriter - Writes text to files

=head1 VERSION

This documentation refers to Test::Approvals version v0.0.5

=head1 SYNOPSIS

    use Test::Approvals::Writers::TextWriter;
    my $w = Test::Approvals::Writers::TextWriter->new( result => 'Hello' );
    
    # Write to a file
    $w->write_to('out.txt');

    # Print to a handle
    my $out_buf;
    open my $out, '>', \$out_buf;
    $w->print_to($out);
    close $out;

    # Let collaborators know what kind of result is stored in the writer
    my $x = Test::Approvals::Writers::TextWriter->new(
        result         => 'Hello',
        file_extension => 'html'
    );

    # $ext gets 'html'
    my $ext = $x->file_extension;

=head1 DESCRIPTION

The Test::Approvals::Writers::TextWriter method stores results until an approver
is ready to write them.

=head1 SUBROUTINES/METHODS

=head2 print_to

Write the result to an open handle.

    my $w = Test::Approvals::Writers::TextWriter->new( result => 'Hello' );
    my $out_buf;
    open my $out, '>', \$out_buf;
    $w->print_to($out);
    close $out;

=head2 write_to

Write the result to a file at the specified path.

    my $w = Test::Approvals::Writers::TextWriter->new( result => 'Hello' );
    $w->write_to('out.txt');

=head1 DIAGNOSTICS

None at this time.

=head1 CONFIGURATION AND ENVIRONMENT

None.

=head1 DEPENDENCIES

=over

Carp
English
Moose
version

=back

=head1 INCOMPATIBILITIES

None known.

=head1 BUGS AND LIMITATIONS

Windows-only.  Linux/OSX/other support will be added when time and access to 
those platforms permit.

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

