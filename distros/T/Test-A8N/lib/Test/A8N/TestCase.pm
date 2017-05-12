package Test::A8N::TestCase;
use warnings;
use strict;

# NB: Moose also enforces 'strict' and warnings;
use Moose;
use Storable qw(dclone);
use YAML::Syck;
use File::Spec::Functions;

sub BUILD {
    my $self = shift;
    my @configs = ();
    foreach my $file (@{ $self->configuration }) {
        $file = catfile($self->config->{file_root}, $file);
        if (!-f $file) {
            die sprintf(
                q{Can't load configuration file "%s" for testcase "%s" in file "%s"; no such file.}, 
                $file, $self->name, $self->filename
            );
        }
        push @configs, %{ LoadFile($file) };
    }
    push @configs, %{ dclone($self->config) };
    my %config = @configs;
    foreach my $key (keys %config) {
        $self->config->{$key} = $config{$key};
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

has data => (
    is       => q{ro},
    required => 1,
    isa      => q{HashRef}
);

has filename => (
    is       => q{ro},
    required => 1,
    isa      => q{Str}
);

has index => (
    is       => q{ro},
    required => 1,
    isa      => q{Int}
);

has id => (
    %default_lazy,
    isa     => q{Str},
    default => sub { 
        my $self = shift;
        if (exists $self->data->{ID}) {
            return $self->data->{ID};
        } else {
            my $id = $self->name;
            $id =~ s/ /_/g;
            return lc($id);
        }
    }
);

has name => (
    %default_lazy,
    isa     => q{Str},
    default => sub { 
        my $self = shift;
        return $self->data->{NAME};
    }
);

has summary => (
    %default_lazy,
    isa     => q{Str},
    default => sub { 
        my $self = shift;
        return $self->data->{SUMMARY};
    }
);

has tags => (
    %default_lazy,
    isa     => q{ArrayRef},
    default => sub { 
        my $self = shift;
        if (ref $self->data->{TAGS} eq 'ARRAY') {
            return [@{ $self->data->{TAGS} }];
        }
        return [];
    }
);

sub hasTags {
    my $self = shift;
    my $truth = 1;
    foreach my $tag (@_) {
        #warn "Inspecting tag $tag against " . join(", ", @{ $self->tags }) . "\n";
        $truth = 0 unless (grep {$_ eq $tag} @{ $self->tags });
    }
    #warn "Returning truth $truth\n";
    return $truth;
}

has configuration => (
    %default_lazy,
    isa     => q{ArrayRef},
    default => sub { 
        my $self = shift;
        if (ref $self->data->{CONFIGURATION} eq 'ARRAY') {
            return [@{ $self->data->{CONFIGURATION} }];
        }
        return [];
    }
);

has instructions => (
    %default_lazy,
    isa     => q{ArrayRef},
    default => sub { 
        my $self = shift;
        if (ref $self->data->{INSTRUCTIONS} eq 'ARRAY') {
            return [@{ $self->data->{INSTRUCTIONS} }];
        }
        return [];
    }
);

has expected => (
    %default_lazy,
    isa     => q{ArrayRef},
    default => sub { 
        my $self = shift;
        if (ref $self->data->{EXPECTED} eq 'ARRAY') {
            return [@{ $self->data->{EXPECTED} }];
        }
        return [];
    }
);

has preconditions => (
    %default_lazy,
    isa     => q{ArrayRef},
    default => sub { 
        my $self = shift;
        if (ref $self->data->{PRECONDITIONS} eq 'ARRAY') {
            return [@{ $self->data->{PRECONDITIONS} }];
        }
        return [];
    }
);

has postconditions => (
    %default_lazy,
    isa     => q{ArrayRef},
    default => sub { 
        my $self = shift;
        if (ref $self->data->{POSTCONDITIONS} eq 'ARRAY') {
            return [@{ $self->data->{POSTCONDITIONS} }];
        }
        return [];
    }
);

has is_valid => (
    %default_lazy,
    isa     => q{Bool},
    default => sub { 
        my $self = shift;
        my $length = @{ $self->test_data };
        return $length > 0;
    }
);

has test_data => (
    %default_lazy,
    isa     => q{ArrayRef},
    default => sub { 
        my $self = shift;
        return $self->parse_data([
            @{ $self->preconditions },
            @{ $self->instructions },
            @{ $self->postconditions },
        ]);
    }
);

sub parse_data {
    my $self = shift;
    my ($data) = @_;
    my @tests = ();
    foreach my $test (@$data) {
        # Handle single-string tests
        if (!ref($test)) {
            push @tests, [$test];
        }

        # Handle hash tests
        elsif (ref($test) eq 'HASH') {
            my ($name) = keys %$test;
            my ($value) = $test->{$name};
            push @tests, [$name, $value];
        }

        else {
          die "Unable to parse structure of type '".ref($test)."'";
        }
    }
    return \@tests;
}

# unimport moose functions and make immutable
no Moose;
__PACKAGE__->meta->make_immutable();
1;

=pod

=head1 NAME

Test::A8N::TestCase - Storytest testcase object

=head1 SYNOPSIS

    my $tc = Test::A8N::TestCase->new({
        data     => [ ... ],
        index    => ++$idx,
        filename => "cases/test1.tc",
    });

=head1 DESCRIPTION

This represents an individual testcase within a test file.  It encapsulates
the logic around parsing test instructions, sorting them and processing
their arguments in such a way that they are readable by
L<Test::FITesque::Test>.

=head1 METHODS

=head2 Data Accessors

=over 4

=item id

Returns the C<ID> property from the testcase data.  If none is supplied, it
generates an ID from the testcase L</name> property.

=item name

Returns the C<NAME> property from the testcase data.

=item summary

Returns the C<SUMMARY> property from the testcase data.

=item tags

Returns an array of the C<TAGS> list from the testcase data.  An example of
the expected syntax is:

    TAGS:
        - clustering
        - smoke

=item expected

Returns an array of the C<EXPECTED> list from the testcase data.

=item configuration

Returns an array of the C<CONFIGURATION> list from the testcase data.  This
can be used by fixtures to load additional configuration that may be needed
to run your test.

=item preconditions

Returns an array of the C<PRECONDITIONS> list, used by L</test_data> to
compose a list of fixture calls.

=item postconditions

Returns an array of the C<POSTCONDITIONS> list, used by L</test_data> to
compose a list of fixture calls.

=item instructions

Returns an array of the C<INSTRUCTIONS> list, used by L</test_data> to
compose a list of fixture calls.

=back

=head2 Object Methods

=over 4

=item data

Returns the raw datastructure of the YAML file.

=item test_data

Assembles the results from L</preconditions>, L</instructions>, and
L</postconditions> and, using L</parse_data>, returns a data structure that
L<Test::FITesque::Test> can process.

=item parse_data

Scrubs the arguments to test statements into a format that
L<Test::FITesque::Test> can process.

=back

=head1 SEE ALSO

L<Test::A8N::File>

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
