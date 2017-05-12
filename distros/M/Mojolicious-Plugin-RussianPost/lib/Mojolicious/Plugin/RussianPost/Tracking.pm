package Mojolicious::Plugin::RussianPost::Tracking;
use Mojo::Base -base;
use Mojo::Util qw(dumper);
use Mojo::UserAgent;
use Carp qw(croak);

our $VERSION = '0.01';

sub request {
     my ($self,$login,$password,$track,$language) = @_;

    my @xml = ();
    push(@xml,qq{<soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope" xmlns:oper="http://russianpost.org/operationhistory" xmlns:data="http://russianpost.org/operationhistory/data" xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/">});
    push(@xml,qq{<soap:Header/><soap:Body>});
    push(@xml,qq{<oper:getOperationHistory>});
    push(@xml,qq{<data:OperationHistoryRequest>});
    push(@xml,qq{<data:Barcode>$track</data:Barcode><data:MessageType>0</data:MessageType><data:Language>$language</data:Language>});
    push(@xml,qq{</data:OperationHistoryRequest>});
    push(@xml,qq{<data:AuthorizationHeader soapenv:mustUnderstand="1">});
    push(@xml,qq{<data:login>$login</data:login>});
    push(@xml,qq{<data:password>$password</data:password>});
    push(@xml,qq{</data:AuthorizationHeader>});
    push(@xml,qq{</oper:getOperationHistory>});
    push(@xml,qq{</soap:Body></soap:Envelope>});

    my $ua = Mojo::UserAgent->new;
    my $tx = $ua->post('https://tracking.russianpost.ru/rtm34'=>join("",@xml));
    my $dom = $tx->res->dom;
    croak qq/invalid xml/ if($dom->xml != 1);

    my @result = ();
    $dom->find('historyRecord')->each(sub {
        my $e = shift;
        push(@result, $self->historyRecord($e));
    });
    return \@result;
}


sub historyRecord {
    my ($self, $dom) = @_;
    my $result = {};
    $result->{'AddressParameters'}   = $self->AddressParameters($dom->at("AddressParameters"));
    $result->{'FinanceParameters'}   = $self->FinanceParameters($dom->at("FinanceParameters"));
    $result->{'ItemParameters'}      = $self->ItemParameters($dom->at("ItemParameters"));
    $result->{'OperationParameters'} = $self->OperationParameters($dom->at("OperationParameters"));
    $result->{'UserParameters'}      = $self->UserParameters($dom->at("UserParameters"));
    return $result;
}

sub UserParameters {
    my ($self, $dom) = @_;
    my $result = {};

    for my $item (qw/SendCtg/){
        if(my $val = $dom->at("$item > Id")){
            $result->{$item}->{'Id'} = $val->content;
        }
        else{
            $result->{$item}->{'Id'} = undef;
        }

        if(my $val = $dom->at("$item > Name")){
            $result->{$item}->{'Name'} = $val->content;
        }
        else{
            $result->{$item}->{'Name'} = undef;
        }
    }

    for my $item (qw/Sndr Rcpn/){
        if(my $val = $dom->at("$item")){
            $result->{$item} = $val->content || undef;
        }
        else{
            $result->{$item} = undef;
        }
    }

    return $result;
}

sub OperationParameters {
    my ($self, $dom) = @_;
    my $result = {};

    for my $item (qw/OperType OperAttr/){
        if(my $val = $dom->at("$item > Id")){
            $result->{$item}->{'Id'} = $val->content;
        }
        else{
            $result->{$item}->{'Id'} = undef;
        }

        if(my $val = $dom->at("$item > Name")){
            $result->{$item}->{'Name'} = $val->content;
        }
        else{
            $result->{$item}->{'Name'} = undef;
        }
    }

    for my $item (qw/OperDate/){
        if(my $val = $dom->at("$item")){
            $result->{$item} = $val->content;
        }
        else{
            $result->{$item} = undef;
        }
    }

    return $result;
}

sub ItemParameters {
    my ($self, $dom) = @_;
    my $result = {};

    for my $item (qw/Barcode Internum ValidRuType ValidEnType ComplexItemName Mass MaxMassRu MaxMassEn/){
        if(my $val = $dom->at("$item")){
            $result->{$item} = $val->content;
        }
        else{
            $result->{$item} = undef;
        }
    }

    for my $item (qw/MailType MailCtg/){
        if(my $val = $dom->at("$item > Id")){
            $result->{$item}->{'Id'} = $val->content;
        }
        else{
            $result->{$item}->{'Id'} = undef;
        }

        if(my $val = $dom->at("$item > Name")){
            $result->{$item}->{'Name'} = $val->content;
        }
        else{
            $result->{$item}->{'Name'} = undef;
        }
    }
    return $result;
}

sub FinanceParameters{
    my ($self, $dom) = @_;
    my $result = {};

    for my $item (qw/Payment Value MassRate InsrRate AirRate Rate CustomDuty/){
        if(my $val = $dom->at("$item")){
            $result->{$item} = $val->content;
        }
        else{
            $result->{$item} = undef;
        }
    }

    return $result;
}

sub AddressParameters {
    my ($self, $dom) = @_;
    my $result = {};

    for my $item (qw/DestinationAddress OperationAddress/){
        if(my $val = $dom->at("$item > Index")){
            $result->{$item}->{'Index'} = $val->content;
        }
        else{
            $result->{$item}->{'Index'} = undef;
        }

        if(my $val = $dom->at("$item > Description")){
            $result->{$item}->{'Description'} = $val->content;
        }
        else{
            $result->{$item}->{'Description'} = undef;
        }
    }

    for my $item (qw/MailDirect CountryFrom CountryOper/){
        if(my $val = $dom->at("$item > Id")){
            $result->{$item}->{'Id'} = $val->content;
        }
        else{
            $result->{$item}->{'Id'} = undef;
        }

        if(my $val = $dom->at("$item > Code2A")){
            $result->{$item}->{'Code2A'} = $val->content;
        }
        else{
            $result->{$item}->{'Code2A'} = undef;
        }

        if(my $val = $dom->at("$item > Code3A")){
            $result->{$item}->{'Code3A'} = $val->content;
        }
        else{
            $result->{$item}->{'Code3A'} = undef;
        }

        if(my $val = $dom->at("$item > NameRu")){
            $result->{$item}->{'NameRu'} = $val->content;
        }
        else{
            $result->{$item}->{'NameRu'} = undef;
        }

        if(my $val = $dom->at("$item > NameEN")){
            $result->{$item}->{'NameEN'} = $val->content;
        }
        else{
            $result->{$item}->{'NameEN'} = undef;
        }
    }
    return $result;
}


1;
