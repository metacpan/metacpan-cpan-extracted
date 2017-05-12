package Test::Attribute::AutoLevel;
use strict;
use warnings;
use 5.008001;
our $VERSION = '0.06';

sub import {
    my ($class, %args) = @_;
    my $caller = caller($args{depth} || 0);

    no strict 'refs';
    *{"${caller}::MODIFY_CODE_ATTRIBUTES"} = \&_MODIFY_CODE_ATTRIBUTES;
}

my $stash = {};
sub _fake {
    my ($pkg, $code) = @_;

    $stash->{$pkg} ||= {};
    my $fake = sub {
        local $Test::Builder::Level = $Test::Builder::Level + 2;
        $code->(@_);
    };
    $stash->{$pkg}{"$code"} = $fake;
}

sub _MODIFY_CODE_ATTRIBUTES {
    my ($pkg, $code, @attrs) = @_;
    return unless $attrs[0] eq 'AutoLevel';
    _fake($pkg, $code);
    return;
}

sub CHECK {
    my $pkg = caller;
    return unless exists $stash->{$pkg};

    no strict 'refs';
    for my $name (keys %{"$pkg\::"}) {
        my $code = *{"${pkg}::${name}"}{CODE} || next;
        my $fake = $stash->{$pkg}{"$code"}    || next;
        no warnings 'redefine';
        *{"${pkg}::${name}"} = $fake;
    }

    delete $stash->{$pkg}; # cleanup
}

1;

__END__

=head1 NAME

Test::Attribute::AutoLevel - auto set $Test::Builder::Level

=head1 SYNOPSIS

  use Test::More;
  use Test::Attribute::AutoLevel;
  
  sub test_foo : AutoLevel {
      fail 'always failed.';
  }
  test_foo(); # test failed. report line at call test_foo().

=head1 DESCRIPTION

Test::Attribute::AutoLevel is auto set $Test::Builder::Level.

=head1 AUTHOR

Atsushi Kobayashi E<lt>nekokak _at_ gmail _dot_ comE<gt>

=head1 CONTRIBUTORS

kamipo

xaicron

pppjam

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
