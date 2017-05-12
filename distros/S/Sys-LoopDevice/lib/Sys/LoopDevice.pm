package Sys::LoopDevice;

our $DATE = '2016-12-28'; # DATE
our $VERSION = '0.003'; # VERSION

use 5.010001;
use strict;
use warnings;

use IPC::System::Options 'system', 'readpipe', -lang=>'C';
use Proc::ChildError qw(explain_child_error);

use Perinci::Exporter;

our %SPEC;

sub _read_file {
    my $path = shift;
    open my($fh), $path or die "Can't open '$path': $!";
    local $/;
    scalar <$fh>;
}

$SPEC{':package'} = {
    v => 1.1,
    summary => 'Routines to manipulate loop(back) device '.
        'in a cross-platform way',
};

# $SPEC{get_max_loop_devices} = {
#     v => 1.1,
#     summary => 'Get the number of maximum loop devices',
#     description => <<'_',


# _
#     result_naked => 1,
# };
# sub get_max_loop_devices {
#     my %args = @_;

#     # TODO: return -1 on windows
#     if ($^O eq 'linux') {
#         # XXX even when we do 'modprobe loop max_loop=16', the value of this
#         # file stays at 0.
#         _read_file("/sys/module/loop/parameters/max_loop") || 8;
#     }
# }

#$SPEC{list_detached_loop_devices} = {
#    v => 1.1,
#    summary => 'List detached loop devices',
#
#};

$SPEC{list_attached_loop_devices} = {
    v => 1.1,
    summary => 'List attached loop devices',
    args => {
    },
};
sub list_attached_loop_devices {
    my %args = @_;

    my @res;
    if ($^O eq 'linux') {
        # XXX use losetup --list instead?
        my $out = readpipe("losetup", "-a");
        return [500, "Can't losetup -a: ".explain_child_error()] if $?;
        my $linenum = 0;
        for my $line (split /^/, $out) {
            $linenum++;
            $line =~ m!^(/dev/loop\d+):.+\((.+)\)$!m or
                return [500, "Unrecognized output on line $linenum: $line"];
            push @res, {device => $1, filename=>$2};
        }
        return [200, "OK", \@res];
    } else {
        return [501, "Not implemented yet on OS=$^O"];
    }
}

#$SPEC{list_loop_devices} = {
#};
#sub list_loop_devices {
#}

$SPEC{attach_loop_device} = {
    v => 1.1,
    summary => 'Attach a file to a loop device',
    args => {
        filename => {
            schema => 'filename*',
            req => 1,
            pos => 0,
        },
        device => {
            schema => 'str*',
            pos => 1,
        },
    },
};
sub attach_loop_device {
    my %args = @_;

    my $filename = $args{filename};
    my $device   = $args{device};

    return [404, "File '$filename' does not exist or not a regular file"]
        unless -f $filename;

    if ($^O eq 'linux') {
        unless (defined $device) {
            $device = readpipe("losetup", "-f");
            return [500, "Can't losetup -f to find a free loop device: ".
                        explain_child_error()] if $?;
            chomp($device);
        }
        return [400, "Device name must start with /dev/loop*"]
            unless $device =~ m!\A/dev/loop\d+\z!;
        system "losetup", $device, $filename;
        return [500, "Can't losetup: ".explain_child_error()] if $?;
        return [200, "OK"];
    } else {
        return [501, "Not implemented yet on OS=$^O"];
    }
}

$SPEC{detach_loop_device} = {
    v => 1.1,
    summary => 'Attach a file to a loop device',
    args => {
        filename => {
            schema => 'filename*',
            pos => 0,
        },
        device => {
            schema => 'str*',
            pos => 1,
        },
    },
    args_rels => {
        req_one => [qw/filename device/],
    },
};
sub detach_loop_device {
    require Perinci::Object::EnvResultMulti;

    my %args = @_;
    my $device   = $args{device};
    my $filename = $args{filename};
    defined($device) || defined($filename)
        or return [400, "At least one of device or filename must be specified"];

    my $res = Perinci::Object::EnvResultMulti->new;
    my @devs;

    if ($^O eq 'linux') {
        if (defined $device) {
            push @devs, $device;
        } else {
            my $list_res = list_attached_loop_devices();
            return [500, "Can't list attached loop devices: $list_res->[0] - $list_res->[1]"]
                unless $list_res->[0] == 200;
            for my $ent (@{ $list_res->[2] }) {
                push @devs, $ent->{device} if $ent->{filename} eq $filename;
            }
        }
        return [304, "No devices to remove"] unless @devs;
      DEV:
        for my $dev (@devs) {
            $dev =~ m!\A/dev/loop\d+\z!
                or return [400, "Device does not match /dev/loop*"];
            system "losetup", "-d", $dev;
            if ($?) {
                $res->add_result(
                    500, "Can't losetup -d: ".explain_child_error(),
                    {item_id=>$dev});
            } else {
                # we still need to check if the device is actually detached,
                # because losetup -d still returns 0 nevertheless
                my $list_res = list_attached_loop_devices();
                return [500, "Can't list attached loop devices: $list_res->[0] - $list_res->[1]"]
                    unless $list_res->[0] == 200;
                for my $ent (@{ $list_res->[2] }) {
                    if ($ent->{device} eq $dev) {
                        $res->add_result(500, "Failed, still attached", {item_id=>$dev});
                        next DEV;
                    }
                }
                $res->add_result(200, "OK", {item_id=>$dev});
            }
        }
    } else {
        return [501, "Not implemented yet on OS=$^O"];
    }
    $res->as_struct;
}

1;
# ABSTRACT: Routines to manipulate loop(back) device in a cross-platform way

__END__

=pod

=encoding UTF-8

=head1 NAME

Sys::LoopDevice - Routines to manipulate loop(back) device in a cross-platform way

=head1 VERSION

This document describes version 0.003 of Sys::LoopDevice (from Perl distribution Sys-LoopDevice), released on 2016-12-28.

=head1 SYNOPSIS

 use Sys::LoopDevice qw(
     list_attached_loop_devices
     list_detached_loop_devices
     attach_loop_devices
     detach_loop_devices
 );

=head1 DESCRIPTION

B<STATUS: Early release, API might still change significantly and only Linux
support has been implemented.>

TODO: Support other OS'es

TODO: Support ro option when attaching

=head1 FUNCTIONS


=head2 attach_loop_device(%args) -> [status, msg, result, meta]

Attach a file to a loop device.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<device> => I<str>

=item * B<filename>* => I<filename>

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)


=head2 detach_loop_device(%args) -> [status, msg, result, meta]

Attach a file to a loop device.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<device> => I<str>

=item * B<filename> => I<filename>

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)


=head2 list_attached_loop_devices() -> [status, msg, result, meta]

List attached loop devices.

This function is not exported.

No arguments.

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sys-LoopDevice>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sys-LoopDevice>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sys-LoopDevice>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
