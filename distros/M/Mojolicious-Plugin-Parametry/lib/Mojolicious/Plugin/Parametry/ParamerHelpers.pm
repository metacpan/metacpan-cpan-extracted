package Mojolicious::Plugin::Parametry::ParamerHelpers;

use strict;
use warnings;
use Mojo::Collection;

our $VERSION = '1.001001'; # VERSION

sub new { bless { _c => $_[1] }, $_[0] }

sub matching {
    my ($self, $re, %args) = @_;
    my $c = $self->{_c};

    $re = qr/^\Q$re\E/ unless ref $re eq 'Regexp';
    my $params = Mojo::Collection->new(grep /$re/, $c->req->params->names->@*);


    if ($args{as_hash}) {
        return +{ $params->map(sub {
            my $orig_name = $_;
            $args{subst} and s/$re/$args{subst}/;
            $args{strip} and s/$re//;
            $_ => $c->param($orig_name)
        })->each }
    }

    $args{vals}
        and return $params->map(sub {$c->param($_)});

    $args{subst} and $params = $params->map(sub {s/$re/$args{subst}/r});
    $args{strip} and $params = $params->map(sub {s/$re//r});
    $params
}

1;

__END__

=encoding utf8

=head1 NAME

Mojolicious::Plugin::Parametry::ParamerHelpers - parameter helpers

=head2 Methods

See C<PP> helper documentation in L<Mojolicious::Plugin::Parametry>

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