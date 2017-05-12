use 5.014;

package Mojo::UserAgent::Mockable::Request::Compare;
$Mojo::UserAgent::Mockable::Request::Compare::VERSION = '1.53';
# VERSION

# ABSTRACT: Helper class for Mojo::UserAgent::Mockable that compares two Mojo::Message::Request instances


use Carp;
use Mojo::Base -base;
use Mojo::URL;
use Safe::Isa qw{$_isa};

has compare_result => '';
has ignore_headers => sub { [] };
has ignore_body => '';
has ignore_userinfo => '';

sub compare {
    my ($self, $r1, $r2) = @_;
    
    if (!$r1->$_isa('Mojo::Message::Request')) {
        my $reftype = ref $r1;
        croak qq{Cannot compare $reftype to Mojo::Message::Request};
    }
    
    if (!$r2->$_isa('Mojo::Message::Request')) {
        my $reftype = ref $r2;
        croak qq{Cannot compare Mojo::Message::Request to $reftype};
    }

    if ( $r1->method ne $r2->method )  {
        $self->compare_result( sprintf q{Method mismatch: got '%s', expected '%s'}, $r1->method, $r2->method );
        return 0;
    }

    if ( !$self->_compare_url( $r1->url, $r2->url ) ) {
        return 0;
    }

    if ( !$self->ignore_body && $r1->body ne $r2->body ) {
        $self->compare_result('Body mismatch');
        return 0;
    }

    if ($self->ignore_headers ne 'all') {
        my $h1 = $r1->headers->to_hash;
        my $h2 = $r2->headers->to_hash;

        for my $header (@{$self->ignore_headers}) {
            delete $h1->{$header};
            delete $h2->{$header};
        }

        if (scalar keys %{$h1} ne scalar keys %{$h2}) {
            $self->compare_result('Header count mismatch');
                return 0;
        }

        for my $header (keys %{$h1}) {
            if (!defined $h2->{$header}) {
                $self->compare_result(qq{Header "$header" mismatch: header not present in both requests.'});
                return 0;
            }

            if ($h1->{$header} ne $h2->{$header}) {
                no warnings qw/uninitialized/;
                $self->compare_result(qq{Header "$header" mismatch: got '$h1->{$header}', expected '$h2->{$header}'});
                return 0;
            }
        }
    }

    $self->compare_result('');
    return 1;
}

sub _compare_url {
    my ($self, $u1, $u2) = @_;

    if (!ref $u1) {
        $u1 = Mojo::URL->new($u1);
    }
    $u1 = $u1->to_abs;

    if (!ref $u2) {
        $u2 = Mojo::URL->new($u2);
    }
    $u2 = $u2->to_abs;

    no warnings qw/uninitialized/;
    for my $key (qw/scheme userinfo host port fragment/) {
        my $ignore = sprintf 'ignore_%s', $key;
        next if $self->can($ignore) && $self->$ignore;

        my $val1 = $u1->$key;
        my $val2 = $u2->$key;
        if ($val1 ne $val2) {
            $self->compare_result(qq{URL $key mismatch: got "$val1", expected "$val2"});
            return 0;
        }
    }
    
    my $p1 = Mojo::Path->new($u1->path);
    my $p2 = Mojo::Path->new($u2->path);
    if ($p1->to_string ne $p2->to_string) {
        my $val1 = $p1->to_string;
        my $val2 = $p2->to_string;
        $self->compare_result(qq{URL path mismatch: got "$val1", expected "$val2"});
        return 0;
    }

    my $q1 = $u1->query->to_hash;
    my $q2 = $u2->query->to_hash;

    if (scalar keys %{$q1} != scalar keys %{$q2}) {
        my $count1 = scalar keys %{$q1};
        my $count2 = scalar keys %{$q2};

        $self->compare_result(qq{URL query mismatch: parameter count mismatch: $count1 != $count2});
        return 0;
    }
    for my $key (keys %{$q1}) {
        if ($q1->{$key} ne $q2->{$key}) {
            $self->compare_result(qq{URL query mismatch: for key "$key", got "$q1->{$key}", expected "$q2->{$key}"});
            return 0;
        }
    }
    use warnings qw/uninitialized/;

    return 1;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mojo::UserAgent::Mockable::Request::Compare - Helper class for Mojo::UserAgent::Mockable that compares two Mojo::Message::Request instances

=head1 VERSION

version 1.53

=head1 ATTRIBUTES

=head2 compare_result

The result of the last compare operation.  It is only populated when two requests B<do not> match.

=head2 ignore_userinfo 

Set this to a true value to ignore a mismatch in the L<userinfo|Mojo::URL/userinfo> portion of a transaction URL.

=head2 ignore_body

Set this to a true value to ignore a mismatch in the bodies of the two compared transactions

=head1 METHODS

=head2 compare

Compare two instances of L<Mojo::Message::Request>.

=head1 AUTHOR

Kit Peters <kit.peters@broadbean.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Broadbean Technology.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
