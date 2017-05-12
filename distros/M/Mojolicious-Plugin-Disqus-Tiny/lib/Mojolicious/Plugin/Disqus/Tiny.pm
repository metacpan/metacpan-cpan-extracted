# ABSTRACT: Mojolicious plugin for integrating Disqus forum

package Mojolicious::Plugin::Disqus::Tiny;

use Mojo::Base 'Mojolicious::Plugin';

our $VERSION = '1.004';

has 'template' => 'disqus_template';

sub register {
    my ( $plugin, $app ) = ( shift, shift );
    push @{ $app->renderer->classes }, __PACKAGE__;

    $app->helper( disqus => sub { $plugin } );

    $app->helper(
        disqus_inc => sub {
            my $self     = shift;
            my $forum_id = shift;

            die "No disqus ID defined" unless defined $forum_id;
            $self->render_to_string( $self->disqus->template,
                forum_id => $forum_id );
        }
    );
}

1;

__DATA__

@@ disqus_template.html.ep

<div id="disqus_thread"></div>
<script type="text/javascript">
   var disqus_shortname = '<%= stash("forum_id") %>';
   (function() {
   var dsq = document.createElement('script'); dsq.type = 'text/javascript'; dsq.async = true;
   dsq.src = '//' + disqus_shortname + '.disqus.com/embed.js';
   (document.getElementsByTagName('head')[0] || document.getElementsByTagName('body')[0]).appendChild(dsq);
   })();
</script>
<noscript>Please enable JavaScript to view the <a href="http://disqus.com/?ref_noscript">comments powered by Disqus.</a></noscript>

__END__

=head1 NAME

Mojolicious::Plugin::Disqus::Tiny - Mojolicious Plugin

=head1 SYNOPSIS

  # Mojolicious
  $self->plugin('Disqus::Tiny');

  # Mojolicious::Lite
  plugin 'Disqus::Tiny';

  # In the template where comments should be
  <%= disqus_inc 'astokes' %>

=head1 DESCRIPTION

L<Mojolicious::Plugin::Disqus::Tiny> is a L<Mojolicious> plugin. Inserts Disqus code and associates your forum id. If you need more control over api please see L<Mojolicious::Plugin::Disqus>. In order to get the B<shortname> visit L<https://disqus.com> and check your dashboard.

=head1 METHODS

L<Mojolicious::Plugin::Disqus::Tiny> inherits all methods from
L<Mojolicious::Plugin> and implements the following new ones.

=head2 register

  $plugin->register(Mojolicious->new);

Register plugin in L<Mojolicious> application.

=head1 AUTHOR

Adam Stokes L<adamjs@cpan.org>

=head1 COPYRIGHT

Copyright 2013- Adam Stokes

=head1 LICENSE

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 SEE ALSO

L<Mojolicious::Plugin::Disqus>, L<Mojolicious>, L<Mojolicious::Guides>, L<http://mojolicio.us>.

=cut
