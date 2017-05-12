#
# This file is part of MooX-LvalueAttribute
#
# This software is copyright (c) 2013 by Damien "dams" Krotkine.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
package Method::Generate::Accessor::Role::LvalueAttribute;
{
  $Method::Generate::Accessor::Role::LvalueAttribute::VERSION = '0.16';
}
use strictures 1;

# ABSTRACT: Provides Lvalue accessors to Moo class attributes

use Moo::Role;
use Variable::Magic qw(wizard cast);

use Hash::Util::FieldHash::Compat;

Hash::Util::FieldHash::Compat::fieldhash my %LVALUES;

require MooX::LvalueAttribute;

around generate_method => sub {
    my $orig = shift;
    my $self = shift;
    # would like a better way to disable XS

    my ($into, $name, $spec, $quote_opts) = @_;

    $MooX::LvalueAttribute::INJECTED_IN_ROLE{$into}
      || $MooX::LvalueAttribute::INJECTED_IN_CLASS{$into}
      or return $self->$orig(@_);

    if ($spec->{lvalue}) {

        my $is = $spec->{is};
        if ($is eq 'rw') {
            $spec->{accessor} = $name unless exists $spec->{accessor}
              or ( $spec->{reader} and $spec->{writer} );
        } elsif ($is eq 'rwp') {
            $spec->{writer} = "_set_${name}" unless exists $spec->{writer};
        }

        exists $spec->{writer} || exists $spec->{accessor}
          or die "lvalue was set but no accessor nor reader, and attribute is not rw";
        foreach( qw(writer accessor) ) {
            my $t = $spec->{$_}
              or next;
            $spec->{'lv_' . $_} = $t;
            $spec->{$_} = '_lv_' . $t;
        }
    }

    my $methods = $self->$orig(@_);

    foreach ( qw(writer accessor) ) {
        my $lv_name = $spec->{'lv_' . $_}
          or next;
        my $name = $spec->{$_};
        no strict 'refs';
        my $sub = sub : lvalue {
            my $self = shift;
            if (! exists $LVALUES{$self}{$lv_name}) {
                my $wiz = wizard(
                 set  => sub {
                     $self->$name(${$_[0]});
                     return 1;
                 },
                 get => sub {
                     ${$_[0]} = $self->$name();
                     return 1;
                 },
                );
                cast $LVALUES{$self}{$lv_name}, $wiz;
            }
            @_ and $self->$name(@_);
            $LVALUES{$self}{$lv_name};
        };
        $methods->{$lv_name} = $sub;
        *{"${into}::${lv_name}"} = $sub;
    }
};

1;

__END__
=pod

=head1 NAME

Method::Generate::Accessor::Role::LvalueAttribute - Provides Lvalue accessors to Moo class attributes

=head1 VERSION

version 0.16

=head1 AUTHOR

Damien "dams" Krotkine

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Damien "dams" Krotkine.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

