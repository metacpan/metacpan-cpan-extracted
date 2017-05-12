package Test::A8N::File;
use warnings;
use strict;

# NB: Moose also enforces 'strict' and warnings;
use Moose;
use YAML::Syck;
use Test::A8N::TestCase;
use Module::Load;
use Storable qw(dclone);

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

has filename => (
    is          => q{ro},
    required    => 1,
    isa         => q{Str}
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

has verbose => (
    %default_lazy,
    isa     => q{Int},
    default => sub { return shift->config->{verbose} },
);

has data => (
    %default_lazy,
    isa     => q{ArrayRef},
    default => sub { 
        my $self = shift;
        my $content = [];
        eval {
            $content = [ LoadFile($self->filename) ];
        };
        if ($@) {
            printf("# YAML syntax error while loading %s: %s\n", $self->filename, $@) if ($self->verbose);
        }
        return $content;
    }
);

has testcase_class => (
    %default_lazy,
    isa     => q{Str},
    default => "Test::A8N::TestCase"
);

has cases => (
    %default_lazy,
    isa     => q{ArrayRef},
    default => sub { 
        my $self = shift;
        my @cases;
        my $idx = 0;
        my $filename = $self->filename;
        foreach my $case (@{ $self->data }) {
            my $case = $self->testcase_class->new({
                'data'     => $case,
                'index'    => ++$idx,
                'filename' => $filename,
                'config'   => dclone( $self->config ),
            });
            push @cases, $case if ($case->is_valid);
        }
        return \@cases;
    }
);

sub filtered_cases {
    my $self = shift;
    my ($id) = @_;

    my @cases = @{ $self->cases };
    if (@{ $self->config->{'tags'}->{'include'} }) {
        @cases = grep { $_->hasTags(@{ $self->config->{'tags'}->{'include'} }) } @cases;
    }
    if (@{ $self->config->{'tags'}->{'exclude'} }) {
        my @filtered_cases = ();
        CASE: foreach my $case (@cases) {
            foreach my $tag (@{ $self->config->{'tags'}->{'exclude'} }) {
                next CASE if ($case->hasTags($tag));
            }
            push @filtered_cases, $case;
        }
        @cases = @filtered_cases;
    }
    if ($id) {
        @cases = grep { $_->id eq $id } @cases;
    }
    return \@cases;
}

has fixture_class => (
    %default_lazy,
    isa     => q{Str},
    default => sub { 
        my $self = shift;
        local @INC = @INC;
        unless (grep $self->fixture_base, @INC) {
            unshift @INC, $self->fixture_base;
        }
        my $filename = $self->filename;
        my $root = $self->file_root;
        $filename =~ s#^$root/?##;
        $filename =~ s/\s+//g;
        my @path = split('/', $filename);
        pop @path; # take off the filename
        unshift @path, split(/::/, $self->fixture_base);

        while ($#path > -1) {
            my $class = join('::', @path);
            print "# Attempting to load fixture class $class\n" if ($self->verbose > 2);
            eval { 
                load($class);
            };
            unless ($@) {
                return $class;
            }
            if ($@ !~ /^Can't locate /) {
                warn "Error while loading fixture $class: $@\n";
            }
            pop @path;
        }
        die 'Cannot find a fixture class for "' . $self->filename . '"';
    }
);

sub BUILD {
    my $self = shift;
    my ($params) = @_;

    if (!-f $self->filename){
        die 'Could not find a8n file "' . $self->filename . '"';
    }
}

# unimport moose functions and make immutable
no Moose;
__PACKAGE__->meta->make_immutable();
1;

=pod

=head1 NAME

Test::A8N::File - Storytest file object

=head1 SYNOPSIS

    my $file = Test::A8N::File->new({
        filename     => "cases/test1.tc",
        file_root    => $a8n->file_root,
        fixture_base => $a8n->fixture_base,
    });
    $file->run_tests();

=head1 DESCRIPTION

This class is used to represent and run tests within individual storytest
files.  For more information, please see L<Test::A8N>.

=head1 METHODS

=head2 Accessors

=over 4

=item filename

The filename that this object is supposed to represent.

=item fixture_base

See L<Test::A8N/fixture_base>.

=item file_root

See L<Test::A8N/file_root>.

=item verbose

See L<Test::A8N/verbose>.

=item testcase_class

Used to set the class used to store testcases.

Default: L<Test::A8N::TestCase>

=back

=head2 Object Methods

=over 4

=item run_tests

This iterates over each of the L</cases> and will create a
L<Test::FITesque::Test> test runner for test case.  If you call this method
with a testcase ID, it will only run that one testcase.

=item data

Returns the raw datastructure of the YAML file.

=item cases

Returns objects representing each testcase within this test file.  Unless
L</testcase_class> is overridden, this property returns instances of the
L<Test::A8N::TestCase> class.

=item fixture_class

This locates the fixture class used to run testcases.  The resulting class
is called whenever a test action needs to be run.

If the L</filename> of this test is one or more sub-directories below the
L</file_root>, then it will append the directory name to the
L</fixture_base>, and will use it as part of the class name.  It works its
way up the directory hierarchy until it finds a valid Perl class.  If no
such classes can be found, it will use the value of L</fixture_base>.

=back

=head1 SEE ALSO

L<Test::A8N::TestCase>, L<Test::FITesque::Test>

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
