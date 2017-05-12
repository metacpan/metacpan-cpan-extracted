package Mojolicious::Plugin::Pingen;
use Mojo::Base 'Mojolicious::Plugin';
use Mojo::UserAgent;
use Mojo::JSON;
use POSIX qw(strftime);
use Mojo::Exception;
use constant DEBUG => $ENV{MOJO_PINGEN_DEBUG} || 0;
our $VERSION = '0.2.3';

=head1 NAME

Mojolicious::Plugin::Pingen - Print Package Send Physical letters

=head1 DESCRIPTION

L<Mojolicious::Plugin::Pingen> is a plugin for the L<Mojolicious> web
framework which allows you to do communicate with pingen.com.

This module is EXPERIMENTAL. The API can change at any time. Let me know
if you are using it.

=head1 SYNOPSIS

=head2 Production mode

    use Mojolicious::Lite;
    plugin Pingen => { apikey => $ENV{SUPER_SECRET_PINGEN_KEY} };

    post '/send' => sub {
        my $c = shift;
        $c->delay(
            sub { $c->pingen->document->upload($c->param('pdf'), shift->begin) },
            sub {
                my ($delay, $res) = @_;
                return $c->reply->exception($res->{errormessage}) if $res->{error};
                $c->pingen->document->send($res->{id},{
                    speed => 1
                },$delay->begin)
            },
            sub {
                my ($delay, $res) = @_;
                return $c->reply->exception($err) if $err;
                return $c->render(text => "Delivery of $res->{id} is scheduled!");
            }
        );
    );

=head2 Testing mode

  use Mojolicious::Lite;
  plugin Pingen => { mocked => 1 };

Setting C<mocked> will enable this plugin to work without an actual connection
to pingen.com. This is done by replicating the behavior of Pingen for those API we support. This is
especially useful when writing unit tests.

The apikey for the mocked interface is: sk_test_super_secret_key

The following routes will be added to your application to mimic Pidgen:

=over

=item * POST /mocked/pingen/document/upload

=item * POST /mocked/pingen/document/send

=item * POST /mocked/pingen/document/delete

=item * POST /mocked/pingen/send/cancel

=back

=cut


=head1 ATTRIBUTES

=head2 base_url

  $str = $self->base_url;

This is the location to Stripe payment solution. Will be set to
L<https://api.pingen.com/>.

=head2 apikey

  $str = $self->apikey;

The value for the private API key. Available in the Stripe admin gui.

=head2 exceptions

This will cause exceptions to be thrown if there is any problem
with submitting the invoice to pingen.

=cut

has base_url      => 'https://api.pingen.com/';
has apikey        => 'sk_test_super_secret_key';
has exceptions    => 0;
has _ua           => sub { Mojo::UserAgent->new; };

=head1 HELPERS

=head2 pingen.document.upload

    my $json =   $c->pingen->document->upload($asset[,\%args]);
    $c->pingen->document->upload($mojoUpload[,\%args], sub { my ($c, $json) = @_; });

Upload a L<Mojo::Upload> object containint a (PDF file). Pingen will analyze the content of the pdf and figure out
how and where to mail it.

C<$json> is the response object from  pingen.

C<%args> can contain the following optional parameters:

=over

=item * color

Print color: 0 = B/W, 1 = Color, 2 = Mixed (optimized)

=item * duplex

Paper hadling: 0 = simplex, 1 = duplex

=item * rightaddress

Where in the document is the address: 0 = Address left, 1 = Address right.

=back

=head2 pingen.document.send

   my $json =   $c->pingen->document->send($id,\%args);
   $c->pingen->document->send($id,\%args, sub { my ($c, $json) = @_; });

Use the C<$id> returned from the upload call to actually send the document.

C<$json> is a response object from pingen.

C<%args> can contain the following parameters:

=over

=item * speed

Delivery Speed. Varies by country. Use L<https://pingen.com/en/developer/testapi-send.html> to get a list
of speeds for your country. In general 1 = Priority, 2 = Economy.

=item * envelope

If you have designed your own envelope in the pingen webinterface, hunt take the html inspector to
the source code of the admin ui to determine the id of your envelope. You can then refer to it using that id.

=back

=head2 pingen.document.delete

   my $json =   $c->pingen->document->delete($id);
   $c->pingen->document->delete($id, sub { my ($c, $json) = @_; });

Use the C<$id> returned from upload call to delete the document. Note that this will not
cancel any pending send tasks.

C<$json> is a response object from pingen.

=head2 pingen.send.cancel

   my $json =   $c->pingen->send->cancel($id);
   $c->pingen->send->cancel($id, sub { my ($c, $json) = @_; });

cancel the given send task. Use the ID returned from the send call.

C<$err> is a string describing the error. Will be empty string on success.
C<$json> is a response object from pingen.

=head1 METHODS

=head2 register

  $app->plugin(Pingen => \%config);

Called when registering this plugin in the main L<Mojolicious> application.

=cut

sub register {
    my ($self, $app, $config) = @_;

    # copy config to this object
    for (grep { $self->can($_) } keys %$config) {
        $self->{$_}  = $config->{$_};
    }
    # self contained
    $self->_mock_interface($app, $config) if $config->{mocked};

    $app->helper('pingen.document.upload'  => sub { $self->_document_upload(@_); });
    $app->helper('pingen.document.send'    => sub { $self->_document_send(@_); });
    $app->helper('pingen.document.delete'  => sub { $self->_document_delete(@_); });
    $app->helper('pingen.send.cancel'      => sub { $self->_send_cancel(@_); });
}

sub _document_upload {
    my ($self, $c, $upload, $args, $cb) = @_;
    my $ua = $self->_ua;
    $args ||= {};
    if (ref $args eq 'CODE'){
        $cb = $args;
        $args = {};
    }
    my %form = ( send => 0 );
    if (ref $args eq 'HASH'){
        for my $key (qw(color duplex rightaddress)){
            $form{$key} = $args->{$key} if defined $args->{$key};
        }
    }

    my $URL = $self->base_url.'/document/upload/token/'.$self->apikey;
    my $data = {
        %form,
        file => { file => $upload->asset, filename => $upload->filename },
    };
    if (ref $cb eq 'CODE'){
        $ua->post( $URL => form => $data => $self->_build_res_cb($cb));
    }
    else {
        return $self->_tx_to_json($ua->post( $URL => form => $data));
    }
}

sub _document_send {
    my ($self, $c, $id, $args, $cb) = @_;
    my $ua = $self->_ua;

    $args ||= {};
    if (ref $args eq 'CODE'){
        $cb = $args;
        $args = {};
    }
    my %data;
    if (ref $args eq 'HASH'){
        for my $key (qw(speed envelope)){
            $data{$key} = $args->{$key} if defined $args->{$key};
        }
    }

    my $URL = $self->base_url.'/document/send/id/'.$id.'/token/'.$self->apikey;

    if (ref $cb eq 'CODE'){
        $ua->post( $URL => json => \%data => $self->_build_res_cb($cb));
    }
    else {
        return $self->_tx_to_json($ua->post( $URL => json => \%data));
    }
}

sub _document_delete {
    my ($self, $c, $id, $cb) = @_;
    my $ua = $self->_ua;

    my $URL = $self->base_url.'/document/delete/id/'.$id.'/token/'.$self->apikey;

    if (ref $cb eq 'CODE'){
        $ua->post( $URL => $self->_build_res_cb($cb));
    }
    else {
        return $self->_tx_to_json($ua->post( $URL ));
    }
}

sub _send_cancel {
    my ($self, $c, $id, $cb) = @_;
    my $ua = $self->_ua;

    my $URL = $self->base_url.'/send/cancel/id/'.$id.'/token/'.$self->apikey;

    if (ref $cb eq 'CODE'){
        $ua->post( $URL => $self->_build_res_cb($cb));
    }
    else {
        return $self->_tx_to_json($ua->post( $URL ));
    }
}

sub _tx_to_json {
    my $self = shift;
    my $tx = shift;
    my $error = $tx->error     || {};
    my $json;
    if ($error->{code}){
        $json = {
            error => Mojo::JSON::true,
            errormessage => $error->{message},
            errorcode => $error->{code}
        };
    }
    else {
        $json  = $tx->res->json || {};
    }
    if ($self->exceptions and $json->{error}){
        Mojo::Exception->throw($json->{errormessage})
    }
    return $json;
}

sub _build_res_cb {
    my $self = shift;
    my $cb = shift;
    return sub {
        my ($c,$tx) = @_;
        $c->$cb($self->_tx_to_json($tx));
    }
}

sub _mock_interface {
    my ($self, $app) = @_;
    my $apikey = 'sk_test_super_secret_key';

    $self->_ua->server->app($app);
    $self->base_url('/mocked/pingen');
    push @{$app->renderer->classes}, __PACKAGE__;

    $app->routes->post( '/mocked/pingen/document/upload/token/:apikey' => sub {
        my $c = shift;
        if ($c->stash('apikey') eq $apikey){
            $c->render(json => {
                'error' => Mojo::JSON::false,
                'item' => {
                    'sent' => 0,
                    'size' => $c->param('file')->size,
                    'pages' => 1,
                    'fileremoved' => 0,
                    'requirement_failure' => 0,
                    'pagetype' => [
                        {
                            'type' => 2,
                            'number' => 1,
                            'color' => 0
                        }
                    ],
                    'filename' => $c->param('file')->filename,
                    'date' => strftime("%Y-%m-%d %H:%M:%S",gmtime(time)),
                    'rightaddress' => $c->param('rightaddress') // 0,
                    'status' => 1,
                    'country' => 'CH',
                    'user_id' => 902706832,
                    'id' => 253193787,
                    'address' => "Tobias Oetiker\nAarweg 15\n4600 Olten\nSchweiz",
                },
                'id' => 253193787
            });
        }
        else {
            $c->render(json => {
                error => Mojo::JSON::true,
                errormessage => 'Your token is invalid or expired',
                errorcode => 99400
            });
        }
    });
    $app->routes->post( '/mocked/pingen/document/send/id/:id/token/:apikey' => sub {
        my $c = shift;
        if ($c->stash('apikey') eq $apikey){
            if ($c->stash('id') == 253193787){
                $c->render(json => {
                   error => Mojo::JSON::false,
                   id => 21830180,
               });
            }
            else {
                $c->render(json => {
                    error => Mojo::JSON::true,
                    errorcode => 15016,
                    errormessage => 'You do not have rights to access this object'
                });
            }
        }
        else {
            $c->render(json => {
                error => Mojo::JSON::true,
                errormessage => 'Your token is invalid or expired',
                errorcode => 99400
            });
        }
    });
    $app->routes->post( '/mocked/pingen/document/delete/id/:id/token/:apikey' => sub {
        my $c = shift;
        if ($c->stash('apikey') eq $apikey){
            if ($c->stash('id') == 253193787){
                $c->render(json => {
                   error => Mojo::JSON::false,
               });
            }
            else {
                $c->render(json => {
                    error => Mojo::JSON::true,
                    errorcode => 15016,
                    errormessage => 'You do not have rights to access this object'
                });
            }
        }
        else {
            $c->render(json => {
                error => Mojo::JSON::true,
                errormessage => 'Your token is invalid or expired',
                errorcode => 99400
            });
        }
    });
    $app->routes->post( '/mocked/pingen/send/cancel/id/:id/token/:apikey' => sub {
        my $c = shift;
        if ($c->stash('apikey') eq $apikey){
            if ($c->stash('id') == 21830180){
                $c->render(json => {
                   error => Mojo::JSON::false,
               });
            }
            else {
                $c->render(json => {
                    error => Mojo::JSON::true,
                    errorcode => 15016,
                    errormessage => 'You do not have rights to access this object'
                });
            }
        }
        else {
            $c->render(json => {
                error => Mojo::JSON::true,
                errormessage => 'Your token is invalid or expired',
                errorcode => 99400
            });
        }
    });
}
1;

__END__

=head1 SEE ALSO

=over

=item * Overview

L<https://www.pingen.com>

=item * API

L<https://www.pingen.com/en/developer.html>

=back

=head1 ACKNOLEDGEMENT

Jan Henning Thorsen for his Mojolicious::Plugin::StripePayment from where I shamelessly copied the
structure of this module. Thanks!

=head1 AUTHOR

S<Tobias Oetiker, E<lt>tobi@oetiker.chE<gt>>

=head1 COPYRIGHT

Copyright OETIKER+PARTNER AG 2015

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10 or,
at your option, any later version of Perl 5 you may have available.

1;
