package Mojolicious::Plugin::AdvancedMod::Configurator;
use Data::Dumper;

sub init {
  my $app     = shift;
  my $helpers = shift;

  $helpers->{configurator} = sub {
    my $self = shift;
    my $mode = $self->app->mode;
    my %args = @_;
    my $conf = {};

    if ( $args{file} && -r $args{file} ) {
      $conf = _load_file( $args{file}, $mode );
    }

    if ( !$conf->{_err} ) {
      if ( $args{include} ) {
        foreach my $param ( keys %{$conf} ) {
          next if $conf->{$param} !~ /\.(yml|json)$/;
          $conf->{$param} = _load_file( $conf->{$param}, $mode );
        }
      }

      if ( $args{eval} && $args{eval}{$mode} ) {
        my $ret = eval $args{eval}{$mode}{code};

        if ( $@ ) {
          $conf->{_err} = $@;
        }
        else {
          if ( $args{eval}{$mode}{key} ) {
            $conf->{ $args{eval}{$mode}{key} } = $ret;
          }
          else {
            $conf = $ret;
          }
        }
      }

      push @{ $self->app->renderer->paths }, $conf->{templates_path} if $conf->{templates_path};
      push @{ $self->app->static->paths },   $conf->{static_path}    if $conf->{static_path};
    }

    $conf = _encapsulate( $conf );

    $self->app->defaults( am_config => $conf );
    # add old key
    $self->app->defaults( switch_config => $conf );

    $self->app->log->debug( "** Configurator config: " . Mojo::JSON->new->encode( $conf ) );

    if ( $conf->{_err} ) {
      $self->app->log->error( "** Configurator error: " . $conf->{_err} );
      return undef if $conf->{_err};
    }

    return 1;
  };
  # add old alias
  $helpers->{switch_config} = $helpers->{configurator};
}

sub _load_package {
  my $ext = shift;
  my %lst = (
    yml  => [qw( YAML::XS YAML YAML::Tiny )],
    json => [qw( JSON::XS JSON Mojo::JSON )]
  );

  foreach my $pkg ( @{ $lst{$ext} } ) {
    eval "use $pkg";
    if ( !$@ ) {
      my $ret = $pkg . "::";
      if ( $pkg =~ /^YAML/ ) { $ret .= 'Load'; }
      elsif ( grep( /^$pkg$/, qw/JSON::XS JSON/ ) ) { $ret .= 'decode_json'; }
      else                                          { $ret .= 'decode'; }
      return { err => 0, name => $ret };
    }
  }
  return { err => 'No module name found' };
}

sub _load_file {
  my ( $file, $mode ) = @_;
  my $ext = ( $file =~ /\.(\w+$)/ )[0];

  my $src;
  eval {
    open my $fh, $file or return;
    $src .= $_ while <$fh>;
    close $fh;
  };

  return { _err => $@ || $! } if $@ || $!;

  my $pkg = _load_package( $ext );
  return { _err => $pkg->{err} } if $pkg->{err};

  my $res = eval $pkg->{name} . '($src)';
  return { _err => $@ } if $@;

  my $ret = {};

  if ( $mode ) {
    %$ret = map { $_ => $res->{$mode}{$_} } keys %{ $res->{$mode} };
    if ( $res->{overall} ) {
      foreach my $k ( keys %{ $res->{overall} } ) {
        $ret->{$k} = $res->{'overall'}{$k};
      }
    }
  }
  else {
    %$ret = map { $_ => $res->{$_} } keys %{$res};
  }

  return $ret;
}

# Decoding example: 'dbi:Pg:dbname=${development.db_slave.dbname};host=${development.db_slave.host};port=${development.db_slave.port}'
sub _encapsulate {
  my $conf       = shift;
  my $plain_dump = Dumper $conf;

  $plain_dump =~ s/^\$VAR1 = //;
  $plain_dump =~ s/(development|production|overall)\.//gs;

  while ( $plain_dump =~ /(\${.*?})/gs ) {
    my $collocation = $1;

    my $copy      = $collocation;
    my $eval_code = qq~\$conf->~;

    $copy =~ s/\$//g;
    $copy =~ s/[{}]//g;

    map { $eval_code .= "{$_}" } split /\./, $copy;
    my $ret_eval = eval "$eval_code";
    $plain_dump =~ s/\Q$collocation/$ret_eval/;
  }

  return eval $plain_dump;
}

1;

=encoding utf8

=head1 NAME

Mojolicious::Plugin::AdvancedMod::Configurator - Configuration change by MOJO_MODE

=head1 ARGUMENTS

=head2 file

Reads the yml/json stream from a file instead of a string

=head2 include

If your configuration has a file.(yml|json), Configurator replace the value of the contents of the file

=head2 eval

Eval code

=head1 SYNOPSIS

  ...
  $self->configurator(
    file => 'etc/conf.yml'
    eval => {
      development => {
        code => '..',
        key  => 'db'
      },
      production  => { code => '..' },
      overall => {
        secret_key: 28937489273897
      }
    },
  );
  ...
  print self->stash( 'configurator' )->{db_name};

=head1 AUTHOR

=over 2

=item

Grishkovelli L<grishkovelli@gmail.com>

=item

https://github.com/grishkovelli/Mojolicious-Plugin-AdvancedMod

=back

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013, 2014
Grishkovelli L<grishkovelli@gmail.com>

This module is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
