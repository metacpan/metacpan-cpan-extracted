#! /bin/false

# Copyright (C) 2016-2018 Guido Flohr <guido.flohr@cantanea.com>,
# all rights reserved.

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

package Qgoda::Repository;
$Qgoda::Repository::VERSION = 'v0.9.3';
use strict;

use Locale::TextDomain qw(qgoda);

use File::Spec;
use File::HomeDir;
use File::Temp;

use Qgoda;
use Qgoda::Util qw(read_file write_file is_archive);

use URI;

sub new {
    my ($class, $uri) = @_;

    $uri = URI->new($uri);

    # This is a mess!  Re-write it from scratch ...
    if ($uri =~ m{^\.\.?\\/}) {
        $uri = 'file://' . File::Spec->rel2abs($uri);
        $uri =~ s{\\}{/}g;
        $uri = URI->new($uri);
    } elsif ($uri =~ s{^~([^/\\]*)}{}) {
        my $user = $1;
        my $home;
        if (length $user) {
            $home = File::HomeDir->user_home($user);
        } else {
            $home = File::HomeDir->my_home;
        }
        $uri = 'file://' . $home . '/' . $uri;
        $uri =~ s{\\}{/}g;
        $uri = URI->new($uri);
    } elsif (File::Spec->file_name_is_absolute($uri)) {
        $uri = URI->new('file://' . $uri);
    }

    if (undef eq $uri->scheme) {
        my $file = "$uri";

        if (File::Spec->file_name_is_absolute($file)) {
            $uri = URI->new($file, 'file');
        } else {
            if ($file =~ /^[_a-zA-Z][_a-zA-Z0-9]*\@/) {
                # Replace the first colon with a slash.
                $uri =~ s{:}{/};
                $uri = URI->new('git+ssh://' . $uri);
            } elsif (!-e $file && $file =~ m{/}) {
                $uri = URI->new('git://github.com/' . $file);
            } else {
                $uri = URI::file->new_abs($file);
            }
        }
    }

    my $self = {
        __uri => $uri
    };

    my $protocol = $uri->scheme;
    my %known = (
        'git' => 'Git',
        'git+ssh' => 'Git',
        'git+http' => 'Git',
        'git+https' => 'Git',
        'git+file' => 'Git',
        'file' => 'File'
    );

    $self->{__type} = $known{$protocol} || 'LWP';

    if ('Git' eq $self->{__type}) {
        my $scheme = $self->{__uri}->scheme;
        if ($scheme =~ /\+(.*)/) {
            $self->{__uri}->scheme($1);
        }
    }

    # If an http/https URI does not look like an archive, assume that it is
    # also a git URI.
    if ('http' eq $uri->scheme || 'https' eq $uri->scheme) {
        # These are file name extenders likely to contain an archive.
        if (!is_archive $uri->path) {
            $self->{__type} = 'Git';
            $self->{__source} = 'Github'
                if 'github.com' eq $self->{__uri}->host;
        }
    }

    if ($self->{__type}) {
        if ('Git' eq $self->{__type}) {
            if ('github.com' eq $self->{__uri}->host) {
                $self->{__source} = 'Github';
            }
        }
    }

    bless $self, $class;
}

sub type { shift->{__type} }
sub source { shift->{__source} }
sub uri { shift->{__uri} }

sub fetch {
    my ($self) = @_;

    my $logger = Qgoda->new->logger;

    my $fetcher_class = 'Qgoda::Repository::Fetcher::' . $self->{__type};
    my $fetcher_module = $fetcher_class;
    $fetcher_module =~ s{::}{/}g;
    $fetcher_module .= '.pm';
    require $fetcher_module;

    $logger->info(__x("fetching '{uri}'", uri => $self->{__uri}));

    my $tmp = File::Temp->newdir;
    $logger->debug(__x("created temporary directory '{dir}'",
                       dir => $tmp));

    my $fetcher = $fetcher_class->new;
    my $dir = $fetcher->fetch($self->{__uri}, $tmp->dirname);

    # Return the object as well, so that it doesn't go out of scope here.
    return ($dir, $tmp);
}

package URI::git;
$URI::git::VERSION = 'v0.9.3';
use strict;

use base qw(URI::http);

package URI::git_Phttp;
$URI::git_Phttp::VERSION = 'v0.9.3';
use strict;

use base qw(URI::git);

package URI::git_Phttps;
$URI::git_Phttps::VERSION = 'v0.9.3';
use strict;

use base qw(URI::git);

package URI::git_Pssh;
$URI::git_Pssh::VERSION = 'v0.9.3';
use strict;

use base qw(URI::git);

package URI::git_Pfile;
$URI::git_Pfile::VERSION = 'v0.9.3';
use strict;

use base qw(URI::file);

1;
