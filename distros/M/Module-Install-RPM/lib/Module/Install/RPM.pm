package Module::Install::RPM;

use strict; use warnings;
use base 'Module::Install::Base';
use 5.008;

our $VERSION = '0.01';

BEGIN { $| = 1; }

# Just gather the list of required RPMs and their versions
sub requires_rpm {
    my ($self, $rpm, $version) = @_;
    push @{$self->{rpms}}, [ $rpm, $version ];
}

sub _version_cmp {
    my ($v1, $v2) = @_;

    my @v1 = split /\./, $v1;
    my @v2 = split /\./, $v2;

    my $end = @v1 < @v2 ? $#v1 : $#v2;
    for my $i (0..$end) {
        my $c = $v1[$i] <=> $v2[$i];
        return $c if $c;
    }
    return 0;
}

sub _check_rpms {
    my $self = shift;

    unless ($self->can_run('rpm')) {
        die "ERROR: Unable to locate ``rpm'' executable\n";
    }

    my $maxlen = 0;
    for my $r (@{$self->{rpms}}) {
        my $l = length($r->[0]);
        $maxlen = $l if $l > $maxlen;
    }

    print "*** Checking for required RPMs\n";
    for my $r (@{$self->{rpms}}) {
        my ($rpm,$version) = @$r;
        printf " - %-${maxlen}s ...", $rpm;
        chomp(my $query = qx(rpm -q $rpm));
        if ($query =~ /not installed/) {
            print "missing", $version ? " (need version $version) " : '', "\n";
            next;
        }
        my @parts = split /-/, $query;
        pop @parts;                 # remove and ignore patch level
        my $rpm_version = pop @parts;

        if ($version && _version_cmp($rpm_version, $version) == -1) {
            print "too old ($rpm_version < $version)\n";
            next;
        }
        print "OK\n";
    }
}

# TODO: Is there a better method to hook into this process?
sub WriteAll {
    my $self = shift;

    $self->_check_rpms;

    # TODO: surely there's a better way to do this
    return Module::Install::WriteAll::WriteAll($self);
}

1;

__END__

=head1 NAME

Module::Install::RPM - require certain RPMs be installed

=head1 SYNOPSIS

  use inc::Module::Install;

  name      'Your-Module';
  all_from  'lib/Your/Module.pm';

  requires_rpm  'gd';
  requires_rpm  'httpd' => '2.2';

  WriteAll;

=head1 DESCRIPTION

Provide a mechanism for a Perl module to require that certain RPMs are
installed and that they optionally meet some minimum version requirements.

B<NOTE:> This is only useful for Linux distributions that utilize the RedHat
Package Manager to maintain package information.

=head1 BUGS

There is no check that the code is being executed on the appropriate operating
system.

=head1 COPYRIGHT

Copyright 2010 Jonathan Scott Duff <duff@pobox.com>

This software is licensed under the same terms as Perl.
