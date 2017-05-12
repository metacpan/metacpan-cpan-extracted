package Narada::Log;

use warnings;
use strict;
use Carp;

our $VERSION = 'v2.3.7';

use Narada::Config qw( get_config_line );
use Log::Fast;


_init_log();


sub import {
    my @args = @_;
    my $pkg = caller 0;
    no strict 'refs';
    for (@args) {
        if (m/\A\$(.*)/xms) {
                *{$pkg.q{::}.$1} = \Log::Fast->global();
        }
    }
    return;
}

sub _init_log {
    my $type = eval { get_config_line('log/type') } || 'syslog';
    my $path = eval { get_config_line('log/output') } || return;
    if ($type eq 'syslog') {
        Log::Fast->global()->config({
            level   => get_config_line('log/level'),
            prefix  => q{},
            type    => 'unix',
            path    => $path,
        });
    }
    elsif ($type eq 'file') {
        open my $fh, '>>', $path or croak "open: $!"; ## no critic (InputOutput::RequireBriefOpen)
        Log::Fast->global()->config({
            level   => get_config_line('log/level'),
            prefix  => q{},
            type    => 'fh',
            fh      => $fh,
        });
    }
    else {
        croak "Unsupported value '$type' in config/log/type";
    }
    return;
}


1; # Magic true value required at end of module
__END__

=encoding utf8

=head1 NAME

Narada::Log - setup project log


=head1 VERSION

This document describes Narada::Log version v2.3.7


=head1 SYNOPSIS

    use Narada::Log qw( $LOG );

    $LOG->INFO("ready to work");


=head1 DESCRIPTION

While loading, this module will configure Log::Fast->global() object
according to configuration in C<config/log/type>, C<config/log/output> and
C<config/log/level>.

If any scalar variable names will be given as parameters while loading
module it will export Log::Fast->global() as given variable names.

See L<Log::Fast> for more details.


=head1 INTERFACE 

None.


=head1 DIAGNOSTICS

=over

=item C<< open: %s >>

File config/log/output contain file name, and error happens while trying to
open this file.

=back


=head1 CONFIGURATION AND ENVIRONMENT

Narada::Log requires configuration files and directories provided by
Narada framework.


=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/powerman/Narada/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software. The code repository is available for
public review and contribution under the terms of the license.
Feel free to fork the repository and submit pull requests.

L<https://github.com/powerman/Narada>

    git clone https://github.com/powerman/Narada.git

=head2 Resources

=over

=item * MetaCPAN Search

L<https://metacpan.org/search?q=Narada>

=item * CPAN Ratings

L<http://cpanratings.perl.org/dist/Narada>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Narada>

=item * CPAN Testers Matrix

L<http://matrix.cpantesters.org/?dist=Narada>

=item * CPANTS: A CPAN Testing Service (Kwalitee)

L<http://cpants.cpanauthors.org/dist/Narada>

=back


=head1 AUTHOR

Alex Efros E<lt>powerman@cpan.orgE<gt>


=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2008- by Alex Efros E<lt>powerman@cpan.orgE<gt>.

This is free software, licensed under:

  The MIT (X11) License


=cut
