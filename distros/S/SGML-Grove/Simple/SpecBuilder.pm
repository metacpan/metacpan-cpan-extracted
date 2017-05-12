#
# Copyright (C) 1997 Ken MacLeod
# See the file COPYING for distribution terms.
#
# $Id: SpecBuilder.pm,v 1.2 1998/01/18 00:21:22 ken Exp $
#

package SGML::Simple::SpecBuilder;

use strict;

=head1 NAME

SGML::Simple::SpecBuilder - build a SGML::Spec object

=head1 SYNOPSIS

    use SGML::SPGroveBuilder;
    use SGML::Grove;
    use SGML::Simple::Spec;
    use SGML::Simple::SpecBuilder;
    use SGML::Simple::BuilderBuilder;

    $spec_grove = SGML::SPGroveBuilder->new ($spec_sysid);
    $spec = SGML::Simple::Spec->new;
    $spec_grove->accept (SGML::Simple::SpecBuilder->new, $spec);
    $builder = SGML::Simple::BuilderBuilder->new (spec => $spec);

=head1 DESCRIPTION

C<SpecBuilder> builds a new SGML::Spec object from a grove conforming
to the ``S<Grove Simple Spec>'' DTD.

The SGML::Spec object can be passed to C<SGML::Simple::BuilderBuilder>
to create a new package for transforming other groves.

See C<SGML::Simple::Spec> for more details about the C<Spec> object.

C<SpecBuilder> is a singleton, calling C<new> always returns the same
object.

=head1 AUTHOR

Ken MacLeod, ken@bitsko.slc.ut.us

=head1 SEE ALSO

  perl(1), SGML::Grove(3), SGML::Simple::Spec(3),
  SGML::Simple::BuilderBuilder(3)

=cut

use SGML::Simple::Spec;

my $singleton = undef;

sub new {
    my $type = shift;

    return ($singleton)
	if (defined $singleton);

    my $self = {};

    bless ($self, $type);

    $singleton = $self;

    return $self;
}

sub visit_SGML_Grove {
    my $self = shift;
    my $grove = shift;

    $grove->root->accept_gi ($self, @_);
}

sub visit_gi_SPEC {
    my $builder = shift;
    my $element = shift;
    $element->children_accept_gi($builder, @_);
}

sub visit_gi_HEAD {
    my $builder = shift;
    my $element = shift;
    $element->children_accept_gi($builder, @_);
}

sub visit_gi_DEFAULTOBJECT {
    my $builder = shift;
    my $element = shift;
    my $spec = shift;

    $spec->default_object ($element->as_string);
}

sub visit_gi_DEFAULTPREFIX {
    my $builder = shift;
    my $element = shift;
    my $spec = shift;

    $spec->default_prefix ($element->as_string);
}

sub visit_gi_USE_GI {
    my $builder = shift;
    my $element = shift;
    my $spec = shift;

    $spec->use_gi (1);
}

sub visit_gi_COPY_ID {
    my $builder = shift;
    my $element = shift;
    my $spec = shift;

    $spec->copy_id (1);
}

sub visit_gi_RULES {
    my $builder = shift;
    my $element = shift;
    $element->children_accept_gi($builder, @_);
}

sub visit_gi_RULE {
    my $builder = shift;
    my $element = shift;
    my $parent_rule = shift;
    my $rule = SGML::Simple::Spec::Rule->new ();
    $parent_rule->push_rules ($rule);
    $element->children_accept_gi($builder, $rule, @_);
}

sub visit_gi_PORT {
    my $builder = shift;
    my $element = shift;
    my $rule = shift;
    my $port = $element->as_string;
    $port =~ tr/-/_/;
    $rule->port ($port);
}

sub visit_gi_QUERY {
    my $builder = shift;
    my $element = shift;
    my $rule = shift;
    my $query = $element->as_string;

    # convert all non-word, non-space characters to `_' (matched in
    # Element.pm)
    $query =~ s/[^\w\s]/_/g;
    $rule->query ($query);
}

sub visit_gi_HOLDER {
    my $builder = shift;
    my $element = shift;
    my $rule = shift;
    $rule->holder (1);
}

sub visit_gi_IGNORE {
    my $builder = shift;
    my $element = shift;
    my $rule = shift;
    $rule->ignore (1);
}

sub visit_gi_MAKE {
    my $builder = shift;
    my $element = shift;
    my $rule = shift;
    my $make_str = [];
    my $new_builder = SGML::Simple::Spec::BuilderSub->new;
    $element->children_accept_gi($new_builder, $make_str);
    $rule->make (join ('', @{$make_str}));
}

sub visit_gi_CODE {
    my $builder = shift;
    my $element = shift;
    my $rule = shift;
    my $make_str = [];
    $element->children_accept_gi($builder, $make_str);
    $rule->code (join ('', @{$make_str}));
}

sub visit_gi_ATTR {
    my $builder = shift;
    my $element = shift;
    my $make_str = shift;
    push (@{$make_str},
	  '($element->attr (\''
	  . $element->as_string()
	  . '\'))');
}

sub visit_gi_ATTR_AS_STRING {
    my $builder = shift;
    my $element = shift;
    my $make_str = shift;
    push (@{$make_str},
	  '($element->attr_as_string (\''
	  . $element->as_string()
	  . '\'))');
}

sub visit_gi_STUFF {
    my $builder = shift;
    my $element = shift;
    my $spec = shift;
    my $data = $element->as_string;
    $data =~ tr/\r/\n/;
    $spec->stuff ($data);
}

sub visit_scalar {
    my $builder = shift;
    my $scalar = shift;
    my $make_str = shift;
    $scalar =~ tr/\r/\n/;
    push (@{$make_str}, $scalar);
}

package SGML::Simple::Spec::BuilderSub;
@SGML::Simple::Spec::BuilderSub::ISA = qw{SGML::Simple::SpecBuilder};

sub new {
    return (bless {});
}

sub visit_scalar {
    my $builder = shift;
    my $scalar = shift;
    my $make_str = shift;
    $scalar =~ s/(\w+):(?!:)/$1 =>/g;
    $scalar =~ tr/\r/\n/;
    push (@{$make_str}, $scalar);
}

1;
