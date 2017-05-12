
=head1 NAME

<tmpl_var module> - The great new <tmpl_var module> web application!

=head1 SYNOPSIS

    use <tmpl_var module>;
    my $app = <tmpl_var module>->new();
    $app->run();

=head1 ABSTRACT

A brief summary of what <tmpl_var module> does.

=cut

package <tmpl_var module>;

use warnings;
use strict;
use base 'Titanium';
use Carp qw( croak );
use File::ShareDir qw( dist_dir );
use File::Spec qw ();

=head1 VERSION

This document describes <tmpl_var module> Version 0.01

=cut

our $VERSION = '0.01';

=head1 DESCRIPTION

Overview of functionality and purpose of
web application module <tmpl_var module>...

=head1 METHODS

=head2 SUBCLASSED METHODS

=head3 setup

Sets up the run mode dispatch table and the start, error, and default run modes.
If the template path is not set, sets it to a default value.

TODO: change all these values to ones more appropriate for your application.

=cut

sub setup {
    my ($self) = @_;

    $self->start_mode('runmode1');
    $self->error_mode('runmode1');
    $self->run_modes( [qw/ runmode1 /] );
    if ( !$self->tmpl_path ) {
        $self->tmpl_path(
            File::Spec->catdir( dist_dir('<tmpl_var distro>'), 'templates' ) );
    }
    $self->run_modes( AUTOLOAD => 'runmode1' );
    return;
}

=pod

TODO: Other methods inherited from Titanium go here.

=head2 RUN MODES

=head3 runmode1

  * Purpose
  * Expected parameters
  * Function on success
  * Function on failure

TODO: Describe runmode1 here. Rename runmode1 to something more appropriate 
for your application.

=cut

sub runmode1 {
    my ($self) = @_;

    my $template = $self->load_tmpl;
    $template->param( message => 'Hello world!' );
    return $template->output;
}

=head2 OTHER METHODS

=head3 function1

TODO: Describe function1 here.  Rename function1 to something more appropriate
for your application.

=cut

sub function1 {
    my ($self) = @_;

    return 1;
}

=pod

TODO: Other methods in your public interface go here.

=cut

# TODO: Private methods go here. Start their names with an _ so they are skipped
# by Pod::Coverage.

=head1 BUGS AND LIMITATIONS

There are no known problems with this module.

Please report any bugs or feature requests to
C<bug-<tmpl_var rtname> at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=<tmpl_var distro>>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SEE ALSO

L<Titanium|Titanium>

=head1 THANKS

List acknowledgements here or delete this section.

=head1 AUTHOR

<tmpl_var author>, C<< <<tmpl_var email_obfuscated>> >>

=head1 LICENSE AND COPYRIGHT

Copyright (C) <tmpl_var year>, <tmpl_var author>.  All rights reserved.

<tmpl_var license_blurb>

The full text of the license can be found in the LICENSE file included
with this distribution.

=cut

1;    # End of <tmpl_var module>

__END__
