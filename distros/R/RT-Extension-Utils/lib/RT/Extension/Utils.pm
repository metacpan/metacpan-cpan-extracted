use 5.008003;
use strict;
use warnings;

package RT::Extension::Utils;

our $VERSION = '0.06';

=head1 NAME

RT::Extension::Utils - collection of command line utilities

=head1 DESCRIPTION

This extension is collection of variouse command line utilities
for Request Tracker. Mostly these are tools for system administrators
for debugging and instrumenting.

=head1 INSTALLAION

As usuall:

    perl Makefile.PL
    make
    make install

Don't forget to register extension in @Plugins config option:

    Set( @Plugins, qw(
        RT::Extesion::Utils
    ));

Without registering some utilities will fail to work.

=head1 FOR UTILITIES WRITERS

=head2 METHODS

=head3 require_module $module $version

Loads a module and checks version. It doesn't die on error, but exit with
exit code 1. As this extension consist of many different scripts that may
require variouse modules from then CPAN, then all dependencies are not
announced during installtion.

=cut

sub require_module {
    my ($self, $module, $version) = @_;

    local $@;
    eval "require $module; 1" or do {
        print STDERR "$@\n\n";
        if ( $@ =~ /^Can't locate / ) {
            print STDERR "Can not load $module. Either module itself or one of its"
                ." dependencies is not installed. $0 script depends on"
                . (defined $version? " version $version of": '') ." $module.\n\n"
                ."Install it from the CPAN using cpan shell, manually or using"
                ." package manager of your system.\n";
        }
        else {
            print STDERR "Can not load $module. Looks like it's installed,"
                ." but broken. It can be permissions on files, missing/uninstalled/deleted"
                ." critical files, libraries or anything else.\n\n"
                ." FULL ERROR IS ABOVE. You should fix this issue before"
                ." you can use $0 script.\n";
        }
        exit 1;
    };
    if ( defined $version ) {
        eval { $module->VERSION($version); 1 } or do {
            print STDERR "$@\n\n";
            if ( $@ =~ /^\Q$module\E version \Q$version\E required/ ) {
                print STDERR "$module is too old."
                    ." Install newer version from the CPAN using cpan shell,"
                    ." manually or using package manager of your system.\n";
            }
            else {
                print STDERR "Can not check version of $module.\n\n"
                    ." FULL ERROR IS ABOVE. You should fix this issue before"
                    ." you can use $0 script.\n";
            }
            exit 1;
        };
    }
}

=head1 LICENSE

Under the same terms as perl itself.

=head1 AUTHOR

Ruslan Zakirov E<lt>Ruslan.Zakirov@gmail.comE<gt>

=cut

1;
