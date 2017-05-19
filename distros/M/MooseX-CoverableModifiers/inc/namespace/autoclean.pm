#line 1
use strict;
use warnings;

package namespace::autoclean;
BEGIN {
  $namespace::autoclean::AUTHORITY = 'cpan:FLORA';
}
{
  $namespace::autoclean::VERSION = '0.13';
}
# ABSTRACT: Keep imports out of your namespace

use Class::MOP 0.80;
use B::Hooks::EndOfScope;
use List::Util qw( first );
use namespace::clean 0.20;


sub import {
    my ($class, %args) = @_;

    my $subcast = sub {
        my $i = shift;
        return $i if ref $i eq 'CODE';
        return sub { $_ =~ $i } if ref $i eq 'Regexp';
        return sub { $_ eq $i };
    };

    my $runtest = sub {
        my ($code, $method_name) = @_;
        local $_ = $method_name;
        return $code->();
    };

    my $cleanee = exists $args{-cleanee} ? $args{-cleanee} : scalar caller;

    my @also = map { $subcast->($_) } (
        exists $args{-also}
        ? (ref $args{-also} eq 'ARRAY' ? @{ $args{-also} } : $args{-also})
        : ()
    );

    on_scope_end {
        my $meta = Class::MOP::Class->initialize($cleanee);
        my %methods = map { ($_ => 1) } $meta->get_method_list;
        $methods{meta} = 1 if $meta->isa('Moose::Meta::Role') && Moose->VERSION < 0.90;
        my %extra = ();

        for my $method (keys %methods) {
            next if exists $extra{$_};
            next unless first { $runtest->($_, $method) } @also;
            $extra{ $method } = 1;
        }

        my @symbols = keys %{ $meta->get_all_package_symbols('CODE') };
        namespace::clean->clean_subroutines($cleanee, keys %extra, grep { !$methods{$_} } @symbols);
    };
}

1;

__END__
#line 165

