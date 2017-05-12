package Net::Google::SafeBrowsing2::Postgres;

use strict;
use warnings;

use base 'Net::Google::SafeBrowsing2::DBI';

use Carp;
use DBI;
use List::Util qw(first);

our $VERSION = '0.02';

=head1 NAME

Net::Google::SafeBrowsing2::Postgres - Postgres as back-end storage for the
Google Safe Browsing v2 database

=head1 SYNOPSIS

  use Net::Google::SafeBrowsing2::Postgres;

  my $storage = Net::Google::SafeBrowsing2::Postgres->new(
    host     => '127.0.0.1',
    database => 'google_safe_browsing',
    username => $username,
    password => $password,
  );
  
  # ...

  $storage->close();

=head1 DESCRIPTION

This is an implementation of L<Net::Google::SafeBrowsing2::Storage> using
Postgres.

=head1 CONSTRUCTOR

=over 4

=back

=head2 new()

Create a Net::Google::SafeBrowsing2::Postgres object

  my $storage = Net::Google::SafeBrowsing2::Postgres->new(
      host     => '127.0.0.1', 
      database => 'google_safe_browsing', 
      username => $username,
      password => $password,
  );

Arguments

=over 4

=item host

Specifies Postgres host name. Defaults to 127.0.0.1.

=item database

Specifies Postgres database name. Defaults to "google_safe_browsing".

=item username

Specifies the username for the Postgres connection. Required.

=item password

Specifies the password for the Postgres connection. Required.

=item keep_all

Optional. Set to 1 to keep old information (such as expiring full hashes)
in the database. 0 (delete) by default.

=back

=cut

sub new {
  my ($class, %args) = @_;

  # Default arguments
  my $self = { 
    host     => '127.0.0.1',
    database => 'google_safe_browsing',
    keep_all => 0,

    %args,
  };

  if (!$self->{username}) {
    croak "username required";
  }

  if (!$self->{password}) {
    croak "password required";
  }

  bless $self, $class;

  $self->init();

  return $self;
}

=head1 PUBLIC FUNCTIONS

=over 4

See L<Net::Google::SafeBrowsing2::Storage> for a complete list of public functions.

=back

=head2 close()

Cleanup old full hashes, and close the connection to the database.

  $storage->close();

=cut

sub init {
  my ($self, %args) = @_;

  $self->{dbh} = DBI->connect(
    "DBI:Pg:dbname=" . $self->{database} . ";host=" . $self->{host},
    $self->{username},
    $self->{password},
    {
      RaiseError => 1,
    },
  );

  my @tables = $self->{dbh}->tables;

  # Postgres reports normal tables (compared to internal ones) with a
  # prefix of "public."
  if (! defined first { /public\.updates/ } @tables) {
    $self->create_table_updates();
  }
  if (! defined first { /public\.a_chunks/ } @tables) {
    $self->create_table_a_chunks();
  }
  if (! defined first { /public\.s_chunks/ } @tables) { 
    $self->create_table_s_chunks();
  }
  if (! defined first { /public\.full_hashes/ } @tables) {
    $self->create_table_full_hashes();
  }
  if (! defined first { /public\.full_hashes_errors/ } @tables) { 
    $self->create_table_full_hashes_errors();
  }
  if (! defined first { /public\.mac_keys/ } @tables) { 
    $self->create_table_mac_keys();
  }
}

# Overridden because Postgres uses SERIAL instead of AUTO_INCREMENT.
sub create_table_full_hashes {
  my ($self, %args) = @_;

  my $schema = qq{
    CREATE TABLE full_hashes (
      id SERIAL PRIMARY KEY,
      num INT,
      hash VARCHAR( 32 ),
      list VARCHAR( 50 ),
      timestamp INT Default '0'
    );
  };

  $self->{dbh}->do($schema);

  my $index = qq{
    CREATE UNIQUE INDEX hash ON full_hashes (
      num,
      hash,
      list
    );
  };
  $self->{dbh}->do($index);
}

# Overridden because Postgres uses SERIAL instead of AUTO_INCREMENT.
sub create_table_full_hashes_errors {
  my ($self, %args) = @_;

  my $schema = qq{
    CREATE TABLE full_hashes_errors (
      id SERIAL PRIMARY KEY,
      errors INT Default '0',
      prefix VARCHAR( 8 ),
      timestamp INT Default '0'
    );
  };

  $self->{dbh}->do($schema);
}


sub add_chunks_a {
  my ($self, %args) = @_;
  my $chunknum = $args{chunknum}  || 0;
  my $chunks   = $args{chunks}    || [];
  my $list     = $args{'list'}    || '';

  $self->{add_chunks_a_ins_sth} ||= $self->{dbh}->prepare('INSERT INTO a_chunks (hostkey, prefix, num, list) VALUES (?, ?, ?, ?)');
  $self->{add_chunks_a_del_sth} ||= $self->{dbh}->prepare('DELETE FROM a_chunks WHERE hostkey = ? AND  prefix  = ? AND num = ? AND  list  = ?');

  my $add = $self->{add_chunks_a_ins_sth};
  my $del = $self->{add_chunks_a_del_sth};

  foreach my $chunk (@$chunks) {
    # Crude workaround for longer prefixes. Although Google state that the
    # length varies, the overwhelming majority are 4 bytes. However, I have
    # seen a 32 byte one (chunk 69961).
    #
    # If this becomes more of a problem, the schema will have to be adjusted.
    if (length($chunk->{prefix}) > 8) {
      $chunk->{prefix} = substr $chunk->{prefix}, 0, 4;
    }

    $del->execute( $chunk->{host}, $chunk->{prefix}, $chunknum, $list );
    $add->execute( $chunk->{host}, $chunk->{prefix}, $chunknum, $list );
  }

  if (scalar @$chunks == 0) { # keep empty chunks
    $del->execute( '', '', $chunknum, $list );
    $add->execute( '', '', $chunknum, $list );
  }
}

=head1 SEE ALSO

See L<Net::Google::SafeBrowsing2> for handling Google Safe Browsing v2.

=head1 COPYRIGHT AND LICENSE

Copyright 2012 Nick Johnston, nickjohnstonsky@gmail.com. Based on
C<Net::Google::SafeBrowsing2> by Julien Sobrier.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut

1;
