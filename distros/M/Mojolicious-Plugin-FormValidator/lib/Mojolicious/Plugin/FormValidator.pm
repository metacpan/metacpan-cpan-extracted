package Mojolicious::Plugin::FormValidator;

use Mojo::Base 'Mojolicious::Plugin';

use Data::FormValidator;

our $VERSION = '0.01';

our $results;

sub dfv_verify {
    my ($route, $c, $captures, $profile) = @_;
    return undef unless $profile;

    my $input_hash = $c->req->params->to_hash;
    _dfv_verify($c, $input_hash, $profile);

    return 1;
}

sub register {
    my ($self, $app) = @_;

    $app->helper(_dfv_error => sub {
        my $self = shift;
        my $field = shift;

        return 0 if !defined $results;
        return 0 if $results->valid($field);
        return 1 if $results->invalid($field);
        return 1 if $results->missing($field);

        return 0;
    });

    return $app->routes->add_condition(dfv_verify => \&dfv_verify);
}

sub _dfv_verify {
    my $c = shift;
    my $input_hash = shift;
    my $dfv_profile = shift;

    my $r = Data::FormValidator->check($input_hash, $dfv_profile);

    my @fields = ();
    my $required = $r->{profile}{required};
    my $optional = $r->{profile}{optional};

    push(@fields, @$required);
    push(@fields, @$optional);

    for my $field (@fields) {
        $c->stash->{$field} = $c->req->param($field) // "";
    }

    return if 0 == keys %$input_hash;

    $results = $r;
}

1;

__END__

=head1 NAME

Mojolicious::Plugin::FormValidator - Mojolicious Plugin

=head1 SYNOPSIS

  # Mojolicious
  $self->plugin('FormValidator');

  # Mojolicious::Lite
  plugin 'FormValidator';

=head1 DESCRIPTION

L<Mojolicious::Plugin::FormValidator> is a L<Mojolicious> plugin.

=head1 METHODS

L<Mojolicious::Plugin::FormValidator> inherits all methods from
L<Mojolicious::Plugin> and implements the following new ones.

=head2 register

  $plugin->register(Mojolicious->new);

Register plugin in L<Mojolicious> application.

=head1 SEE ALSO

L<Mojolicious>, L<Mojolicious::Guides>, L<http://mojolicio.us>.

=cut
