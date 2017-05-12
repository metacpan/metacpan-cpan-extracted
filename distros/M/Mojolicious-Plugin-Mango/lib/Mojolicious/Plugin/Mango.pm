package Mojolicious::Plugin::Mango;
use Modern::Perl;
use Mango;
use Mojo::Base 'Mojolicious::Plugin';
use namespace::clean;

our $VERSION = '0.0.2'; # VERSION
# ABSTRACT: provide mango helpers to Mojolicious

sub register {
  my $self = shift;
  my $app  = shift;
  my $conf = shift || {};
  $conf->{helper} ||= 'db';
  $conf->{default_db} ||= 'test';
  $app->attr('_mango' => sub {
      my $m = Mango->new($conf->{mango});
      $m->default_db($conf->{default_db});
      $m->hosts($conf->{hosts}) if $conf->{hosts};
      $m;
    }
  );
  $app->helper('mango' => sub { shift; Mango->new(@_) });
  $app->helper($conf->{helper} => sub {
      my $self = shift;
      return $self->app->_mango->db(@_);
    }
  );
  $app->helper('hosts' => sub {
      my $self = shift;
      return $self->app->_mango->hosts(@_);
    });
  $app->helper('default_db' => sub {
      my $self = shift;
      return $self->app->_mango->default_db(@_);
    });
  $app->helper('coll' => sub {
      my $self = shift;
      return $self->app->_mango->db->collection(@_);
    });
  for my $helper (qw/get_more kill_cursors query/) {
    next if (defined ($conf->{"no_$helper"}));
    $app->helper($helper => sub {
        my $self = shift;
        $self->app->_mango->$helper(@_);
      })
  }
  for my $helper (qw/collection collection_names command dereference gridfs stats/) {
    next if (defined ($conf->{"no_$helper"}));
    $app->helper($helper => sub {
        my $self = shift;
        $self->app->_mango->db->$helper(@_);
      })
  }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mojolicious::Plugin::Mango - provide mango helpers to Mojolicious

=head1 VERSION

version 0.0.2

=head1 SYNOPSIS

For quick use:

In your Mojolicious app:

  use Mojolicious::Lite;
  plugin 'Mango', {default_db => 'mymongo'};

Then in your code:

  sub foo {
    my $self = shift;
    $self->coll('coll');
    $self->command();
    $self->db('other')->collection('othercoll');
  }

There's a more manually plugin step:

  use Mojolicious::Lite;
  plugin 'Mango', {
    mango => 'mangodb://name:pass@host:port/db',
    helper => 'foo',
    default_db => 'default_db',
    hosts => [ [localhost => 3000], [localhost => 4000] ],
    no_query => 1,
    no_command => 1,
  };

=head1 HELPERS

=over 4

=item * mango

Just call C<Mango-E<gt>new(@_)>.

=item * db or foo

The helper name is setted manually, default is db.

You could call this like: C<$self-E<gt>db>, it will allways
return a L<Mango::Database> object by C<default_db>

=item * coll/collection

Short for C<$self-E<gt>db-E<gt>collection>

=item * default_db

Reset default_db as you want, suggest no.

=item * hosts

May set the hosts to listen.

=item * kill_cursors

Delegated to C<Mango-E<gt>kill_cursors>.

=item * query

Deleaget to C<Mango-E<gt>query>.

=back

=head1 SEE ALSO

L<Mango>, L<Mango::Database>, L<Mango::Collection>

=head1 AUTHOR

Huo Linhe <huolinhe@berrygenomics.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Berry Genomics.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
