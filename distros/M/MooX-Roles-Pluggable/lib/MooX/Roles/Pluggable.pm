package MooX::Roles::Pluggable;

use 5.008003;
use strict;
use warnings FATAL => 'all';

require Module::Pluggable::Object;

our $VERSION = '0.003';

my %DEFAULT_OPTIONS = (
                        search_path => undef,
                        require     => 1,
                      );

my %role_lists;

sub _roles
{
    defined( $role_lists{ $_[0]->{search_path} } )
      and return $role_lists{ $_[0]->{search_path} };
    my @plugins = Module::Pluggable::Object->new( %{ $_[0] } )->plugins();
    my @roles   = grep {
        my @target_isa;
        { no strict 'refs'; @target_isa = @{ $_ . "::ISA" } };
        0 == scalar @target_isa;
    } @plugins;
    $role_lists{ $_[0]->{search_path} } = \@roles;
}

sub _inject_roles
{
    my ( $target, $options ) = @_;
    my $with = $target->can('with') or return;    # neither a class nor a role ...
    my $roles = _roles($options);

    $with->($_) foreach (@$roles);
}

sub import
{
    my ( undef, @import ) = @_;
    my $target = caller;
    my %options = ( %DEFAULT_OPTIONS, @import );
    defined( $options{search_path} ) or $options{search_path} = "${target}::Role";

    _inject_roles( $target, \%options );

    return;
}

=head1 NAME

MooX::Roles::Pluggable - Moo eXtension for pluggable roles

=head1 SYNOPSIS

    package MyPackage;

    use Moo;

    sub foo { ... }

    use MooX::Roles::Pluggable search_path => 'MyPackage::Role';

    package MyPackage::Role::Bar;

    use Moo::Role;

    around foo => sub {
	...
    };

    1;

=head1 DESCRIPTION

This module allows a class consuming several roles based on rules passed
to L<Module::Pluggable::Object>.

The basic idea behind this tool is the ability to have plugins as roles
which attach themselve using the C<around>, C<before> and C<behind> sugar
of I<Moo(se)>.

The arguments of import are redirected to L<Module::Pluggable::Object>,
with following defaults (unless specified):

=over 4

=item C<search_path>

Default search_path is C<< ${caller}::Role >>.

=item C<require>

Default for require is 1.

=back

=head2 USE WITH CAUTION

Remember that using a module like this which automatically injects code
into your existing and running and (hopefully) well tested programs
and/or modules can be dangerous and should be avoided whenever possible.

=head2 USE ANYWAY

On the other hand, when you're allowing plugins being loaded by your
code, it's probably faster compiling the chain of responsibility once than
doing it at runtime again and again. Allowing plugins changing the
behaviour of your code anyway. When that's the intension, this is your
module.

=head1 AUTHOR

Jens Rehsack, C<< <rehsack at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-moox-roles-pluggable at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=MooX-Roles-Pluggable>.
I will be notified, and then you'll automatically be notified of progress
on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc MooX::Roles::Pluggable

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=MooX-Roles-Pluggable>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/MooX-Roles-Pluggable>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/MooX-Roles-Pluggable>

=item * Search CPAN

L<http://search.cpan.org/dist/MooX-Roles-Pluggable/>

=back

=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2013-2015 Jens Rehsack.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.

=cut

1;    # End of MooX::Roles::Pluggable
