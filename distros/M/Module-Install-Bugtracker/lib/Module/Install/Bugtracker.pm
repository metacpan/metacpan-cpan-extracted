package Module::Install::Bugtracker;
use 5.006;
use strict;
use warnings;
use URI::Escape;
use base qw(Module::Install::Base);

our $VERSION = sprintf "%d.%02d%02d", q/0.3.4/ =~ /(\d+)/g;

sub auto_set_bugtracker {
    my $self = shift;
    if ($self->name) {
        $self->configure_requires('URI::Escape', 0);

        $self->bugtracker(
            sprintf 'http://rt.cpan.org/Public/Dist/Display.html?Name=%s',
            uri_escape($self->name),
        );
    } else {
        warn "can't set bugtracker if 'name' is not set\n";
    }
}
1;
__END__

=for test_synopsis
BEGIN { $INC{'inc/Module/Install.pm'} = 'dummy'; }
sub name ($) {}
sub auto_set_bugtracker () {}

=head1 NAME

Module::Install::Bugtracker - A Module::Install extension that automatically sets the CPAN bugtracker URL

=head1 SYNOPSIS

    # in Makefile.PL
    use inc::Module::Install;
    name 'Foo-Bar';
    auto_set_bugtracker;

=head1 DESCRIPTION

This is a plugin for L<Module::Install> to automatically set the bugtracker URL
via C<bugtracker()> which will then be added to resources under I<META.yml>.

At present this module only support CPAN bug trackers, resulting in links such
as https://rt.cpan.org/Dist/Display.html?Name=Module-Install-Bugtracker

=head1 FUNCTIONS

=over 4

=item C<auto_set_bugtracker>

Sets the bugtracker URL via L<Module::Install>'s C<bugtracker()> function. The
C<name()> needs to be set before calling this function.

=back

=head1 BUGS AND LIMITATIONS

Please report any bugs or feature requests through the web interface at
L<https://rt.cpan.org/Dist/Display.html?Name=Module-Install-Bugtracker>.

=head1 INSTALLATION

See perlmodinstall for information and options on installing Perl modules.

=head1 AVAILABILITY

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit L<http://www.perl.com/CPAN/> to find a CPAN
site near you. Or see L<http://search.cpan.org/dist/Module-Install-Bugtracker/>.

The development version lives at
L<http://github.com/coppit/module-install-bugtracker/>. Instead of sending
patches, please fork this project using the standard git and github
infrastructure.

=head1 AUTHORS

David Coppit, C<< <david@coppit.org> >>

Marcel GrE<uuml>nauer, C<< <marcel@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright 2015, David Coppit. Prior versions copyright Marcel GrE<uuml>nauer.

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. See the file LICENSE in the distribution for
details.


=head1 SEE ALSO

L<Module::Install>

=cut

