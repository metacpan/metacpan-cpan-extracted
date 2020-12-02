package Mojolicious::Plugin::Parametry;

use Mojo::Base 'Mojolicious::Plugin';

use Mojolicious::Plugin::Parametry::Paramer;
use Mojolicious::Plugin::Parametry::ParamerHelpers;


our $VERSION = '1.001001'; # VERSION

sub register {
    my ($self, $app, $conf) = @_;

    $app->helper(
        ($conf->{shortcut_key} // 'P') => sub {
            Mojolicious::Plugin::Parametry::Paramer
            ->__THIS_ISNT_THE_PARAM_YOU_SHOULD_BE_LOOKING_FOR_BLARGGRGTRKASDFHJKTRDHSYTSD(shift)
        });
    $app->helper(
        ($conf->{helpers_key}  // 'PP') => sub {
            Mojolicious::Plugin::Parametry::ParamerHelpers->new(shift)
        });
}

1;

__END__

=encoding utf8

=head1 NAME

Mojolicious::Plugin::Parametry - Mojolicious plugin providing param helpers

=head1 SYNOPSIS

    $self->plugin('Parametry');

    # Trim whitespace on the value of param `the_test_param` and
    # set it to empty string if it doesn't exist:
    my $p  = $self->P->the_test_param;

    # Access `matching` param helper, to gather all params starting with `foo_`
    my $ps = $self->PP->matching('foo_');


    # These are regular helpers, and so available inside templates too:

    <p>Param meow_meow has value <%= P->meow_meow %></p>
    <p>Meowy params: <%= PP->matching(qr/meow/, vals => 1)->join(', ') %></p>


    # And if you're not a fan of 1-letter helper names, you can change them:

    $self->plugin(Parametry
        => shortcut_key => 'paramer', helpers_key => 'param_helpers');
    my $par_val = $self->paramer->the_test;
    my $params  = $self->param_helpers->matching(qr/^foo_/);

=head1 DESCRIPTION

L<Mojolicious::Plugin::Parametry> is a L<Mojolicious> plugin that provides
a simpler (to a taste) way to access parameter values as well as a set of
helpers for managing params and their values.

=head1 CAVEATS

No testing or support has been made for handling multi-value params. Some
helpers provided by the plugin only support params named with valid Perl
method named.

=head1 METHODS

L<Mojolicious::Plugin::Parametry> inherits all methods from
L<Mojolicious::Plugin> and implements the following new ones.

=head2 register

  $plugin->register(Mojolicious->new);

Register plugin in L<Mojolicious> application.

=head1 HELPERS

=head2 C<P>

    $c->P->some_param_value;

    # Equivalent to:
    # ($c->param('some_param_value') // '') =~ s/^\s+|\s+$//gr;

This is the default name for the I<Paramer> shortcut param access helper and
can be changed using C<shortcut_key> plugin configuration key.

To access a param value, make a method call on the object returned by
this helper, with the name of the method matching the name of the param.
If param value is `undef`, the helper will set it to an emptry string. The
helper will also trim leading and trailing whitespace.

B<CAVEATS:> this helper can be used to access only params named with valid
Perl method names and no support for other names is currently planned.

=head2 C<P>

    $c->PP

Provides access to L<Mojolicious::Plugin::Parametry::ParamerHelpers>
object, initialized with the current controller object. Available methods
are:

=head3 C<matching>

    $c->PP->matching('foo_'); # all param names starting with 'foo_'

    # all param values of params whose name match regex /foo/
    $c->PP->matching(qr/foo/, vals => 1);

    # all param names starting with 'foo_', with 'foo_' stripped from names
    $c->PP->matching('foo_', strip => 1);

    # all param names starting with 'foo_', with 'foo_' changed to 'bar_'
    $c->PP->matching('foo_', subst => 'bar_');

    # all param names starting with 'foo_', with 'foo_' changed to 'bar_'
    # returned together with their values, as a hashref
    $c->PP->matching('foo_', subst => 'bar_', as_hash => 1);

Gathers matching params, optionally complemented with their values, and
returns them as a L<Mojo::Collection> (or a hashref, if C<as_hash> is set),
optionally manipulating the names. Available args:

=head4 first positional

    $c->PP->matching('foo_');
    $c->PP->matching(qr/foo.+bar/);

B<Mandatory>. Specifies the matcher for parameter B<name> matching.
Takes either a C<Regexp> object or a plain string. I<String match is anchored
to the start of the parameter name>
(C<'fo.o'> is equivalent to C<qr/^fo\.o/>).

=head4 C<vals>

    $c->PP->matching(qr/foo/, vals => 1);

B<Optional>. Causes the method to return a L<Mojo::Collection> of
the values of parameter whose names match the matcher.

=head4 C<as_hash>

    $c->PP->matching(qr/foo/, as_hash => 1);

B<Optional>. Causes the method to return a I<hashref> where keys are
parameter names
and values are parameter values. No attempt to handle multi-value parameters
is done. This argument takes precedence over C<vals> arugment.

=head4 C<subst>

    # all param names starting with 'foo_', with 'foo_' changed to 'bar_'
    $c->PP->matching('foo_', subst => 'bar_');

B<Optional>. Replaces the matching part of parameter names with
the provided replacement. When used with C<as_hash>, the modified names
will become the new keys (the values are still obtained from original
param names)

=head4 C<subst>

    # all param names starting with 'foo_', with 'foo_' stripped from names
    $c->PP->matching('foo_', strip => 1);

B<Optional>. Alternative way of specifying C<< subst => '' >>

=head1 REPOSITORY

Fork this module on GitHub:
L<https://github.com/zoffixznet/Mojolicious-Plugin-Parametry>

=head1 BUGS

To report bugs or request features, please use
L<https://github.com/zoffixznet/Mojolicious-Plugin-Parametry/issues>

If you can't access GitHub, you can email your request
to C<bug-mojolicious-plugin-parametry at rt.cpan.org>

=head1 AUTHOR

Zoffix Znet C<zoffix at cpan.org>, (L<https://zoffix.com/>)

=head1 LICENSE

You can use and distribute this module under the same terms as Perl itself.
See the C<LICENSE> file included in this distribution for complete
details.

=cut