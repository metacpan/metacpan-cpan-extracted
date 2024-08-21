package Syntax::Keyword::Junction::One;
use strict;
use warnings;

our $VERSION = '0.003009';

use parent 'Syntax::Keyword::Junction::Base';

BEGIN {
  if (Syntax::Keyword::Junction::Base::_WANT_SMARTMATCH) {
    eval '#line '.(__LINE__+1).' "' . __FILE__.qq["\n] . <<'END_CODE' or die $@;
no if Syntax::Keyword::Junction::Base::_SMARTMATCH_WARNING_CATEGORY,
  warnings => Syntax::Keyword::Junction::Base::_SMARTMATCH_WARNING_CATEGORY;

sub match {
    my ( $self, $other, $is_rhs ) = @_;

    my $count = 0;

    if ($is_rhs) {

        for (@$self) {
            if ($other ~~ $_) {
              return if $count;
              $count = 1;
            }
        }

        return($count == 1);
    }

    for (@$self) {
        if ($_ ~~ $other) {
            return if $count;
            $count = 1;
        }
    }

    return($count == 1);
}

1;
END_CODE
  }
}

sub num_eq {
    return regex_eq(@_) if ref( $_[1] ) eq 'Regexp';

    my ( $self, $test ) = @_;
    my $count = 0;

    for (@$self) {
        if ( $_ == $test ) {
            return if $count;
            $count = 1;
        }
    }

    return 1 if $count;
}

sub num_ne {
    return regex_ne(@_) if ref( $_[1] ) eq 'Regexp';

    my ( $self, $test ) = @_;
    my $count = 0;

    for (@$self) {
        if ( $_ != $test ) {
            return if $count;
            $count = 1;
        }
    }

    return 1 if $count;
}

sub num_ge {
    my ( $self, $test, $switch ) = @_;

    return num_le( $self, $test ) if $switch;

    my $count = 0;

    for (@$self) {
        if ( $_ >= $test ) {
            return if $count;
            $count = 1;
        }
    }

    return 1 if $count;
}

sub num_gt {
    my ( $self, $test, $switch ) = @_;

    return num_lt( $self, $test ) if $switch;

    my $count = 0;

    for (@$self) {
        if ( $_ > $test ) {
            return if $count;
            $count = 1;
        }
    }

    return 1 if $count;
}

sub num_le {
    my ( $self, $test, $switch ) = @_;

    return num_ge( $self, $test ) if $switch;

    my $count = 0;

    for (@$self) {
        if ( $_ <= $test ) {
            return if $count;
            $count = 1;
        }
    }

    return 1 if $count;
}

sub num_lt {
    my ( $self, $test, $switch ) = @_;

    return num_gt( $self, $test ) if $switch;

    my $count = 0;

    for (@$self) {
        if ( $_ < $test ) {
            return if $count;
            $count = 1;
        }
    }

    return 1 if $count;
}

sub str_eq {
    my ( $self, $test ) = @_;
    my $count = 0;

    for (@$self) {
        if ( $_ eq $test ) {
            return if $count;
            $count = 1;
        }
    }

    return 1 if $count;
}

sub str_ne {
    my ( $self, $test ) = @_;
    my $count = 0;

    for (@$self) {
        if ( $_ ne $test ) {
            return if $count;
            $count = 1;
        }
    }

    return 1 if $count;
}

sub str_ge {
    my ( $self, $test, $switch ) = @_;

    return str_le( $self, $test ) if $switch;

    my $count = 0;

    for (@$self) {
        if ( $_ ge $test ) {
            return if $count;
            $count = 1;
        }
    }

    return 1 if $count;
}

sub str_gt {
    my ( $self, $test, $switch ) = @_;

    return str_lt( $self, $test ) if $switch;

    my $count = 0;

    for (@$self) {
        if ( $_ gt $test ) {
            return if $count;
            $count = 1;
        }
    }

    return 1 if $count;
}

sub str_le {
    my ( $self, $test, $switch ) = @_;

    return str_ge( $self, $test ) if $switch;

    my $count = 0;

    for (@$self) {
        if ( $_ le $test ) {
            return if $count;
            $count = 1;
        }
    }

    return 1 if $count;
}

sub str_lt {
    my ( $self, $test, $switch ) = @_;

    return str_gt( $self, $test ) if $switch;

    my $count = 0;

    for (@$self) {
        if ( $_ lt $test ) {
            return if $count;
            $count = 1;
        }
    }

    return 1 if $count;
}

sub regex_eq {
    my ( $self, $test, $switch ) = @_;

    my $count = 0;

    for (@$self) {
        if ( $_ =~ $test ) {
            return if $count;
            $count = 1;
        }
    }

    return 1 if $count;
}

sub regex_ne {
    my ( $self, $test, $switch ) = @_;

    my $count = 0;

    for (@$self) {
        if ( $_ !~ $test ) {
            return if $count;
            $count = 1;
        }
    }

    return 1 if $count;
}

sub bool {
    my ($self) = @_;
    my $count = 0;

    for (@$self) {
        if ($_) {
            return if $count;
            $count = 1;
        }
    }

    return 1 if $count;
}

1;

__END__

=pod

=encoding UTF-8

=for :stopwords Arthur Axel "fREW" Schmidt Carl Franks

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/haarg/Syntax-Keyword-Junction/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHORS

=over 4

=item *

Arthur Axel "fREW" Schmidt <frioux+cpan@gmail.com>

=item *

Carl Franks

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Arthur Axel "fREW" Schmidt.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
