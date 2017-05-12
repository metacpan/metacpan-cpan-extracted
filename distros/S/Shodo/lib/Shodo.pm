package Shodo;
use 5.008005;
use strict;
use warnings;
use Shodo::Suzuri;
use Shodo::Hanshi;
use Path::Tiny qw/path/;

our $VERSION = "0.08";

sub new {
    my ($class, %args) = @_;
    my $self = bless {
        template => $args{template},
        document_root => $args{document_root} ? path($args{document_root}) : path('.'),
    }, $class;
    $self->{stock} = '';
    $self;
}

sub template {
    my ($self, $tmpl) = @_;
    return $self->{template} unless $tmpl;
    $self->{template} = $tmpl;
    return $self->{template};
}

sub document_root {
    my ($self, $path) = @_;
    return $self->{document_root} unless $path;
    $self->{document_root} = path($path);
    return $self->{document_root};
}

sub new_suzuri {
    my ($self, $description) = @_;
    my $hanshi = Shodo::Hanshi->new(
        template => $self->template,
    );
    return Shodo::Suzuri->new(
        hanshi => $hanshi,
        description => $description,
        document_root => $self->document_root
    );
}

sub stock {
    my ($self, $doc) = @_;
    return $self->{stock} unless $doc;
    $self->{stock} .= $doc;
    return $self->{stock};
}

sub write {
    my ($self, $filename) = @_;
    Carp::croak "Document root is not direcotry: " . $self->document_root unless( -d $self->document_root );
    my $file = $self->document_root->child($filename);
    $file->spew_utf8( $self->stock );
    $self->{stock} = '';
}

1;
__END__

=encoding utf-8

=head1 NAME

Shodo - Auto-generate documents from HTTP::Request and HTTP::Response

=head1 SYNOPSIS

    use HTTP::Request::Common;
    use HTTP::Response;
    use Shodo;

    my $shodo = Shodo->new();
    my $suzuri = $shodo->new_suzuri('An endpoint method.');

    my $req = POST '/entry', [ id => 1, message => 'Hello Shodo' ];
    $suzuri->request($req);
    my $res = HTTP::Response->new(200);
    $res->content('{ "message" : "success" }');
    $suzuri->response($res);

    print $suzuri->document(); # print document as Markdown format

=head1 DESCRIPTION

Shodo generates Web API documents as Markdown format automatically and validates parameters using HTTP::Request/Response.

B<THIS IS A DEVELOPMENT RELEASE. API MAY CHANGE WITHOUT NOTICE>.

=head1 Methods

=head2 new

    my $shodo = Shodo->new(
        document_root => 'doc'
    );

Create and return new Shodo object. "document_root" is optional parameter for your document root directory.

=head2 template

    $shodo->template($tmpl);

Set custom template.

=head2 document_root

    $shodo->document_root('doc');

Set document root directory.

=head2 new_suzuri

    my $suzuri = $shodo->new_suzuri('This is description.');

Create and return new L<Shodo::Suzuri> object with the description.

=head2 stock

    $shodo->stock($suzuri->doc());

Stock text of documents for writing later. The parameter document is anything ok, but Markdown based is recommended.

=head2 write

    $shodo->write('output.md');

Write the documentation in stocks to the file and make the stock empty.

=head1 SEE ALSO

L<Test::Shodo::JSONRPC>

"autodoc": L<https://github.com/r7kamura/autodoc>

L<Test::JsonAPI::Autodoc>

What is Shodo?: L<http://en.wikipedia.org/wiki/Shodo>

=head1 THANKS

Songmu for naming as "Shodo". It's pretty.

Moznion for making Test::JsonAPI::Autodoc.

Hachioji.pm for advising.

=head1 LICENSE

Copyright (C) Yusuke Wada.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Yusuke Wada E<lt>yusuke@kamawada.comE<gt>

=cut
