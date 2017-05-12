package Net::Kotonoha;

use strict;
use warnings;
use Carp;
use WWW::Mechanize;
use HTML::Selector::XPath qw/selector_to_xpath/;
use HTML::TreeBuilder::XPath;
use HTML::Entities qw/decode_entities/;
use Net::Kotonoha::Koto;

our $VERSION = '0.08';

sub new {
    my $class = shift;
    my %args  = @_;

    $args{mail}     ||= '';
    $args{password} ||= '';
    $args{user}     ||= '';
    $args{limit}    ||= 1000;

    croak "need to set mail and password" unless $args{mail} && $args{password};

    my $mech = WWW::Mechanize->new;
    $mech->agent_alias('Windows IE 6');
    $mech->quiet(1);
    $mech->add_header('Accept-Encoding', 'identity');
    $args{mech} = $mech;

    return bless {%args}, $class;
}

sub login {
    my $self = shift;

    return 1 if $self->{loggedin};

    $self->{mech}->get('http://kotonoha.cc');
    my $res = $self->{mech}->submit_form(
        form_number => 1,
        fields      => {
            mail     => $self->{mail},
            password => $self->{password},
        }
    );
    if ($res->is_success && $self->{mech}->uri =~ /\/home$/) { # no critic
        my $tree = HTML::TreeBuilder::XPath->new;
        $tree->parse($res->content);
        $tree->eof;
        my $user = $tree->findnodes(selector_to_xpath('dt.profileicon a'));
        my $link = $user ? $user->shift->attr('href') : '';
        if ($link =~ /^\/user\/(\w+)/) {
            $self->{loggedin} = ($self->{user} = $1);
        }
        $tree->delete;
    }
    croak "can't login kotonoha.cc" unless $self->{loggedin};
    return $self->{loggedin};
}

sub _get_list {
    my $self = shift;
    my $xpath = shift;
    my $page = shift || 'http://kotonoha.cc/home';

    $self->login unless defined $self->{loggedin};

    my $res = $self->{mech}->get( $page );
    croak "can't login kotonoha.cc" unless $res->is_success;
    return unless $res->is_success;

    my @list;

    my $tree = HTML::TreeBuilder::XPath->new;
    $tree->parse($res->content);
    $tree->eof;
    foreach my $item ($tree->findnodes(selector_to_xpath($xpath))) {
        if ($item->attr('href') =~ /^\/no\/(\d+)/) {
            my $koto_no = $1;
            if ($item->as_text =~ /^(.*)\s*\(([^\)]+)\)$/) {
                push @list, {
                    koto_no => $koto_no,
                    title   => $1,
                    answers => $2
                }
            }
        }
    }
    $tree->delete;
    return \@list;
}

sub _get_stream {
    my $self = shift;
    my $xpath = shift;
    my $page = shift || 'http://kotonoha.cc/stream';

    $self->login unless defined $self->{loggedin};

    my $res = $self->{mech}->get( $page );
    croak "can't login kotonoha.cc" unless $res->is_success;
    return unless $res->is_success;

    my @list;

    my $tree = HTML::TreeBuilder::XPath->new;
    $tree->parse($res->content);
    $tree->eof;
    foreach my $line ($tree->findnodes(selector_to_xpath($xpath))) {
        my $html = decode_entities($line->as_HTML);
        if ($html =~ /<a href="\/user\/(\w+)">([^<]+)<\/a>[^<]+<a href="\/no\/(\d+)">([^<]+)<\/a>([^ ]+)(?: [^ ]+ (.+))?$/) {
            push @list, {
                user    => $1,
                name    => $2,
                comment => $6 || '',
                answer  => $5,
                koto_no => $3,
                title   => $4,
            }
        }
    }
    $tree->delete;
    return \@list;
}

sub newer_list {
    return shift->_get_list('dl#newkoto a');
}

sub recent_list {
    return shift->_get_list('dl#recentkoto a');
}

sub hot_list {
    return shift->_get_list('dl#hot20 a');
}

sub answered_list {
    return shift->_get_list('dl#answeredkoto a');
}

sub posted_list {
    return shift->_get_list('dl#postedkoto a');
}

sub stream_list {
    return shift->_get_stream('dl#stream li');
}

sub subscribed_list {
    return shift->_get_stream('dl#subscribelist li', 'http://kotonoha.cc/inbox');
}

sub get_koto {
    my $self = shift;
    $self->login unless defined $self->{loggedin};
    return Net::Kotonoha::Koto->new(
        kotonoha => $self,
        koto_no => shift);
}

1;
__END__

=head1 NAME

Net::Kotonoha - A perl interface to kotonoha.cc

=head1 SYNOPSIS

  use Net::Kotonoha;
  use Data::Dumper;

  my $kotonoha = Net::Kotonoha->new(
        mail     => 'xxxxx@example.com',
        password => 'xxxxx',
    );
  warn Dumper $kotonoha->newer_list;
  my $koto = $kotonoha->get_koto(120235);
  $koto->answer(1, 'YES!YES!YES!');
  warn Dumper $koto->answer;

=head1 DESCRIPTION

This module allows easy access to kotonoha. kotonoha is not provide API.
Thus, this module is helpful for make kotonoha application.

=head1 CONSTRUCTOR

=over 4

=item new(\%account_settings)

Two parameter is required, a hashref of options.
It requires C<mail> and C<password> in the parameter.
You have to sign-up your account at kotonoha if you don't have them.

=back

=head1 METHOD

You can access koto list with following methods.

  newer_list
  recent_list
  answered_list
  posted_list
  stream_list
  subscribed_list

And, you can get koto object with following method specified id of koto.

  get_koto($koto_no)

You'll get koto object.
see L<Net::Kotonoha::Koto>.

=head1 AUTHOR

Yasuhiro Matsumoto E<lt>mattn.jp@gmail.comE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Net::Kotonoha::Koto>

=cut
