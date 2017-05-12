use strictures 1;
package Mojito::Template::Role::Javascript;
{
  $Mojito::Template::Role::Javascript::VERSION = '0.24';
}
use Moo::Role;
use MooX::Types::MooseLike::Base qw(:all);
use Data::Dumper::Concise;

=head1 Name

Mojito::Template::Role::Javascript - a class for Javascript resources

=cut

with('Mojito::Role::Config');

has javascripts => (
    is => 'ro',
    isa => ArrayRef,
    lazy => 1,
    builder => '_build_javascripts',
);

sub _build_javascripts {
       [
#          { uri => 'https://ajax.googleapis.com/ajax/libs/jquery/1.7.2/jquery.min.js'},
#          { uri => 'https://ajax.googleapis.com/ajax/libs/jqueryui/1.8.18/jquery-ui.min.js'},
          'jquery/jquery.min.js',
          'javascript/render_page.js',
          'javascript/style.js',
          'javascript/publish.js',
          'syntax_highlight/prettify.js',
          'jquery/jquery-ui.custom.min.js',
          'jquery/jquery.cookie.js',
#          'SHJS/sh_main.min.js',
#          'SHJS/sh_perl.min.js',
#          'SHJS/sh_javascript.min.js',
#          'SHJS/sh_html.min.js',
#          'SHJS/sh_css.min.js',
#          'SHJS/sh_sql.min.js',
#          'SHJS/sh_sh.min.js',
#          'SHJS/sh_diff.min.js',
#          'SHJS/sh_haskell.min.js',
#-concatenation fo the SHJS/sh_$language.js files
          'SHJS/sh_langs.min.js',
       ];
}

has javascript_html => (
    is => 'ro',
    isa => ArrayRef,
    lazy => 1,
    builder => '_build_javascript_html',
);

sub _build_javascript_html {
    my $self = shift;
    my $static_url = $self->config->{static_url};
    my @javascripts; # = map { "<script src=${static_url}$_></script>" } @{$self->javascripts};
    # Local scripts comes as scalars, while remote scripts are a HashRef
    foreach my $script (@{$self->javascripts}) {
        if (ref($script) eq 'HASH') {
            push @javascripts, "<script src=$script->{uri}></script>";
        }
        else { 
            push @javascripts, "<script src=${static_url}$script></script>";
        }
    }
    return [@javascripts];
}

1
