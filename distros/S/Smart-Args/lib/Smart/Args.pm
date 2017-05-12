package Smart::Args;
use strict;
use warnings;
use 5.008001;
our $VERSION = '0.14';
use Exporter 'import';
use PadWalker qw/var_name/;
use Carp ();
use Mouse::Util::TypeConstraints ();

*_get_isa_type_constraint = \&Mouse::Util::TypeConstraints::find_or_create_isa_type_constraint;
*_get_does_type_constraint = \&Mouse::Util::TypeConstraints::find_or_create_does_type_constraint;

our @EXPORT = qw/args args_pos/;

our $VERBOSE = 1;

my %is_invocant = map{ $_ => undef } qw($self $class);

sub args {
    {
        package DB;
        # call of caller in DB package sets @DB::args,
        # which requires list context, but we don't need return values
        () = CORE::caller(1);
    }

    if(@_) {
        my $name = var_name(1, \$_[0]) || '';
        if(exists $is_invocant{ $name }){ # seems method call
            $_[0] = shift @DB::args; # set the invocant
            if(defined $_[1]) { # has rule?
                $name =~ s/^\$//;
                # validate_pos($value, $exists, $name, $basic_rule, $used_ref)
                $_[0] = _validate_by_rule($_[0], 1, $name, $_[1]);
                shift;
            }
            shift;
        }
    }

    my $args = ( @DB::args == 1 && ref($DB::args[0]) )
            ?    $DB::args[0]  # must be hash
            : +{ @DB::args };  # must be key-value list

    ### $args
    ### @_

    # args my $var => RULE
    #         ~~~~    ~~~~
    #         undef   defined

    my $used = 0;
    for(my $i = 0; $i < @_; $i++){

        (my $name = var_name(1, \$_[$i]))
            or  Carp::croak('usage: args my $var => TYPE, ...');
        $name =~ s/^\$//;

        # with rule  (my $foo => $rule, ...)
        if(defined $_[ $i + 1 ]) {
            # validate_pos($value, $exists, $name, $basic_rule, $used_ref)
            $_[$i] = _validate_by_rule($args->{$name}, exists($args->{$name}), $name, $_[$i + 1], \$used);
            $i++;
        }
        # without rule (my $foo, my $bar, ...)
        else {
            if(!exists $args->{$name}) { # parameters are mandatory by default
                @_ = ("missing mandatory parameter named '\$$name'");
                goto \&Carp::confess;
            }
            $_[$i] = $args->{$name};
            $used++;
        }
    }

    if( $used < keys %{$args} && warnings::enabled('void') )  {
        # hack to get unused argument names
        my %vars;
        foreach my $slot(@_) {
            my $name = var_name(1, \$slot) or next;
            $name =~ s/^\$//;
            $vars{$name} = undef;
        }
        local $Carp::CarpLevel = $Carp::CarpLevel + 1;
        warnings::warn( void =>
            'unknown arguments: '
            . join ', ', sort grep{ not exists $vars{$_} } keys %{$args} );
    }
    return;
}

sub args_pos {
    {
        package DB;
        # call of caller in DB package sets @DB::args,
        # which requires list context, but we don't need return values
        () = CORE::caller(1);
    }
    if(@_) {
        my $name = var_name(1, \$_[0]) || '';
        if(exists $is_invocant{ $name }){ # seems method call
            $_[0] = shift @DB::args; # set the invocant
            if(defined $_[1]) { # has rule?
                $name =~ s/^\$//;
                # validate_pos($value, $exists, $name, $basic_rule, $used_ref)
                $_[0] = _validate_by_rule($_[0], 1, $name, $_[1]);
                shift;
            }
            shift;
        }
    }

    my @args = @DB::args;

    ### $args
    ### @_

    # args my $var => RULE
    #         ~~~~    ~~~~
    #         undef   defined

    for(my $i = 0; $i < @_; $i++){
        (my $name = var_name(1, \$_[$i]))
            or  Carp::croak('usage: args my $var => TYPE, ...');

        # with rule  (my $foo => $rule, ...)
        if (defined $_[ $i + 1 ]) {
            $_[$i] = _validate_by_rule($args[0], @args>0, $name, $_[$i + 1]);
            shift @args;
            $i++;
        }
        # without rule (my $foo, my $bar, ...)
        else {
            if (@args == 0) { # parameters are mandatory by default
                @_ = ("missing mandatory parameter named '\$$name'");
                goto \&Carp::confess;
            }
            $_[$i] = shift @args;
        }
    }

    # too much arguments
    if ( scalar(@args) > 0 )  {
        # hack to get unused argument names
        local $Carp::CarpLevel = $Carp::CarpLevel + 1;
        Carp::croak( void =>
            'too much arguments. This function requires only ' . scalar(@_) . ' arguments.' );
    }
    return;
}

# rule: $type or +{ isa => $type, optional => $bool, default => $default }
sub _validate_by_rule {
    my ($value, $exists, $name, $basic_rule, $used_ref) = @_;

    # compile the rule
    my $rule;
    my $type;
    my $mandatory = 1; # all the arguments are mandatory by default
    if(ref($basic_rule) eq 'HASH') {
        $rule = $basic_rule;
        if (defined $basic_rule->{isa}) {
            $type = _get_isa_type_constraint($basic_rule->{isa});
        } elsif (defined $basic_rule->{does}) {
            $type = _get_does_type_constraint($basic_rule->{does});
        }
        $mandatory = !$rule->{optional};
    }
    else {
        # $rule is a type constraint name or type constraint object
        $type = _get_isa_type_constraint($basic_rule);
    }

    # validate the value by the rule
    if ($exists){
        if(defined $type ){
            if(!$type->check($value)){
                $value = _try_coercion_or_die($name, $type, $value);
            }
        }
        ${$used_ref}++ if defined $used_ref;
    }
    else {
        if(defined($rule) and exists $rule->{default}){
            $value = $rule->{default};
        }
        elsif($mandatory){
            @_ = ("missing mandatory parameter named '\$$name'");
            if ($VERBOSE) {
                goto \&Carp::confess;
            } else {
                goto \&Carp::croak;
            }
        }
        else{
            # no default, and not mandatory; noop
        }
    }
    return $value;
}

sub _try_coercion_or_die {
    my($name, $tc, $value) = @_;
    if($tc->has_coercion) {
        $value = $tc->coerce($value);
        $tc->check($value) and return $value;
    }
    @_ = ("'$name': " . $tc->get_message($value));
    if ($VERBOSE) {
        goto \&Carp::confess;
    } else {
        goto \&Carp::croak;
    }
}
1;
__END__

=head1 NAME

Smart::Args - argument validation for you

=head1 SYNOPSIS

  use Smart::Args;

  sub func2 {
    args my $p => 'Int',
         my $q => { isa => 'Int', optional => 1 };
  }
  func2(p => 3, q => 4); # p => 3, q => 4
  func2(p => 3);         # p => 3, q => undef

  sub func3 {
    args my $p => {isa => 'Int', default => 3},
  }
  func3(p => 4); # p => 4
  func3();       # p => 3

  package F;
  use Moose;
  use Smart::Args;

  sub method {
    args my $self,
         my $p => 'Int';
  }
  sub class_method {
    args my $class => 'ClassName',
         my $p => 'Int';
  }

  sub simple_method {
    args_pos my $self, my $p;
  }

  my $f = F->new();
  $f->method(p => 3);

  F->class_method(p => 3);

  F->simple_method(3);

=head1 DESCRIPTION

Smart::Args is yet another argument validation library.

This module makes your module more readable, and writable =)

=head1 FUNCTIONS

=head2 C<args my $var [, $rule], ...>

Checks parameters and fills them into lexical variables. All the parameters
are mandatory by default, and unknown parameters (i.e. possibly typos) are
reported as C<void> warnings.

The arguments of C<args()> consist of lexical <$var>s and optional I<$rule>s.

I<$vars> must be a declaration of a lexical variable.

I<$rule> can be a type name (e.g. C<Int>), a HASH reference (with
C<type>, C<default>, and C<optional>), or a type constraint object.

Note that if the first variable is named I<$class> or I<$self>, it
is dealt as a method call.

See the SYNOPSIS section for examples.

=head2 C<args_pos my $var[, $rule, ...>

Check parameters and fills them into lexical variables. All the parameters
are mandatory by default.

The arguments of C<args()> consist of lexical <$var>s and optional I<$rule>s.
I<$vars> must be a declaration of a lexical variable.

I<$rule> can be a type name (e.g. C<Int>), a HASH reference (with
C<type>, C<default>, and C<optional>), or a type constraint object.

Note that if the first variable is named I<$class> or I<$self>, it
is dealt as a method call.

See the SYNOPSIS section for examples.

=head1 TYPES

The types that C<Smart::Args> uses are type constraints of C<Mouse>.
That is, you can define your types in the way Mouse does.

In addition, C<Smart::Args> also allows Moose type constraint objects,
so you can use any C<MooseX::Types::*> libraries on CPAN.

Type coercions are automatically tried if validations fail.

See L<Mouse::Util::TypeConstraints> for details.

=head1 AUTHOR

Tokuhiro Matsuno E<lt>tokuhirom@gmail.comE<gt>

=head1 SEE ALSO

L<Params::Validate>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
