package SQL::Type::Guess;
use strict;
use warnings;
our $VERSION = '0.05';

=head1 NAME

SQL::Type::Guess - guess an appropriate column type for a set of data

=head1 SYNOPSIS

    my @data=(
      { seen => 1, when => '20140401', greeting => 'Hello', value => '1.05'  },
      { seen => 0, when => '20140402', greeting => 'World', value => '99.05' },
      { seen => 0, when => '20140402', greeting => 'World', value => '9.005' },
    );

    my $g= SQL::Type::Guess->new();
    $g->guess( @data );

    print $g->as_sql( table => 'test' );
    # create table test (
    #    "seen" decimal(1,0),
    #    "greeting" varchar(5),
    #    "value" decimal(5,3),
    #    "when" date
    # )

=cut

=head1 METHODS

=head2 C<< SQL:::Type::Guess->new( %OPTIONS ) >>

  my $g= SQL::Type::Guess->new();

Creates a new C<SQL::Type::Guess> instance. The following options are
supported:

=over 4

=item B<column_type>

Hashref of already known column types.

=item B<column_map>

Hashref mapping the combinations SQL type names
to the resulting type name.

=back

=cut

sub new {
    my( $class, %options )= @_;
    
    $options{ column_type } ||= {};
    $options{ column_map } ||= {
        ";date" => 'date',
        ";datetime" => 'datetime',
        ";decimal" => 'decimal(%2$d,%3$d)',
        ";varchar" => 'varchar(%1$d)',
        "date;" => 'date',
        "datetime;" => 'datetime',
        "datetime;datetime" => 'datetime',
        "decimal;" => 'decimal(%2$d,%3$d)',
        "varchar;" => 'varchar(%1$d)',
        "varchar;date" => 'varchar(%1$d)',
        "varchar;datetime" => 'varchar(%1$d)',
        "varchar;decimal" => 'varchar(%1$d)',
        "varchar;varchar" => 'varchar(%1$d)',
        "date;decimal" => 'decimal(%2$d,%3$d)',
        "date;varchar" => 'varchar(%1$d)',
        "date;date" => 'date',
        "datetime;varchar" => 'varchar(%1$d)',
        "decimal;date" => 'decimal(%2$d,%3$d)',
        "decimal;varchar" => 'varchar(%1$d)',
        "decimal;decimal" => 'decimal(%2$d,%3$d)',
        ";" => '',
    };
    
    bless \%options => $class;
}

=head2 C<< $g->column_type >>

    $g->guess({ foo => 1, bar => 'Hello' },{ foo => 1000, bar => 'World' });
    print $g->column_type->{ 'foo' } # decimal(4,0)

Returns a hashref containing the SQL types to store all
values in the columns seen so far.

=cut

sub column_type { $_[0]->{column_type} };

=head2 C<< $g->column_map >>

Returns the hashref used for the type transitions. The current
transitions used for generalizing data are:

  date -> decimal -> varchar

This is not entirely safe, as C<2014-01-01> can't be safely
loaded into an C<decimal> column, but assuming your data is representative
of the data to be stored that shouldn't be much of an issue.

=cut

sub column_map  { $_[0]->{column_map} };

=head2 C<< $g->guess_data_type $OLD_TYPE, @VALUES >>

    $type= $g->guess_data_type( $type, 1,2,3,undef,'Hello','World', );

Returns the data type that encompasses the already established data type in C<$type>
and the new values as passed in via C<@values>.

If there is no preexisting data type, C<$type> can be C<undef> or the empty string.

=cut

our @recognizers = (
    sub { if( ! defined $_[0] or $_[0] eq ''                              ) { return {} }}, # empty value, nothing to change
    sub { if( $_[0] =~ /^((?:19|20)\d\d)-?(0\d|1[012])-?([012]\d|3[01])$/ ) { return { this_value_type => 'date', 'pre' => 8 } }}, # date
    sub { if( $_[0] =~ m!^\s*[01]\d/[0123]\d/(?:19|20)\d\d\s[012]\d:[012345]\d:[0123456]\d(\.\d*)?$! ) { return { this_value_type => 'datetime',        } }}, # US-datetime
    sub { if( $_[0] =~ m!^\s*[0123]\d\.[01]\d\.(?:19|20)\d\d\s[012]\d:[012345]\d:[0123456]\d(\.\d*)?$! ) { return { this_value_type => 'datetime',        } }}, # EU-datetime
    sub { if( $_[0] =~ m!^\s*(?:19|20)\d\d-[01]\d-[0123]\d[\sT][012]\d:[012345]\d:[0123456]\d(\.\d*)?Z?$! ) { return { this_value_type => 'datetime',        } }}, # ISO-datetime
    sub { if( $_[0] =~ m!^\s*[01]\d/[0123]\d/(?:19|20)\d\d$!              ) { return { this_value_type => 'date',            } }}, # US-date
    sub { if( $_[0] =~ m!^\s*[0123]\d\.[01]\d\.(?:19|20)\d\d$!            ) { return { this_value_type => 'date',            } }}, # EU-date
    sub { if( $_[0] =~ /^\s*[+-]?(\d+)\s*$/                               ) { return { this_value_type => 'decimal', 'pre' => length($1), post => 0 } }}, # integer
    sub { if( $_[0] =~ /^\s*[+-]?(\d+)\.(\d+)\s*$/                        ) { return { this_value_type => 'decimal', 'pre' => length($1), post => length($2) } }}, # integer
    sub {                                                                     return { this_value_type => 'varchar', length => length $_[0] }}, # catch-all
);

sub guess_data_type {
    my( $self, $type, @values )= @_;

    my $column_map= $self->column_map;
    for my $value (@values) {
        my $old_type = $type;

        my ( $descriptor );
        for (@recognizers) {
            last if $descriptor = $_->($value);
        };
        $descriptor->{ this_value_type } ||= '';
        $descriptor->{ pre }    ||= 0;
        $descriptor->{ post }   ||= 0;
        $descriptor->{ length } ||= length( $value ) || 0;

        if( $type ) {
            if( $type =~ s/\s*\((\d+)\)// ) {
                if( $1 > $descriptor->{ 'length' } ) {
                    $descriptor->{ 'length' } = $1;
                };

            } elsif( $type =~ s/\s*\((\d+),(\d+)\)// ) {
                my( $new_prec, $new_post )= ($1,$2);
                my $new_pre= $new_prec - $new_post;
                $descriptor->{ pre }  = $new_pre > $descriptor->{ pre }  ? $new_pre : $descriptor->{ pre } ;
                $descriptor->{ post } = $2 > $descriptor->{ post } ? $2 : $descriptor->{ post } ;
            };
        } else {
            $type= '';
        };
        
        my $this_value_type = $descriptor->{ this_value_type };
        if( $type ne $this_value_type ) {
            if( not exists $column_map->{ "$type;$this_value_type" }) {
                die "Unknown transition '$type' => '$this_value_type'";
            };
        };

        {
            no warnings;
            $type = sprintf $column_map->{ "$type;$this_value_type" }, $descriptor->{ 'length' }, $descriptor->{ pre } + $descriptor->{ post }, $descriptor->{ post };
        };
    };
    $type
};

=head2 C<< $g->guess( @RECORDS ) >>

    my @data= (
        { rownum => 1, name => 'John Smith', street => 'Nowhere Road', birthday => '1996-01-01' },
        { rownum => 2, name => 'John Doe', street => 'Anywhere Plaza', birthday => '1904-01-01' },
        { rownum => 3, name => 'John Bull', street => 'Everywhere Street', birthday => '2001-09-01' },
    );
    $g->guess( @data );

Modifies the data types for the keys in the given hash.

=cut

sub guess {
    my( $self, @records )= @_;
    my $column_type= $self->column_type;
    for my $row (@records) {
        for my $col (keys %$row) {
            my( $new_type )= $self->guess_data_type($column_type->{$col}, $row->{ $col });
            if( $new_type ne ($column_type->{ $col } || '')) {
                #print sprintf "%s: %s => %s ('%s')\n",
                #    $col, ($column_type{ $col } || 'unknown'), ($new_type || 'unknown'), $info->{$col};
                $column_type->{ $col }= $new_type;
            };
        }
    }
}

=head2 C<< $g->as_sql %OPTIONS >>

    print $g->as_sql();

Returns an SQL string that describes the data seen so far.

Options:

=over 4

=item B<user>

Supply a username for the table

=item B<columns>

This allows you to specify the columns and their order. The default
is alphabetical order of the columns.

=back

=cut

sub as_sql {
    my( $self, %options )= @_;
    my $table= $options{ table };
    my $user= defined $options{ user }
              ? "$options{ user }."
              : ''
              ;
    my $column_type= $self->column_type;
    $options{ columns }||= [ sort keys %{ $column_type } ];
    my $columns= join ",\n", map { qq{    "$_" $column_type->{ $_ }} } @{ $options{ columns }};
        my($sql)= <<SQL;
create table $user$table (
$columns
)
SQL
    return $sql;
}

1;

=head1 BUG TRACKER

Please report bugs in this module via the RT CPAN bug queue at
L<https://rt.cpan.org/Public/Dist/Display.html?Name=SQL-Type-Guess>
or via mail to L<sql-type-guess-Bugs@rt.cpan.org>.

=head1 AUTHOR

Max Maischein C<corion@cpan.org>

=head1 COPYRIGHT (c)

Copyright 2014-2018 by Max Maischein C<corion@cpan.org>.

=head1 LICENSE

This module is released under the same terms as Perl itself.

=cut
