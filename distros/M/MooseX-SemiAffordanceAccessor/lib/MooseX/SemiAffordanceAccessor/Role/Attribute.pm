package MooseX::SemiAffordanceAccessor::Role::Attribute;
$MooseX::SemiAffordanceAccessor::Role::Attribute::VERSION = '0.10';
use strict;
use warnings;

use Moose::Role;

before '_process_options' => sub {
    my $class   = shift;
    my $name    = shift;
    my $options = shift;

    if ( exists $options->{is}
        && !( exists $options->{reader} || exists $options->{writer} ) ) {
        if ( $options->{is} eq 'ro' ) {
            $options->{reader} = $name;
            delete $options->{is};
        }
        elsif ( $options->{is} eq 'rw' ) {
            $options->{reader} = $name;

            my $prefix = 'set';
            if ( $name =~ s/^_// ) {
                $prefix = '_set';
            }

            $options->{writer} = $prefix . q{_} . $name;
            delete $options->{is};
        }
    }
};

no Moose::Role;

1;

# ABSTRACT: This meta trait is applied to attributes in order to change writer names

__END__

=pod

=encoding UTF-8

=head1 NAME

MooseX::SemiAffordanceAccessor::Role::Attribute - This meta trait is applied to attributes in order to change writer names

=head1 VERSION

version 0.10

=head1 SYNOPSIS

=head1 DESCRIPTION

This role applies a method modifier to the C<_process_options()>
method, and tweaks the reader and writer parameters so that they
follow the semi-affordance naming style.

=for test_synopsis BEGIN { die 'SKIP: no need to test this'; }

  Moose::Util::MetaRole::apply_metaclass_roles(
      for_class => $p{for_class},
      attribute_metaclass_roles =>
          ['MooseX::SemiAffordanceAccessor::Role::Attribute'],
  );

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2011 by Dave Rolsky.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
