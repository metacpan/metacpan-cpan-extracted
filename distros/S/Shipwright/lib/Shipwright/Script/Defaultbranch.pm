package Shipwright::Script::Defaultbranch;
use strict;
use warnings;
use Shipwright::Util;

use base qw/App::CLI::Command Shipwright::Base Shipwright::Script/;

use Shipwright;

sub run {
    my $self    = shift;
    my $name    = shift;
    my $default = shift;

    confess_or_die "need name arg\n"    unless $name;
    confess_or_die "need default arg\n" unless $default;

    my $shipwright = Shipwright->new( repository => $self->repository, );

    my $branches = $shipwright->backend->branches;

    if ( grep { $default eq $_ } @{ $branches->{$name} } ) {

        # move $default to head
        @{ $branches->{$name} } =
          ( $default, grep { $_ ne $default } @{ $branches->{$name} } );
        $shipwright->backend->branches($branches);
        $self->log->fatal(
            "successfully set default branch for $name, now it's $default");
    }
    else {
        confess_or_die "$name doesn't have branches $default.
Available branches are " . join( ', ', @{ $branches->{$name} } ) . "\n";
    }
}

1;

__END__

=head1 NAME

Shipwright::Script::Defaultbranch - Set the default branch for a source

=head1 SYNOPSIS

 shipwright defaultbranch cpan-Shipright 2.0

=head1 DESCRIPTION

See also L<Shipwright::Manual::UsingBranches>.

=head1 GLOBAL OPTIONS

 -r [--repository] REPOSITORY   : specify the repository uri of our shipyard
 -l [--log-level] LOGLEVEL      : specify the log level
                                  (info, debug, warn, error, or fatal)
 --log-file FILENAME            : specify the log file


=head1 AUTHORS

sunnavy  C<< <sunnavy@bestpractical.com> >>

=head1 LICENCE AND COPYRIGHT

Shipwright is Copyright 2007-2015 Best Practical Solutions, LLC.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

