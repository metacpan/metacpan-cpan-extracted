package Object::GMP;
$Object::GMP::VERSION = '0.006';
=head1 NAME

Object::GMP - Moo Role for any object has GMP field

=head2 USAGE

This module is a moo role

=head3 Example

 package Foo;
 use Moo;
 with "Object::GMP";
 has a     => ( is => 'ro' );
 has b     => ( is => 'ro' );
 has prime => ( is => 'rw' );
 around BUILDARGS => __PACKAGE__->BUILDARGS_val2gmp('prime');
 1;

The above exmaple to declare the field 'prime' is a GMP value.

 my $prime =
  '0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFC2F';
 my $foo = Foo->new( a => 0, b => 7, prime => $prime );
 isnt( ref( $foo->a ), undef, 'a is not gmp' );
 isnt( ref( $foo->b ), undef, 'b is not gmp' );
 isa_ok( $foo->prime, 'Math::BigInt', 'prime is gmp' );

So when you create an object, a and b will be normal value
and prime will be a GMP value.

=head1 LINKS

B<Git Repo>: L<https://github.com/mvu8912/perl5-object-gmp.git>

B<CPAN Module>: L<https://metacpan.org/pod/Object::GMP>

=cut

use Moo::Role;
use Math::BigInt lib => 'GMP';
require JSON::XS;

my %GMP_FIELDS = ();

sub BUILDARGS_val2gmp {
    my ($class, @fields) = @_;

    map { $GMP_FIELDS{$_} = 1 } @fields;

    return sub {
        my ($orig, $class, %args) = @_;

        foreach my $key(@fields) {
            $args{$key} = $class->val2gmp($args{$key});
        }

        return $class->$orig(%args);
    }
}

sub val2gmp {
    my ($class, $val) = @_;
	return $val if !defined $val;
	return $val if UNIVERSAL::isa($val, 'Math::BigInt');
    return Math::BigInt->from_hex($val);
}

sub copy {
    my ($self, %args) = @_;

    my %new_me = ();

    while (my ($key, $val) = each %$self) {
        $new_me{$key} = $args{$key} // $val;

        if ($GMP_FIELDS{$key} && defined $new_me{$key}) {
            $new_me{$key} = $new_me{$key}->copy;
        }
    }

    return ref($self)->new(%new_me);
}

sub hashref {
    my ($self, %options) = @_;

    my %hash;

    my %keep = map { $_ => 1 } @{$options{keep} // []};

    while (my ($key, $val) = each %$self) {
        if ($GMP_FIELDS{$key}) {
            if ($keep{$key}) {
                $hash{$key} = "$val";
            }
            else {
                $hash{$key} = uc $val->as_hex;
                $hash{$key} =~ s/^([\-\+]?0)X/${1}x/;
            }
        }
        else {
            $hash{$key} = $val;
        }
    }

    return \%hash;
}

sub to_json {
    my ($self, %options) = @_;
    return JSON::XS->new->pretty->encode($self->hashref(%options));
}

sub _debug {
    my ($self, $pre_note, %options) = @_;
    return if !$ENV{DEBUG};
    return if $ENV{ONLY_SHOW} && $pre_note !~/$ENV{ONLY_SHOW}/;
    print "$pre_note: " if $pre_note;
    print $self->to_json(%options);
    print "\n";
}

1;
