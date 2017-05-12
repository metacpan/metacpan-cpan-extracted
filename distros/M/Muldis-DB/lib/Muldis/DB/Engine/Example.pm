use 5.008001;
use utf8;
use strict;
use warnings FATAL => 'all';

use Muldis::DB::Interface;
use Muldis::DB::Engine::Example::Operators;

###########################################################################
###########################################################################

{ package Muldis::DB::Engine::Example; # module
    our $VERSION = 0.004000;
    # Note: This given version applies to all of this file's packages.

###########################################################################

sub new_dbms {
    my ($class, $args) = @_;
    my ($dbms_config) = @{$args}{'dbms_config'};
    return Muldis::DB::Engine::Example::Public::DBMS->new({
        'dbms_config' => $dbms_config });
}

###########################################################################

} # module Muldis::DB::Engine::Example

###########################################################################
###########################################################################

{ package Muldis::DB::Engine::Example::Public::DBMS; # class
    use base 'Muldis::DB::Interface::DBMS';

    use Carp;

    # User-supplied config data for this DBMS object / virtual machine.
    # For the moment, the Example Engine doesn't actually have anything
    # that can be configured in this way, so input $dbms_config is ignored.
    my $ATTR_DBMS_CONFIG = 'dbms_config';

    # Lists of user-held objects associated with parts of this DBMS.
    # For each of these, Hash keys are obj .WHERE/addrs, vals the objs.
    # These should be weak obj-refs, so objs disappear from here
    my $ATTR_ASSOC_VARS          = 'assoc_vars';
    my $ATTR_ASSOC_FUNC_BINDINGS = 'assoc_func_bindings';
    my $ATTR_ASSOC_PROC_BINDINGS = 'assoc_proc_bindings';

    # Maintain actual state of the this DBMS' virtual machine.
    # TODO: the VM itself should be in another file, this attr with it.
    my $ATTR_TRANS_NEST_LEVEL = 'trans_nest_level';

###########################################################################

sub new {
    my ($class, $args) = @_;
    my $self = bless {}, $class;
    $self->_build( $args );
    return $self;
}

sub _build {
    my ($self, $args) = @_;
    my ($dbms_config) = @{$args}{'dbms_config'};

    $self->{$ATTR_DBMS_CONFIG} = $dbms_config;

    $self->{$ATTR_ASSOC_VARS}          = {};
    $self->{$ATTR_ASSOC_FUNC_BINDINGS} = {};
    $self->{$ATTR_ASSOC_PROC_BINDINGS} = {};

    $self->{$ATTR_TRANS_NEST_LEVEL} = 0;

    return;
}

sub DESTROY {
    my ($self) = @_;
    # TODO: check for active trans and rollback ... or member VM does it.
    # Likewise with closing open files or whatever.
    return;
}

###########################################################################

sub new_var {
    my ($self, $args) = @_;
    my ($decl_type) = @{$args}{'decl_type'};
    return Muldis::DB::Engine::Example::Public::Var->new({
        'dbms' => $self, 'decl_type' => $decl_type });
}

sub assoc_vars {
    my ($self) = @_;
    return [values %{$self->{$ATTR_ASSOC_VARS}}];
}

sub new_func_binding {
    my ($self) = @_;
    return Muldis::DB::Engine::Example::Public::FuncBinding->new({
        'dbms' => $self });
}

sub assoc_func_bindings {
    my ($self) = @_;
    return [values %{$self->{$ATTR_ASSOC_FUNC_BINDINGS}}];
}

sub new_proc_binding {
    my ($self) = @_;
    return Muldis::DB::Engine::Example::Public::ProcBinding->new({
        'dbms' => $self });
}

sub assoc_proc_bindings {
    my ($self) = @_;
    return [values %{$self->{$ATTR_ASSOC_PROC_BINDINGS}}];
}

###########################################################################

sub call_func {
    my ($self, $args) = @_;
    my ($func_name, $f_args) = @{$args}{'func_name', 'args'};

#    my $f = Muldis::DB::Engine::Example::Public::FuncBinding->new({
#        'dbms' => $self });

    my $result = Muldis::DB::Engine::Example::Public::Var->new({
        'dbms' => $self, 'decl_type' => 'sys.Core.Universal.Universal' });

#    $f->bind_func({ 'func_name' => $func_name });
#    $f->bind_result({ 'var' => $result });
#    $f->bind_params({ 'args' => $f_args });

#    $f->call();

    return $result;
}

###########################################################################

sub call_proc {
    my ($self, $args) = @_;
    my ($proc_name, $upd_args, $ro_args)
        = @{$args}{'proc_name', 'upd_args', 'ro_args'};

#    my $p = Muldis::DB::Engine::Example::Public::FuncBinding->new({
#        'dbms' => $self });

#    $p->bind_proc({ 'proc_name' => $proc_name });
#    $p->bind_upd_params({ 'args' => $upd_args });
#    $p->bind_ro_params({ 'args' => $ro_args });

#    $p->call();

    return;
}

###########################################################################

sub trans_nest_level {
    my ($self) = @_;
    return $self->{$ATTR_TRANS_NEST_LEVEL};
}

sub start_trans {
    my ($self) = @_;
    # TODO: the actual work.
    $self->{$ATTR_TRANS_NEST_LEVEL} ++;
    return;
}

sub commit_trans {
    my ($self) = @_;
    confess q{commit_trans(): Could not commit a transaction;}
            . q{ none are currently active.}
        if $self->{$ATTR_TRANS_NEST_LEVEL} == 0;
    # TODO: the actual work.
    $self->{$ATTR_TRANS_NEST_LEVEL} --;
    return;
}

sub rollback_trans {
    my ($self) = @_;
    confess q{rollback_trans(): Could not rollback a transaction;}
            . q{ none are currently active.}
        if $self->{$ATTR_TRANS_NEST_LEVEL} == 0;
    # TODO: the actual work.
    $self->{$ATTR_TRANS_NEST_LEVEL} --;
    return;
}

###########################################################################

} # class Muldis::DB::Engine::Example::Public::DBMS

###########################################################################
###########################################################################

{ package Muldis::DB::Engine::Example::Public::Var; # class
    use base 'Muldis::DB::Interface::Var';

    use Carp;
    use Scalar::Util qw( refaddr weaken );

    my $ATTR_DBMS = 'dbms';

    my $ATTR_VAR = 'var';
    # TODO: cache Perl-Hosted Muldis D version of $!var.

    # Allow Var objs to update DBMS' "assoc" list re themselves.
    my $DBMS_ATTR_ASSOC_VARS = 'assoc_vars';

###########################################################################

sub new {
    my ($class, $args) = @_;
    my $self = bless {}, $class;
    $self->_build( $args );
    return $self;
}

sub _build {
    my ($self, $args) = @_;
    my ($dbms, $decl_type) = @{$args}{'dbms', 'decl_type'};

    $self->{$ATTR_DBMS} = $dbms;
    $dbms->{$DBMS_ATTR_ASSOC_VARS}->{refaddr $self} = $self;
    weaken $dbms->{$DBMS_ATTR_ASSOC_VARS}->{refaddr $self};

#    $self->{$ATTR_VAR} = Muldis::DB::Engine::Example::VM::Var->new({
#        'decl_type' => $decl_type }); # TODO; or some such

    return;
}

sub DESTROY {
    my ($self) = @_;
    delete $self->{$ATTR_DBMS}->{$DBMS_ATTR_ASSOC_VARS}->{refaddr $self};
    return;
}

###########################################################################

sub fetch_ast {
    my ($self) = @_;
#    return $self->{$ATTR_VAR}->as_phmd(); # TODO; or some such
    return;
}

###########################################################################

sub store_ast {
    my ($self, $args) = @_;
    my ($ast) = @{$args}{'ast'};
#    $self->{$ATTR_VAR} = from_phmd( $ast ); # TODO; or some such
    return;
}

###########################################################################

} # class Muldis::DB::Engine::Example::Public::Var

###########################################################################
###########################################################################

{ package Muldis::DB::Engine::Example::Public::FuncBinding; # class
    use base 'Muldis::DB::Interface::FuncBinding';

    use Carp;
    use Scalar::Util qw( refaddr weaken );

###########################################################################

# TODO.

###########################################################################

} # class Muldis::DB::Engine::Example::Public::FuncBinding

###########################################################################
###########################################################################

{ package Muldis::DB::Engine::Example::Public::ProcBinding; # class
    use base 'Muldis::DB::Interface::ProcBinding';

    use Carp;
    use Scalar::Util qw( refaddr weaken );

###########################################################################

# TODO.

###########################################################################

} # class Muldis::DB::Engine::Example::Public::ProcBinding

###########################################################################
###########################################################################

1; # Magic true value required at end of a reusable file's code.
__END__

=pod

=encoding utf8

=head1 NAME

Muldis::DB::Engine::Example -
Self-contained reference implementation of a Muldis DB Engine

=head1 VERSION

This document describes Muldis::DB::Engine::Example version 0.4.0 for Perl
5.

It also describes the same-number versions for Perl 5 of
Muldis::DB::Engine::Example::Public::DBMS,
Muldis::DB::Engine::Example::Public::Var,
Muldis::DB::Engine::Example::Public::FuncBinding, and
Muldis::DB::Engine::Example::Public::ProcBinding.

=head1 SYNOPSIS

I<This documentation is pending.>

=head1 DESCRIPTION

B<Muldis::DB::Engine::Example>, aka the I<Muldis DB Example Engine>, aka
I<Example>, is the self-contained and pure-Perl reference implementation of
Muldis DB.  It is included in the Muldis DB core distribution to allow the
core to be completely testable on its own.

Example is coded intentionally in a simple fashion so that it is easy to
maintain and and easy for developers to study.  As a result, while it
performs correctly and reliably, it also performs quite slowly; you should
only use Example for testing, development, and study; you should not use it
in production.  (See the L<Muldis::DB::SeeAlso> file for a list of other
Engines that are more suitable for production.)

This C<Muldis::DB::Engine::Example> file is the main file of the Example
Engine, and it is what applications quasi-directly invoke; its
C<Muldis::DB::Engine::Example::Public::\w+> classes directly do/subclass
the roles/classes in L<Muldis::DB::Interface>.  The other
C<Muldis::DB::Engine::Example::\w+> files are used internally by this file,
comprising the rest of the Example Engine, and are not intended to be used
directly in user code.

I<This documentation is pending.>

=head1 INTERFACE

I<This documentation is pending; this section may also be split into
several.>

=head1 DIAGNOSTICS

I<This documentation is pending.>

=head1 CONFIGURATION AND ENVIRONMENT

I<This documentation is pending.>

=head1 DEPENDENCIES

This file requires any version of Perl 5.x.y that is at least 5.8.1.

It also requires these Perl 5 classes that are in the current distribution:
L<Muldis::DB::Interface-0.4.0|Muldis::DB::Interface>.

It also requires these Perl 5 classes that are in the current distribution:
L<Muldis::DB::Engine::Example::PhysType-0.4.0|
Muldis::DB::Engine::Example::PhysType>,
L<Muldis::DB::Engine::Example::Operators-0.4.0|
Muldis::DB::Engine::Example::Operators>.

=head1 INCOMPATIBILITIES

None reported.

=head1 SEE ALSO

Go to L<Muldis::DB> for the majority of distribution-internal references,
and L<Muldis::DB::SeeAlso> for the majority of distribution-external
references.

=head1 BUGS AND LIMITATIONS

I<This documentation is pending.>

=head1 AUTHOR

Darren Duncan (C<perl@DarrenDuncan.net>)

=head1 LICENSE AND COPYRIGHT

This file is part of the Muldis DB framework.

Muldis DB is Copyright © 2002-2007, Darren Duncan.

See the LICENSE AND COPYRIGHT of L<Muldis::DB> for details.

=head1 ACKNOWLEDGEMENTS

The ACKNOWLEDGEMENTS in L<Muldis::DB> apply to this file too.

=cut
