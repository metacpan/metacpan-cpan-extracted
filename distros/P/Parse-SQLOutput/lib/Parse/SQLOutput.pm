use strict; use warnings;
package Parse::SQLOutput;
our $VERSION = '0.08';

use Mo qw'default';

has as => (default => sub { 'hoh' });
has header => (default => sub { 0 });
has key => (default => sub { '' });

sub parse {
    my ($self, $text) = @_;
    my @lines = split /\r?\n/, $text;

    my @tables = ();

    while (@lines) {
        $_ = shift(@lines);
        next unless /^\+/;
        my $offset = 2;
        my $fields = [];
        for (/\+(\-+)/g) {
            my $length = length() - 2;
            push @$fields, [$offset, $length];
            $offset += $length + 3;
        }
        my $header = shift(@lines);
        for (@$fields) {
            push(@$_, $self->_get_field($header, $_));
        }
        my $table = [[map $_->[-1], @$fields]];
        shift(@lines);
        while (my $line = shift(@lines)) {
            last unless $line =~ /^\|/;
            push @$table, [
                map {
                    $self->_get_field($line, $_);
                } @$fields
            ];
        }
        push @tables, $self->format($table);
    }
    return @tables;
}

sub format {
    my ($self, $input) = @_;
    my $method = 'format_' . $self->as;
    die "'as' must be 'hoh' or 'hol' or 'loh' or 'lol'"
        unless $self->can($method);
    return $self->$method($input);
}

sub format_hoh {
    my ($self, $input) = @_;
    my $output = {};
    my $as = $self->as;
    my $header = shift @$input;
    my $pos = $self->_key_pos($header);
    $output->{''} = $header if $self->header;
    for my $row (@$input) {
        my $key = $row->[$pos];
        $output->{$key} =
            $as eq 'hoh' ?  { $self->_zip($header, $row) } :
            $as eq 'hol' ? $row : die;
    }
    return $output;
}
*format_hol = \&format_hoh;

sub format_lol {
    my ($self, $input) = @_;
    my $output = [];
    my $as = $self->as;
    my $header = shift @$input;
    push @$output, $header if $self->header;
    for my $row (@$input) {
        push @$output,
            $as eq 'loh' ?  { $self->_zip($header, $row) } :
            $as eq 'lol' ? $row : die;
    }
    return $output;
}
*format_loh = \&format_lol;

sub _get_field {
    my ($self, $line, $offsets) = @_;
    my $value = substr($line, $offsets->[0], $offsets->[1]);
    $value =~ s!^\s*(.*?)\s*$!$1!;
    return $value;
}

sub _key_pos {
    my ($self, $header) = @_;
    my $key = $self->key;
    return 0 unless length $key;
    for (my $i = 0; $i < @$header; $i++) {
        return $i if $key eq $header->[$i];
    }
    die "'$key' is an invalid key name";
}

sub _zip {
    my ($self, $header, $row) = @_;
    map {
        ($_, shift(@$row));
    } @$header;
}

1;
