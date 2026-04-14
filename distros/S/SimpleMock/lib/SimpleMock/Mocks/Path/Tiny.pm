package SimpleMock::Mocks::Path::Tiny;
use strict;
use warnings;
use Carp qw(confess);
use Storable qw(dclone);

our $VERSION = '0.03';

require Path::Tiny;

no warnings 'redefine';

# copied over for convenieince
use constant {
    PATH     => 0,
    CANON    => 1,
    VOL      => 2,
    DIR      => 3,
    FILE     => 4,
    TEMP     => 5,
    IS_WIN32 => ( $^O eq 'MSWin32' ),
};
my %formats = (
    'ls'  => [ 1024, log(1024), [ "", map { " $_" } qw/K M G T/ ] ],
    'iec' => [ 1024, log(1024), [ "", map { " $_" } qw/KiB MiB GiB TiB/ ] ],
    'si'  => [ 1000, log(1000), [ "", map { " $_" } qw/kB MB GB TB/ ] ],
);


sub _get_path_mock {
    my $path = shift;
    for my $layer (reverse @SimpleMock::MOCK_STACK) {
        return $layer->{PATH_TINY}{$path} if exists $layer->{PATH_TINY}{$path};
    }
    return undef;
}

my $orig_path = \&Path::Tiny::path;

*Path::Tiny::path = sub {
    my @arg = @_;
    confess "No mock defined for path $_[0]" unless _get_path_mock($_[0]);
    return $orig_path->(@arg);
};

*Path::Tiny::slurp = sub {
    return _get_path_mock($_[0])->{data};
};

# synonyms for now. TBD if they need more customization
*Path::Tiny::slurp_raw  = sub { &Path::Tiny::slurp; };
*Path::Tiny::slurp_utf8 = sub { &Path::Tiny::slurp; };

*Path::Tiny::spew = sub { shift };
*Path::Tiny::chmod = sub { 1 }; # no op chmod

*Path::Tiny::cwd = sub {
    $ENV{PATH_TINY_CWD} or die "You must set the env var PATH_TINY_CWD to mock the cwd call";
    return Path::Tiny::_path($ENV{PATH_TINY_CWD});
};

*Path::Tiny::append = sub { 1 };
*Path::Tiny::append_raw = sub { 1 };
*Path::Tiny::append_utf8 = sub { 1 };

# assert defaults to true but can be overridden in mocks if needed
*Path::Tiny::assert = sub {
    my $self = shift;
    my $assert = _get_path_mock($self->[0])->{assert};
    if (defined $assert) {
        $assert or Path::Tiny::Error->throw( "assert", $self->[0], "failed assertion" );
    }
    return $self;
};

*Path::Tiny::children = sub {
    my $self = shift;
    my $path = $self->[0];
    # must be defined as a file
    $self->is_dir
        or $self->_throw('opendir');

    my %all_paths;
    $all_paths{$_} = 1 for map { keys %{ $_->{PATH_TINY} || {} } } @SimpleMock::MOCK_STACK;
    my @mock_paths = keys %all_paths;

    my @children = grep { m|$path/[^/]*$| } @mock_paths;
    return sort map { Path::Tiny::path($_) } @children;
};

# copy the mock and all attributes to a new mock and return the path object of the new mock.
# there's a small hack here to keep the syntax light - if a path ends in /(?:^|\/)\w+/
# assume it's a directory
*Path::Tiny::copy = sub {
    my ($self, $dest_path) = @_;
    my $source_path = $self->[0];

    # if target doesn't exist, assume it's a file
    # if it does, see if the target is a directory
    my $dest_mock   = _get_path_mock($dest_path);
    my $target_path = defined $dest_mock
                      ? $dest_mock->{data}
                        ? Path::Tiny::_path($dest_path)->[0]
                        : Path::Tiny::_path($dest_path, $self->basename)->[0]
                      : Path::Tiny::_path($dest_path)->[0];

    # now we have the copy, register it as a mock
    SimpleMock::_register_into_current_scope(
        PATH_TINY => {
            $target_path => _get_path_mock($source_path),
        },
    );
    my $copied = Path::Tiny::_path($target_path);
};

*Path::Tiny::digest = sub {
    my $self = shift;
    my $path = $self->[0];
    my $digest = _get_path_mock($path)->{digest}
        or die "'digest' attribute must be defined for '$path' mock";
    return $digest;
};

# I think we can no-op these for now
*Path::Tiny::edit            = sub {};
*Path::Tiny::edit_utf8       = sub {};
*Path::Tiny::edit_raw        = sub {};
*Path::Tiny::edit_lines      = sub {};
*Path::Tiny::edit_lines_utf8 = sub {};
*Path::Tiny::edit_lines_raw  = sub {};

*Path::Tiny::exists = sub {
    my $self = shift;
    my $exists = _get_path_mock($self->[0])->{exists};
    return defined $exists
           ? $exists
           : 1;
};

*Path::Tiny::is_file = sub {
    my $path = $_[0]->[0];
    return _get_path_mock($path)->{data}
           ? 1 : 0;
};

*Path::Tiny::is_dir = sub {
    my $path = $_[0]->[0];
    return _get_path_mock($path)->{data}
           ? 0 : 1;
};

# If there's a need, I guess I can spend time later on mocking filehandles
*Path::Tiny::filehandle = sub { die "Not implemented"; };

# target file does not need to be mocked. This is just an attribute of the mock object
*Path::Tiny::has_same_bytes = sub {
    my $path = $_[0]->[0];
    return _get_path_mock($path)->{has_same_bytes};
};

# not a full path iterator - only iterates through current directory
# (which I think should be fine for most unit tests)
*Path::Tiny::iterator = sub {
    my ($self, $args) = @_;
    $args->{recurse} and die "'recurse' is not supported on iterator()";
    my @children = shift->children;
    return sub {
        shift @children;
    }
};
*Path::Tiny::lines = sub {
    my $self    = shift;
    my $args    = Path::Tiny::_get_args( shift, qw/binmode chomp count/ );
    my $path = $self->[0];
    my @lines = map { "$_\n" } split /\n/, _get_path_mock($path)->{data};
    chomp(@lines) if $args->{chomp};
    my $count = $args->{count};
    my @ret = $count
           ? splice(@lines, 0, $count)
           : @lines;
    return @ret;
};
*Path::Tiny::lines_raw = sub { &Path::Tiny::lines; };
*Path::Tiny::lines_utf8 = sub { &Path::Tiny::lines; };

# just succeed for now - can tweak later if use case exists
*Path::Tiny::mkdir = sub { shift };
*Path::Tiny::mkpath = sub { die "Deprecated functionality - not implemented" };

# just succeed for now - can tweak later if use case exists
*Path::Tiny::move = sub {
    my ( $self, $dest ) = @_;
    return -d $dest ? Path::Tiny::_path( $dest, $self->basename ) : Path::Tiny::_path($dest);
};
*Path::Tiny::realpath = sub { die "Not implemented"; };

# just succeed for now
*Path::Tiny::remove = sub { 1 };
*Path::Tiny::remove_tree = sub { 1 };
*Path::Tiny::size= sub {
    my $path = $_[0]->[0];
    return length(_get_path_mock($path)->{data});
};

# note: not tested _human_size    , but I think 't's OK
*Path::Tiny::size_human = sub {
    my $self     = shift;
    my $args     = Path::Tiny::_get_args( shift, qw/format/ );
    my $format   = defined $args->{format} ? $args->{format} : "ls";
    my $fmt_opts = $formats{$format}
      or Carp::croak("Invalid format '$format' for size_human()");
    my $size = $self->size;
    return defined $size ? Path::Tiny::_human_size( $size, @$fmt_opts ) : "";
};

# _formats only used in tests - ignore

# hard code in data if needed
*Path::Tiny::stat = sub {
    my $path = $_[0]->[0];
    my $stat = _get_path_mock($path)->{stat};
    defined $stat or die "stat must be defined in mock for $path";
    ref $stat eq 'ARRAY' or die "stat muct be defined as an arrayref for $path";
    return $stat;
};
*Path::Tiny::lstat = sub { &Path::Tiny::stat };

# always true for now
*Path::Tiny::touch = sub { shift };
*Path::Tiny::touchpath = sub { shift };

# visit should be fine, but not recursive not supported right now

1;

=head1 NAME

SimpleMock::Mocks::Path::Tiny - mocks for testing Path::Tiny code

=head1 DESCRIPTION

This module overrides methods in Path::Tiny to allow you to unit test code with Path::Tiny in it.

It currently doesn't mock everything, but covers a lot of use cases.

I don't have any production code using this module, so I've written what I think are core mocks.
If you have a specific use case that could do with mocking, or spot issues that affect usage,
please implement via a pull request (or just request it and I'll implement when I have time)

=head1 USAGE

    use SimpleMock qw(register_mocks);

    register_mocks(
        PATH_TINY => {
            '/path/to/dir/pr/file' => {

                # if data is set, it's implicitly a file, otherwise it's a directory
                data => $file_content,

                # these are all true by default, but you can set to false for them to throw
                # or return false as noted
                assert => 0,              # throws
                exists => 0,              # return 0
                has_same_bytes => 0,      # return 0 - value is hard coded for ALL comparisons on a mock

                # returns this hard coded value for the stat - set as appropriate (obviously fake below)
                stat => [1,2,3,4],

                # digest hash for the mock. Set as appropriate if calling digest()
                digest => '1a2b3c4d536f',
            },
        }
    );

For basic usage, you just need this:

    register_mocks(
        PATH_TINY => {

            # file MUST have a data attribute
            '/path/to/file.txt' => { data => 'file content' },

            # directory must NOT have a data attribute
            '/path/to/dir' => {},
        }
    );


=head1 MOCK ATTRIBUTES

These are all valid keys for mock attributes:

=head2 data

The data to return if the file was read via slurp or lines (and their raw and utf8 variants).
Setting this attribute implicitly defines the mock as a file, omitting it implies a directory.

It is up to you to ensure utf8/raw values are set as expected.

=head2 assert

All calls on the mock to assert() return true by default. If you set this to 0, all calls to
assert throw instead. Hard coded on a per mock basis.

=head2 exists

All calls on the mock to exists() return true by default. If you set this to 0, it returns a false value.

=head2 has_same_bytes

All calls on the mock to has_same_bytes() return true by default. If you set this to 0, it returns a false value.

=head2 stat

Arrayref to return when calling stat. Example above is obviously fake, so amend to suit your tests needs as appropriate.

This is also used for the return value of lstat.

=head2 digest

Hard coded digest value to return for all calls to digest() on the mock.

=head2 size()

This is set to the length of the data attribute.

=head1 A few notes

=head2 copy()

If you are using copy, there's small differences in behavior between copy to file and copy to a directory

    my $p = path('/path/to/file.txt');

    # copy to an explicit file - no mock is needed for the target
    $p->copy('/path/to/file.txt')

    # copy to a directory you must set the target dir as a mock
    $p->copy('/path/to/dir');

ie, in your `register` mocks call, you must have:

    '/path/to/dir' => {},

so that the code knows that the path '/path/to/dir' is not a file.

Note: if you explicitly set a mock for the target file, this will get overridden when making the copy.

=head2 children()

All children MUST be defined as mocks. Grep is used to retrieve immediate children in the mocks code.

=head2 Not Windows friendly (`/` path seperator expected).

Sorry. First stab at this, and I don't have a Windows system I can tweak and test this on.
If someone wants to add in functionality for it to work in Windows, please do.

=head2 No recursion mocking

`iterator` does NOT recurse child directories. If the flag is set, an exception is thrown.

`visit` uses `iterator`, so an exception is thrown if you set the `recurse` argument.

If recursion is really needed, it can be added, but so far it's not implemented.

=cut
