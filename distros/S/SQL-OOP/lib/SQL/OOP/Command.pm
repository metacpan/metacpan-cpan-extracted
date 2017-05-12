package SQL::OOP::Command;
use strict;
use warnings;
use SQL::OOP::Base;
use SQL::OOP::ID;
use SQL::OOP::IDArray;
use base qw(SQL::OOP::Array);

### ---
### Constructor
### ---
sub new {
    my ($class, %args) = (@_);
    my $self = bless {
        gen => undef,
        array => undef,
    }, $class;
    
    $self->set(%args);
    return $self;
}

### ---
### Get Names of set arguments in array ref
### ---
sub KEYS {
    
}

### ---
### Get prefixes for each clause in hash ref
### ---
sub PREFIXES {
    
}

### ---
### Get clause names and array index in array
### ---
sub keys_to_idx {
    my ($self) = (@_);
    my $out = ();
    my $idx = 0;
    foreach my $key (@{$self->KEYS}) {
        $out->{$key} = $idx;
        $idx++;
    }
    return $out;
}

### ---
### Set elements
### ---
sub set {
    my ($self, %args) = @_;
    $self->_init_gen;
    my $tokens = $self->keys_to_idx;
    foreach my $key (keys %args) {
        my $idx = $tokens->{$key};
        $self->{array}->[$idx] = SQL::OOP::Base->new($args{$key});
    }
    
    return $self;
}

### ---
### Genereate SQL snippet
### ---
sub generate {
    my ($self) = @_;
    $self->{gen} = '';
    my $prefix = $self->PREFIXES;
    my $tokens = $self->keys_to_idx;
    for (my $idx = 0; $idx < @{$self->KEYS}; $idx++) {
        if (my $obj = $self->{array}->[$idx]) {
            if (my $a = $obj->to_string) {
                if ($obj->isa(__PACKAGE__)) {
                    $a = '('. $a. ')';
                }
                my $name = $self->KEYS->[$idx];
                if ($prefix->{$name}) {
                    $self->{gen} .= ' '. $prefix->{$name}. ' '. $a;
                } else {
                    $self->{gen} .= ' '. $a;
                }
            }
        }
    }
    
    $self->{gen} =~ s/^ //;
}

1;

__END__

=head1 NAME

SQL::OOP::Command

=head1 SYNOPSIS

See document of subclasses.

=head1 DESCRIPTION

SQL::OOP::Command is an abstract class which represents SQL commands such as
SELECT, INSERT, UPDATE etc.

=head1 METHODS

=head2 generate

=head2 keys_to_idx

=head2 new

=head2 set

=head1 Constants

=head2 KEYS

=head2 PREFIXES

=head1 SEE ALSO

=cut
