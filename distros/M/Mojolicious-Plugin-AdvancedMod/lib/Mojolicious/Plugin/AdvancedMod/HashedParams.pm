package Mojolicious::Plugin::AdvancedMod::HashedParams;

sub init {
  my $app     = shift;
  my $helpers = shift;

  $helpers->{hparams} = sub {
    my $self   = shift;
    my @permit = @_;

    if ( !$self->stash( 'hparams' ) ) {
      my $hprms = $self->req->params->to_hash;
      my $index = 0;
      my @array;

      foreach my $p ( keys %$hprms ) {
        my $key = $p;
        my $val = $hprms->{$p};

        $key =~ s/[^\]\[0-9a-zA-Z_]//g;
        $key =~ s/\[{2,}/\[/g;
        $key =~ s/\]{2,}/\]/g;

        my @list;
        foreach my $n ( split /[\[\]]/, $key ) {
          push @list, $n if length( $n ) > 0;
        }

        map $array[$index] .= "{$list[$_]}", 0 .. $#list;

        if ( ref( $val ) ne 'ARRAY' ) {
          $array[$index] .= " = '$val';";
        }
        else {
          my @ar = @$val;
          undef $val;
          foreach my $v ( @ar ) { $val .= "'$v',"; }
          $val =~ s/,$//;
          $array[$index] .= " = [$val];";
        }
        $index++;
      }

      my $code = 'my $h = {};';
      map { $code .= "\$h->$_" } @array;
      $code .= '$h;';

      my $ret = eval $code;

      if ( $@ ) {
        $self->stash( hparams       => {} );
        $self->stash( hparams_error => $@ );
        return $self->stash( 'hparams' );
      }

      if ( %$ret ) {
        if ( @permit ) {
          foreach my $k ( keys %$ret ) {
            delete $ret->{$k} if grep( /\Q$k/, @permit );
          }
        }

        $self->stash( hparams => $ret );
      }
    }
    else {
      $self->stash( hparams => {} );
    }
    return $self->stash( 'hparams' );
  }
}

1;

=encoding utf8

=head1 NAME

Mojolicious::Plugin::AdvancedMod::HashedParams - Transformation request parameters into a hash and multi-hash

=head1 SYNOPSIS

  # Transmit params:
  /route?message[body]=PerlOrDie&message[task][id]=32
    or
  <input type="text" name="message[task][id]" value="32"> 

  get '/route' => sub {
    my $self = shift;
    # you can also use permit parameters
    $self->hparams( qw/message/ );
    # return all parameters in the hash
    $self->hparams();
  };

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
