package MozRepl::Plugin::Base;

use strict;
use warnings;

use base qw(Class::Accessor::Fast);

use Carp::Clan qw(croak);
use Template;
use Template::Provider::FromDATA;

__PACKAGE__->mk_accessors($_) for (qw/template/);

=head1 NAME

MozRepl::Plugin::Base - Plugin base class.

=head1 VERSION

version 0.03

=cut

our $VERSION = '0.03';

=head1 SYNOPSIS

    package MozRepl::Plugin::Foo::Bar;

    use strict;
    use warnings;

    use base qw(MozRepl::Plugin::Base);

    sub execute {
        my ($self, $ctx, $args) = @_;

        $ctx->execute(q|window.alert("Anta ga taisho!")|);
    }

    1;

    package main;

    use MozRepl;

    my $repl = MozRepl->new;
    $repl->setup({ plugins => { plugins => [qw/Foo::Bar/] } });
    $repl->foo_bar();

=head1 DESCRIPTION

This module is base class any plugins for MozRepl.

=head1 METHODS

=head2 new($args)

Create instance.

=over 4

=item $args

Hash reference.

=back

=cut

sub new {
    my ($class, $args) = @_;

    my $provider = Template::Provider::FromDATA->new({
        CLASSES => $class
    });
    $args->{template} = Template->new({
        LOAD_TEMPLATES => [$provider],
        PRE_CHOMP => 1
    });

    my $self = $class->SUPER::new($args);

    return $self;
}

=head2 setup($ctx, @args)

Called from L<MozRepl> setup() method.
This is abstract method, If you want to task in setup pharse,
then must be overriding this method.

=over 4

=item $ctx

Context object. See L<MozRepl>

=item @args

Extra parameters.

=back

=cut

sub setup {
    my ($self, $ctx, @args) = @_;
}

=head2 execute($ctx, @args)

Execute plugin method.
Please override me.

=over 4

=item $ctx

Context object. See L<MozRepl>

=item @args

Extra parameters.

=back

=cut

sub execute {
    my ($self, $ctx, @args) = @_;

    croak('Please override this method');
}

=head2 method_name()

If you override this method and return constant string, 
then the string will be used as method name in context.

Not overriding method name will be determined by L<MozRepl::Util> plugin_to_method() method.
See L<MozRepl::Util/plugin_to_method($plugin, $search)>

=cut

sub method_name {
    return "";
}

=head2 process($name, $vars)

Processing template using by L<Template>, L<Template::Provider::FromDATA>.

=over 4

=item $name

Label name in DATA Section.

=item $vars

Append values as hash reference.

=back

=cut

sub process {
    my ($self, $name, $vars) = @_;

    my $output = '';

    $self->template->process($name, $vars, \$output);
    return $output;
}

=head1 SEE ALSO

=over 4

=item L<MozRepl>

=item L<Template>

=item L<Template::Provider::FromDATA>

=back

=head1 AUTHOR

Toru Yamaguchi, C<< <zigorou@cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-mozrepl-plugin-base@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.  I will be notified, and then you'll automatically be
notified of progress on your bug as I make changes.

=head1 COPYRIGHT & LICENSE

Copyright 2007 Toru Yamaguchi, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of MozRepl::Plugin::Base
