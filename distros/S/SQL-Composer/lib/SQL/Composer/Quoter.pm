package SQL::Composer::Quoter;

use strict;
use warnings;

sub new {
    my $class = shift;
    my (%params) = @_;

    my $self = {};
    bless $self, $class;

    $self->{quote_char}        = $params{quote_char}        ||= '`';
    $self->{name_separator}    = $params{name_separator}    ||= '.';
    $self->{quote_string_char} = $params{quote_string_char} ||= "'";

    if (my $driver = $params{driver}) {
        if ($driver =~ /Pg/i) {
            $self->{quote_char} = '"';
        }
    }

    return $self;
}

sub quote {
    my $self = shift;
    my ($column, $prefix) = @_;

    my @parts = split /\Q$self->{name_separator}\E/, $column;
    foreach my $part (@parts) {
        $part = $self->{quote_char} . $part . $self->{quote_char};
    }

    if ($prefix && @parts == 1) {
        unshift @parts, $self->{quote_char} . $prefix . $self->{quote_char};
    }

    return join $self->{name_separator}, @parts;
}

sub quote_string {
    my $self = shift;
    my ($string) = @_;

    $string =~ s{$self->{quote_string_char}}{\\$self->{quote_string_char}}g;

    return $self->{quote_string_char} . $string . $self->{quote_string_char};
}

sub split {
    my $self = shift;
    my ($quoted_column) = @_;

    my ($table, $column) = split /\Q$self->{name_separator}\E/, $quoted_column;
    ($column, $table) = ($table, '') unless $column;

    return
      map { s/^\Q$self->{quote_char}\E//; s/\Q$self->{quote_char}\E$//; $_ }
      ($table, $column);
}

1;
__END__

=pod

=head1 NAME

SQL::Composer::Quoter - internal SQL quotation

=head1 DESCRIPTION

Used internally.

=cut
