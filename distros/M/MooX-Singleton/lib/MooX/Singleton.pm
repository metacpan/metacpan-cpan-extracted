
package MooX::Singleton;
BEGIN {
  $MooX::Singleton::AUTHORITY = 'cpan:AJGB';
}
{
  $MooX::Singleton::VERSION = '1.20';
}
# ABSTRACT: turn your Moo class into singleton

use strict;
use warnings;
use Role::Tiny;


sub instance {
    my $class = shift;

    no strict 'refs';
    my $instance = \${"$class\::_instance"};
    return defined $$instance ? $$instance
        : ( $$instance = $class->new(@_) );
}

sub _has_instance {
    my $class = ref $_[0] || $_[0];

    no strict 'refs';
    return ${"$class\::_instance"};
}

sub _clear_instance {
    my $class = ref $_[0] || $_[0];

    no strict 'refs';
    undef ${"$class\::_instance"};

    return $class;
}

1;

__END__
=pod

=encoding utf-8

=head1 NAME

MooX::Singleton - turn your Moo class into singleton

=head1 VERSION

version 1.20

=head1 SYNOPSIS

    package MyApp;
    use Moo;
    with 'MooX::Singleton';

    package main;

    my $instance = MyApp->instance(@optional_init_args);
    my $same = MyApp->instance;

=head1 DESCRIPTION

Role::Tiny role that provides L<"instance"> method turning your object into singleton.

=head1 METHODS

=head2 instance

    my $singleton = MyApp->instance(@args1);
    my $same = MyApp->instance;
    # @args2 are ignored
    my $above = MyApp->instance(@args2);

Creates a new object initialized with arguments provided and then returns it.

NOTE: Subsequent calls to C<instance> will return the singleton instance ignoring
any arguments. This is different from L<MooseX::Singleton> which does not allow any
arguments.

=head1 AUTHOR

Alex J. G. Burzyński <ajgb@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Alex J. G. Burzyński <ajgb@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

