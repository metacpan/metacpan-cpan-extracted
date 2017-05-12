package Test::A8N;
use warnings;
use strict;

# NB: Moose also enforces 'strict' and warnings;
use Moose;
use Test::FITesque::Suite;
use Test::FITesque::Test;
use Test::A8N::File;
use File::Find;
use Storable qw(dclone);

our $VERSION = '0.06';

sub BUILD {
    my $self = shift;
    my %defaults = (
        fixture_base       => "Fixture",
        file_root          => "cases",
        filenames          => [],
        verbose            => 0,
        allowed_extensions => [qw( tc st )],
        tags               => {
            include => [],
            exclude => [],
        },
    );
    foreach my $key (keys %defaults) {
        next if exists $self->config->{$key};
        $self->config->{$key} = $defaults{$key};
    }
}

has config => (
    is          => q{ro},
    required    => 1,
    isa         => q{HashRef}
);

my %default_lazy = (
    required => 1,
    lazy     => 1,
    is       => q{ro},
    default  => sub { die "need to override" },
);

has verbose => (
    %default_lazy,
    isa     => q{Int},
    default => sub { return shift->config->{verbose} },
);

has testcase_id => (
    %default_lazy,
    isa     => q{Str},
    default => sub { return shift->config->{testcase_id} || '' },
);

has filenames => (
    %default_lazy,
    isa     => q{ArrayRef},
    default => sub { return shift->config->{filenames} },
);

has file_root => (
    %default_lazy,
    isa     => q{Str},
    default => sub { return shift->config->{file_root} },
);

has fixture_base => (
    %default_lazy,
    isa     => q{Str},
    default => sub { return shift->config->{fixture_base} },
);

has allowed_extensions => (
    %default_lazy,
    isa     => q{ArrayRef},
    default => sub { return shift->config->{allowed_extensions} },
);

has file_paths => ( 
    is       => q{ro}, 
    required => 1, 
    lazy     => 1, 
    isa      => q{ArrayRef},
    default => sub { 
        my $self = shift;
        my @file_list = ();
        my $wanted = sub {
            my $filename = $File::Find::name;
            for my $extension (@{$self->allowed_extensions}) {
                if (-f and /^[^\.].*\.$extension$/) {
                    push @file_list, $filename;
                }
            }
        };
        my $root = $self->file_root;
        my @files = scalar(@{ $self->filenames() }) ? @{ $self->filenames() } : ($root);
        find($wanted, @files);
        return \@file_list;
    }
);

has files => ( 
    is => q{ro}, 
    required => 1, 
    lazy => 1, 
    default => sub { 
        my $self = shift;
        my @files = ();
        for my $filename ( @{ $self->file_paths } ) {
            push @files, Test::A8N::File->new({
                filename => $filename,
                config   => dclone( $self->config ),
            });
        }
        return \@files;
    }
);

sub run_tests {
    my $self = shift;
    my $id = $self->testcase_id;
    my $suite = Test::FITesque::Suite->new();

    my $test_count = 0;
    foreach my $file (@{ $self->files }) {
        my @cases = @{ $file->filtered_cases( $id ) };
        foreach my $case (@cases) {
            my @data = @{ $case->test_data };
            my $test = Test::FITesque::Test->new({
                data => [ 
                    [$file->fixture_class, { testcase => $case } ], 
                    @data 
                ]
            });
            $suite->add($test);
            $test_count++;
        }
    }
    $suite->run_tests() if $test_count > 0;
}

# unimport moose functions to make immutable
no Moose;
__PACKAGE__->meta->make_immutable();
1;

=pod

=head1 NAME

Test::A8N - Storytest Automation Runner

=head1 SYNOPSIS

    my $a8 = Test::A8N->new({
        filenames => [qw( cases/test1.tc )],
        file_root => 'cases',
    });
    $a8->run_tests();

=head1 DESCRIPTION

Test::A8N was created as a mechanism for writing and running automated
storytests in a human-readable and reusable fashion.  Its storytest files
are easily readable, are natural to write, and are easy for non-technical
users to read, while still being easy for developers to automate.

It works by leveraging L<Test::FITesque> to describe test fixtures in a
list style, while providing syntatic sugar for test authors.  The tests
themselves are written in YAML, and while they have a specific
structure, it doesn't limit test author's flexibility.  And many of the
features of YAML, most notably its concept of creating pointers between
different parts of a document, means reusing parts of your tests for use
elsewhere is trivial.

=head2 Testcase Syntax

An A8N testcase file can consist of mulitple YAML documents, separated by
three dashes C<--->.  But the structure for each testcase within a file
is the same.  It consists of a name, a summary, an optional ID, test
instructions, and optional preconditions and postconditions.

The instructions, preconditions, and postconditions contain a list of steps
that are to be run as part of the test.

    ---
    NAME:    Administrator changes their timezone
    ID:      admin_changes_tz
    SUMMARY: Administrators need to have a mechanism for changing their
             timezone.
    PRECONDITIONS:
        - ensure user exists: admin
        - ensure timezone is: America/Vancouver
    INSTRUCTIONS:
        - login:
            username: admin
            password: testpass
        - goto page: Account Settings
        - verify current timezone is: America/Vancouver
        - change timezone to: Australia/Brisbane
        - verify current timezone is: Australia/Brisbane
    POSTCONDITIONS:
        - ensure timezone is: America/Vancouver

Despite the actual order specified in a testcase block, each testcase will
run its tests in the order of 1) precondition, 2) instructions, 3)
postconditions.  If you don't specify an ID, then one will be
auto-generated for you based on the testcase name.

=head2 Goals of this Testcase Format

When a product manager or some other non-technical business user comes up
with a set of initial story tests for some feature, most people will
naturally think of writing a list.  Even describing how to access some
feature, people will fall back to describing a list of steps.  We therefore
set out to capture that as closely as possible in our tests.

As much as possible, we recommend making your fixture calls, and their
arguments, read as much as possible as english phrases, without having
unnecessary "no-op" filler that will get in the way.

=head2 Testcase Fixtures and Suggestions

From the sample testcase described at the beginning of this section, you
can see just how natural this method of writing tests is.  The tests don't
even need to be automated to be able to follow them, as they're readable
enough for a user to navigate a website or command-line to be able to
follow the specified steps.

However, once you do automate them, there are some subtleties that we've
found work quite well in authoring test cases.  Namely in there's a
difference between performing an action, and testing the result.  For
instance:

    - change timezone to: <some timezone>
    - verify timezone is: <some timezone>
    - ensure timezone is: <some timezone>

"change" can be used to set some value using the UI you're testing.
"verify" can be used to test that some value is set or is present.
"ensure" is a subtle one, but it can be used to change a value only if it
isn't already present.  It's useful to use in preconditions where you don't
care to exercise the UI every time you need to add a user, for instance.
If you need a user account simply for testing purposes, then your C<ensure
user exists> action can simply drop a user account into a database or onto
disk without using the UI.  This not only speeds up your tests, but makes
sure that you only test user creation within your user account tests, not
on every test that requires a user to be present.

=head1 METHODS

=head2 Accessors

=over 4

=item fixture_base

Specifies the base fixture classname to use when running testcases.  When
test files are found within sub-directories of L</file_root>, the directory
names are converted to class names, and appended to this L</fixture_base>
value.

=item file_root

Indicates where your testcase files live.  This is important because
any directory below this point is assumed to be part of the fixture class
name.

=item filenames

The list of test files you wish L<Test::A8N> to run.  If none are
specified, the test runner will try to find all files under the
L</file_root> that has an extension in the L</allowed_extensions> list.

=item verbose

Turns on increasing amounts of debugging output.  All debug messages are
prefixed with a "#" so that it doesn't interfere with TAP output.

Default: 0

=item allowed_extensions

Specifies what file extensions are valid testcases.  In this way you can
mix story tests and unit tests within the same directory.

Default: "st", "tc"

=item testcase_id

Specifies a testcase ID you wish to run.  If unset, it will run all
testcases in test files.

=back

=head2 Object Methods

=over 4

=item run_tests

Calls L<Test::A8N::File/run_tests>() in all the L<Test::A8N::File>
objects returned by L</files>.

=item file_paths

Returns a list of paths to all the testcase files that are to be processed.
If nothing is specified in L</filenames>, or it contains directories, then
L</file_paths> will search in those sub-directories to find any available
testcase files.

=item files

Returns the contents of L</file_paths> as instances of the
L<Test::A8N::File> class.

=back

=head1 SEE ALSO

L<Test::A8N::File>, L<Test::FITesque>

=head1 AUTHORS

Michael Nachbaur E<lt>mike@nachbaur.comE<gt>,
Scott McWhirter E<lt>konobi@cpan.orgE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.7 or,
at your option, any later version of Perl 5 you may have available.

=head1 COPYRIGHT

Copyright (C) 2008 Sophos, Plc.

=cut
