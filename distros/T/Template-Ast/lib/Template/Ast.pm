#: Template/Ast.pm
#: Facilities to handle the Perl AST data structures that
#:   fits the TT template file
#: Template-Ast v0.01
#: 2005-07-15 2005-07-17

package Template::Ast;

use 5.008001;
use strict;
use warnings;
use Data::Dumper;

our $VERSION = '0.01';

our $error;

# Rebuild the AST stored in the given file:
sub read {
    shift if @_ > 1;
    my $fname = shift;
    my $fh;
    unless (open $fh, $fname) {
        $error = "file error - Can't open $fname for reading: $!\n";
        return undef;
    }
    my $code;
    {
        local $/;
        $code = <$fh>;
        close $fh;
    }
    $code =~ s/^\s*[\$\w]+\s*=\s*//os;
    my $ast = eval $code;
    if ($@) {
        $error = "file error - The AST contained in $fname is invalid: $@\n";
        return undef;
    }
    return $ast;
}

# Write the given AST to disk file:
sub write {
    shift if @_ > 2;
    my ($ast, $fname) = @_;
    my $fh;
    unless (open $fh, ">$fname") {
        $error = "file error - Can't open $fname for writing: $!\n";
        return undef;
    }
    my $code = Data::Dumper->Dump([$ast], ['ast']);
    print $fh $code;
    close $fh;
    return 1;
}

# Merging two ASTs together:
sub merge {
    shift if @_ > 2;
    my ($ast1, $ast2) = @_;
    unless (defined $ast1) { return $ast2 }
    unless (defined $ast2) { return $ast1 }
    unless (ref($ast1) and ref($ast1) eq 'HASH' and
            ref($ast2) and ref($ast2) eq 'HASH') {
        return $ast2;
    }
    my %ast1 = %$ast1;
    my %ast2 = %$ast2;
    foreach my $key (keys %ast2) {
        if (defined $ast1{$key}) { # share the same key:
            $ast1{$key} = merge($ast1{$key}, $ast2{$key});
        } else {
            $ast1{$key} = $ast2{$key};
        }
    }
    return \%ast1;
}

# Return the error info stored in the package:
sub error {
    return $error;
}

# Simple interface to Data::Dumper->Dump
sub dump {
    shift;
    return Data::Dumper->Dump(@_);
}

1;
__END__

=head1 NAME

Template::Ast - Processing ASTs for Perl Template Toolkit

=head1 SYNOPSIS

    use Template::Ast;

    # Rebuild AST stored in file:
    $ast = Template::Ast->read('foo.ast') or
        die Template::Ast->error();

    # Writing existing AST to file:
    $ast = { Marry => [24, 'F'], John => [21, 'M'] };
    Template::Ast->write($ast, 'foo.ast') or
        die Template::Ast->error();

    $ast = Template::Ast->merge([1,2,3], undef);  # [1,2,3]
    $ast = Template::Ast->merge(undef, [1,2,3]);  # [1,2,3]
    $ast = Template::Ast->merge(undef, undef);    # undef

    $ast = Template::Ast->merge({A=>1,B=>2}, ['C']);  # ['C']
    $ast = Template::Ast->merge([1,2,3], [5,6]);      # [5,6]
    $ast = Template::Ast->merge([{A=>1},2], 5);       # 5

    $ast = Template::Ast->merge({A=>1,B=>2}, {C=>3});  # {A=>1,B=>2,C=>3}
    $ast = Template::Ast->merge({A=>1,B=>2}, {B=>3});  # {A=>1,B=>3}

    # {A=>1,B=>2}
    $ast = Template::Ast->merge({A=>1,B=>undef}, {A=>undef,B=>2});

    Template::Ast->merge(
        {A=>1,B=>{C=>1,D=>2}},
        {B=>{C=>1,D=>3,E=>4}}
    );  # {A=>1,B=>{C=>1,D=>3,E=>4}}

    Template::Ast->merge(
        {A=>1,B=>{C=>[1,2]}},
        {B=>{C=>[3,4]}}
    );  # {A=>1,B=>{C=>[3,4]}}

    print Template::Ast->dump([$vars], ['vars']);

=head1 DESCRIPTION

ASTs are essential in the programming model based on Perl Template Toolkit.
This module provides some easy interface to do the dirty work involved
in AST handling. The term AST used here are referred to any Perl referece pointed
to a complex data structure, such as a nested hash, a nested array, or such.

=head1 METHODS

=over

=item Template::Ast->read($filename)

This method reads the specified file, evals the code contained in it, and
returns the result back. It is important to note that the file needn't be
generated by the C<Template::Ast->write> method. The code should be generated in
the form used by Data::Dumper, and the variable name used is not important for it
will be ignored completely by Template::Ast. The following AST specs are all okay
(but they can't appear in a single file simultaneously:

    $vars = { John => 3, Mary => [1, 2, {age => 5}] }

    $ast =
        [ 'item1',
          'item2',
          'item3',
        ];

    { [1,2], [3,4], { a => 1, b => 2} }

    [ 1, 2, 3, 4]

The read static method will return undef when an error occurs. In case of a
failure, you should check the error info via the ->error() method.

=item Template::Ast->write($ast, $filename)

The write method writes the given AST C<$ast>, to the file C<$filename>, utilizing
Data::Dumper internally. It returns undef if it encounters an error, and replies 1
otherwise. Always invoke the ->error() method when you fail to write the AST.

=item Template::Ast->merge($ast1, $ast2)

This method merges C<$ast2> to C<$ast1>, and returns the final AST. The arguments
passed to the method stay unchanged during the merging process.

The merging rule used here is a little hard to explain and may be completely
not what you expect, but it is still very useful in many cases. The algorithm
is as follows:

=over

=item *

If one of the two ASTs is undef, The result will be exactly the same as
other one. In the case that both ASTs are undef, undef will be returned.
Here are some samples:

    Template::Ast->merge($ref, undef);     # $ref
    Template::Ast->merge(undef, $ref);     # $ref
    Template::Ast->merge(undef, undef);    # undef

=item *

If C<$ast1> and C<$ast2> are not both hash refs, the result will simply
be C<$ast2> provided that C<$ast2> is not undef.

    Template::Ast->merge({A=>1,B=>2}, ['C']);  # ['C']
    Template::Ast->merge([1,2,3], [5,6]);      # [5,6]
    Template::Ast->merge([{A=>1},2], 5);       # 5

=item *

If C<$ast1> and C<$ast2> are both hash refs, The key-value pairs that appear in
C<%$ast2> but not in C<%$ast1> will be added to C<%$ast1>, forming the final
result. If a key is shared by both C<%$ast1> and C<%$ast2>, the corresponding
values of both hashes will the treated as two sub-ASTs, and be merged recursively,
the resulting sub-AST will be assigned to the hash of the final AST. Here are some
examples:

    Template::Ast->merge({A=>1,B=>2}, {C=>3});  # {A=>1,B=>2,C=>3}
    Template::Ast->merge({A=>1,B=>2}, {B=>3});  # {A=>1,B=>3}

    Template::Ast->merge(
        {A=>1,B=>{C=>1,D=>2}},
        {B=>{C=>1,D=>3,E=>4}}
    );  # {A=>1,B=>{C=>1,D=>3,E=>4}}

    Template::Ast->merge(
        {A=>1,B=>{C=>[1,2]}},
        {B=>{C=>[3,4]}}
    );  # {A=>1,B=>{C=>[3,4]}}

=back

As you may have noticed, the merging rule is completely "hash-oriented".
No merging but substitution will happen if the two ASTs are arrays or scalars.
This may look strange at the first glance, but is quite reasonable for most
AST-TT applications.

You will doubtlessly need you own version of AST merging rule. In that case,
it is recommended to override the ->merge() method via class inheritance.

=item Template::Ast->error()

It returns the most recent error info stored in the module, mostly set by the other
static methods of Template::Ast.

=item Template::Ast->dump(...)

Simple interface to the Data::Dumper->Dump method. It accepts exactly the same
arguments as the latter.

=back

=head1 SEE ALSO

L<Template>,
L<Data::Dumper>

=head1 AUTHOR

Agent Zhang, E<lt>agent2002@126.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 Agent Zhang

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
