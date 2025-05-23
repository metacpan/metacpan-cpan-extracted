package MooseX::Extended::Role::Custom;

# ABSTRACT: Build a custom Moose::Role, just for you.

use 5.20.0;
use strict;
use warnings;
use true;
use MooseX::Extended::Core qw(
  _enabled_features
  _disabled_warnings
);
use MooseX::Extended::Role ();
use namespace::autoclean;

our $VERSION = '0.35';

sub import {
    my @caller       = caller(0);
    my $custom_moose = $caller[0];    # this is our custom Moose definition
    true->import::into($custom_moose) unless $caller[1] =~ /^\(eval/;
    strict->import::into($custom_moose);
    warnings->import::into($custom_moose);
    namespace::autoclean->import::into($custom_moose);
    feature->import( _enabled_features() );
    warnings->unimport(_disabled_warnings);
}

sub create {
    my ( $class, %args ) = @_;
    my $target_class = caller(1);     # this is the class consuming our custom Moose
    MooseX::Extended::Role->import(
        %args,
        call_level => 1,
        for_class  => $target_class,
    );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MooseX::Extended::Role::Custom - Build a custom Moose::Role, just for you.

=head1 VERSION

version 0.35

=head1 SYNOPSIS

Define your own version of L<MooseX::Extended>:

    package My::Moose::Role {
        use MooseX::Extended::Role::Custom;

        sub import {
            my ( $class, %args ) = @_;
            MooseX::Extended::Role::Custom->create(
                excludes => [qw/ carp /],
                includes => ['multi'],
                %args    # you need this to allow customization of your customization
            );
        }
    }

    # no need for a true value

And then use it:

    package Some::Class::Role {
        use My::Moose::Role types => [qw/ArrayRef Num/];

        param numbers => ( isa => ArrayRef[Num] );

        multi sub foo ($self)       { ... }
        multi sub foo ($self, $bar) { ... }
    }

=head1 DESCRIPTION

I hate boilerplate, so let's get rid of it. Let's say you don't want warnings
on classes implicitly overriding role methods, L<namespace::autoclean> or
C<carp>, but you do want C<multi>. Plus, you have custom versions of C<carp>
and C<croak>:

    package Some::Class {
        use MooseX::Extended
          excludes => [qw/ WarnOnConflict autoclean carp /],
          includes => ['multi'];
        use My::Carp q(carp croak);

        ... my code here
    }

You probably get tired of typing that every time. Now you don't have to. 

    package My::Moose {
        use MooseX::Extended::Custom;
        use My::Carp ();
        use Import::Into;

        sub import {
            my ( $class, %args ) = @_;
            my $target_class = caller;
            MooseX::Extended::Custom->create(
                excludes => [qw/ autoclean carp /],
                includes => ['multi'],
                %args    # you need this to allow customization of your customization
            );
            My::Carp->import::into($target_class, qw(carp croak));
        }
    }

And then when you use C<My::Moose>, that's all set up for you.

If you need to change this on a "per class" basis:

    use My::Moose
      excludes => ['carp'],
      types    => [qw/ArrayRef Num/];

The above changes your C<excludes> and adds C<types>, but doesn't change your C<includes>.

=head1 AUTHOR

Curtis "Ovid" Poe <curtis.poe@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2022 by Curtis "Ovid" Poe.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
