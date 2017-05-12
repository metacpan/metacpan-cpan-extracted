package Prophet::Server::ViewHelpers;
{
  $Prophet::Server::ViewHelpers::VERSION = '0.751';
}

use warnings;
use strict;

use base 'Exporter::Lite';
use Params::Validate qw/validate/;
use Template::Declare::Tags;
use Prophet::Web::Field;
our @EXPORT =
  (qw(form page content widget function param_from_function hidden_param));
use Prophet::Server::ViewHelpers::Widget;
use Prophet::Server::ViewHelpers::Function;
use Prophet::Server::ViewHelpers::ParamFromFunction;
use Prophet::Server::ViewHelpers::HiddenParam;

sub page (&;$) {
    unshift @_, undef if $#_ == 0;
    my ( $meta, $code ) = @_;

    sub {
        my $self  = shift;
        my @args  = @_;
        my $title = $self->default_page_title;
        $title = $meta->( $self, @args ) if $meta;
        html {
            attr { xmlns => 'http://www.w3.org/1999/xhtml' };
            show( 'head' => $title );
            body {
                div {
                    class is 'page';
                    show( 'header', $title );
                    div {
                        class is 'body';
                        $code->( $self, @args );
                    }
                }

            };
            show('footer');
        }

      }
}

sub content (&) {
    my $sub_ref = shift;
    return $sub_ref;
}

sub function {
    my $f = Prophet::Server::ViewHelpers::Function->new(@_);
    $f->render;
    return $f;
}

sub param_from_function {
    my $w = Prophet::Server::ViewHelpers::ParamFromFunction->new(@_);
    $w->render;
    return $w;
}

sub hidden_param {
    my $w = Prophet::Server::ViewHelpers::HiddenParam->new(@_);
    $w->render;
    return $w;
}

sub widget {
    my $w = Prophet::Server::ViewHelpers::Widget->new(@_);
    $w->render;
    return $w;
}

BEGIN {
    no warnings 'redefine';
    *old_form = \&form;
    *form     = sub (&;$) {
        my $code = shift;
        old_form(
            sub {
                attr { method => 'post' };
                $code->(@_);
            }
        );
      }
}

1;

__END__

=pod

=head1 NAME

Prophet::Server::ViewHelpers

=head1 VERSION

version 0.751

=head1 AUTHORS

=over 4

=item *

Jesse Vincent <jesse@bestpractical.com>

=item *

Chia-Liang Kao <clkao@bestpractical.com>

=item *

Christine Spang <christine@spang.cc>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2009 by Best Practical Solutions.

This is free software, licensed under:

  The MIT (X11) License

=head1 BUGS AND LIMITATIONS

You can make new bug reports, and view existing ones, through the
web interface at L<https://rt.cpan.org/Public/Dist/Display.html?Name=Prophet>.

=head1 CONTRIBUTORS

=over 4

=item *

Alex Vandiver <alexmv@bestpractical.com>

=item *

Casey West <casey@geeknest.com>

=item *

Cyril Brulebois <kibi@debian.org>

=item *

Florian Ragwitz <rafl@debian.org>

=item *

Ioan Rogers <ioanr@cpan.org>

=item *

Jonas Smedegaard <dr@jones.dk>

=item *

Kevin Falcone <falcone@bestpractical.com>

=item *

Lance Wicks <lw@judocoach.com>

=item *

Nelson Elhage <nelhage@mit.edu>

=item *

Pedro Melo <melo@simplicidade.org>

=item *

Rob Hoelz <rob@hoelz.ro>

=item *

Ruslan Zakirov <ruz@bestpractical.com>

=item *

Shawn M Moore <sartak@bestpractical.com>

=item *

Simon Wistow <simon@thegestalt.org>

=item *

Stephane Alnet <stephane@shimaore.net>

=item *

Unknown user <nobody@localhost>

=item *

Yanick Champoux <yanick@babyl.dyndns.org>

=item *

franck cuny <franck@lumberjaph.net>

=item *

robertkrimen <robertkrimen@gmail.com>

=item *

sunnavy <sunnavy@bestpractical.com>

=back

=cut
