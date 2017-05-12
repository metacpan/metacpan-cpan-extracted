package Test::Approvals::Core::FileApprover;

use strict;
use warnings FATAL => 'all';

use version; our $VERSION = qv('v0.0.5');

use File::Compare;
use Test::Builder;
use Readonly;

require Exporter;
use base qw(Exporter);

our @EXPORT_OK = qw(verify verify_files);

Readonly my $TEST => Test::Builder->new();

sub verify {
    my ( $writer, $namer, $reporter ) = @_;

    my $ext = $writer->file_extension;

    my $approved = $namer->get_approved_file($ext);
    my $received = $namer->get_received_file($ext);

    $writer->write_to($received);

    my $e = verify_files( $received, $approved );
    my $ok = !defined $e;
    if ( !$ok ) {
        my $message = "\n$e:\nAPPROVED: $approved\nRECEIVED: $received\n";
        $TEST->note($message);
        $reporter->report( $received, $approved );
    }
    else {
        unlink $received;
    }

    return $ok;
}

sub verify_files {
    my ( $received_file, $approved_file ) = @_;

    if ( !-e $approved_file ) {
        return 'Approved file does not exist';
    }

    if ( ( -s $approved_file ) != ( -s $received_file ) ) {
        return 'File sizes do not match';
    }

    if ( compare( $approved_file, $received_file ) != 0 ) {
        return 'Files do not match';
    }

    return;
}

1;
__END__
=head1 NAME

Test::Approvals::Core::FileApprover - Verify two files are the same

=head1 VERSION

This documentation refers to Test::Approvals::Core::FileApprover version v0.0.5

=head1 SYNOPSIS

    use Test::Approvals::Core::FileApprover qw(verify);
    use Test::Approvals::Namers::DefaultNamer;
    use Test::Approvals::Writers::TextWriter;
    use Test::Approvals::Reporters;

    my $w = Test::Approvals::Writers::TextWriter->new( result => 'Hello' );
    my $r = Test::Approvals::Reporters::DiffReporter->new();
    my $n = Test::Approvals::Namers::DefaultNamer->new( name => 'Hello Test' );

    ok verify( $w, $n, $r ), $n->name;

=head1 DESCRIPTION

This module provides the low level routines that actually compare two files 
for equality, and take the appropriate actions when the files don't match (ie.
launch the reporter) and when the files do match (ie. clean up the received 
file).

=head1 SUBROUTINES/METHODS

=head2 verify

    ok verify( $writer, $namer, $rerporter ), $namer->name;

Low level method to verify that the result data matches the approved data 
(stored in a file).  Returns a value indicating whether the data matches and
invokes the reporter when needed.

=head2 verify_files

    my $failure = verify_files('r.txt', 'a.txt');
    if(defined $failure) {
        print "Verification failed because: $failure";
    }
    else {
        pring "Verification success!";
    }

Compare two files and return a message if they are not the same.  When they
are the same, return null.

=head1 DIAGNOSTICS

None at this time.

=head1 CONFIGURATION AND ENVIRONMENT

None.

=head1 DEPENDENCIES

=over

    Exporter
    File::Compare
    Readonly
    Test::Builder
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

