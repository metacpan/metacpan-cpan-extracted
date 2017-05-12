package Test::Sietima::MailStore;
use Moo;
use Sietima::Policy;
use List::AllUtils qw(all first_index);
use Digest::SHA qw(sha1_hex);
use namespace::clean;

with 'Sietima::MailStore';

has _mails => (
    is => 'rw',
    default => sub { +{} },
);

sub clear { shift->_mails({}) }

sub store ($self,$mail,@tags) {
    my $str = $mail->as_string;
    my $id = sha1_hex($str);
    $self->_mails->{$id} = {
        id => $id,
        mail => $str,
        tags => { map {$_ => 1;} @tags, },
    };
    return $id;
}

sub retrieve_ids_by_tags ($self,@tags){
    my @ret;
    for my $m (values $self->_mails->%*) {
        next unless all { $m->{tags}{$_} } @tags;
        push @ret, $m->{id};
    }
    return \@ret;
}

sub retrieve_by_tags ($self,@tags){
    my @ret;
    for my $m (values $self->_mails->%*) {
        next unless all { $m->{tags}{$_} } @tags;
        push @ret, {
            $m->%{id},
            mail => Email::MIME->new($m->{mail})
        };
    }

    return \@ret;
}

sub retrieve_by_id ($self,$id) {
    if (my $m = $self->_mails->{$id}) {
        return Email::MIME->new($m->{mail});
    }

    return;
}

sub remove($self,$id) {
    delete $self->_mails->{$id};
    return;
}

1;
