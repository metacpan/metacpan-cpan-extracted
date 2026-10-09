package Perl::Critic::Distribution 0.001;

# ABSTRACT: Parse a distribution once, for every policy that needs all of it.

use 5.014;

use strict;
use warnings FATAL => 'all';

use re '/aa';

use Readonly;

use Cwd                    ();
use Cpanel::JSON::XS       ();
use File::Basename         ();
use File::Find             ();
use File::Path             ();
use File::Slurper          ();
use File::Slurper::Temp    ();
use File::Spec             ();
use Digest::SHA            ();
use List::Util             ();
use IO::Compress::Gzip     ();
use IO::Uncompress::Gunzip ();
use PPI                    ();
use Time::HiRes            ();

use Perl::Critic::Utils qw{ all_perl_files };


# One object per distribution root and cache directory, for the life of the
# process.  our, so that a test can empty it and read the cache on disk as a
# new process does.
our %FOR;

# The collectors registered in this process, by name.  our for the same
# reason.
our %COLLECTORS;

Readonly::Array my @AREAS => qw{ bin lib t xt };

Readonly::Array my @DIST_MARKERS => qw{ dist.ini Makefile.PL Build.PL META.json META.yml cpanfile .git };

# Change it when what the cache holds changes shape.
Readonly::Scalar my $CACHE_FORMAT => 1;

Readonly::Scalar my $CACHE_NAME => 'perl-critic-distribution';

# What the files in the cache directory are named.
Readonly::Scalar my $CACHE_FILE_RX => qr/\A [[:xdigit:]]{40} [.]json[.]gz \z/xs;

my $cache_path = sub {
    my ($self) = @_;

    return if !defined $self->{cache_dir};
    return File::Spec->catfile( $self->{cache_dir}, Digest::SHA::sha1_hex( $self->{root} ) . '.json.gz' );
};

# The format of the cache and the stamp of this file.  A cache made by another
# version of this module, or by this one before an edit, has a different key.
my $cache_key = sub {
    return join q{/}, $CACHE_FORMAT, __PACKAGE__->stamp(__FILE__) // q{};
};

# Replaces the file whole, so a reader never sees half of it.  A cache that
# cannot be written costs the next run a parse, and nothing else.
my $write_cache = sub {
    my ($self) = @_;

    my $path = $self->$cache_path() or return;
    my $json = Cpanel::JSON::XS->new->canonical->encode( { key => $cache_key->(), root => $self->{root}, files => $self->{files}, stash => $self->{stash} } );

    # The root goes in the gzip header too, so that the pruning below can read
    # it without decompressing the file.
    IO::Compress::Gzip::gzip( \$json => \my $gz, Comment => $self->{root} ) or return;

    File::Path::make_path( $self->{cache_dir}, { error => \my $errors } );
    return if @$errors;

    eval { File::Slurper::Temp::write_binary( $path, $gz ); 1 } or return;

    # Removes the cache of each root that is gone, such as a deleted checkout.
    # A file whose header cannot be read is removed too, since nothing can read
    # it either.
    my $dir = $self->{cache_dir};
    File::Find::find(
        {
            no_chdir => 1,
            wanted   => sub {
                $File::Find::prune = 1 if -d $File::Find::name && $File::Find::name ne $dir;
                return                 if File::Basename::basename($File::Find::name) !~ m/$CACHE_FILE_RX/xs;

                my $z      = IO::Uncompress::Gunzip->new($File::Find::name);
                my $header = $z && $z->getHeaderInfo();
                $z->close() if $z;
                my $root = ref $header eq 'HASH' ? $header->{Comment} : undef;
                unlink $File::Find::name if !defined $root || !-d $root;
            },
        },
        $dir
    );
    return 1;
};

# Brings what each registered collector returned up to date, for each file of
# the distribution: from this object, then from the cache on disk, and by
# parsing what neither has.  Each file is parsed at most once, whatever number
# of collectors need it.
my $refresh = sub {
    my ($self) = @_;

    # Every registered collector, at its version, already has data for every
    # file, in this process.
    return if $self->{files} && !List::Util::any { ( $self->{current}{$_} // q{} ) ne $COLLECTORS{$_}{version} } keys %COLLECTORS;

    my $cache = $self->{files} ? { files => $self->{files}, stash => $self->{stash} } : {};
    if ( !$self->{files} && ( my $path = $self->$cache_path() ) ) {

        # A cache that is not there fails to read, like one that is unreadable.
        my $read = eval {
            my $gz = File::Slurper::read_binary($path);
            IO::Uncompress::Gunzip::gunzip( \$gz => \my $json ) or return;
            Cpanel::JSON::XS->new->decode($json);
        };
        $cache = $read if ref $read eq 'HASH' && ( $read->{key} // q{} ) eq $cache_key->() && ref $read->{files} eq 'HASH';
    }

    my $cached = $cache->{files} // {};
    my %now;
    my $changed = 0;

    foreach my $area (@AREAS) {
        my $path = File::Spec->catdir( $self->{root}, $area );
        next if !-d $path;

        foreach my $file ( sort( all_perl_files($path) ) ) {
            my $stamp = $self->stamp($file) // next;

            my $entry = $cached->{$file};
            if ( ref $entry ne 'HASH' || ( $entry->{stamp} // q{} ) ne $stamp || ref $entry->{collected} ne 'HASH' ) {
                $entry   = { stamp => $stamp, area => $area, collected => {} };
                $changed = 1;
            }

            # The collectors that have nothing for this file, at their version.
            my @needed = grep {
                my $held = $entry->{collected}{$_};
                !( ref $held eq 'HASH' && exists $held->{data} && ( $held->{version} // q{} ) eq $COLLECTORS{$_}{version} )
            } sort keys %COLLECTORS;

            if (@needed) {

                # Not kept, so a file that PPI cannot read is tried again by
                # the next process, as it would be with no cache.
                my $ppi = PPI::Document->new($file) or next;
                foreach my $name (@needed) {
                    my $collector = $COLLECTORS{$name};
                    $entry->{collected}{$name} = { version => $collector->{version}, data => $collector->{collect}->( $ppi, $file, $area ) };
                }
                $changed = 1;
            }
            $now{$file} = $entry;
        }
    }

    # A file in the cache that is gone is a change too.
    $changed ||= List::Util::any { !$now{$_} } keys %$cached;

    $self->{files}   = \%now;
    $self->{stash}   = ref $cache->{stash} eq 'HASH' ? $cache->{stash} : {};
    $self->{current} = { map { $_ => $COLLECTORS{$_}{version} } keys %COLLECTORS };

    $self->$write_cache() if $changed;
    return;
};


sub register {
    my ( $class, %opts ) = @_;

    my $name = $opts{name};
    die "A collector needs a name\n"                            if ( $name // q{} ) eq q{};
    die "The collector $name needs collect, a code reference\n" if ref $opts{collect} ne 'CODE';

    $COLLECTORS{$name} = { version => $opts{version} // q{}, collect => $opts{collect} };
    return $name;
}


sub stamp {
    my ( $class, $file ) = @_;

    my @st = Time::HiRes::stat($file) or return;
    return join q{:}, @st[ 0, 1, 7 ], map { sprintf '%.9f', $_ } @st[ 9, 10 ];
}


sub root_of {
    my ( $class, $file ) = @_;

    return if !defined $file;
    my $path = Cwd::abs_path($file) // return;

    my ( $volume, $directories ) = File::Spec->splitpath($path);
    my @dirs = File::Spec->splitdir($directories);
    pop @dirs while @dirs && $dirs[-1] eq q{};

    my %area = map { $_ => 1 } @AREAS;
    my @fallback;
    foreach my $depth ( reverse 0 .. $#dirs ) {
        my $ancestor = File::Spec->catpath( $volume, File::Spec->catdir( @dirs[ 0 .. $depth ] ), q{} );
        my $area     = $depth < $#dirs && $area{ $dirs[ $depth + 1 ] } ? $dirs[ $depth + 1 ] : undef;

        if ( List::Util::any { -e File::Spec->catfile( $ancestor, $_ ) } @DIST_MARKERS ) {
            return if !defined $area;
            return ( $ancestor, $area );
        }
        @fallback = ( $ancestor, $area ) if !@fallback && defined $area;
    }
    return @fallback;
}


sub default_cache_dir {
    my $base = $ENV{XDG_CACHE_HOME} || ( $ENV{HOME} && File::Spec->catdir( $ENV{HOME}, '.cache' ) ) or return;
    return File::Spec->catdir( $base, $CACHE_NAME );
}


sub for_file {
    my ( $class, $file, %opts ) = @_;

    my ($root) = $class->root_of($file) or return;
    my $cache_dir = exists $opts{cache_dir} ? $opts{cache_dir} : $class->default_cache_dir();

    return $FOR{ join "\0", $root, $cache_dir // q{} } //= bless { root => $root, cache_dir => $cache_dir }, $class;
}


sub root {
    my ($self) = @_;
    return $self->{root};
}


sub collected {
    my ( $self, $name ) = @_;

    die "No collector is registered as $name\n" if !$COLLECTORS{$name};
    $self->$refresh();

    my $files = $self->{files};
    return { map { $_ => $files->{$_}{collected}{$name}{data} } keys %$files };
}


sub area_of {
    my ( $self, $file ) = @_;

    $self->$refresh();
    my $entry = $self->{files}{$file} or return;
    return $entry->{area};
}


sub stamp_of {
    my ( $self, $file ) = @_;

    $self->$refresh();
    my $entry = $self->{files}{$file} or return;
    return $entry->{stamp};
}


sub stash {
    my ( $self, $name ) = @_;

    die "No collector is registered as $name\n" if !$COLLECTORS{$name};
    $self->$refresh();

    my $kept = $self->{stash}{$name};
    return if ref $kept ne 'HASH' || ( $kept->{version} // q{} ) ne $COLLECTORS{$name}{version};
    return $kept->{data};
}


sub keep {
    my ( $self, $name, $data ) = @_;

    die "No collector is registered as $name\n" if !$COLLECTORS{$name};
    $self->$refresh();

    $self->{stash}{$name} = { version => $COLLECTORS{$name}{version}, data => $data };
    return $self->$write_cache();
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Perl::Critic::Distribution - Parse a distribution once, for every policy that needs all of it.

=head1 VERSION

version 0.001

=head1 SYNOPSIS

    package Perl::Critic::Policy::Something;
    use parent qw{Perl::Critic::Policy};
    use Perl::Critic::Distribution;

    sub initialize_if_enabled {
        my ( $self, $config ) = @_;
        Perl::Critic::Distribution->register(
            name    => __PACKAGE__,
            version => Perl::Critic::Distribution->stamp(__FILE__),
            collect => sub {
                my ( $ppi, $file, $area ) = @_;
                return { subs => [ map { $_->name } @{ $ppi->find('PPI::Statement::Sub') || [] } ] };
            },
        );
        return $self->SUPER::initialize_if_enabled($config);
    }

    sub violates {
        my ( $self, $elem, $doc ) = @_;
        my $dist = Perl::Critic::Distribution->for_file( $doc->filename ) or return;
        my $all  = $dist->collected(__PACKAGE__);    # { $file => what collect returned }
        ...
    }

=head1 DESCRIPTION

L<Perl::Critic::Document> is what a policy knows about one file.  Some
questions need the whole distribution: whether anything calls a sub, or what a
sub in another file returns.  A policy that asks such a question has to parse
every file of the distribution, and two such policies parse every file twice.

This module parses each file once per process, and hands the parsed document
to every collector that is registered.  A collector is a sub that a policy
registers.  It reads the L<PPI::Document> and returns what the policy needs
from that file as plain data, which JSON can hold.  The policy then asks for
what its collector returned, for every file.

The files are the Perl files under F<bin/>, F<lib/>, F<t/> and F<xt/> of the
distribution.  The distribution of a file is found as
L</root_of> says.

=head2 WHEN A COLLECTOR RUNS

Register a collector from C<initialize_if_enabled> in the policy.
Perl::Critic calls that for each enabled policy before it critiques the first
file, so a disabled policy adds no work, and every collector is registered
before the first policy asks for anything.  The first C<collected> call of a
process then parses each file once and runs every registered collector on it.

A collector that registers later, after a distribution was read, is filled in
on its first C<collected> call.  That walk parses each file again, and runs
only the collectors whose data is missing or stale.

=head2 THE CACHE ON DISK

An editor integration such as PerlNavigator starts a new process for every file
that it checks.  Without a cache, every such check parses the whole
distribution.

So what the collectors return is also kept on disk, one file for each
distribution, as JSON compressed with gzip.  For each file it holds a stamp of
the file: its device, inode, size, and modification and change times.  It also
holds what each collector returned, with the version of that collector.  A new
process reads the cache.  It parses only a file whose stamp differs, or a file
that lacks the data of a registered collector at its current version.  A file
that is gone drops out, and a new file is parsed.  The cache is written again
only when something changed.

The data of a collector that is not registered in this process is kept, as
long as the stamp of its file is the same, for the next process that registers
it.

The cache also records the stamp of this module's own file.  So a new version
of this module, or an edit to it, starts from an empty cache.

Each time a cache is written, the cache of each distribution whose root is
gone, such as a deleted checkout, is removed from the cache directory.  The
root is in the gzip header of each file, so this does not read the files
whole.

A cache that cannot be read, does not parse, or cannot be written is ignored,
and the distribution is read as though there were none.  A check never fails
because of the cache.

=head2 CAVEATS

A distribution is read once per process for each set of collectors.  A file
that is edited after that is not seen again in that process.  L</THE CACHE ON
DISK> is how the next process sees it.

Two policies that pass different C<cache_dir> values to C<for_file> get two
objects, and so two parses.  Leave C<cache_dir> to its default, or give each
policy the same one.

=head2 METHODS

=head3 register

    Perl::Critic::Distribution->register( name => $name, version => $version, collect => \&collect );

Registers a collector for every distribution of this process.  C<name> is the
key that C<collected> and C<stash> take, usually the package of the policy.
C<version> is any string, and a change to it runs the collector again on every
file.  The stamp of the policy's own file, from C<stamp>, changes whenever the
policy does.  C<collect> is called as C<< collect->( $ppi, $file, $area ) >>,
with the L<PPI::Document>, the absolute path of the file, and C<bin>, C<lib>,
C<t> or C<xt>.  It returns what that policy needs from the file, as data that
JSON can hold.

Registering a name again replaces it.  Returns the name.  Dies on a missing
name or a C<collect> that is not a code reference.

=head3 stamp

    my $stamp = Perl::Critic::Distribution->stamp($file);

What changes when a file does: its device, inode, size, and modification and
change times, as one string.  The inode changes when an editor saves by
renaming a new file over the old one, and the times are to the nanosecond, so
an edit that keeps the size within one second still changes it.  Undef if the
file cannot be read.

=head3 root_of

    my ( $root, $area ) = Perl::Critic::Distribution->root_of($file);

The root of the distribution that C<$file> belongs to, and which of F<bin/>,
F<lib/>, F<t/> and F<xt/> of it the file is in.  An empty list when it is in
none of them.

The root is the nearest directory above the file with a F<dist.ini>,
F<Makefile.PL>, F<Build.PL>, F<META.json>, F<META.yml>, F<cpanfile> or F<.git>
in it.  So a file in F<t/lib> is in F<t/>, not in a distribution whose root is
F<t/>.  With no such directory anywhere above, the root is the directory that
holds the nearest F<bin/>, F<lib/>, F<t/> or F<xt/> that the file is in.

=head3 default_cache_dir

F<$XDG_CACHE_HOME/perl-critic-distribution>, or
F<~/.cache/perl-critic-distribution> when C<XDG_CACHE_HOME> is not set.  Undef
when neither that nor C<HOME> is set.

=head3 for_file

    my $dist = Perl::Critic::Distribution->for_file( $file, cache_dir => $dir );

The distribution that C<$file> belongs to, as C<root_of> finds it, or undef
for a file in none.  Source with no file name, such as a string handed to
C<critique>, belongs to none.

C<cache_dir> is where the cache is kept.  Without it, C<default_cache_dir>.
Undef keeps no cache.  The same root and cache directory return the same
object for the life of the process.

=head3 root

The root directory of the distribution.

=head3 collected

    my $by_file = $dist->collected($name);

What the collector C<$name> returned for each file of the distribution, as a
hash reference keyed by the absolute path of the file.  A file that PPI cannot
parse is not in it.  Reads the distribution the first time any collector asks,
and again for a collector that registered after that.  Dies on a name that is
not registered.

=head3 area_of

    my $area = $dist->area_of($file);

C<bin>, C<lib>, C<t> or C<xt>: which part of the distribution a file it read
is in.  Undef for a file it did not read.

=head3 stamp_of

The stamp, as C<stamp> makes it, that a file had when the distribution was
read.  A policy that keeps derived data in its C<stash> can compare it, to
tell which files changed.  Undef for a file it did not read.

=head3 stash

    my $data = $dist->stash($name);

What the policy registered as C<$name> last kept with C<keep>, in this process
or in the cache on disk.  Undef when there is nothing, or when it was kept by
another version of the collector.

It is for data that a policy works out from what its collector returned for
every file, and that costs time to work out again.

=head3 keep

    $dist->keep( $name, $data );

Keeps C<$data> as the stash of C<$name>, and writes the cache.  Returns true if
the cache was written, which is never when there is no cache directory.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/teodesian/perl-critic-distribution/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHORS

Current Maintainers:

=over 4

=item *

George S. Baugh <george@troglodyne.net>

=back

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2026 Troglodyne LLC


Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:
The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

=cut
