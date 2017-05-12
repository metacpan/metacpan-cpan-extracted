package Mojolicious::Plugin::RussianPost;
use Mojo::Base 'Mojolicious::Plugin';
use Mojo::Util qw(dumper);
use Mojolicious::Plugin::RussianPost::Tracking;

our $VERSION = '0.01';

has ['result'] => sub {};

sub register {
    my ($self, $app, $conf) = @_;
    $app->helper('rp.tracking'=> sub {
        my ($c,$track,$language) = @_;
        $language ||= 'RUS';
        my $tracking = Mojolicious::Plugin::RussianPost::Tracking->new();
        my $result = $tracking->request($conf->{'login'},$conf->{'password'},$track,$language);
        $self->result($result);
        return $self;
    });
}

sub hash {
    my ($self) = @_;
    my $result = $self->result;

    my $return = {};

    for my $item (@{$result}){
        my $res = {};

        if(my $Barcode =  $item->{'ItemParameters'}->{'Barcode'}){
            $return->{'track_number'} = $Barcode;
        }

        if(my $recipient = $item->{'UserParameters'}->{'Rcpn'}){
            $return->{'recipient'} = $recipient;
        }

        if(my $sender = $item->{'UserParameters'}->{'Sndr'}){
            $return->{'sender'} = $sender;
        }

        if(my $weight = $item->{'ItemParameters'}->{'Mass'}){
            $return->{'weight'} = $weight;
        }

        if(my $name = $item->{'ItemParameters'}->{'MailType'}->{'Name'}){
            $return->{'mail'}->{'type'}->{'name'} = $name;
        }

        if(my $id = $item->{'ItemParameters'}->{'MailType'}->{'Id'}){
            $return->{'mail'}->{'type'}->{'id'} = $id;
        }

        if(my $name = $item->{'ItemParameters'}->{'MailCtg'}->{'Name'}){
            $return->{'mail'}->{'config'}->{'name'} = $name;
        }

        if(my $id = $item->{'ItemParameters'}->{'MailCtg'}->{'Id'}){
            $return->{'mail'}->{'config'}->{'id'} = $id;
        }

        if(my $description = $item->{'AddressParameters'}->{'DestinationAddress'}->{'Description'}){
            $return->{'description'}->{'address'} = $description;
        }

        if(my $index = $item->{'AddressParameters'}->{'DestinationAddress'}->{'Index'}){
            $return->{'description'}->{'index'} = $index;
        }

        $res->{'date'} = Mojo::Date->new($item->{'OperationParameters'}->{'OperDate'});

        $res->{'attr'}->{'name'} = $item->{'OperationParameters'}->{'OperAttr'}->{'Name'};
        $res->{'attr'}->{'id'} = $item->{'OperationParameters'}->{'OperAttr'}->{'Id'};

        $res->{'address'}->{'description'} = $item->{'AddressParameters'}->{'OperationAddress'}->{'Description'};
        $res->{'address'}->{'index'} = $item->{'AddressParameters'}->{'OperationAddress'}->{'Index'};

        $res->{'type'}->{'name'} = $item->{'OperationParameters'}->{'OperType'}->{'Name'};
        $res->{'type'}->{'id'} = $item->{'OperationParameters'}->{'OperType'}->{'Id'};

        $res->{'weight'} = $item->{'ItemParameters'}->{'Mass'};

        push(@{$return->{'operations'}}, $res);
    }
    return $return;
}

1;
__END__

=encoding utf8

=head1 NAME

Mojolicious::Plugin::RussianPost - Mojolicious Plugin Russian Post

=head1 SYNOPSIS

  # Mojolicious
  $self->plugin('RussianPost'=>{login=>'you login', password=>'you login'});

  # Mojolicious::Lite
  plugin 'RussianPost'=>{login=>'you login', password=>'you login'};

  # in controller named params
  my $rp = $self->rp->tracking('66510689006089');
  say dumper $rp->hash;

=head1 DESCRIPTION
 
Provides quick and easy access to the software access to the mail service of Mail of Russia

=head1 METHODS
 
=head2 register
 
  # Mojolicious
  $self->plugin('RussianPost'=>{login=>'you login', password=>'you login'});
 
  # Mojolicious::Lite
  plugin 'RussianPost'=>{login=>'you login', password=>'you login'};

Called when registering the plugin.

=head1 HELPERS
 
=head2 tracking
 
  # In Controller:
  my $obj = $self->rp->tracking('66510689006089');

Returns object L<Mojolicious::Plugin::RussianPost>.

=head1 METHODS

=head2 hash
 
  # In Controller:
  my $obj = $self->rp->tracking('66510689006089');
  say dumper $obj->hash

Returns array hash.

=head2 result
 
  # In Controller:
  my $obj = $self->rp->tracking('66510689006089');
  say dumper $obj->result;

Returns original output API.

=head1 SEE ALSO

L<Mojolicious>, L<Mojolicious::Guides>, L<http://mojolicious.org>.

=cut
