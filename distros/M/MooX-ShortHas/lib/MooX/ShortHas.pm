package MooX::ShortHas;

use strictures 2;

our $VERSION = '1.172300'; # VERSION

# ABSTRACT: shortcuts for common Moo has attribute configurations

#
# This file is part of MooX-ShortHas
#
#
# Christian Walde has dedicated the work to the Commons by waiving all of his
# or her rights to the work worldwide under copyright law and all related or
# neighboring legal rights he or she had in the work, to the extent allowable by
# law.
#
# Works under CC0 do not require attribution. When citing the work, you should
# not imply endorsement by the author.
#


use Moo::_Utils;

sub _modified_has {
    my ( $has, $mod, $name, @args ) = @_;
    $has->( $name, @{$mod}, @args );
}

sub import {
    my $caller = caller;
    my $has    = $caller->can( "has" ) or die "Moo not loaded in caller: $caller";
    my %mods   = (
        lazy => [qw( is lazy builder )],
        map { $_ => [ is => $_ => required => 1 ] } qw( ro rwp rw )
    );
    for my $mod ( keys %mods ) {
        _install_coderef $caller. "::$mod" => sub {
            _modified_has $has, $mods{$mod}, @_;
        };
    }
}

1;

__END__

=pod

=head1 NAME

MooX::ShortHas - shortcuts for common Moo has attribute configurations

=head1 VERSION

version 1.172300

=head1 SYNOPSIS

Instead of:

    use Moo;
    
    has hro => is => ro => required => 1;
    has hlazy => is => lazy => builder => sub { 2 };
    has hrwp => is => rwp => required => 1;
    has hrw => is => rw => required => 1;

You can now write:

    use Moo;
    use MooX::ShortHas;
    
    ro "hro";
    lazy hlazy => sub { 2 };
    rwp "hrwp";
    rw "hrw";

And options can be added or overriden by appending them:

    ro hro_opt => required => 0;

=head1 DESCRIPTION

L<Moo>'s C<has> asks developers to repeat themselves a lot to set up attributes,
and since its inceptions the most common configurations of attributes have
crystallized through long usage.

This module provides sugar shortcuts that wrap around has under the appropriate
names to reduce the effort of setting up an attribute to naming it with a
shortcut.

=head1 EXPORTS

=head2 ro, rwp, rw

These three work the same, they convert a call like this:

    ro $name => @extra_args;

To this corresponding has call:

    has $name => is => ro => required => 1 => @extra_args;

The appending of extra args  makes it easy to override the required if
necessary.

=head2 lazy

This one is slightly different than the others, as lazy arguments don't require
a constructor value, but almost always want a builder of some kind:

    lazy $name => @extra_args;

Corresponds to:

    has $name => is => lazy => builder => @extra_args;

The first extra argument is thus expected to be any of the values appropriate
for the builder option.

=head1 SEE ALSO

=over

=item *

L<Mu> - automatically wraps this module into Moo

=item *

L<Mu::Role> - automatically wraps this module into Moo::Role

=back

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/wchristian/MooX-ShortHas/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/wchristian/MooX-ShortHas>

  git clone https://github.com/wchristian/MooX-ShortHas.git

=head1 AUTHOR

Christian Walde <walde.christian@gmail.com>

=head1 CONTRIBUTOR

=for stopwords mst - Matt S. Trout (cpan:MSTROUT)

mst - Matt S. Trout (cpan:MSTROUT) <mst@shadowcat.co.uk>

=head1 COPYRIGHT AND LICENSE


Christian Walde has dedicated the work to the Commons by waiving all of his
or her rights to the work worldwide under copyright law and all related or
neighboring legal rights he or she had in the work, to the extent allowable by
law.

Works under CC0 do not require attribution. When citing the work, you should
not imply endorsement by the author.

=cut
