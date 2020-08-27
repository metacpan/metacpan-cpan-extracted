package OpenTracing::Integration;

use strict;
use warnings;

our $VERSION = '1.003'; # VERSION
our $AUTHORITY = 'cpan:TEAM'; # AUTHORITY

no indirect;
use utf8;

=encoding utf8

=head1 NAME

OpenTracing::Integration - top-level class for integrating OpenTracing
with other Perl modules

=head1 SYNOPSIS

 # Apply tracing for specific modules
 use OpenTracing::Integration qw(HTTP::Tiny DBI);

 # Trace every module we know about
 use OpenTracing::Integration qw(:all);

=head1 DESCRIPTION

This is the base rôle for handling tracing integration with other CPAN modules.

It provides functionality for loading available integrations
via the import list on a C<use> statement:

=over 4

=item * with C<:all>, any module that supports OpenTracing will be pulled in, if the module-to-be-traced is already loaded

=item * with a specific list of modules, these will be applied unconditionally, loading the modules-to-be-traced as required

=back

This means that you can expect L<HTTP::Tiny> to be traced
if you do this:

 use OpenTracing::Integration qw(HTTP::Tiny);

or this:

 use HTTP::Tiny;
 use OpenTracing::Integration qw(:all);

but it will B<not> be traced if you do this:

 use OpenTracing::Integration qw(:all);
 use HTTP::Tiny;

The reason for this inconsistent behaviour is simple:
with a large install, C<:all> might pull in a lot of
unwanted modules. Instead, you'd do this at the end
of your module imports, and any functionality that
you're actively using in the code would gain tracing,
if available.

=cut

use Syntax::Keyword::Try;
use Module::Pluggable;
use Module::Load ();
use List::Util qw(uniqstr);

use Role::Tiny;

use Log::Any qw($log);

sub import {
    my ($class, @args) = @_;
    return unless @args;

    # If we have an explicit list, then we load
    # dependencies - this is turned off by :all tag
    my $load_deps = 1;

    my @modules;
    for my $target (@args) {
        # Try to load *all* available integrations
        if($target eq ':all') {
            push @modules, $class->plugins;
            $load_deps = 0;
        } else {
            push @modules, __PACKAGE__ . '::' . $target;
        }
    }

    for my $module (uniqstr @modules) {
        try {
            $log->tracef('Loading [%s]', $module);
            Module::Load::load($module);
            $module->load($load_deps);
        } catch {
            # Just a warning, if we're loading everything then
            # we shouldn't cause chaos just because something
            # doesn't happen to be available.
            $log->warnf('Unable to loading OpenTracing integration %s - %s', $module, $@);
        }
    }
}

1;

__END__

=head1 AUTHOR

Tom Molesworth C<< TEAM@cpan.org >>

=head1 LICENSE

Copyright Tom Molesworth 2018-2020. Licensed under the same terms as Perl itself.

