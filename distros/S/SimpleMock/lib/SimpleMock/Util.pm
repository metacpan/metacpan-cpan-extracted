package SimpleMock::Util;
use strict;
use warnings;
use Data::Dumper qw(Dumper);
use Exporter     qw(import);
use Digest::SHA  qw(sha256_hex);

our $VERSION = '0.03';

our @EXPORT_OK = qw(
    all_file_subs
    generate_args_sha
    namespace_from_file
    file_from_namespace
);

sub all_file_subs {
    my $file = shift;
    $INC{$file} or die "File $file not loaded";
    my $ns = namespace_from_file($file);
    
    my @subs = ();
    no strict 'refs'; ## no critic 'ProhibitNoStrict';
    SYM: foreach my $sym (keys %{$ns.'::'}) {
        if (my $code_ref = *{$ns."::$sym"}{CODE}) {
            # ignore constants
            next SYM if (defined(prototype($code_ref)));
            push @subs, $sym
        }
    }
    return @subs;
}

# create sha for arg lists sent
sub generate_args_sha {
    my $args = shift;
    @_ and die "generate_args_sha() does not take a second argument"; 

    # coderefs will be replaced with dummy markers safely, so disable warnings for this
    local $SIG{__WARN__} = sub {
        $_[0] =~ /^Encountered CODE ref/
            or warn $_[0];
    };
  
    local $Data::Dumper::Deepcopy=1;
    local $Data::Dumper::Indent=0;
    local $Data::Dumper::Purity=1;
    local $Data::Dumper::SortKeys=1;
    local $Data::Dumper::Terse=1;

    return defined $args ? sha256_hex(Dumper($args)) : '_default';
}

sub namespace_from_file {
    my $file = shift;
    $file =~ s/\.pm$//;
    $file =~ s/\//::/g;
    return $file;
}

sub file_from_namespace {
    my $ns = shift;
    $ns =~ s/::/\//g;
    return $ns . '.pm';
}

1;

=head1 NAME

SimpleMock::Util - Utility functions for SimpleMock

=head1 DESCRIPTION

This module provides utility functions for the SimpleMock framework.

=head1 FUNCTIONS

All of these functions are exportable on request.

=head2 all_file_subs

    my @subs = SimpleMock::Util::all_file_subs($file);

Returns a list of all subroutine names defined in the given file. The file must already be loaded and in %INC.

=head2 generate_args_sha

    my $sha = SimpleMock::Util::generate_args_sha($args);

Generates a SHA-256 hash of the provided arguments. If no arguments are provided, it returns '_default'.

This is used to create a unique identifier for the arguments passed to a mock function so that we
can retrieve mocks via a lookup hash.

=head2 namespace_from_file

    my $namespace = SimpleMock::Util::namespace_from_file($file);

Converts a file path to a namespace. For example, `Foo/Bar.pm` becomes `Foo::Bar`.

=head2 file_from_namespace

    my $file = SimpleMock::Util::file_from_namespace($namespace);

Converts a namespace back to a file path. For example, `Foo::Bar` becomes `Foo/Bar.pm`.

=cut

