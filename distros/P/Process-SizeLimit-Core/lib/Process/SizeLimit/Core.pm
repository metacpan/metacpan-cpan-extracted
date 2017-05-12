# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.
# The ASF licenses this file to You under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with
# the License.  You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

package Process::SizeLimit::Core;

use strict;
use warnings;

use Config;
use Exporter;

use vars qw(
            $VERSION
            $REQUEST_COUNT
            $USE_SMAPS

            $MAX_PROCESS_SIZE
            $MAX_UNSHARED_SIZE
            $MIN_SHARE_SIZE
            $CHECK_EVERY_N_REQUESTS
            $START_TIME

            @ISA
            @EXPORT_OK
           );

@ISA = qw(Exporter);

@EXPORT_OK = qw(
                $VERSION
                $REQUEST_COUNT
                $USE_SMAPS
                $MAX_PROCESS_SIZE
                $MAX_UNSHARED_SIZE
                $MIN_SHARE_SIZE
                $CHECK_EVERY_N_REQUESTS
                $START_TIME
               );

$VERSION = '0.9507';

$REQUEST_COUNT          = 1;

use constant IS_WIN32 => $Config{'osname'} eq 'MSWin32' ? 1 : 0;

sub set_max_process_size {
    my $class = shift;

    $MAX_PROCESS_SIZE = shift;
}

sub set_max_unshared_size {
    my $class = shift;

    $MAX_UNSHARED_SIZE = shift;
}

sub set_min_shared_size {
    my $class = shift;

    $MIN_SHARE_SIZE = shift;
}

sub set_check_interval {
    my $class = shift;

    $CHECK_EVERY_N_REQUESTS = shift;
}

sub get_check_interval { return $CHECK_EVERY_N_REQUESTS; }

sub set_start_time { $START_TIME ||= time(); }

sub get_start_time { return $START_TIME; }

sub get_and_pinc_request_count { return $REQUEST_COUNT++; }

sub get_request_count { return $REQUEST_COUNT++; }

# REVIEW - Why doesn't this use $r->warn or some other
# Plack::Middleware/Plack::Middleware::Log API?
sub _error_log {
    my $class = shift;

    print STDERR "[", scalar( localtime(time) ),
        "] ($$) $class @_\n";
}

sub _limits_are_exceeded {
    my $class = shift;

    my ($size, $share, $unshared) = $class->_check_size();

    return 1 if $MAX_PROCESS_SIZE  && $size > $MAX_PROCESS_SIZE;

    return 0 unless $share;

    return 1 if $MIN_SHARE_SIZE    && $share < $MIN_SHARE_SIZE;

    return 1 if $MAX_UNSHARED_SIZE && $unshared > $MAX_UNSHARED_SIZE;

    return 0;
}

sub _check_size {
    my $class = shift;

    my ($size, $share) = $class->_platform_check_size();

    return ($size, $share, $size - $share);
}

sub _load {
    my $mod = shift;

    eval "require $mod"
        or die 
            "You must install $mod for SizeLimit to work on your" .
            " platform.";
}

BEGIN {
    my ($major,$minor) = split(/\./, $Config{'osvers'});
    if ($Config{'osname'} eq 'solaris' && 
        (($major > 2) || ($major == 2 && $minor >= 6))) {
        *_platform_check_size   = \&_solaris_2_6_size_check;
        *_platform_getppid = \&_perl_getppid;
    }
    elsif ($Config{'osname'} eq 'linux') {
        _load('Linux::Pid');

        *_platform_getppid = \&_linux_getppid;

        if (eval { require Linux::Smaps::Tiny }) {
            $USE_SMAPS = 1;
            *_platform_check_size = \&_linux_smaps_tiny_size_check;
        }
        elsif (eval { require Linux::Smaps } && Linux::Smaps->new($$)) {
            $USE_SMAPS = 1;
            *_platform_check_size = \&_linux_smaps_size_check;
        }
        else {
            $USE_SMAPS = 0;
            *_platform_check_size = \&_linux_size_check;
        }
    }
    elsif ($Config{'osname'} =~ /(?:bsd|aix)/i) {
        # on OSX, getrusage() is returning 0 for proc & shared size.
        _load('BSD::Resource');

        *_platform_check_size   = \&_bsd_size_check;
        *_platform_getppid = \&_perl_getppid;
    }
    elsif ($Config{'osname'} =~ /darwin/i) {
        _load('BSD::Resource');
        my $ver = qx[sw_vers -productVersion] || 0;
        chomp $ver;
        $ver =~ s/^10\.(\d+)\.\d+$/$1/;
        if ($ver >= 9) {
            # OSX 10.9+ has no concept of rshrd in top
            *_platform_check_size   = \&_bsd_size_check;
        }
        else {
            *_platform_check_size   = \&_darwin_size_check;
        }
        *_platform_getppid = \&_perl_getppid;
    }
#    elsif (IS_WIN32i && $mod_perl::VERSION < 1.99) {
#        _load('Win32::API');
#
#        *_platform_check_size   = \&_win32_size_check;
#        *_platform_getppid = \&_perl_getppid;
#    }
    else {
        die "SizeLimit is not implemented on your platform.";
    }
}

sub _linux_smaps_size_check {
    my $class = shift;

    return $class->_linux_size_check() unless $USE_SMAPS;

    my $s = Linux::Smaps->new($$)->all;
    return ($s->size, $s->shared_clean + $s->shared_dirty);
}

sub _linux_smaps_tiny_size_check {
    my $class = shift;

    return $class->_linux_size_check() unless $USE_SMAPS;

    my $s = Linux::Smaps::Tiny::get_smaps_summary();
    return ($s->{Size}, $s->{Shared_Clean} + $s->{Shared_Dirty});
}

sub _linux_size_check {
    my $class = shift;

    my ($size, $share) = (0, 0);

    if (open my $fh, '<', '/proc/self/statm') {
        ($size, $share) = (split /\s/, scalar <$fh>)[0,2];
        close $fh;
    }
    else {
        $class->_error_log("Fatal Error: couldn't access /proc/self/status");
    }

    # linux on intel x86 has 4KB page size...
    return ($size * 4, $share * 4);
}

sub _solaris_2_6_size_check {
    my $class = shift;

    my $size = -s "/proc/self/as"
        or $class->_error_log("Fatal Error: /proc/self/as doesn't exist or is empty");
    $size = int($size / 1024);

    # return 0 for share, to avoid undef warnings
    return ($size, 0);
}

# rss is in KB but ixrss is in BYTES.
# This is true on at least FreeBSD, OpenBSD, & NetBSD
sub _bsd_size_check {

    my @results = BSD::Resource::getrusage();
    my $max_rss   = $results[2];
    my $max_ixrss = int ( $results[3] / 1024 );

    return ($max_rss, $max_ixrss);
}

sub _darwin_size_check {
    my ($size) = _bsd_size_check();
    my ($shared) = (`top -e -l 1 -stats rshrd -pid $$ -s 0`)[-1];
    $shared =~ s/^(\d+)M.*/$1 * 1024 * 1024/e
        or
    $shared =~ s/^(\d+)K.*/$1 * 1024/e
        or
    $shared =~ s/^(\d+)B.*/$1/;
    no warnings 'numeric';
    return ($size, int($shared));
}

sub _win32_size_check {
    my $class = shift;

    # get handle on current process
    my $get_current_process = Win32::API->new(
        'kernel32',
        'get_current_process',
        [],
        'I'
    );
    my $proc = $get_current_process->Call();

    # memory usage is bundled up in ProcessMemoryCounters structure
    # populated by GetProcessMemoryInfo() win32 call
    my $DWORD  = 'B32';    # 32 bits
    my $SIZE_T = 'I';      # unsigned integer

    # build a buffer structure to populate
    my $pmem_struct = "$DWORD" x 2 . "$SIZE_T" x 8;
    my $mem_counters
        = pack( $pmem_struct, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 );

    # GetProcessMemoryInfo is in "psapi.dll"
    my $get_process_memory_info = new Win32::API(
        'psapi',
        'GetProcessMemoryInfo',
        [ 'I', 'P', 'I' ],
        'I'
    );

    my $bool = $get_process_memory_info->Call(
        $proc,
        $mem_counters,
        length $mem_counters,
    );

    # unpack ProcessMemoryCounters structure
    my $peak_working_set_size =
        (unpack($pmem_struct, $mem_counters))[2];

    # only care about peak working set size
    my $size = int($peak_working_set_size / 1024);

    return ($size, 0);
}

sub _perl_getppid { return getppid }
sub _linux_getppid { return Linux::Pid::getppid() }

1;

__END__

=encoding utf8

=head1 NAME

Process::SizeLimit::Core - Apache::SizeLimit::Core, repackaged

=head1 DESCRIPTION

This module is simply a re-packaging of L<Apache::SizeLimit::Core>
into its own distribution; please refer to L<Apache::SizeLimit>
and L<Plack::Middleware::SizeLimit> for sample usage.

=head1 AUTHORS

唐鳳 E<lt>cpan@audreyt.orgE<gt>, repackaging this module for L<Plack::Middleware::SizeLimit>.

Fred Moyer <fred@redhotpenguin.com>, maintainer of Apache::SizeLimit distribution.

Doug Bagley <doug+modperl@bagley.org>, channeling Procrustes.

Brian Moseley <ix@maz.org>: Solaris 2.6 support

Doug Steinwand and Perrin Harkins <perrin@elem.com>: added support for shared memory and additional diagnostic info

Matt Phillips <mphillips@virage.com> and Mohamed Hendawi <mhendawi@virage.com>: Win32 support

Dave Rolsky <autarch@urth.org>, maintenance and fixes outside of mod_perl tree (0.9+).

=head1 LICENSE

Apache License 2.0

=cut
