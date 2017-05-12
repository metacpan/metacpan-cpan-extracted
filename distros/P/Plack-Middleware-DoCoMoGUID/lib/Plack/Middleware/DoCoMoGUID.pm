package Plack::Middleware::DoCoMoGUID;

use strict;
use warnings;
our $VERSION = '0.06';
use parent 'Plack::Middleware';

use Plack::Middleware::DoCoMoGUID::HTMLStickyQuery;
use Plack::Middleware::DoCoMoGUID::RedirectFilter;
use Plack::Middleware::DoCoMoGUID::CheckParam;

sub call {
    my ($self, $env) = @_;

    my %params;
    if ( $self->{params} ) {
        $params{params} = $self->{params};
    }
    my $app = Plack::Middleware::DoCoMoGUID::HTMLStickyQuery->wrap($self->app, %params);
    $app = Plack::Middleware::DoCoMoGUID::RedirectFilter->wrap($app, %params);
    $app = Plack::Middleware::DoCoMoGUID::CheckParam->wrap($app, %params);
    return $app->($env);
}

1;
__END__

=head1 NAME

Plack::Middleware::DoCoMoGUID - combine DoCoMoGUID::RedirectFilter and DoCoMoGUID::HTMLStickyQuery.

=head1 SYNOPSIS

  use Plack::Builder;

  builder {
    enable_if { $_[0]->{HTTP_USER_AGENT} =~ m/DoCoMo/i } "DoCoMoGUID";
  };

or add check param

  builder {
    enable_if { $_[0]->{HTTP_USER_AGENT} =~ m/DoCoMo/i } "DoCoMoGUID", params => +{
        'foo' => 'bar',
    };
  };

this will check guid and foo parameter.

=head1 DESCRIPTION

Plack::Middleware::DoCoMoGUID append ?guid=ON to HTML content relative link or form action or Location header of your HTTP_HOST.

If you want not to use with redirect filter and html filter, consider using RedirectFilter or HTMLStickyQuery separatery.

=head1 AUTHOR

Keiji Yoshimi E<lt>walf443 at gmail dot comE<gt>

=head1 SEE ALSO

L<Plack::Middleware::DoCoMoGUID::RedirectFilter>, L<Plack::Middleware::DoCoMoGUID::HTMLStickyQuery>
L<Plack::Middleware::DoCoMoGUID::CheckParam> 

http://www.nttdocomo.co.jp/service/imode/make/content/ip/index.html#imodeid

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
