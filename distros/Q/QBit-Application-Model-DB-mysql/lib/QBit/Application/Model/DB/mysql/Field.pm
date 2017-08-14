package QBit::Application::Model::DB::mysql::Field;
$QBit::Application::Model::DB::mysql::Field::VERSION = '0.011';
use qbit;

use base qw(QBit::Application::Model::DB::Field);

our %DATA_TYPES = (
    DATE       => 'EMPTY',
    TIME       => 'EMPTY',
    TIMESTAMP  => 'EMPTY',
    DATETIME   => 'EMPTY',
    YEAR       => 'EMPTY',
    TINYBLOB   => 'BLOB',
    BLOB       => 'BLOB',
    MEDIUMBLOB => 'BLOB',
    LONGBLOB   => 'BLOB',
    BOOLEAN    => 'EMPTY',
    TINYINT    => 'INT',
    SMALLINT   => 'INT',
    MEDIUMINT  => 'INT',
    INT        => 'INT',
    BIGINT     => 'INT',
    REAL       => 'FLOAT',
    FLOAT      => 'FLOAT',
    DECIMAL    => 'FLOAT',
    NUMERIC    => 'FLOAT',
    BIT        => 'BINARY',
    BINARY     => 'BINARY',
    VARBINARY  => 'BINARY',
    CHAR       => 'CHAR',
    VARCHAR    => 'CHAR',
    TINYTEXT   => 'TEXT',
    TEXT       => 'TEXT',
    MEDIUMTEXT => 'TEXT',
    LONGTEXT   => 'TEXT',
    ENUM       => 'ENUM',
    SET        => 'ENUM',
    JSON       => 'BLOB',
);

our %FIELD2STR = (
    EMPTY => sub {
        return
            $_->quote_identifier($_->name) . ' '
          . uc($_->type)
          . ($_->{'not_null'} ? ' NOT NULL' : '')
          . (exists($_->{'default'}) ? ' DEFAULT ' . $_->quote($_->{'default'}) : '');
    },
    INT => sub {
        return
            $_->quote_identifier($_->name) . ' '
          . uc($_->type)
          . ($_->{'length'}          ? '(' . int($_->{'length'}) . ')'          : '')
          . ($_->{'unsigned'}        ? ' UNSIGNED'                              : '')
          . ($_->{'zerofill'}        ? ' ZEROFILL'                              : '')
          . ($_->{'not_null'}        ? ' NOT NULL'                              : '')
          . ($_->{'autoincrement'}   ? ' AUTO_INCREMENT'                        : '')
          . (exists($_->{'default'}) ? ' DEFAULT ' . $_->quote($_->{'default'}) : '');
    },
    FLOAT => sub {
        return
            $_->quote_identifier($_->name) . ' '
          . uc($_->type)
          . (
            $_->{'length'}
            ? '(' . int($_->{'length'}) . ($_->{'decimals'} ? ', ' . int($_->{'decimals'}) : '') . ')'
            : ''
          )
          . ($_->{'unsigned'}        ? ' UNSIGNED'                              : '')
          . ($_->{'zerofill'}        ? ' ZEROFILL'                              : '')
          . ($_->{'not_null'}        ? ' NOT NULL'                              : '')
          . (exists($_->{'default'}) ? ' DEFAULT ' . $_->quote($_->{'default'}) : '');
    },
    BINARY => sub {
        return
            $_->quote_identifier($_->name) . ' '
          . uc($_->type)
          . ($_->{'length'}          ? '(' . int($_->{'length'}) . ')'          : '')
          . ($_->{'not_null'}        ? ' NOT NULL'                              : '')
          . (exists($_->{'default'}) ? ' DEFAULT ' . $_->quote($_->{'default'}) : '');
    },
    CHAR => sub {
        my @locales;
        @locales = keys(%{$_[0]->db->get_option('locales', [])}) if $_->{'i18n'};
        @locales = (undef) unless @locales;

        my $f = $_;
        return join(
            ", ",
            map {
                    $f->quote_identifier($f->name . (defined($_) ? "_$_" : '')) . ' '
                  . uc($f->type) . '('
                  . (int($f->{'length'} || 0) || 255) . ')'
                  . (
                    $f->{'charset'} ? ' CHARACTER SET ' . $f->quote($f->{'charset'})
                    : ''
                  )
                  . (
                    $f->{'collation'} ? ' COLLATE ' . $f->quote($f->{'collation'})
                    : ''
                  )
                  . ($f->{'not_null'} ? ' NOT NULL' : '')
                  . (exists($f->{'default'}) ? ' DEFAULT ' . $f->quote($f->{'default'}) : '');
              } @locales
        );
    },
    TEXT => sub {
        my @locales;
        @locales = keys(%{$_[0]->db->get_option('locales', [])}) if $_->{'i18n'};
        @locales = (undef) unless @locales;

        my $f = $_;
        return join(
            ", ",
            map {
                    $f->quote_identifier($f->name . (defined($_) ? "_$_" : '')) . ' '
                  . uc($f->type)
                  . ($f->{'binary'} ? ' BINARY' : '')
                  . (
                    $f->{'charset'} ? ' CHARACTER SET ' . $f->quote($f->{'charset'})
                    : ''
                  )
                  . (
                    $f->{'collation'} ? ' COLLATE ' . $f->quote($f->{'collation'})
                    : ''
                  )
                  . ($f->{'not_null'} ? ' NOT NULL' : '')
              } @locales
        );
    },
    ENUM => sub {
        my $self = $_;
        return
            $_->quote_identifier($_->name) . ' '
          . uc($_->type) . '('
          . join(', ', map {$self->quote($_)} @{$_->{'values'}}) . ')'
          . (
            $_->{'charset'} ? ' CHARACTER SET ' . $_->quote($_->{'charset'})
            : ''
          )
          . (
            $_->{'collation'} ? ' COLLATE ' . $_->quote($_->{'collation'})
            : ''
          )
          . ($_->{'not_null'} ? ' NOT NULL' : '')
          . (exists($_->{'default'}) ? ' DEFAULT ' . $_->quote($_->{'default'}) : '');
    },
    BLOB => sub {
        return $_->quote_identifier($_->name) . ' ' . uc($_->type) . ($_->{'not_null'} ? ' NOT NULL' : '');
    },
);

sub init_check {
    my ($self) = @_;

    $self->SUPER::init_check();

    throw gettext('Unknown type: %s', $self->{'type'})
      unless exists($DATA_TYPES{uc($self->{'type'})});
}

sub create_sql {
    my ($self) = @_;

    return $FIELD2STR{$DATA_TYPES{uc($self->type)}}($self);
}

TRUE;

__END__

=encoding utf8

=head1 Name

QBit::Application::Model::DB::mysql::Field - Class for MySQL fields.

=head1 Description

Implements work with MySQL fields.

=head1 Package methods

=head2 create_sql

Generate and returns a sql for field.

B<No arguments.>

B<Return values:>

=over

=item

B<$sql> - string

=back

=head2 init_check

Check options for field.

B<No arguments.>

=cut
