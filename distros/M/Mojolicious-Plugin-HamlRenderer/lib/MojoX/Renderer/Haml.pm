package MojoX::Renderer::Haml;
our $VERSION = '2.100000';

use warnings;
use strict;

use base 'Mojo::Base';

use Mojo::ByteStream 'b';
use Mojo::Exception;
use Text::Haml;

__PACKAGE__->attr(haml_args=>sub { return {}; });

sub build {
    my $self = shift->SUPER::new(@_);
    my %args=@_;
    $self->haml_args(\%args);
    return sub { $self->_render(@_) }
}

my $ESCAPE = <<'EOF';
    my $v = shift;
    ref $v && ref $v eq 'Mojo::ByteStream'
      ? "$v"
      : Mojo::ByteStream->new($v)->xml_escape->to_string;
EOF

sub _render {
    my ($self, $r, $c, $output, $options) = @_;

    # TODO: Handle $options->{inline} ?
    my $name = $r->template_name($options);
    return unless defined $name;

    my $path;
    # FIXME: Does anything set this stash var?  Does it ever exist?
    unless ($path = $c->stash->{'template_path'}) {
        $path = $r->template_path($options);
    }

    my $list = join ', ', sort keys %{$c->stash};
    # If this is a data template path may be blank but name should be what we want.
    my $cache_key = $path || $name;
    my $cache = b("$cache_key($list)")->md5_sum->to_string;

    $r->{_haml_cache} ||= {};

    my $t = $name;

    my $haml = $r->{_haml_cache}->{$cache};

    my %args = (app => $c->app, %{$c->stash});

    # Interpret again
    if ( $c->app->mode ne 'development' &&  $haml && $haml->compiled) {
        $haml->helpers_arg($c);

        $c->app->log->debug("Rendering cached $t.");
        $$output = $haml->interpret(%args);
    }

    # No cache
    else {
        $haml ||= Text::Haml->new(escape => $ESCAPE,%{$self->{haml_args}});

        $haml->helpers_arg($c);
        $haml->helpers($r->helpers);

        # Try template
        if ($path && -r $path) {
            $c->app->log->debug("Rendering template '$t'.");
            $$output = $haml->render_file($path, %args);
        }

        # Try DATA section
        # as of Mojolicious 3.34 get_data_template discards $t
        elsif (my $d = $r->get_data_template($options, $t)) {
            $c->app->log->debug("Rendering template '$t' from DATA section.");
            $$output = $haml->render($d, %args);
        }

        # No template
        else {
            $c->app->log->debug(qq/Template "$t" missing or not readable./);
            return;
        }
    }

    unless (defined $$output) {
        $$output = '';
        die(qq/Template error in "$t": / . $haml->error);
    }

    $r->{_haml_cache}->{$cache} ||= $haml;

    return ref $$output ? die($$output) : 1;
}

1;

=head1 NAME

MojoX::Renderer::Haml - Mojolicious renderer for HAML templates.

=head1 SYNOPSIS

   my $haml = MojoX::Renderer::Haml->build(%$args, mojo => $app);

   # Add "haml" handler
   $app->renderer->add_handler(haml => $haml);

=head1 DESCRIPTION

This module is a renderer for L<HTML::Haml> templates. normally, you 
just want to use L<Mojolicious::Plugin::HamlRenderer>.

=head1 CREDITS

Marcus Ramberg, C<mramberg@cpan.org>

Randy Stauner, C<rwstauner@cpan.org>

=head1 AUTHOR

Viacheslav Tykhanovskyi, C<viacheslav.t@gmail.com>.

Currently maintained by Breno G. de Oliveira, C<garu@cpan.org>.

=head1 COPYRIGHT

Copyright (C) 2008-2012, Viacheslav Tykhanovskyi.

This program is free software, you can redistribute it and/or modify it under
the same terms as Perl 5.10.

=cut
