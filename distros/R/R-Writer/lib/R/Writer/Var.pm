# $Id: /mirror/coderepos/lang/perl/R-Writer/trunk/lib/R/Writer/Var.pm 43085 2008-03-01T12:28:42.888222Z daisuke  $
# 
# Copyright (c) 2008 Daisuke Maki <daisuke2endeworks.jp>
# All rights reserved.

package R::Writer::Var;
use strict;
use warnings;
use base qw(Class::Accessor::Fast);

__PACKAGE__->mk_accessors($_) for qw(name value writer);

sub new
{
    my $class = shift;
    my $self  = $class->SUPER::new({ name => $_[0], value => $_[1], writer => $_[2] || R::Writer::R() });
    return $self;
}

sub as_string
{
    my $self  = shift;
    my $c     = shift;
    my $var   = $self->name;
    my $value = $self->value;

    my $s = "";

    my $ref = defined $value ? ref $value : undef;
    if (!defined $value) {
        $s = "$var;";
    }
    elsif (! $ref) {
        $s = "$var <- $value;";
    } 
    elsif ($ref eq 'ARRAY' || $ref eq 'HASH') {
        $s = "$var <- " . $self->encoder->encode($value) . ";"
    }
    elsif ($ref eq 'CODE') {
        $s = "$var <- " . $c->__obj_as_string($value->());
    }
    elsif ($ref =~ /^R::Writer/) {
        $s = "$var <- " . $value->as_string($c);
    }
    elsif ($ref eq 'REF') {
        my $j = $self->new;
        $j->var($var => $$value);
        $s = $j->as_string;
    }
    elsif ($ref eq 'SCALAR') {
        if (defined $$value) {
            my $v = $self->__obj_as_string($value);

            $s = "var $var = $v;";
        }
        else {
            $s = "var $var;";
        }

        eval {
            R::Writer::Var->new(
                $value,
                {
                    name => $var,
                    jsw  => $self
                }
            );
        };
    }

    return $s;
}

1;

__END__

=head1 NAME

R::Writer::Var - Variables

=head1 SYNOPSIS

  use R::Writer::Var;
  # Internal use only

=head1 METHODS

=head2 new

=head2 as_string

=cut
