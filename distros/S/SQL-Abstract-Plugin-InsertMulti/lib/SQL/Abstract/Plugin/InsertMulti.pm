package SQL::Abstract::Plugin::InsertMulti;

use strict;
use warnings;

our $VERSION = '0.04';

use Carp ();
use Sub::Exporter -setup => +{
    into    => 'SQL::Abstract',
    exports => [
        qw/insert_multi update_multi _insert_multi _insert_multi_HASHREF _insert_multi_ARRAYREF _insert_multi_values _insert_multi_process_args/
    ],
    groups => +{
        default => [
            qw/insert_multi update_multi _insert_multi _insert_multi_HASHREF _insert_multi_ARRAYREF _insert_multi_values _insert_multi_process_args/
        ]
    },
};

sub insert_multi {
    my $self  = shift;
    my $table = $self->_table(shift);
    my ( $data, $opts, $fields ) = $self->_insert_multi_process_args(@_);
    my ( $sql, @bind ) = $self->_insert_multi( $table, $data, $opts );
    return wantarray ? ( $sql, @bind ) : $sql;
}

sub _insert_multi {
    my ( $self, $table, $data, $opts ) = @_;

    my $method = $self->_METHOD_FOR_refkind( '_insert_multi', $data->[0] );
    my ( $sql, @bind ) = $self->$method( $data, $opts );
    $sql = '( '
      . join( ', ', ( map { $self->_quote($_) } @{ $opts->{fields} } ) ) . ' ) '
      . $sql;

    $sql = join ' ' => grep { defined $_ } (
        $self->_sqlcase('insert'),
        $opts->{option},
        $self->_sqlcase( ( $opts->{ignore} ) ? 'ignore' : 'into' ),
        $table, $sql,
    );

    return ( $sql, @bind );
}

sub _insert_multi_HASHREF {
    my ( $self, $data, $opts ) = @_;
    my ( $sql, @bind ) = $self->_insert_multi_values( $data, $opts );
    return ( $sql, @bind );
}

sub _insert_multi_ARRAYREF {
    my ( $self, $data, $opts ) = @_;
    my ( $sql, @bind ) = $self->_insert_multi_values(
        [
            map {
                my %h;
                @h{ @{ $opts->{fields} } } = @$_;
                \%h;
              } @$data
        ],
        $opts
    );
    return ( $sql, @bind );
}

sub _insert_multi_values {
    my ( $self, $data, $opts ) = @_;

    my ( @value_sqls, @all_bind );

    for my $d (@$data) {
        my @values;
        for my $column ( @{$opts->{fields}} ) {
            my $v = $d->{$column};

            $self->_SWITCH_refkind(
                $v,
                {
                    ARRAYREFREF => sub {    # literal SQL with bind
                        my ( $sql, @bind ) = @${$v};

                        # $self->_assert_bindval_matches_bindtype(@bind);
                        push @values,   $sql;
                        push @all_bind, @bind;
                    },

                    # THINK : anything useful to do with a HASHREF ?
                    HASHREF => sub { # (nothing, but old SQLA passed it through)
                                     #TODO in SQLA >= 2.0 it will die instead
                        push @values, '?';
                        push @all_bind, $self->_bindtype( $column, $v );
                    },
                    SCALARREF => sub {    # literal SQL without bind
                        push @values, $$v;
                    },
                    SCALAR_or_UNDEF => sub {
                        push @values, '?';
                        push @all_bind, $self->_bindtype( $column, $v );
                    },
                }
            );
        }
        push( @value_sqls, '( ' . join( ', ' => @values ) . ' )' );
    }

    my $sql = $self->_sqlcase('values') . ' ' . join( ', ' => @value_sqls );

    if ( $opts->{update} ) {
        my @set;

        for my $k ( sort keys %{ $opts->{update} } ) {
            my $v     = $opts->{update}{$k};
            my $r     = ref $v;
            my $label = $self->_quote($k);

            $self->_SWITCH_refkind(
                $v,
                {
                    ARRAYREFREF => sub {    # literal SQL with bind
                        my ( $sql, @bind ) = @${$v};
                        push @set,      "$label = $sql";
                        push @all_bind, @bind;
                    },
                    SCALARREF => sub {      # literal SQL without bind
                        push @set, "$label = $$v";
                    },
                    SCALAR_or_UNDEF => sub {
                        push @set, "$label = ?";
                        push @all_bind, $self->_bindtype( $k, $v );
                    },
                }
            );
        }

        $sql .=
          $self->_sqlcase(' on duplicate key update ') . join( ', ', @set );
    }

    return ( $sql, @all_bind );
}

sub _insert_multi_process_args {
    my $self = shift;
    my ( $data, $opts, $fields );

    if ( ref $_[0] eq 'ARRAY' && !ref $_[0]->[0] ) {
        $fields = shift;
    }
    else {
        $fields = [ sort keys %{ $_[0]->[0] } ];
    }

    ( $data, $opts ) = @_;

    $opts ||= +{};
    $opts->{fields} ||= $fields;

    return ( $data, $opts );
}

sub update_multi {
    my $self  = shift;
    my $table = $self->_table(shift);
    my ( $data, $opts ) = $self->_insert_multi_process_args(@_);

    my %ignore;
    if ($opts->{update_ignore_fields}) {
        @ignore{@{$opts->{update_ignore_fields}}} = map { 1 } @{$opts->{update_ignore_fields}};
    }
    
    $opts->{update} = +{
        map {
            my ( $k, $v ) = ( $_, $self->_sqlcase('values( ') . $_ . ' )' );
            ( $k, \$v );
        }
        grep { !exists $ignore{$_} }
        @{ $opts->{fields} }
    };

    my ( $sql, @bind ) = $self->_insert_multi( $table, $data, $opts );
    return wantarray ? ( $sql, @bind ) : $sql;
}

1;
__END__

=head1 NAME

SQL::Abstract::Plugin::InsertMulti - add mysql bulk insert supports for SQL::Abstract

=head1 SYNOPSIS

  use SQL::Abstract;
  use SQL::Abstract::Plugin::InsertMulti;

  my $sql = SQL::Abstract->new;
  my ($stmt, @bind) = $sql->insert_multi('people', [
    +{ name => 'foo', age => 23, },
    +{ name => 'bar', age => 40, },
  ]);

=head1 DESCRIPTION

SQL::Abstract::Plugin::InsertMulti is enable bulk insert support for L<SQL::Abstract>. Declare 'use SQL::Abstract::Plugin::InsertMulti;' with 'use SQL::Abstract;',
exporting insert_multi() and update_multi() methods to L<SQL::Abstract> namespace from SQL::Abstract::Plugin::InsertMulti.
Plugin system is depends on 'into' options of L<Sub::Exporter>.

Notice: please check your mysql_allow_packet parameter using this module.

=head1 METHODS

=head2 insert_multi($table, \@data, \%opts)

  my ($stmt, @bind) = $sql->insert_multi('foo', [ +{ a => 1, b => 2, c => 3 }, +{ a => 4, b => 5, c => 6, }, ]);
  # $stmt = q|INSERT INTO foo( a, b, c ) VALUES ( ?, ?, ? ), ( ?, ?, ? )|
  # @bind = (1, 2, 3, 4, 5, 6);

@data is HashRef list.
%opts details is below.

=over

=item ignore

Use 'INSERT IGNORE' instead of 'INSERT INTO'.

=item update

Use 'ON DUPLICATE KEY UPDATE'.
This value is same as update()'s data parameters.

=item update_ignore_fields

update_multi() method is auto generating 'ON DUPLICATE KEY UPDATE' parameters:

  my ($stmt, @bind) = $sql->update_multi('foo', [qw/a b c/], [ [ 1, 2, 3 ], [ 4, 5, 6 ] ]);
  # $stmt = q|INSERT INTO foo( a, b, c ) VALUES ( ?, ?, ? ), ( ?, ?, ? ) ON DUPLICATE KEY UPDATE a = VALUES( a ), b = VALUES( b ), c = VALUES( c )|
  # @bind = (1, 2, 3, 4, 5, 6);

given update_ignore_fields,

  my ($stmt, @bind) = $sql->update_multi('foo', [qw/a b c/], [ [ 1, 2, 3 ], [ 4, 5, 6 ] ], +{ update_ignore_fields => [qw/b c/], });
  # $stmt = q|INSERT INTO foo( a, b, c ) VALUES ( ?, ?, ? ), ( ?, ?, ? ) ON DUPLICATE KEY UPDATE a = VALUES( a )|
  # @bind = (1, 2, 3, 4, 5, 6);

=back

=head2 insert_multi($table, \@field, \@data, \%opts)

  my ($stmt, @bind) = $sql->insert_multi('foo', [qw/a b c/], [ [ 1, 2, 3 ], [ 4, 5, 6 ] ]);
  # $stmt = q|INSERT INTO foo( a, b, c ) VALUES ( ?, ?, ? ), ( ?, ?, ? )|
  # @bind = (1, 2, 3, 4, 5, 6);

@data is ArrayRef list. See also L<insert_multi($table, \@data, \%opts)> %opts details.

=head2 update_multi($table, \@data, \%opts)

@data is HashRef list. See also L<insert_multi($table, \@data, \%opts)> %opts details.

  my ($stmt, @bind) = $sql->update_multi('foo', [ [ 1, 2, 3 ], [ 4, 5, 6 ] ]);
  # $stmt = q|INSERT INTO foo( a, b, c ) VALUES ( ?, ?, ? ), ( ?, ?, ? ) ON DUPLICATE KEY UPDATE a = VALUES( a ), b = VALUES( b ), c = VALUES( c )|
  # @bind = (1, 2, 3, 4, 5, 6);

=head2 update_multi($table, \@field, \@data, \%opts)

  my ($stmt, @bind) = $sql->update_multi('foo', [qw/a b c/], [ +{ a => 1, b => 2, c => 3 }, +{ a => 4, b => 5, c => 6, }, ]);
  # $stmt = q|INSERT INTO foo( a, b, c ) VALUES ( ?, ?, ? ), ( ?, ?, ? ) ON DUPLICATE KEY UPDATE a = VALUES( a ), b = VALUES( b ), c = VALUES( c )|
  # @bind = (1, 2, 3, 4, 5, 6);

@data is ArrayRef list. See also L<insert_multi($table, \@data, \%opts)> %opts details.

=head1 AUTHOR

Toru Yamaguchi E<lt>zigorou@cpan.orgE<gt>

Thanks ma.la L<http://subtech.g.hatena.ne.jp/mala/>. This module is based on his source codes.

=head1 SEE ALSO

=over

=item http://subtech.g.hatena.ne.jp/mala/20090729/1248880239

=item http://gist.github.com/158203

=item L<SQL::Abstract>

=item L<Sub::Exporter>

=back

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
