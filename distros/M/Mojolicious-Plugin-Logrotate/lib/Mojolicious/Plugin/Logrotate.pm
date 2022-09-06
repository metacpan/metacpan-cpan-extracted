package Mojolicious::Plugin::Logrotate;

# ABSTRACT: Logrotate Mojolicious Application log
#------------------------------------------------------------------------------
# 加载项目模块依赖
#------------------------------------------------------------------------------
use Mojo::Base 'Mojolicious::Plugin';
use Mojo::File qw/curfile/;
use File::Path qw/make_path/;
use Carp       qw/croak/;

#------------------------------------------------------------------------------
# 注册到 Mojolicious 插件
#------------------------------------------------------------------------------
sub register {
  my ($self, $app, $opts) = @_;
Logrotate: {
    croak "Must set home_path and app_mode" unless (exists $opts->{home} and exists $opts->{mode});

    # 裁剪日志切割相关属性
    my $home    = $opts->{home};
    my $mode    = $opts->{mode};
    my $dirname = qq{$home/log};
    make_path $dirname or die "Can't create dir $dirname\n" unless -d $dirname;

    # 自动切割日志文件
    my $handler = curfile->sibling('logHandler.pl');
    my $script  = qq{$handler $dirname/$mode-%Y%m%d.log};
    open(my $FH, qq{| $script});
    $app->log->handle($FH);
  }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mojolicious::Plugin::Logrotate

=head1 VERSION

version 0.03

=head1 SYNOPSIS

    package App;
    use Mojo::Base 'Mojolicious';
    use Mojo::File qw/curfile/;

    sub startup {
        my $self = shift;

        # 裁剪项目家目录、运行模式和项目名称
        my $home    = curfile->dirname->sibling;
        my $mode    = $self->app->mode;

        $self->plugin( 'Mojolicious::Plugin::Logrotate', {mode => $mode, home => $home} );
    }

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/ciscolive/mojolicious-plugin-logrotate/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/ciscolive/mojolicious-plugin-logrotate>

  git clone git://github.com/ciscolive/mojolicious-plugin-logrotate.git

=head1 AUTHOR

WENWU YAN <careline@cpan.org>

=head1 CONTRIBUTOR

WENWU YAN  <careline@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by WENWU YAN.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
