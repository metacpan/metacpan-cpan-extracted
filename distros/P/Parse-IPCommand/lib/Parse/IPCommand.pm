package Parse::IPCommand;

our $DATE = '2019-02-26'; # DATE
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;

use Exporter qw(import);
our @EXPORT_OK = qw(
                       parse_ip_addr_show
                       list_network_interfaces
               );

our %SPEC;

our %arg0_output = (
    output => {
        summary => 'Output of command',
        description => <<'_',

This function only parses program's output. You need to invoke "ip" command on
your own.

_
        schema => 'str*',
        pos => 0,
        req => 1,
        cmdline_src => 'stdin_or_files',
    },
);

our %argopt_output = (
    output => {
        summary => 'Output of command',
        description => <<'_',

This function only parses program's output. You need to invoke "ip" command on
your own.

_
        schema => 'str*',
        cmdline_src => 'stdin_or_files',
    },
);

$SPEC{parse_ip_addr_show} = {
    v => 1.1,
    summary => 'Parse the output of "ip addr show" command',
    args => {
        %arg0_output,
    },
};
sub parse_ip_addr_show {
    my %args = @_;

    my $output = $args{output} or return [400, "Please specify output"];
    [501, "Not yet implemented"];
}

$SPEC{list_network_interfaces} = {
    v => 1.1,
    summary => 'List network interfaces from "ip addr show" output',
    description => <<'_',

If `output` is not specified, will run '/sbin/ip addr show' to get the output.

_
    args => {
        %argopt_output,
    },
};
sub list_network_interfaces {
    my %args = @_;

    my $out = $args{output} // `LANG=C /sbin/ip addr`;
    return [500, "Can't get the output of /sbin/ip addr: $! (exit=$?)"]
        unless $out;
    my @ifaces_txt = $out =~ /^\d: (.+?)(?=\z|^\d+:)/gms;
    return [500, "Can't find any interface from output of /sbin/ip addr, not even lo!"]
        unless @ifaces_txt;

    my @ifaces;
    my $i = 0;
    for (@ifaces_txt) {
        $i++;
        if (/\A(lo):/) {
            push @ifaces, {dev=>$1, mac=>'', addr=>''};
        } else {
            my $iface = {};

            s!\A(\S+):!! or do {
                warn "Can't get device name for interface #$i, skipped";
                next;
            };
            $iface->{dev} = $1;

            m!^\s*inet (\S+?)(?:/\d+)? brd \S+ scope global!ms and do {
                $iface->{addr} = $1;
            } or do {
                warn "Can't get inet address for dev $iface->{dev}";
            };

            m!^\s*link/ether (\S+)!m and do {
                $iface->{mac} = $1;
            };

            push @ifaces, $iface;
        }
    }
    [200, "OK", \@ifaces];
}


1;
# ABSTRACT: List network interfaces from "ip addr show" output

__END__

=pod

=encoding UTF-8

=head1 NAME

Parse::IPCommand - List network interfaces from "ip addr show" output

=head1 VERSION

This document describes version 0.001 of Parse::IPCommand (from Perl distribution Parse-IPCommand), released on 2019-02-26.

=head1 SYNOPSIS

 use Parse::IPCommand qw(
     parse_ip_addr_show
     list_network_interfaces
 );

 my $res = parse_ip_addr_show(output => scalar `ip addr show`);

=head1 DESCRIPTION

=head1 FUNCTIONS


=head2 list_network_interfaces

Usage:

 list_network_interfaces(%args) -> [status, msg, payload, meta]

List network interfaces from "ip addr show" output.

If C<output> is not specified, will run '/sbin/ip addr show' to get the output.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<output> => I<str>

Output of command.

This function only parses program's output. You need to invoke "ip" command on
your own.

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)


=head2 parse_ip_addr_show

Usage:

 parse_ip_addr_show(%args) -> [status, msg, payload, meta]

Parse the output of "ip addr show" command.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<output>* => I<str>

Output of command.

This function only parses program's output. You need to invoke "ip" command on
your own.

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Parse-IPCommand>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Parse-IPCommand>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Parse-IPCommand>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
