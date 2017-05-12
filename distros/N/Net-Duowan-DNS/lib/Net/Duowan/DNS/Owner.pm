package Net::Duowan::DNS::Owner;

use 5.006;
use warnings;
use strict;
use Carp qw/croak/;
use JSON;
use base 'Net::Duowan::DNS::Common';

use vars qw/$VERSION/;
$VERSION = '1.2.0';

sub new {
    my $class = shift;
    my $psp = shift;
    my $token = shift;
    bless { psp => $psp, token => $token },$class;
}

sub reGenerateToken {
    my $self = shift;

    my $psp = $self->{psp};
    my $token = $self->{token};
    my $act = 'user_edit_token';
    my %reqs = (a=>$act, psp=>$psp, tkn=>$token);

    return $self->reqTemplate(%reqs);
}

sub fetchOpsLog {
    my $self = shift;

    my $psp = $self->{psp};
    my $token = $self->{token};
    my $act = 'userlog_load_all';

    my %args = @_;
    my $offset = $args{offset} || 0;
    my $number = $args{number} || 100;
    my %reqs = (a=>$act, psp=>$psp, tkn=>$token, offset=>$offset, number=>$number);

    return $self->reqTemplate(%reqs);
}

sub fetchZoneApplyHistory {
    my $self = shift;

    my $psp = $self->{psp};
    my $token = $self->{token};
    my $act = 'applyhist_load_all';

    my %args = @_;
    my $offset = $args{offset} || 0;
    my $number = $args{number} || 100;
    my %reqs = (a=>$act, psp=>$psp, tkn=>$token, offset=>$offset, number=>$number);

    return $self->reqTemplate(%reqs);
}

1;
