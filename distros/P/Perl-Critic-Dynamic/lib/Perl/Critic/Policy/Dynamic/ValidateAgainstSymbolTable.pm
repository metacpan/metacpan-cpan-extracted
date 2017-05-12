##############################################################################
#      $URL: http://perlcritic.tigris.org/svn/perlcritic/tags/Perl-Critic-Dynamic-0.05/lib/Perl/Critic/Policy/Dynamic/ValidateAgainstSymbolTable.pm $
#     $Date: 2010-09-24 12:32:37 -0700 (Fri, 24 Sep 2010) $
#   $Author: thaljef $
# $Revision: 3935 $
##############################################################################

package Perl::Critic::Policy::Dynamic::ValidateAgainstSymbolTable;

use strict;
use warnings;

use base 'Perl::Critic::DynamicPolicy';

use Carp qw(confess);
use English qw(-no_match_vars);
use Devel::Symdump ();
use Readonly ();

use Perl::Critic::Utils qw(
    :severities
    &hashify
    &is_function_call
    &is_perl_builtin
    &policy_short_name
);

#-----------------------------------------------------------------------------

our $VERSION = 0.05;

#-----------------------------------------------------------------------------

Readonly::Scalar my $AMPERSAND => q{&};
Readonly::Scalar my $FAKE_NAMESPACE => '__FAKE_NAMESPACE__';
Readonly::Scalar my $CONFIG_PATH_SPLIT_REGEX => qr/ \s* [|] \s* /xms;
Readonly::Hash   my %GLOBAL_PACKAGES => hashify(qw(UNIVERSAL CORE));

#-----------------------------------------------------------------------------

sub default_severity     { return $SEVERITY_HIGH          }
sub default_themes       { return qw( dynamic bugs )      }
sub applies_to           { return 'PPI::Document'         }

sub supported_parameters {
    return qw(
        at_inc
        at_inc_prefix
        at_inc_suffix
        max_recursion
        inspect_autoloaders
        inspect_required_modules
    );
}

#-----------------------------------------------------------------------------

sub new {

    my ( $class, %args ) = @_;
    my $self = bless {}, $class;

    # Configure @INC list...
    my @at_inc_prefix = defined $args{at_inc_prefix} ?
      split $CONFIG_PATH_SPLIT_REGEX, $args{at_inc_prefix} : ();

    my @at_inc_suffix = defined $args{at_inc_suffix} ?
      split $CONFIG_PATH_SPLIT_REGEX, $args{at_inc_suffix} : ();

    my @at_inc = defined $args{at_inc} ?
      split $CONFIG_PATH_SPLIT_REGEX, $args{at_inc} : @INC;

    $self->{_inc} = [@at_inc_prefix, @at_inc, @at_inc_suffix];


    # Other configurations...
    $self->{_max_recursion} = defined $args{max_recursion} ?
       $args{max_recursion} : 0;

    $self->{_inspect_autoloaders} = defined $args{inspect_autoloaders} ?
       $args{inspect_autoloaders} : 0;

    $self->{_inspect_required_modules} = defined $args{inspect_required_modules} ?
       $args{inspect_required_modules} : 0;


    return $self;
}

#-----------------------------------------------------------------------------

sub violates_dynamic {

    my ($self, undef, $doc) = @_;

    my $all_elements = $doc->find('PPI::Element');
    return if not $all_elements;


    my @wanted_namespaces = $self->_find_wanted_namespaces( $doc );
    my %wanted_namespaces = hashify(@wanted_namespaces);


    $self->_compile_document($doc);
    my $symbols_of = $self->_hashify_symbol_table(@wanted_namespaces);


    my @violations = ();
    my $current_ns = $FAKE_NAMESPACE;


    # TODO: Factor this if/elsif block into a dispatch table
  ELEMENT:
    for my $elem ( @{$all_elements} ) {


        if ($elem->isa('PPI::Statement::Package') ) {
            $current_ns = $elem->namespace();
            next ELEMENT;
        }



        if ($elem->isa('PPI::Statement::Include') ) {

            next if $elem->type() ne 'require';
            next if not $self->{_inspect_required_modules};

            my $module = $elem->module() || next;
            $self->_require_module($current_ns, $module);

            $wanted_namespaces{$module} = 1;
            @wanted_namespaces = keys %wanted_namespaces;
            $symbols_of = $self->_hashify_symbol_table(@wanted_namespaces);
            next ELEMENT;
        }



        if ( $elem->isa('PPI::Token::Symbol') ) {

            next if $elem->isa('PPI::Token::Magic');

            push @violations,
              $self->_check_symbol($elem, $symbols_of,
                                   \%wanted_namespaces, $current_ns);
        }
        elsif( $elem->isa('PPI::Token::Word') ) {

            next if not is_function_call($elem);
            next if is_perl_builtin($elem);

            push @violations,
              $self->_check_bareword($elem, $symbols_of,
                                     \%wanted_namespaces, $current_ns);
        }
    }

    return @violations;
}


#-----------------------------------------------------------------------------

sub _check_symbol {

    my ($self, $symbol, $symbols_of, $included_modules, $current_ns) = @_;


    # Normalize and parse symbol
    # TODO: Document the regexes used here
    my $canon = $symbol->canonical();

    $canon =~ m{ \A [\$@%&*] (.*?) (?: ::)? ([^:]*) \z }xms
      or confess "Unexpected symbol format: $symbol";

    my ($pkg, $sym_name) = ($1, $2);
    my $sigil = $symbol->symbol_type();


    # Unqualified symbols are exempt because lexicals aren't in the symbol
    # table.  However, subroutines are.  So we do want things like "&foo()" and
    # "$code_ref = \&foo";

    return if $sigil ne $AMPERSAND && !$pkg;
    if ( !$pkg && $sigil eq $AMPERSAND ) {$pkg = $current_ns}


    # If asked, skip calls to packages with AUTOLOAD
    if ( $symbols_of->{$sigil}->{"${pkg}::AUTOLOAD"} ) {
        return if not $self->{_inspect_autoloaders};
    }


    # Ignore stuff from global packages
    return if exists $GLOBAL_PACKAGES{$pkg};


    # Check if is in the symbol table
    return if exists $symbols_of->{$sigil}->{"${pkg}::${sym_name}"};


    # If we get here, there must be a violation
    my $desc = qq{Symbol "$canon" does not appear to be defined};
    my $expl = qq{Perhaps you forgot to load "$pkg"};

    return $self->violation($desc, $expl, $symbol);
}

#-----------------------------------------------------------------------------

sub _check_bareword {

    my ($self, $bareword, $symbols_of, $included_modules, $current_ns) = @_;



    # Normalize and parse bareword
    # TODO: Document the regexes used here
    my $canon = _canonicalize_bareword($bareword->content(), $current_ns);
    $canon =~ m{ (.+) :: ([^:]+) \z }xms
      or confess "Unexpected bareword format: $canon";
    my ($sigil, $pkg, $sub_name) = ($AMPERSAND, $1, $2);


    # Ignore stuff from global packages
    return if exists $GLOBAL_PACKAGES{$pkg};


    # If asked, skip calls to packages with AUTOLOAD
    if ( $symbols_of->{$sigil}->{"${pkg}::AUTOLOAD"} ) {
        return if not $self->{_inspect_autoloaders};
    }


    # Check if barewords is in the symbol table.  It could be a
    # a subroutine, or just a file-handle.  I can't tell the diff.
    return if exists $symbols_of->{$sigil}->{$canon};
    return if exists $symbols_of->{ios}->{$canon};



    # If we get here, there must be a violation
    my $desc = qq{Subroutine "$bareword" does not appear to be defined};
    my $expl = $included_modules->{$pkg} ?
      qq{Perhaps "$sub_name" is misspelled}
    : qq{Perhaps you forgot to load "$pkg"};


    return $self->violation($desc, $expl, $bareword);
}

#-----------------------------------------------------------------------------

sub _require_module {

    my ($self, $current_ns, $module) = @_;

    my $code = <<"END_CODE";

package $current_ns;
require $module;

END_CODE

    local @INC = @{ $self->{_inc} };
    eval $code;  ## no critic (Eval)

     if ($EVAL_ERROR) {
         my $policy = policy_short_name(__PACKAGE__);
         die qq($policy: Couldn't require "$module": $EVAL_ERROR\n);
    }

    return 1;
}

#-----------------------------------------------------------------------------

sub _find_wanted_namespaces {

    my ($self, $doc) = @_;

    my @declared_packages = $self->_find_declared_packages($doc);
    my @included_modules  = $self->_find_included_modules($doc);

    return (
        'main',
         $FAKE_NAMESPACE,
         @declared_packages,
         @included_modules,
    );
}

#-----------------------------------------------------------------------------

sub _compile_document {

    my ($self, $doc) = @_;

    # The $doc could be a script or a library or just an arbitrary block of
    # code.  I use "eval" to compile the code and populate the symbol table,
    # but I don't want to execute anything.  So I ineject code to die before
    # anything is executed.  Also, I want to protect myself from the chance
    # that "die" has been overridden, so I call CORE::die directly.  Perhaps
    # there is a more elegant way to do this, but I haven't figured it out.

    my $suicide_note = '__execution_aborted__';
    my $code_header = <<"END_HEADER";

package $FAKE_NAMESPACE;

no strict;
no warnings;
CORE::die("$suicide_note\\n");

END_HEADER

    # As of version 1.118, PPI has trouble accurately parsing & reproducing
    # files that contain HEREDOCs.  So if $doc is a file, we'll try and read
    # the code from the source.  Otherwise, we'll use PPI's translation of it.

    my $source_code = q{};
    my $filename = $doc->filename();
    if (defined $filename && -f $filename) {
        open my $fh, '<', $filename
          or confess qq{Can't open "$filename" for reading: $OS_ERROR};
        $source_code = do {local $INPUT_RECORD_SEPARATOR = undef; <$fh>; };
        close $fh or confess qq{Can't close "$filename": $OS_ERROR};
    }
    else {
        $source_code = $doc->content();
    }

    # Prepend our special header to the source
    $source_code = $code_header . $source_code;

    # Now eval the code, using the @INC paths that has been configured.  If
    # all goes well, it to die with a very particular error message.

    local @INC = @{ $self->{_inc} };
    eval $source_code;  ## no critic (Eval)
    return 1 if $EVAL_ERROR eq "$suicide_note\n";


    # Something went wrong then...
    my $file = $doc->filename() || 'unknown file';
    my $policy = policy_short_name(__PACKAGE__);

    if ($EVAL_ERROR) {
        die qq($policy: Compilation of "$file" failed: $EVAL_ERROR\n);
    }
    else {
        confess qq($policy: PANIC - "$file" did not commit suicide);
    }
}

#-----------------------------------------------------------------------------

sub _find_declared_packages {

    my ($self, $doc) = @_;

    my $package_declarations = $doc->find('PPI::Statement::Package');
    return if not $package_declarations;

    my @declared_packages = map { $_->namespace() } @{$package_declarations};
    return @declared_packages;
}

#-----------------------------------------------------------------------------

sub _find_included_modules {

    my ($self, $doc) = @_;

    my $includes = $doc->find('PPI::Statement::Include');
    return if not $includes;


    my @include_statements = grep {$_->type() =~ m/(?:use|no)/xms} @{$includes};

    # I'm assuming that the name of the module, is the namespace where its
    # symbols are going to be declared.  But that isn't always true.  Might be
    # able to accommodate that by using Devel::Symdump in recursive mode.

    my @included_modules = map { $_->module() } @include_statements;
    return @included_modules;
}

#-----------------------------------------------------------------------------

sub _hashify_symbol_table {

    my ($self, @wanted_packages) = @_;

    local $Devel::Symdump::MAX_RECURSION = $self->{_max_recursion};
    my $symbol_table = Devel::Symdump->rnew(@wanted_packages);

    # This is kinda lame.  Consider creating an OO interface for this, or just
    # use Devel::Symdump directly.  Or maybe there's a better module on CPAN.

    ## no critic (NoisyQuotes)
    my %symbols_by_sigil = (
       'ios' => { hashify( $symbol_table->ios()       ) },
        '@'  => { hashify( $symbol_table->arrays()    ) },
        '%'  => { hashify( $symbol_table->hashes()    ) },
        '$'  => { hashify( $symbol_table->scalars()   ) },
        '&'  => { hashify( $symbol_table->functions() ) },
    );

    return \%symbols_by_sigil;
}

#-----------------------------------------------------------------------------

sub _canonicalize_bareword {

    my ($bareword_as_string, $current_ns) = @_;
    return $bareword_as_string if $bareword_as_string =~ m/\A .+ ::/xms;
    return 'main' . $bareword_as_string if $bareword_as_string =~ m/\A ::/xms;
    return $current_ns. q{::} . $bareword_as_string;
}

#-----------------------------------------------------------------------------

1;

__END__

=pod

=head1 NAME

Perl::Critic::Policy::Dynamic::ValidateAgainstSymbolTable

=head1 DESCRIPTION

This Policy warns if any subroutine call that appears in your code is not
defined in the symbol table at compile-time.  The intent is to detect typos in
the names of packages and subroutines, and possible failures to import,
declare, or include all the static subroutines that are invoked by your code..

B<VERY IMPORTANT:> Most L<Perl::Critic> Policies (including all the ones that
ship with Perl::Critic> use pure static analysis -- they never compile nor
execute any of the code that they analyze.  However, this policy is very
different.  It actually attempts to compile your code and then compares the
subroutines mentioned in your code to those found in the symbol table.
Therefore you should B<not> use this Policy on any code that you do not trust,
or may have undesirable side-effects at compile-time (such as connecting to
the network or mutating files).

For these reasons, this Policy (and any other Policy that inherits from
L<Perl::Critic::DynamicPolicy>) is marked as "unsafe" and usually ignored by
both L<Perl::Critic> and L<perlcritic>.  So to use this Policy, you must set
the C<-allow-unsafe> switch in the L<Perl::Critic> contstructor or on the
L<perlcritic> command line.

For this Policy to work, all the modules included in your code must be
installed locally, and must compile without error.  See L<"CONFIGURATION"> for
information about controlling where this Policy searches for the included
modules.

=head1 LIMITATIONS

This Policy will not detect subroutines that are declared at run-time or
through direct manipulation of the symbol table, which may lead to false
warnings.  The most common examples of this are modules that use C<AUTOLOAD>.

Sophisticated code often use the C<require> function to postpone loading
modules or only load modules under certain conditions.  If you set the
C<inspect_required_modules> option, the Policy will attempt to load all
modules that are C<require'd> at any point in your code.  However, this Policy
does not know whether the module would have been loaded during normal
execution of your program.  This may cause the Policy to overlook potential
violations.

This Policy only examines static subroutine calls -- method calls are not
covered.  Indirect method calls such as C<"my $fh = new FileHandle"> also tend
to trigger false warnings.

This Policy compiles your code into the same symbol table as Perl::Critic
itself.  So to maintain integrity in the symbol table, this Policy forks
itself before analyzing each file.  On some systems, this may be slow and
consume a lot of resources.

=head1 CONFIGURATION

This Policy supports the following configuration parameters.  See below for
example of how to set these parameters in you f<.perlcriticrc> file.

=over

=item C<at_inc_prefix>

Prepends an arrayref of directories to the front of the current C<@INC> list.
This affects where the Policy will find dependent modules when it compiles
your code.

=item C<at_inc_suffix>

Appends an arrayref of directories to the end of the current C<@INC> list.
This affects where the Policy will find dependent modules when it compiles
your code.

=item C<at_inc>

Sets the C<@INC> list outright. This affects where the Policy will find
dependent modules when it compiles your code.

=item C<inspect_required_modules>

By default, this Policy only examines modules that are loaded by your code at
compile-time.  If C<inspect_required_modules> is set to a true value, this Policy
will also compile all the modules that are C<require>'d in your code at
runtime.  Note that this Policy does not know if these modules will actually
be loaded when your program runs, nor does it try to invoke the C<import>
method on those modules.

=item C<inspect_autoloaders>

By default, this Policy does not attempt to validate a function call into a
package that has an C<AUTOLOAD> method.  Such packages usually define
functions at run-time, so this Policy has no chance of knowing what functions
that package might have.  But if C<inspect_autoloaders> is set to a true
value, the Policy will check to see if a function exists in such packages.

=item C<max_recursion>

By default, this Policy only looks at the symbol tables for the namespaces
that are directly C<use'd> (or C<require'd>) by your code.  However, some
modules contain multiple namespaces which may lead to false violations.  But
if you set C<max_recursion> to a positive integer, this Policy will recurse
into those other namespaces.  Beware, however, that using a deep recursion can
mask other violations.  Setting C<max_recursion> to 1 or 2 is usually
sufficient.

=back

You can set these configuration parameters but putting any or all of the
following in your F<.perlcriticrc> file.

  [Dynamic::ValidateAgainstSymbolTable]

  at_inc_prefix = some/directory/path | another/directory/path
  at_inc_suffix = some/directory/path | another/directory/path
  at_inc = some/directory/path | another/directory/path

  inspect_required_modules = 1
  inspect_autoloaders   = 1

=head1 AUTHOR

Jeffrey Ryan Thalhammer <thaljef@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2007 Jeffrey Ryan Thalhammer.  All rights reserved.

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.  The full text of this license can be found in
the LICENSE file included with this module.

=cut

##############################################################################
# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab :
