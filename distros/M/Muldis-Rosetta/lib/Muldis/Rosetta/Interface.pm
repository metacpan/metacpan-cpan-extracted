use 5.008001;
use utf8;
use strict;
use warnings FATAL => 'all';

###########################################################################
###########################################################################

{ package Muldis::Rosetta::Interface; # package
    our $VERSION = '0.016000';
    $VERSION = eval $VERSION;
    # Note: This given version applies to all of this file's packages.
} # package Muldis::Rosetta::Interface

###########################################################################
###########################################################################

{ package Muldis::Rosetta::Interface::Machine; # role

    use namespace::autoclean 0.09;

    use Moose::Role 0.98;

    requires 'new_process';

} # role Muldis::Rosetta::Interface::Machine

###########################################################################
###########################################################################

{ package Muldis::Rosetta::Interface::Process; # role

    use namespace::autoclean 0.09;

    use Moose::Role 0.98;

    requires 'assoc_machine';
    requires 'pt_command_lang';
    requires 'update_pt_command_lang';
    requires 'hd_command_lang';
    requires 'update_hd_command_lang';
    requires 'execute';
    requires 'new_value';
    requires 'func_invo';
    requires 'upd_invo';
    requires 'proc_invo';
    requires 'trans_nest_level';
    requires 'start_trans';
    requires 'commit_trans';
    requires 'rollback_trans';

} # role Muldis::Rosetta::Interface::Process

###########################################################################
###########################################################################

{ package Muldis::Rosetta::Interface::Value; # role

    use namespace::autoclean 0.09;

    use Moose::Role 0.98;

    requires 'assoc_process';
    requires 'pt_source_code';
    requires 'hd_source_code';

} # role Muldis::Rosetta::Interface::Value

###########################################################################
###########################################################################

1; # Magic true value required at end of a reusable file's code.
__END__

=pod

=encoding utf8

=head1 NAME

Muldis::Rosetta::Interface -
Common public API for Muldis Rosetta Engines

=head1 VERSION

This document describes Muldis::Rosetta::Interface version 0.16.0 for Perl
5.

It also describes the same-number versions for Perl 5 of
Muldis::Rosetta::Interface::Machine ("Machine"),
Muldis::Rosetta::Interface::Process ("Process"),
Muldis::Rosetta::Interface::Value ("Value").

=head1 SYNOPSIS

This simple example declares two Perl variables containing relation data,
then does a (N-adic) relational join (natural inner join) on them,
producing a third Perl variable holding the relation data of the result.

    use Muldis::Rosetta::Engine::Example;
    my $machine = Muldis::Rosetta::Engine::Example::select_machine();

    my $process = $machine->new_process();
    $process->update_hd_command_lang({ 'lang' => [ 'Muldis_D',
        'http://muldis.com', '0.110.0', 'HDMD_Perl5_STD',
        { catalog_abstraction_level => 'rtn_inv_alt_syn',
        op_char_repertoire => 'extended' } ] });

    my $r1 = $process->new_value({
        'source_code' => [ 'Relation', [ [ 'x', 'y' ] => [
            [ 4, 7 ],
            [ 3, 2 ],
        ] ] ]
    });

    my $r2 = $process->new_value({
        'source_code' => [ 'Relation', [ [ 'y', 'z' ] => [
            [ 5, 6 ],
            [ 2, 1 ],
            [ 2, 4 ],
        ] ] ]
    });

    my $r3 = $process->func_invo({
        'function' => 'join',
        'args' => {
            'topic' => [ 'Set', [ $r1, $r2 ] ],
        }
    });

    my $r3_as_perl = $r3->hd_source_code();

    # Then $r3_as_perl contains:
    # [ 'Relation', [ [ 'x', 'y', 'z' ] => [
    #     [ 3, 2, 1 ],
    #     [ 3, 2, 4 ],
    # ] ] ]

If the name of the Muldis Rosetta Engine to use is being read from a config
file, as C<$engine_name>, rather than being hard-coded into the
application, then these next 2 lines can be used instead of the first 2
lines above, assuming the Class::MOP module is already loaded:

    Class::MOP::load_class( $engine_name );
    my $machine = &{$engine_name->can( 'select_machine' )}();

For most examples of using Muldis Rosetta, and tutorials, please see the
separate L<Muldis::D::Manual>.

=head1 DESCRIPTION

B<Muldis::Rosetta::Interface>, aka I<Interface>, comprises the minimal core
of the Muldis Rosetta framework, the one component that probably every
program would use.  Together with the Muldis D language (see L<Muldis::D>),
it defines the common API for Muldis Rosetta implementations to do and
which applications invoke.

I<This documentation is pending.>

=head1 INTERFACE

The interface of Muldis::Rosetta::Interface is fundamentally
object-oriented; you use it by creating objects from its member classes (or
more specifically, of implementing classes that compose its member roles)
and then invoking methods on those objects.  All of their attributes are
private, so you must use accessor methods.

To aid portability of your applications over multiple implementing Engines,
the normal way to create Interface objects is by invoking a
constructor-wrapping method of some other object that would provide context
for it; since you generally don't have to directly invoke any package
names, you don't need to change your code when the package names change due
to switching the Engine.  You only refer to some Engine's root package name
once, as the namespace on which you invoke the C<select_machine>
constructor function, and even that can be read from a config file rather
than being hard-coded in your application.

The usual way that Muldis::Rosetta::Interface indicates a failure is to
throw an exception; most often this is due to invalid input.  If an invoked
routine simply returns, you can assume that it has succeeded, even if the
return value is undefined.

=head1 The Root Package of a Muldis Rosetta Engine

A Perl module that is a Muldis Rosetta Engine is expected to be implemented
with a public API consisting of one stateless root package plus several
classes.  The stateless root package is what by way of which you access the
whole Muldis Rosetta API; that is, you use it to instantiate virtual
machines, which provide the rest of the Muldis Rosetta API.  The root
package is expected to have the same Perl package name as the conceptual
Perl package name of the whole Engine; for example, the Engine named
C<Muldis::Rosetta::Engine::Example> is expected to declare a package named
C<Muldis::Rosetta::Engine::Example> as its root package. There is no strict
requirement on what the other API-providing classes of the Engine are
named, especially since in general any users of the Engine would never be
referencing objects of theirs by name; however, best practice would have
them living in child namespaces of the Engine root package, for example
C<Muldis::Rosetta::Engine::Example::Public::Machine>.

The root package of a Muldis Rosetta Engine is expected to declare a
C<select_machine> constructor function, as described next.

=head2 select_machine

C<sub select_machine of Muldis::Rosetta::Interface::Machine ()>

This constructor function selects (first creating if necessary) and returns
the singleton C<Machine> object that is implemented by the Muldis Rosetta
Engine whose stateless root package name it is invoked on.  This
constructor function is expected to return an object of some class of the
same Engine which does the C<Muldis::Rosetta::Interface::Machine> role.

=head1 The Muldis::Rosetta::Interface::Machine Role

A C<Machine> object represents a single active Muldis Rosetta virtual
machine / Muldis D environment, which is the widest scope stateful context
in which any other database activities happen.  Other activities meaning
the compilation and execution of Muldis D code, mounting or unmounting
depots, performing queries, data manipulation, data definition, and
transactions.  It is expected that a Muldis Rosetta Engine would implement
a C<Machine> as a singleton (or behave as if it did), so only one such
object would exist at a time in a Perl process per distinct Engine, in
which case a C<Machine> would be a proxy for the Engine as a whole, by
which one can act on the Engine in a "global" sense.  If a C<Machine>
object is ever garbage collected by Perl while it has any active
transactions, then those will all be rolled back, and then an exception
thrown.

=head2 new_process

C<method new_process of Muldis::Rosetta::Interface::Process ($self:
Hash :$process_config?)>

This method creates and returns a new C<Process> object that is associated
with the invocant C<Machine>; that C<Process> object is initialized using
the C<$process_config> argument.

=head1 The Muldis::Rosetta::Interface::Process Role

A C<Process> object represents a single Muldis Rosetta in-DBMS process,
which has its own autonomous transactional context, and for the most part,
its own isolated environment.  It is associated with a specific C<Machine>
object, the one whose C<new_process> method created it.

A new C<Process> object's "expected plain-text|Perl-hosted-data command
language" attribute is undefined by default, meaning that each
plain-text|Perl-hosted-data command fed to the process must declare what
plain-text|Perl-hosted-data language it is written in; if that attribute
was made defined, then plain-text|Perl-hosted-data commands fed to it would
not need to declare their plain-text|Perl-hosted-data language and will be
interpreted according to the expected plain-text|Perl-hosted-data language;
if both the attribute is defined and the command has its own language
declaration, then the one with the command will override the attribute.

=head2 assoc_machine

C<method assoc_machine of Muldis::Rosetta::Interface::Machine ($self:)>

This method returns the C<Machine> object that the invocant C<Process> is
associated with.

=head2 pt_command_lang

C<method pt_command_lang of Str ($self:)>

This method returns the fully qualified name of its invocant C<Process>
object's "expected plain-text command language" attribute, which might be
undefined; if it is defined, then is a Perl Str that names a Plain Text
language; these may be Muldis D dialects or some other language.

=head2 update_pt_command_lang

C<method update_pt_command_lang ($self: Str :$lang!)>

This method assigns a new (possibly undefined) value to its invocant
C<Process> object's "expected plain-text command language" attribute.  This
method dies if the specified language is defined and its value isn't one
that the invocant's Engine knows how to or desires to handle.

=head2 hd_command_lang

C<method hd_command_lang of Array ($self:)>

This method returns the fully qualified name of its invocant C<Process>
object's "expected Perl-hosted-data command language" attribute, which
might be undefined; if it is defined, then is a Perl (ordered) Array that
names a Perl Hosted Data language; these may be Muldis D dialects or some
other language.

=head2 update_hd_command_lang

C<method update_hd_command_lang ($self: Array :$lang!)>

This method assigns a new (possibly undefined) value to its invocant
C<Process> object's "expected Perl-hosted-data command language" attribute.
This method dies if the specified language is defined and its value isn't
one that the invocant's Engine knows how to or desires to handle.

=head2 execute

C<method execute ($self: Any :$source_code!, Any :$lang?)>

This method compiles and executes the (typically Muldis D) source code
given in its C<$source_code> argument.  If C<$source_code> is a Perl Str
then it is treated as being written in a plain-text language; if
C<$source_code> is any kind of Perl 5 reference or Perl 5 object then it is
treated as being written in a Perl-hosted-data language.  This method dies
if the source code fails to compile for some reason, or if the executing
code has a runtime exception.  If C<$lang> is defined, it must match
C<$source_code> in Str vs Array|obj categorization.

=head2 new_value

C<method new_value of Muldis::Rosetta::Interface::Value ($self:
Any :$source_code!, Any :$lang?)>

This method creates and returns a new C<Value> object that is associated
with the invocant C<Process>; that C<Value> object is initialized using the
(typically Muldis D) source code given in its C<$source_code> argument,
which defines a value literal.  If C<$source_code> is a Perl Str then it is
treated as being written in a plain-text language; if C<$source_code> is
any kind of Perl 5 reference or Perl 5 object then it is treated as being
written in a Perl-hosted-data language.  If the C<$source_code> is in a
Perl Hosted Data language, then it may consist partially of other C<Value>
objects.  If C<$source_code> is itself just a C<Value> object, then it will
be cloned.  Because a source code fragment representing a value literal
typically doesn't embed its own declaration of the
plain-text|Perl-hosted-data language it is written in, that language must
be specified external to the fragment, either by giving a defined C<$lang>
argument, or by ensuring that the invocant C<Process> object has a defined
"expected plain-text|Perl-hosted-data command language" attribute.  If
C<$lang> is defined, it must match C<$source_code> in Str vs Array|obj
categorization.

=head2 func_invo

C<method func_invo of Muldis::Rosetta::Interface::Value ($self:
Str :$function!, Hash :$args?, Str :$pt_lang?, Array :$hd_lang?)>

This method invokes the Muldis D function named by its C<$function>
argument, giving it arguments from C<$args>, and then returning the result
as a C<Value> object.  Each C<$args> Hash key must match the name of a
parameter of the named function, and the corresponding Hash value is the
argument for that parameter; each Hash value may be either a C<Value>
object or some other Perl value that would be suitable as the
C<$source_code> constructor argument for a new C<Value> object; if
C<$pt_lang> or C<$hd_lang> are defined, the appropriate one will be given
as the C<$lang> constructor argument.

=head2 upd_invo

C<method upd_invo ($self: Str :$updater!, Hash :$upd_args!,
Hash :$ro_args?, Str :$pt_lang?, Array :$hd_lang?)>

This method invokes the Muldis D updater named by its C<$updater> argument,
giving it subject-to-update arguments from C<$upd_args> and read-only
arguments from C<$ro_args>; the C<Value> objects in C<$upd_args> are
possibly substituted for other C<Value> objects as a side-effect of the
updater's execution.  The C<$ro_args> parameter is as per the C<$args>
parameter of the C<func_invo> method, but the C<$upd_args> parameter is a
bit different; each Hash value in the C<$upd_args> argument must be a Perl
scalar reference pointing to the Perl variable being bound to the
subject-to-update parameter; said Perl variable is then what holds a
C<Value> object et al prior to the updater's execution, and that may have
been updated to hold a different C<Value> object as a side-effect.

=head2 proc_invo

C<method proc_invo ($self: Str :$procedure!, Hash :$upd_args?,
Hash :$ro_args?, Str :$pt_lang?, Array :$hd_lang?)>

This method invokes the Muldis D procedure
named by its C<$procedure> argument, giving it
subject-to-update arguments from C<$upd_args> and read-only arguments from
C<$ro_args>; the C<Value> objects in C<$upd_args> are possibly substituted
for other C<Value> objects as a side-effect of the procedure's execution.
The parameters of C<proc_invo> are as per those of the C<upd_invo> method,
save that only C<upd_invo> makes C<$upd_args> mandatory, while C<proc_invo>
makes it optional.

=head2 trans_nest_level

C<method trans_nest_level of Int ($self:)>

This method returns the current transaction nesting level of its invocant's
virtual machine process.  If no explicit transactions were started, then
the nesting level is zero, in which case the process is conceptually
auto-committing every successful Muldis D statement.  Each call of
C<start_trans> will increase the nesting level by one, and each
C<commit_trans> or C<rollback_trans> will decrease it by one (it can't be
decreased below zero).  Note that all transactions started or ended within
Muldis D code are attached to a particular lexical scope in the Muldis D
code, and so they will never have any effect on the nest
level that Perl sees (assuming that a Muldis D host language will never be
invoked by Muldis D), regardless of whether the Muldis D code successfully
returns or throws an exception.

=head2 start_trans

C<method start_trans ($self:)>

This method starts a new child-most transaction within the invocant's
virtual machine process.

=head2 commit_trans

C<method commit_trans ($self:)>

This method commits the child-most transaction within the invocant's
virtual machine process; it dies if there isn't one.

=head2 rollback_trans

C<method rollback_trans ($self:)>

This method rolls back the child-most transaction within the invocant's
virtual machine process; it dies if there isn't one.

=head1 The Muldis::Rosetta::Interface::Value Role

A C<Value> object represents a single Muldis Rosetta in-DBMS value, which
is conceptually immutable, eternal, and not fixed in time or space; the
object is immutable.  It is associated with a specific C<Process> object,
the one whose C<new_value> method created it.  You can use C<Value> objects
in Perl routines the same as normal immutable Perl values or objects,
including that you just do ordinary Perl variable assignment.  C<Value>
objects are the normal way to directly share or move data between the
Muldis Rosetta DBMS and main Perl environments.  The value that a C<Value>
object represents is set when the C<Value> object is created, and it can't
be changed afterwards.

=head2 assoc_process

C<method assoc_process of Muldis::Rosetta::Interface::Process ($self:)>

This method returns the C<Process> object that the invocant C<Value> is
associated with.

=head2 pt_source_code

C<method pt_source_code of Str ($self: Str :$lang?)>

This method returns (typically Muldis D) plain-text source code that
defines a value literal equivalent to the in-DBMS value that the invocant
C<Value> represents.  The plain-text language of the source code to return
must be explicitly specified, either by giving a defined C<$lang> argument,
or by ensuring that the C<Process> object associated with this C<Value> has
a defined "expected plain-text command language" attribute.

=head2 hd_source_code

C<method hd_source_code of Any ($self: Array :$lang?)>

This method returns (typically Muldis D) Perl-hosted-data source code that
defines a value literal equivalent to the in-DBMS value that the invocant
C<Value> represents.  The Perl-hosted-data language of the source code to
return must be explicitly specified, either by giving a defined C<$lang>
argument, or by ensuring that the C<Process> object associated with this
C<Value> has a defined "expected Perl-hosted-data command language"
attribute.

=head1 DIAGNOSTICS

I<This documentation is pending.>

=head1 CONFIGURATION AND ENVIRONMENT

I<This documentation is pending.>

=head1 DEPENDENCIES

This file requires any version of Perl 5.x.y that is at least 5.8.1, and
recommends one that is at least 5.10.1.

It also requires these Perl 5 packages that are on CPAN:
L<namespace::autoclean-ver(0.09..*)|namespace::autoclean>,
L<Moose::Role-ver(0.98..*)|Moose::Role>.

=head1 INCOMPATIBILITIES

None reported.

=head1 SEE ALSO

Go to L<Muldis::Rosetta> for the majority of distribution-internal
references, and L<Muldis::Rosetta::SeeAlso> for the majority of
distribution-external references.

=head1 BUGS AND LIMITATIONS

The Muldis Rosetta framework for Perl 5 does not make explicit attempts in
code to enforce privacy of the framework's internals, besides not
documenting them as part of the public API.  (The Muldis Rosetta framework
for Perl 6 is different.)  That said, you should still respect that privacy
and just use the public API that Muldis Rosetta provides.  If you bypass
the public API anyway, as Perl 5 allows, you do so at your own peril.

I<This documentation is pending.>

=head1 AUTHOR

Darren Duncan (C<darren@DarrenDuncan.net>)

=head1 LICENSE AND COPYRIGHT

This file is part of the Muldis Rosetta framework.

Muldis Rosetta is Copyright © 2002-2010, Muldis Data Systems, Inc.

See the LICENSE AND COPYRIGHT of L<Muldis::Rosetta> for details.

=head1 TRADEMARK POLICY

The TRADEMARK POLICY in L<Muldis::Rosetta> applies to this file too.

=head1 ACKNOWLEDGEMENTS

The ACKNOWLEDGEMENTS in L<Muldis::Rosetta> apply to this file too.

=cut
