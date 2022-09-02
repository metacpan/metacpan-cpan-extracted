package Mojolicious::Plugin::Access;

# ABSTRACT: Mojolicious::Plugin::Access Control remote ip access your App
use Mojo::Base 'Mojolicious::Plugin';

sub register {
  my ($self, $app, $opts) = @_;
Access: {
    $app->hook(
      before_dispatch => sub {
        my $c = shift;

        # 设定并读取白名单
        my %addresses;
        my $accessIps = $c->app->home->to_string . '/conf/.remote_access.conf';
        `touch $accessIps`            unless -e $accessIps;
        `echo 127.0.0.1 > $accessIps` unless -s $accessIps;

        open IPADDR, "<$accessIps";
        while (<IPADDR>) {
          chomp;
          next if /^#|!|;/;
          $addresses{$_} = 1;
        }
        close IPADDR;

        # 判定客户端地址是否有权限访问接口
        my $remote_ip = $c->tx->original_remote_address;
        unless (exists $addresses{$remote_ip}) {
          return $c->render(json => {'code' => 403, 'message' => qq{client address $remote_ip is forbidden}});
        }
      }
    );
  }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mojolicious::Plugin::Access

=head1 VERSION

version 0.03

=head1 SYNOPSIS

    package App;
    use Mojo::Base 'Mojolicious';

    sub startup {
        my $self = shift;
        $self->plugin( 'Mojolicious::Plugin::Access' );
    }

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/ciscolive/mojolicious-plugin-access/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/ciscolive/mojolicious-plugin-cors>

  git clone git://github.com/ciscolive/mojolicious-plugin-access.git

=head1 AUTHOR

WENWU YAN <careline@cpan.org>

=head1 CONTRIBUTOR

WENWU YAN  <careline@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by WENWU YAN.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
