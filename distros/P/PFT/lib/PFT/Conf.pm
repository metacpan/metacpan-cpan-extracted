# Copyright 2014-2016 - Giovanni Simoni
#
# This file is part of PFT.
#
# PFT is free software: you can redistribute it and/or modify it under the
# terms of the GNU General Public License as published by the Free
# Software Foundation, either version 3 of the License, or (at your
# option) any later version.
#
# PFT is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with PFT.  If not, see <http://www.gnu.org/licenses/>.
#
package PFT::Conf v1.3.0;

=encoding utf8

=head1 NAME

PFT::Conf - Configuration parser for PFT

=head1 SYNOPSIS

    PFT::Conf->new_default()        # Using default
    PFT::Conf->new_load($root)      # Load from conf file in directory
    PFT::Conf->new_load_locate()    # Load from conf file, find directory
    PFT::Conf->new_load_locate($cwd)

    PFT::Conf::locate()             # Locate root
    PFT::Conf::locate($cwd)

    PFT::Conf::isroot($path)        # Check if location exists under path.

    use Getopt::Long;
    Getopt::Long::Configure 'bundling';
    GetOptions(
        PFT::Conf::wire_getopt(\my %opts),
        'more-opt' => \$more,
    );
    PFT::Conf->new_getopt(\%opts);  # Create with command line options

=head1 DESCRIPTION

Automatic loader and handler for the configuration file of a I<PFT> site.

The configuration is a simple I<YAML> file with a conventional name.  Some
keys are mandatory, while other are optional. This module allows a
headache free check for mandatory ones.

=head2

Many constructors are available, here described:

=over

=item new_default

Creates a new configuration based on environment variables and common
sense.

The configuration can later be stored on a file with the C<save_to>
method.

=item new_load

Loads a configuration file which must already exist. Accepts as optional
argument the name of a directory (not encoded), which defaults on
the current directory.

This constructor fails with C<croak> if the directory does not contain a
configuration file.

=item new_load_locate

Works as C<new_load>, but before failing makes an attempt to locate the
configuration file in the parent directories up to the root level.

This is handy for launching commands from the command line without
worrying on the current directory: it works as long as your I<cwd> is
below a I<PFT> root directory.

=item wire_getopt and new_getopt

This is a two-steps constructor meant for command line initializers.

An example of usage can be found in the B<SYNOPSIS> section. In short, the
auxiliary function C<PFT::Conf::wire_getopt> provides a list of
ready-to-use options for the C<GetOpt::Long> Perl module. It expects a
hash reference as argument, which will be used as storage for selected
options. The C<new_getopt> constructor expects as argument the same hash
reference.

=back

=cut

use utf8;
use v5.16;
use strict;
use warnings;

use Carp;
use Cwd;
use Encode::Locale;
use Encode;
use File::Basename qw/dirname/;
use File::Path qw/make_path/;
use File::Spec::Functions qw/updir catfile catdir rootdir/;
use YAML::Tiny;

=head2 Shared variables

C<$PFT::Conf::CONF_NAME> is a string. Defines the name of the
configuration file.

=cut

use Exporter 'import';
our @EXPORT_OK = qw(
    pod_autogen
    bash_completion_autogen
);
our $CONF_NAME = 'pft.yaml';

# %CONF_RECIPE maps configuration names to an array.
#
# Keys of this map correspond to keys in the configuratoin file. They use dashes
# to identify the hierarchy, so that, for instance, site-author corresponds to
# the key 'author' in the section 'site' of the configuration file.
#
# Keys are also used for generating automatically the POD user guide and the
# command line options of the `pft init` command.
#
# The semantics of each array item is defined by the following $IDX_* variables:
my(
    $IDX_MANDATORY,     # true if the configuration is mandatory
    $IDX_GETOPT_SUFFIX, # the corresponding suffix in getopt (see Getopt::Long)
    $IDX_DEFAULT,       # The default value when generating a configuration
    $IDX_HELP           # A human readable text descrbing the option
) = 0 .. 3;
my %CONF_RECIPE = do {
    my $user = $ENV{USER} || 'anon';
    my $editor = $ENV{EDITOR} || 'vim';
    my $browser = $ENV{BROWSER} || 'firefox';
    (
        'site-author'     => [1, '=s', $user || 'Anonymous',
            'Default author of entries'
        ],
        'site-template'   => [1, '=s', 'default.html',
            'Default template for compilation, can be overriden by single '.
            'entries'
        ],
        'site-theme'      => [0, '=s', 'light',
            'Global theme (e.g. "light" or "dark") optionally honored by '.
            'templates. Specific accepted values depend on the template '.
            'implementation'
        ],
        'site-title'      => [1, '=s', 'My PFT website',
            'Title of the website',
        ],
        'site-url'        => [0, '=s', 'http://example.org',
            'Base url for the website',
        ],
        'site-home'       => [1, '=s', 'Welcome',
            'First page, where index.html redirects the browsers',
        ],
        'site-encoding'   => [1, '=s', $Encode::Locale::ENCODING_LOCALE,
            'Charset of the generated web pages'
        ],
        'site-feedfile'  => [0, '=s', 'feed.rss',
            'File name of the RSS XML to be published by "pft gen-rss"',
        ],
        'publish-method'  => [1, '=s', 'rsync+ssh',
            'Method used for publishing'
        ],
        'publish-host'    => [0, '=s', 'example.org',
            'Remote host where to publish'
        ],
        'publish-user'    => [0, '=s', $user,
            'User login on publishing host'
        ],
        'publish-port'    => [0, '=i', 22,
            'Port for connection on publishing host'
        ],
        'publish-path'    => [0, '=s', "/home/$user/public_html",
            'Directory on publishing host'
        ],
        'system-editor'   => [0, '=s', "$editor %s",
            'Editor to be invoked by C<pft edit>. You may specify an '.
            'executable, or a shell command where "%s" gets replaced '.
            'with the file name'
        ],
        'system-browser'  => [0, '=s', "$browser %s",
            'Browser to be invoked by C<pft show>. You may specify an '.
            'executable, or a shell command where "%s" gets replaced '.
            'with the file name'
        ],
    )
};

# Transforms a flat mapping as $CONF_RECIPE into 'deep' hash table. Items in the
# form 'foo-bar-baz' will be accessible as _hashify()->{foo}{bar}{baz}.
sub _hashify {
    my %out;

    @_ % 2 and die "Odd number of args";
    for (my $i = 0; $i < @_; $i += 2) {
        defined(my $val = $_[$i + 1]) or next;
        my @keys = split /-/, $_[$i];

        die "Key is empty? \"$_[$i]\"" unless @keys;
        my $dst = \%out;
        while (@keys > 1) {
            my $k = shift @keys;
            $dst = exists $dst->{$k}
                ? $dst->{$k}
                : do { $dst->{$k} = {} };
            ref $dst ne 'HASH' and croak "Not pointing to hash: $_[$i]";
        }
        my $k = shift @keys;
        exists $dst->{$k} && ref $dst->{$k} eq 'HASH'
            and croak "Overwriting $_[$i]";
        $dst->{$k} = $val;
    }

    \%out;
}

# Read the %CONF_RECIPE map and return a mapping between each key and the
# associated field. The first parameter is the index to select. The second
# parameter is optional: if true retrieves only the configuration which evaluate
# as true.
sub _read_recipe {
    my $select = shift;
    my @out;
    if (my $filter = shift) {
        while (my($k, $vs) = each %CONF_RECIPE) {
            my $v = $vs->[$select] or next;
            push @out, $k => $vs->[$select];
        }
    } else {
        while (my($k, $vs) = each %CONF_RECIPE) {
            push @out, $k => $vs->[$select];
        }
    }
    @out;
}

sub pod_autogen {
    my @out = ('=over', '');

    for my $key (sort keys %CONF_RECIPE) {
        my $info = $CONF_RECIPE{$key};
        push @out,
            "=item --$key", '',
            $info->[$IDX_HELP], '',
            "Defaults to C<$info->[$IDX_DEFAULT]>", ''
    }

    join "\n", @out, '=back';# '', '=cut';
}

sub bash_completion_autogen {
    '--' . join "\n--", keys %CONF_RECIPE;
}

sub new_default {
    my $self = _hashify(_read_recipe($IDX_DEFAULT));
    $self->{_root} = undef;
    bless $self, shift;
}

sub _check_assign {
    my $self = shift;
    local $" = '-';
    my $i;

    for my $mandk (grep { ++$i % 2 } _read_recipe($IDX_MANDATORY, 1)) {
        my @keys = split /-/, $mandk;
        my @path;

        my $c = $self;
        while (@keys > 1) {
            push @path, (my $k = shift @keys);
            confess "Missing section \"@path\"" unless $c->{$k};
            $c = $c->{$k};
            confess "Seeking \"@keys\" in \"@path\""
                unless ref $c eq 'HASH';
        }
        push @path, shift @keys;
        confess "Missing @path" unless exists $c->{$path[-1]};
    }
}

sub new_load {
    my($cls, $root) = @_;

    my $self = do {
        my $enc_fname = isroot($root)
            or croak "$root is not a PFT site: $CONF_NAME is missing";
        open(my $f, '<:encoding(locale)', $enc_fname)
            or croak "Cannot open $CONF_NAME in $root $!";
        local $/ = undef;
        my $yaml = <$f>;
        close $f;

        YAML::Tiny::Load($yaml);
    };
    _check_assign($self);

    $self->{_root} = $root;
    bless $self, $cls;
}

sub new_load_locate {
    my $cls = shift;
    my $root = locate(my $start = shift);
    croak "Not a PFT site (or any parent up to $start)"
        unless defined $root;

    $cls->new_load($root);
}

sub new_getopt {
    my($cls, $wired_hash) = @_;

    my $self = _hashify(
        _read_recipe($IDX_DEFAULT), # defaults
        %$wired_hash,               # override via wire_getopt
    );
    $self->{_root} = undef;
    bless $self, $cls;
}

=head2 Utility functions

=over

=item isroot

The C<PFT::Conf::isroot> function searches for the configuration file in
the given directory path (not encoded).

Returns C<undef> if the file was not found, and the encoded file name
(according to locale) if it was found.

=cut

sub isroot {
    my $f = encode(locale_fs => catfile(shift, $CONF_NAME));
    -e $f ? $f : undef
}

=item locate

The C<PFT::Conf::locate> function locates a I<PFT> configuration file.

It accepts as optional parameter a directory path (not encoded),
defaulting on the current working directory.

Possible return values:

=over

=item The input directory itself if the configuration file was
found in it;

=item The first encountered parent directory containing the configuration
file;

=item C<undef> if no configuration file was found, up to the root of all
directories.

=back

=back

=cut

sub locate {
    my $cur = shift || Cwd::getcwd;
    my $root;

    croak "Not a directory: $cur" unless -d encode(locale_fs => $cur);

    # No single root directory on Windows. File::Spec->rootdir does not
    # work as intended. Workaround: $prev is like $cur on the previous
    # step: we stay on the same directory even going up, we reached the
    # root. Thanks to Alexandr Ciornii for checking this.
    my $prev = '';
    until ($cur eq rootdir or $cur eq $prev or defined($root)) {
        $prev = $cur;
        if (isroot($cur)) {
            $root = $cur
        } else {
            $cur = Cwd::abs_path catdir($cur, updir)
        }
    }
    $root;
}

sub wire_getopt {
    my $hash = shift;
    confess 'Needs hash' unless ref $hash eq 'HASH';

    my @out;
    my @recipe = _read_recipe($IDX_GETOPT_SUFFIX);
    for (my $i = 0; $i < @recipe; $i += 2) {
        push @out, $recipe[$i] . $recipe[$i + 1] => \$hash->{$recipe[$i]}
    }
    @out;
}

=head2 Methods

=over 1

=item save_to

Save the configuration to a file. This will also update the inner root
reference, so the intsance will point to the saved file.

=cut

sub save_to {
    my($self, $root) = @_;

    my $orig_root = delete $self->{_root};

    # YAML::Tiny does not like blessed items. I could unbless with
    # Data::Structure::Util, or easily do a shallow copy
    my $yaml = YAML::Tiny::Dump {%$self};

    eval {
        my $enc_root = encode(locale_fs => $root);
        -e $enc_root or make_path $enc_root
            or die "Cannot mkdir $root: $!";
        open(my $out,
            '>:encoding(locale)',
            encode(locale_fs => catfile($root, $CONF_NAME)),
        ) or die "Cannot open $CONF_NAME in $root: $!";
        print $out $yaml;
        close $out;

        $self->{_root} = $root;
    };
    $@ and do {
        $self->{_root} = $orig_root;
        croak $@ =~ s/ at.*$//sr;
    }
}

=back

=cut

use overload
    '""' => sub { 'PFT::Conf[ ' . (shift->{_root} || '?') . ' ]' },
;

1;
