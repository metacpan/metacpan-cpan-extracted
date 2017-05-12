package SQL::OOP::Dataset;
use strict;
use warnings;
use SQL::OOP::Base;
use SQL::OOP::ID;
use Scalar::Util qw(blessed);
use base qw(SQL::OOP::Base);

sub MODE_INSERT() {1} ## no critic
sub MODE_UPDATE() {2} ## no critic

### ---
### Constructor
### ---
sub new {
    my $class = shift @_;
    my $data_ref = (scalar @_ == 1) ? shift @_ : [@_];
    if (ref $data_ref eq 'HASH') {
        warn 'Deprecated: call the method with key-value array instead of hash';
        $data_ref = [%$data_ref];
    }
    my $self = bless {
        gen     => undef,
        array  => [],
    }, $class;
    
    return $self->append($data_ref);
}

### ---
### append elements
### ---
sub append {
    my $self = shift @_;
    my $data_ref = (scalar @_ == 1) ? shift @_ : [@_];
    if (ref $data_ref eq 'HASH') {
        warn 'Deprecated: call the method with key-value array instead of hash';
        $data_ref = [%$data_ref];
    }
    my @copied = @{$data_ref};
    $self->_init_gen;
    
    while (my($key, $val) = splice @copied, 0, 2) {
        push(@{$self->{array}}, SQL::OOP::ID->new($key)->to_string, $val);
    }
    
    return $self;
}

### ---
### Get binded values in array
### ---
sub bind {
    my $self = shift;
    my @copy = @{$self->{array}};
    my @vals;
    while (my ($k, $v) = splice @copy, 0, 2) {
        push(@vals, $v);
    }
    my @out = map {
        if (blessed($_)) {
            $_->bind;
        } else {
            $_;
        }
    } @vals;
    return @out if (wantarray);
    return scalar @out;
}

### ---
### Get SQL for UPDATE command in string
### ---
sub to_string_for_update {
    my ($self, $prefix) = @_;
    local $SQL::OOP::Base::quote_char = $self->quote_char;
    $self->generate(MODE_UPDATE);
    if ($self->{gen} && $prefix) {
        return $prefix. ' '. $self->{gen};
    } else {
        return $self->{gen};
    }
}

### ---
### Get SQL for INSERT command in string
### ---
sub to_string_for_insert {
    my ($self, $prefix) = @_;
    local $SQL::OOP::Base::quote_char = $self->quote_char;
    $self->generate(MODE_INSERT);
    if ($self->{gen} && $prefix) {
        return $prefix. ' '. $self->{gen};
    } else {
        return $self->{gen};
    }
}

sub generate {
    my ($self, $type) = @_;
    
    my @copy = @{$self->{array}};
    my @key;
    my @val;
    while (my($k, $v) = splice @copy, 0, 2) {
        push(@key, $k);
        push(@val, $v);
    }
    
    if ($type eq MODE_INSERT) {
        $self->{gen} = sprintf('(%s) VALUES (%s)',
            join(', ', @key),
            join(', ', map {blessed($_) ? $_->to_string : '?'} @val));
    } elsif ($type eq MODE_UPDATE) {
        $self->{gen} = '';
        for my $idx (0 .. (scalar @key) - 1) {
            $self->{gen} .= ', '. sprintf('%s = %s', $key[$idx],
                        blessed($val[$idx]) ? $val[$idx]->to_string : '?');
        }
        $self->{gen} =~ s{^, }{};
    }
    return $self;
}

sub retrieve {
    my ($self, $key) = @_;
    my %tmp = (@{$self->{array}});
    return $tmp{$key} || $tmp{$self->quote($key)};
}

1;

__END__

=head1 NAME

SQL::OOP::Dataset - Dataset class for INSERT or UPDATE commands

=head1 SYNOPSIS

    my $dataset = SQL::OOP::Dataset->new(field1 => $value2, field2 => $value2);
    
    $dataset->append(field3 => $value3, field4 => $value4);

=head1 DESCRIPTION

SQL::OOP::Dataset is a class which represents data sets for INSERT or UPDATE

=head1 METHODS

=head2 SQL::OOP::Dataset->new(@data)

Constructor.

    SQL::OOP::Dataset->new(field => 'a', field2 => 'b', field3 => undef);

=head2 $instance->append(@data)

Appends data entries.

    $instance->append(field => 'a', field2 => 'b', field3 => undef);

=head2 $instance->generate(MODE_INSERT or MODE_UPDATE)

This method must be called internally and generates SQL snippet for commands.

=head2 $instance->to_string_for_insert

This method must be called from inside the command subclasses.

=head2 $instance->to_string_for_update

This method must be called from inside the command subclasses.

=head2 $instance->bind

Returns binded values.

=head1 CONSTANTS

=head2 MODE_INSERT

insert mode(=1)

=head2 MODE_UPDATE

insert mode(=2)

=head1 SEE ALSO

=cut
