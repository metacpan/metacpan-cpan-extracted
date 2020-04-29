package SQL::Bind;
use strict;
use warnings;
use base 'Exporter';
our @EXPORT_OK = qw(sql);

our $VERSION = '1.00';

sub sql {
    my ($sql, %params) = @_;

    my @bind;

    $sql =~ s{:([a-z_][a-z0-9_]*)(!)?}{
        my ($replacement, @subbind) = _replace($1, $2, %params);

        push @bind, @subbind;

        $replacement;
    }gei;

    return ($sql, @bind);
}

sub _replace {
    my ($placeholder, $raw, %params) = @_;

    my @bind;

    my $replacement = '';

    if (!exists $params{$placeholder}) {
        die sprintf 'unknown placeholder: %s', $placeholder;
    }

    if (ref $params{$placeholder} eq 'HASH') {
        if ($raw) {
            $replacement = join ', ', map { $_ . '=' . $params{$placeholder}->{$_} }
              keys %{$params{$placeholder}};
        }
        else {
            $replacement = join ', ', map { $_ . '=?' } keys %{$params{$placeholder}};
            push @bind, values %{$params{$placeholder}};
        }
    }
    elsif (ref $params{$placeholder} eq 'ARRAY') {
        if ($raw) {
            $replacement = join ', ', @{$params{$placeholder}};
        }
        else {
            $replacement = join ', ', map { '?' } 1 .. @{$params{$placeholder}};
            push @bind, @{$params{$placeholder}};
        }
    }
    else {
        if ($raw) {
            $replacement = $params{$placeholder};
        }
        else {
            $replacement = '?';
            push @bind, $params{$placeholder};
        }
    }

    return ($replacement, @bind);
}

1;
__END__

=head1 NAME

SQL::Bind - SQL flexible placeholders

=head1 SYNOPSIS

    use SQL::Bind qw(sql);

    # Scalars
    my ($sql, @bind) =
      sql 'SELECT foo FROM bar WHERE id=:id AND status=:status',
      id     => 1,
      status => 'active';

    # Arrays
    my ($sql, @bind) = sql 'SELECT foo FROM bar WHERE id IN (:id)', id => [1, 2, 3];

    # Hashes
    my ($sql, @bind) = sql 'UPDATE bar SET :columns', columns => {foo => 'bar'};

    # Raw values
    my ($sql, @bind) = sql 'INSERT INTO bar (:keys!) VALUES (:values)',
      keys   => [qw/foo/],
      values => [qw/bar/];

=head1 DESCRIPTION

L<SQL::Bind> simplifies SQL queries maintenance by introducing placeholders. The behavior of the replacement depends on
the type of the value. Scalars, Arrays and Hashes are supported.

=head2 C<Placeholders>

A placeholders is an alphanumeric sequence that is prefixed with C<:> and can end with C<!> for raw values. Some examples:

    :name
    :status
    :CamelCase
    :Value_123
    :ThisWillBeInsertedAsIs!

=head2 C<Scalar values>

Every value is replace with a C<?>.

    my ($sql, @bind) =
      sql 'SELECT foo FROM bar WHERE id=:id AND status=:status',
      id     => 1,
      status => 'active';

    # SELECT foo FROM bar WHERE id=? AND status=?
    # [1, 'active']

=head2 C<Array values>

Arrays are replaced with a sequence of C<?, ?, ...>.

    my ($sql, @bind) = sql 'SELECT foo FROM bar WHERE id IN (:id)', id => [1, 2, 3];

    # SELECT foo FROM bar WHERE id IN (?, ?, ?)
    # [1, 2, 3]

=head2 C<Hash values>

Hahes are replaced with a sequence of C<key1=?, key2=?, ...>.

    my ($sql, @bind) = sql 'UPDATE bar SET :columns', columns => {foo => 'bar'};

    # UPDATE bar SET foo=?
    # ['bar']

=head2 C<Raw values>

Sometimes raw values are needed be it another identifier, or a list of columns (e.g. C<INSERT, UPDATE>). For this case
a placeholder should be suffixed with a C<!>.

    my ($sql, @bind) = sql 'INSERT INTO bar (:keys!) VALUES (:values)',
      keys   => [qw/foo/],
      values => [qw/bar/];

    # INSERT INTO bar (foo) VALUES (?)
    # ['bar']

=head1 DEVELOPMENT

=head2 Repository

    http://github.com/vti/sql-bind

=head1 CREDITS

=head1 AUTHOR

Viacheslav Tykhanovskyi, C<vti@cpan.org>.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2020, Viacheslav Tykhanovskyi

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=cut
