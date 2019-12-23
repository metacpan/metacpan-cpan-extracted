package Template::Plugin::Thumbalizr;

use 5.016003;
use strict;
use warnings;

use base 'Template::Plugin';
use WebService::Thumbalizr;

our $VERSION = '1.0.1';




=head1 NAME

Template::Plugin::Thumbalizr - A Thumbalizr (https://thumbalizr.com) plugin for Template::Toolkit. This allows you to easily embed live screenshots into your website.

=head1 SYNOPSIS

  [% USE thumbalizr = Thumbalizr('api_key', 'secret') %]
	<img src="[% thumbalizr.url('https://www.google.com/') %]" />

=head1 DESCRIPTION

Thumbalizr (L<http://www.thumbalizr.com/>) is a web service to easily embed live screenshots of any URL in your website. Thumbalizr has full support for Flash, JavaScript, CSS, & HTML5.

The latest API version is detailed at L<https://www.thumbalizr.com/api/documentation>. WebService::Thumbalizr.

The source code is available on github at L<https://github.com/juliensobrier/thumbalizr-template-toolkit>.


=head1 METHODS

=head2 new()

  [% USE thumbalizr = Thumbalizr('api_key', 'secret') %]

Initialize the Thumbalizr plugin. You must pass your API secret (login to your Thumbalizr account to display your secret).

Arguments:

=over 4

=item api_key

Required. Embed API key.

=item secret

Required. Thumbalizr secret.

=back

=cut

sub new {
	my ($class, $context, $api_key, $secret) = @_;
	
	return $class->fail("API key missing")
		unless $api_key;
        
  return $class->fail("Secret missing")
		unless $secret;
    
  my $thumbalizr = WebService::Thumbalizr->new(key => $api_key, secret => $secret);
  
  
  bless {
		 _CONTEXT 		=> $context,
		 _thumbalizr	=> $thumbalizr,
  }, $class;
  
}


=head2 url()

  <img src="[% thumbalizr.url('https://www.google.com/', size => 'page', bheight => 1280) %]" />

Display the URL of the Thumbalizr screenshot. You can use it as the src attribute of your img tag.

Arguments:

=over 4

=item url

Required. URL of the website to create a screenshot of.

=back

=cut
sub url {
	my ($self, $url, %args) = @_;

	return $self->{_thumbalizr}->url($url, %args);
}


1;
__END__
=head1 SEE ALSO

C<WebService::Thumbalizr>

See L<https://thumbalizr.com/api/documentation> for the API documentation.

Create a free account at L<https://thumbalizr.com/member> to get your free API key.

Go to L<https://thumbalizr.com/member> to find your API key and secret after you registered.

=head1 AUTHOR

Julien Sobrier, E<lt>julien@sobrier.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2019 by Julien Sobrier

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut
