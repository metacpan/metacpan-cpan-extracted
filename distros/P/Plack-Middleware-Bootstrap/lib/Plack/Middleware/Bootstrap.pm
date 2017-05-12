package Plack::Middleware::Bootstrap;
use 5.008001;
use strict;
use warnings;

our $VERSION = "0.08";

use parent qw(Plack::Middleware);
use Plack::Util ();
use Plack::Response;

use Text::MicroTemplate::DataSection qw();
use HTML::TreeBuilder::XPath;

sub call {
    my ($self, $env) = @_;

    Plack::Util::response_cb(
        $self->app->($env),
        sub {
            my $res = shift;

            my $plack_res = Plack::Response->new(@$res);
            return unless $plack_res->content_type =~ /\Atext\/html/;
            return if $plack_res->content_encoding;

            my $content;
            Plack::Util::foreach($res->[2] || [], sub { $content .= $_[0] });

            my $tree = HTML::TreeBuilder::XPath->new();
            $tree->ignore_unknown(0);
            $tree->store_comments(1);
            $tree->parse_content($content);

            my $head = join "\n", map { ref($_) ? $_->as_HTML(q{&<>'"}, '', {}) : $_ } $tree->findnodes('//head')->[0]->content_list;
            my $body = join "\n", map { ref($_) ? $_->as_HTML(q{&<>'"}, '', {}) : $_ } $tree->findnodes('//body')->[0]->content_list;

            my $renderer = Text::MicroTemplate::DataSection->new(
                escape_func => undef
            );

            # render_mt returns Text::MicroTemplate::EncodedString.
            $res->[2] = [ $renderer->render_mt('template.mt', $head, $body).q() ];

            Plack::Util::header_remove($res->[1], 'Content-Length');
        });
}

1;
__DATA__
@@ template.mt
? my ($head, $body) = @_;
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.1/css/bootstrap.min.css">
    <!-- HTML5 shim and Respond.js for IE8 support of HTML5 elements and media queries -->
    <!-- WARNING: Respond.js doesn't work if you view the page via file:// -->
    <!--[if lt IE 9]>
      <script src="https://oss.maxcdn.com/html5shiv/3.7.2/html5shiv.min.js"></script>
      <script src="https://oss.maxcdn.com/respond/1.4.2/respond.min.js"></script>
    <![endif]-->
?= $head
  </head>
  <body>
    <div class="container">
?= $body
    </div>
    <!-- jQuery (necessary for Bootstrap's JavaScript plugins) -->
    <script src="https://ajax.googleapis.com/ajax/libs/jquery/1.11.1/jquery.min.js"></script>
    <!-- Include all compiled plugins (below), or include individual files as needed -->
    <script src="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.1/js/bootstrap.min.js"></script>
  </body>
</html>
__END__

=encoding utf-8

=head1 NAME

Plack::Middleware::Bootstrap - A Plack Middleware to prettify simple HTML with Bootstrap design template

=head1 SYNOPSIS

    use Plack::Builder;

    my $app = sub {
        return [
            200,
            [ 'Content-Type' => 'text/html' ],
            [ "<head><title>Hello!</title></head><body><h1>Hello</h1>\n<p>World!</p></body>" ]
        ];
    };
    builder {
        enable "Bootstrap";
        $app;
    };

And you will get

    <!DOCTYPE html>
    <html lang="en">
      <head>
        <meta charset="utf-8">
        <meta http-equiv="X-UA-Compatible" content="IE=edge">
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.1/css/bootstrap.min.css">
        <!-- HTML5 shim and Respond.js for IE8 support of HTML5 elements and media queries -->
        <!-- WARNING: Respond.js doesn't work if you view the page via file:// -->
        <!--[if lt IE 9]>
          <script src="https://oss.maxcdn.com/html5shiv/3.7.2/html5shiv.min.js"></script>
          <script src="https://oss.maxcdn.com/respond/1.4.2/respond.min.js"></script>
        <![endif]-->
    <title>Hello!</title>
      </head>
      <body>
        <div class="container">
    <h1>Hello</h1>
    <p>World!</p>
        </div>
        <!-- jQuery (necessary for Bootstrap's JavaScript plugins) -->
        <script src="https://ajax.googleapis.com/ajax/libs/jquery/1.11.1/jquery.min.js"></script>
        <!-- Include all compiled plugins (below), or include individual files as needed -->
        <script src="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.1/js/bootstrap.min.js"></script>
      </body>
    </html>

=head1 DESCRIPTION

Plack::Middleware::Bootstrap pretifies HTML with Bootstrap design template.

Plack::Middleware::Bootstrap provides better design to simple HTML.

For example, You can generate simple HTML document with some tool, and prettify with Plack::Middleware::Bootstrap.

=head1 SEE ALSO

=over

=item * L<http://getbootstrap.com/>

=item * L<Plack::Middleware>

=item * L<Plack::Builder>

=back

=head1 LICENSE

Copyright (C) hitode909.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

hitode909 E<lt>hitode909@gmail.comE<gt>

=cut

