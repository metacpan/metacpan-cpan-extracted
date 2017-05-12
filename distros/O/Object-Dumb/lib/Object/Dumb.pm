package Object::Dumb;

our $DATE = '2016-06-16'; # DATE
our $VERSION = '0.02'; # VERSION

#use strict;
#use warnings;

sub new {
    my $class = shift;
    my $o = {@_};

    $o->{returns} = 0 if !exists($o->{returns});
    bless $o, $class;
}

sub AUTOLOAD {
    my $meth = $AUTOLOAD; $meth =~ s/.+:://;
    my $self = shift;
    if ($self->{methods}) {
        my $known = 0;
        if (ref($self->{methods}) eq 'ARRAY') {
            $known = 1 if grep { $_ eq $meth } @{ $self->{methods} };
        } elsif (ref($self->{methods}) eq 'Regexp') {
            $known = 1 if $meth =~ $self->{methods};
        }
        die "Unknown method '$meth'" unless $known;
    }
    return $self->{returns};
}

1;
# ABSTRACT: A dumb object that responds to any method and just returns 0

__END__

=pod

=encoding UTF-8

=head1 NAME

Object::Dumb - A dumb object that responds to any method and just returns 0

=head1 VERSION

This document describes version 0.02 of Object::Dumb (from Perl distribution Object-Dumb), released on 2016-06-16.

=head1 SYNOPSIS

 use Object::Dumb;

 my $obj = Object::Dumb->new;
 $obj->foo;          # -> 0
 $obj->bar(1, 2, 3); # -> 0

You can limit what methods will be available:

 my $obj = Object::Dumb->new(methods => [qw/foo bar/]);
 $obj->foo; # ok
 $obj->bar; # ok
 $obj->baz; # dies

or:

 my $obj = Object::Dumb->new(methods => qr/^(foo.*|bar.+)$/);
 $obj->foo;  # ok
 $obj->barb; # ok
 $obj->baz;  # dies

And you can also customize what value the methods will return:

 my $obj = Object::Dumb->new(returns => 1);
 print $obj->foo; # 1

=head1 DESCRIPTION

This module lets you create a "dumb" object that responds to any method and just
returns 0.

You can customize by limiting what methods the object will respond to, and what
value the methods will return.

=for Pod::Coverage ^(.+)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Object-Dumb>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Object-Dumb>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Object-Dumb>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
