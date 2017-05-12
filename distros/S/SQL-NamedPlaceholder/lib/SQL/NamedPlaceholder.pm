package SQL::NamedPlaceholder;

use strict;
use warnings;
use Exporter::Lite;
use Scalar::Util qw(reftype);

use Carp;

our $VERSION = '0.10';
our @EXPORT_OK = qw(bind_named);

sub bind_named {
	my ($sql, $hash) = @_;
	$sql or croak 'my ($sql, $bind) = bind_named($sql, $hash) requires $sql';
	(reftype($hash) || '') eq 'HASH' or croak 'must specify HASH as bind values';

	# replace question marks as placeholder. e.g. [`hoge` = ?] to [`hoge` = :hoge]
	$sql =~ s{(([`"]?)(\S+?)\2\s*(=|<=?|>=?|<>|!=|<=>)\s*)\?}{$1:$3}g;

	my $bind = [];

	$sql =~ s{:([A-Za-z_][A-Za-z0-9_]*)}{
		croak("'$1' does not exist in bind hash") if !exists $hash->{$1};
		my $type = ref($hash->{$1});
		if ($type eq 'ARRAY') {
			if (@{ $hash->{$1} }) {
				push @$bind, @{ $hash->{$1} };
				join ', ', map { '?' } @{ $hash->{$1} };
			} else {
				push @$bind, undef;
				'?';
			}
		} else {
			push @$bind, $hash->{$1};
			'?';
		}
	}eg;

	wantarray ? ($sql, $bind) : [$sql, $bind];
}

1;
__END__

=encoding utf8

=head1 NAME

SQL::NamedPlaceholder - extension of placeholder

=head1 SYNOPSIS

  use SQL::NamedPlaceholder qw(bind_named);

  my ($sql, $bind) = bind_named(q[
      SELECT *
      FROM entry
      WHERE
          user_id = :user_id
  ], {
      user_id => $user_id
  });

  $dbh->prepare_cached($sql)->execute(@$bind);


=head1 DESCRIPTION

SQL::NamedPlaceholder is extension of placeholder. This enable more readable and robust code.

=head1 FUNCTION

=over 4

=item ($sql, $bind) = bind_named($sql, $hash);

The $sql parameter is SQL string which contains named placeholders. The $hash parameter is map of bind parameters.

The returned $sql is new SQL string which contains normal placeholders ('?'), and $bind is array reference of bind parameters.

=back

=head1 SYNTAX

=over 4

=item :foobar

Replace as placeholder which uses value from $hash->{foobar}.

=item foobar = ?, foobar > ?, foobar < ?, foobar <> ?, etc.

This is same as 'foobar = :foobar'.

=back

=head1 AUTHOR

cho45 E<lt>cho45@lowreal.netE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
