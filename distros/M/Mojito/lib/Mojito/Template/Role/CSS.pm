use strictures 1;
package Mojito::Template::Role::CSS;
$Mojito::Template::Role::CSS::VERSION = '0.25';
use Moo::Role;
use MooX::Types::MooseLike::Base qw(:all);

=head1 Name

Mojito::Template::Role::CSS - a class for CSS resources

=cut

with('Mojito::Role::Config');

has css => (
    is => 'ro',
    isa => ArrayRef,
    lazy => 1,
    builder => '_build_css',
);

sub _build_css {
    [
      'css/ui-lightness/jquery-ui.custom.css',
      'syntax_highlight/prettify_mojito.css',
      'SHJS/sh_mojito.css',
      'css/mojito.css',
    ];
}

has css_html => (
    is => 'ro',
    isa => ArrayRef,
    lazy => 1,
    builder => '_build_css_html',
);

sub _build_css_html {
    my $self = shift;
    my $static_url = $self->config->{static_url};
    my @css =  map { "<link href=${static_url}$_ type=text/css rel=stylesheet />" } @{$self->css};
    [@css];
}

1
