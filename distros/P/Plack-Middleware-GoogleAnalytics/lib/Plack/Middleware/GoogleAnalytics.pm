package Plack::Middleware::GoogleAnalytics; 
use Moo;
use Plack::Util;
use Text::MicroTemplate qw(:all);
use 5.008008;

extends 'Plack::Middleware';

our $VERSION = '0.01';

has 'ga_id' => (
    is => 'ro',
);

has 'ga_template' => (
    is => 'ro',
    default => sub {<<'EOF'}
<script type="text/javascript">

  var _gaq = _gaq || [];
  _gaq.push(['_setAccount', '<?= $_[0] ?>']);
  _gaq.push(['_trackPageview']);

  (function() {
    var ga = document.createElement('script'); ga.type = 'text/javascript'; ga.async = true;
    ga.src = ('https:' == document.location.protocol ? 'https://ssl' : 'http://www') + '.google-analytics.com/ga.js';
    var s = document.getElementsByTagName('script')[0]; s.parentNode.insertBefore(ga, s);
  })();

</script>
EOF
);
 
sub call {
    my ($self, $env) = @_;

    my $response = $self->app->($env);
    $self->response_cb($response, sub { $self->_handle_response(shift) });
}

sub _handle_response {
    my ($self, $response)   = @_;
    my $header              = Plack::Util::headers($response->[1]);
    my $content_type        = $header->get('Content-Type');
    my $ga_id               = $self->ga_id;
    
    return unless defined $content_type && $content_type =~ qr[text/html] && $ga_id;
    
    my $body = [];
    Plack::Util::foreach( $response->[2], sub { push @$body, $_[0] });
    $body = join '', @$body;

    $body .= render_mt($self->ga_template, $ga_id)->as_string;
    
    $response->[2] = [$body];
    $header->set('Content-Length', length $body);

    return;
}

1;
=head1 NAME

Plack::Middleware::GoogleAnalytics - Middleware to apply Google Anlytics javascript code.

=head1 SYNOPSIS

    use Plack::Builder;

    builder {
        enable "Plack::Middleware::GoogleAnalytics", ga_id => 'UA-214112-11';
        $app;
    };

=head1 DESCRIPTION

L<Plack::Middleware::GoogleAnalytics> will insert the standard google analytics 
Javascript at the end of a text/html document. It places this boilerplate code at the
end of the document.

=head1 ARGUMENTS

This middleware accepts the following arguments.

=head2 ga_id

This is the id that is supplied by Google. This is a required argument.

=head1 SEE ALSO

L<Plack>, L<Plack::Middleware>, L<Moo> 

=head1 AUTHOR

Logan Bell, C<< <logie@cpan.org> >>

=head1 COPYRIGHT & LICENSE

Copyright 2012, Logan Bell

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

