package PAX::Differential;

our $VERSION = '0.031';

use strict;
use warnings;
use IPC::Open3;
use JSON::PP ();
use Symbol qw(gensym);
use PAX::Capture;

sub new {
    my ($class, %args) = @_;
    return bless {
        pax_bin => $args{pax_bin},
    }, $class;
}

sub compare_capture {
    my ($self, $entrypoint) = @_;
    my $stock = _run($^X, $entrypoint);
    my $capture = eval { PAX::Capture->new(mode => 'live')->capture($entrypoint) };
    my $pax = {
        command => ['PAX::Capture', $entrypoint],
        exit => ($@ || !$capture || ($capture->{status} // '') ne 'ok') ? 1 : 0,
        stdout => '',
        stderr => $@ // '',
    };

    return {
        entrypoint => $entrypoint,
        stock => $stock,
        pax => $pax,
        pass => ($stock->{exit} == 0 && $pax->{exit} == 0) ? JSON::PP::true() : JSON::PP::false(),
        comparison => {
            stock_exit => $stock->{exit},
            pax_exit => $pax->{exit},
            stock_stderr_present => $stock->{stderr} ne '' ? JSON::PP::true() : JSON::PP::false(),
            pax_stderr_present => $pax->{stderr} ne '' ? JSON::PP::true() : JSON::PP::false(),
        },
    };
}

sub _run {
    my (@cmd) = @_;
    my $err = gensym;
    my $pid = open3(my $in, my $out, $err, @cmd);
    close $in;
    local $/;
    my $stdout = <$out> // '';
    my $stderr = <$err> // '';
    waitpid($pid, 0);
    return {
        command => \@cmd,
        exit => $? >> 8,
        stdout => $stdout,
        stderr => $stderr,
    };
}

1;

__END__

=head1 NAME

PAX::Differential - compare stock Perl execution with PAX capture behavior

=head1 SYNOPSIS

  my $diff = PAX::Differential->new;
  my $report = $diff->compare_capture('script.pl');

=head1 DESCRIPTION

C<PAX::Differential> is an internal validation helper. It keeps differential
capture checks available after SOW-03 removed C<pax capture> from the public CLI
by invoking C<PAX::Capture> directly.

=head1 METHODS

=head2 new

Constructs a differential runner. The historical C<pax_bin> argument is accepted
for compatibility with older tests but no longer drives capture through the CLI.

=head2 compare_capture

Runs the entrypoint with stock Perl, captures it through C<PAX::Capture>, and
returns comparable exit/status metadata.

=head1 PURPOSE

This module exists to make stock-Perl versus PAX capture differences explicit
when a behavior mismatch appears, instead of forcing contributors to debug the
two paths manually from scratch.

=cut
