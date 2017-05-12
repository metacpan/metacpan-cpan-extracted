package Net::DNS::LivedoorDomain::DDNS::Response;

use strict;
use warnings;
use base qw/Class::Accessor/;

__PACKAGE__->mk_accessors(qw/result_code ip user hostname message/);

sub new {
    my ($class, $res) = @_;
    my $self = bless {}, $class;
    $self->_init($res);
    $self;
}

sub is_success {
    my $self = shift;
    return $self->result_code eq '200';
}

sub _init {
    my ($self, $res) = @_;
    return unless $res->code =~ m/^(2|3)/;
    my $content = $res->content;
    return unless $content =~ m/<PRE>\n(.*)<\/PRE>/s;
    $content = $1;
    my @lines = split m/\n/, $content;
    my %data;
    for my $line(@lines) {
        my ($key, $val) = split m/\:\s*/, $line;
        $key = lc($key);
        $self->$key($val);
    }
}

1;
__END__
