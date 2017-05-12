package Silki::Role::Schema::DebugUTF8;
{
  $Silki::Role::Schema::DebugUTF8::VERSION = '0.29';
}

use namespace::autoclean;

use Moose::Role;
use Encode ();

before new => sub {
    warn "new\n";
    shift->_debug_utf8(@_);
};

sub _get_column_values {
    my $self   = shift;
    my $select = shift;
    my $bind   = shift;

    my $dbh = $self->_dbh($select);

    my $sth = $dbh->prepare( $select->sql($dbh) );

    $sth->execute( @{$bind} );

    my %col_values;
    $sth->bind_columns( \( @col_values{ @{ $sth->{NAME} } } ) );

    my $fetched = $sth->fetch();

    $sth->finish();

    return unless $fetched;

    warn "_get_column_values\n";
    $self->_debug_utf8(%col_values);

    $self->_set_column_values_from_hashref( \%col_values );

    return \%col_values;
}

sub _debug_utf8 {
    my $inv = shift;

    my %data = ref $_[0] ? %{ $_[0] } : @_;

    my $class = ref $inv || $inv;
    warn "$class\n";

    for my $k ( sort keys %data ) {
        next if $k eq 'cached_content';
        warn "    $k => $data{$k} - ",
            ( Encode::is_utf8( $data{$k} ) || 0 ), "\n";
    }
    warn "\n\n";
}

1;
