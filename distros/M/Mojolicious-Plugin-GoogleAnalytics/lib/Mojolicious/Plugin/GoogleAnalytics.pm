package Mojolicious::Plugin::GoogleAnalytics;
# ABSTRACT: GoogleAnalytics plugin
$Mojolicious::Plugin::GoogleAnalytics::VERSION = '1.005';

use Mojo::Base 'Mojolicious::Plugin';

has 'template' => 'analytics_template';

sub register {
    my ($plugin, $app) = (shift, shift);
    push @{$app->renderer->classes}, __PACKAGE__;

    $app->helper(analytics => sub {$plugin});

    $app->helper(
        analytics_inc => sub {
            my $self                  = shift;
            my $analytics_id          = shift;
            my $domain_sub            = shift;
            my $allow_multi_top_level = shift;

            die "No analytics ID defined" unless defined $analytics_id;
            $self->render(
                template              => $self->analytics->template,
                partial               => 1,
                analytics_id          => $analytics_id,
                domain_sub            => $domain_sub,
                allow_multi_top_level => $allow_multi_top_level || undef,
            );
        }
    );
}

1;

=pod

=encoding UTF-8

=head1 NAME

Mojolicious::Plugin::GoogleAnalytics - GoogleAnalytics plugin

=head1 VERSION

version 1.005

=head1 SYNOPSIS

  # Mojolicious
  $self->plugin('GoogleAnalytics');

  # Mojolicious::Lite
  plugin 'GoogleAnalytics';

  # In your layout template
  <%= analytics_inc 'UA-32432-1', 'example.com', 1 %>
  </head> <!-- Make sure its just before closing head tag -->

=head1 DESCRIPTION

L<Mojolicious::Plugin::GoogleAnalytics> is a L<Mojolicious>
plugin. Inserts Google Analytics code and associates your analytics
id.

=head1 METHODS

=head2 register

  $plugin->register(Mojolicious->new);

Register plugin in L<Mojolicious> application.

=head1 OPTIONS

=head2 Track Subdomains

Put the domain which qualifies any subdomains you wish to track,
eg. blog.example.com, apps.example.com will have the second arguement
set to 'example.com'

=head2 Multiple top level domains

Default is set to 1 to allow domains such as example.fr, example.cn,
and example.com

=head1 AUTHOR

Adam Stokes <adamjs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Adam Stokes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT
WHEN OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER
PARTIES PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND,
EITHER EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
PURPOSE. THE ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE
SOFTWARE IS WITH YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME
THE COST OF ALL NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE LIABLE
TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE THE
SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH
DAMAGES.

=cut

__DATA__

@@ analytics_template.html.ep

%= javascript begin
  var _gaq = _gaq || [];
  _gaq.push(['_setAccount', '<%= $analytics_id %>']);
  % if ($domain_sub) {
  _gaq.push(['_setDomainName', '<%= $domain_sub %>']);
  % }
  % if ($allow_multi_top_level) {
  _gaq.push(['_setAllowLinker', true]);
  % }
  _gaq.push(['_trackPageview']);

  (function() {
    var ga = document.createElement('script'); ga.type = 'text/javascript'; ga.async = true;
    ga.src = ('https:' == document.location.protocol ? 'https://ssl' : 'http://www') + '.google-analytics.com/ga.js';
    var s = document.getElementsByTagName('script')[0]; s.parentNode.insertBefore(ga, s);
  })();
%= end

