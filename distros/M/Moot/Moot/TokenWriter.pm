package Moot::TokenWriter;
use Carp;
use strict;

##=====================================================================
## TokenWriter: Constructors etc.

sub new {
  confess(__PACKAGE__, "::new(): abstract method called");
}

##=====================================================================
## TokenWriter: Token Stream Operations

sub to_string {
  my $tw = shift;
  my $bufr = ref($_[0]) ? $_[0] : \$_[0];
  open(my $fh, ">>", $bufr)
    or confess(__PACKAGE__, "::to_string(): could not open fh to string buffer");
  return $tw->to_fh($fh);
}

1; ##-- be happy

__END__

=pod

=head1 NAME

Moot::TokenWriter - libmoot: Token I/O: writer

=head1 SYNOPSIS

  use Moot::TokenWriter;

  ##=====================================================================
  ## Constructors etc

  $tw = $CLASS->new($fmt)	      ##-- constructor, given TokenIOFormat

  ##=====================================================================
  ## Output Selection

  $tw->close();			     ##-- close current output sink
  $bool = $tw->opened();             ##-- true iff opened

  $tw->to_file($filename);           ##-- output to named file
  $tw->to_fh($fh);                   ##-- output to filehandle
  $tw->to_string($buffer);           ##-- output to string buffer

  ##=====================================================================
  ## Token-Stream Access

  $tw->put_token($w);
  $tw->put_tokens(\@s);
  $tw->put_sentence($s);

  $tw->put_comment_block_begin();
  $tw->put_comment_block_end();
  $tw->put_comment($str);

  $tw->put_raw($raw_str);

  ##=====================================================================
  ## Accessors

  $fmt = $tw->format();              ##-- get/set bitmask of I/O format flags
  $fmt = $tw->format($fmt);

  $name = $tw->name();               ##-- get/set reader (class) name
  $name = $tw->name($name);

=head1 DESCRIPTION

The Moot::TokenWriter module provides wrappers for word- and sentence-oriented output
streams included in the libmoot library for Hidden Markov Model decoding.

=head1 SEE ALSO

Moot::TokenWriter::Native(3perl),
Moot::TokenWriter(3perl),
Moot::TokenIO(3perl),
Moot(3perl),
moot(1),
perl(1).

=head1 AUTHOR

Bryan Jurish E<lt>moocow@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013 by Bryan Jurish

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.2 or,
at your option, any later version of Perl 5 you may have available.

=cut
