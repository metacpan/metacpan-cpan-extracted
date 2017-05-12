package Puncheur::Dispatcher::PHPish;
use strict;
use warnings;
use utf8;
use File::Spec;

# TODO register controllers
# sub new { bless {}, shift }

sub dispatch {
    my ($self, $c) = @_;

    my $template_dir = $c->template_dir;

    my $path_info //= $c->req->env->{PATH_INFO};
    $path_info =~ s!(?:index)?/+\z!!ms;

    return $c->res_404 if $path_info =~ m![^a-zA-Z0-9/_]!;
    return $c->res_404 if $path_info =~ m!/[^a-zA-Z0-9]!;

    for my $template_dir (@{ $c->template_dir }) {
        for my $prefix ('', 'index') {
            my $tmpl_path = File::Spec->catfile($template_dir, $path_info, $prefix ? $prefix : ());

            next if $prefix eq '' && $path_info eq '';
            return $c->render($tmpl_path) if -e $tmpl_path . '.mt';
        }
    }
    $c->res_404;
}

1;
