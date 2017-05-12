package MooseX::Constructor::AllErrors::Role::Object;
# ABSTRACT: object role for verifying constructor arguments

our $VERSION = '0.025';

use Moose::Role;
use Try::Tiny;
use namespace::autoclean;

my $new_error = sub {
  my $class = shift;
  return "MooseX::Constructor::AllErrors::Error::$class"->new(@_);
};

around BUILDARGS => sub {
  my ($orig, $self, @args) = @_;

  my $args = $self->$orig(@args);

  my $error = $new_error->(Constructor => {
    # counting frames in the callstack is a bit fragile... we should find a
    # better way...
    # 1: Class::MOP::Method::Wrapped::__ANON__
    # 2: Moose::Meta::Class::BUILDARGS
    # 3: Moose::Object::new
    caller => [ caller(3) ],
  });

  my $meta = Moose::Util::find_meta($self);
  for my $attr (sort { $a->insertion_order <=> $b->insertion_order } $meta->get_all_attributes) {
    next unless defined( my $init_arg = $attr->init_arg );

    if ($attr->is_required and
      ! $attr->is_lazy and
      ! $attr->has_default and
      ! $attr->has_builder and
      ! exists $args->{$init_arg}) {
      $error->add_error($new_error->(Required => { attribute => $attr }));
      next;
    }

    next unless exists $args->{$init_arg} && $attr->has_type_constraint;

    my $tc = $attr->type_constraint;
    my $value = $tc->has_coercion && $attr->should_coerce
        ? $tc->coerce($args->{$init_arg})
        : $args->{$init_arg};

    # use the attributes verify_against_type_constraint as that can be wrapped
    # by other roles, namely MooseX::UndefTolerant
    try {
      $attr->verify_against_type_constraint($value);
    }
    catch {
      $error->add_error($new_error->(TypeConstraint => {
        attribute => $attr,
        data      => $value,
      }));
    };
  }

  if ($error->has_errors) {
    if ($meta->can('error_class'))
    {
      # Moose before 2.1100, and possibly 2.12xx too
      $meta->throw_error($error, params => $args);
    }
    else
    {
      die $error;
    }
  }

  return $args;
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MooseX::Constructor::AllErrors::Role::Object - object role for verifying constructor arguments

=head1 VERSION

version 0.025

=head1 AUTHOR

Hans Dieter Pearcey <hdp@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2009 by Hans Dieter Pearcey.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
