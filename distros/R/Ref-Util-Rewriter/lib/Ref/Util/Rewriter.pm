package Ref::Util::Rewriter;
# ABSTRACT: Rewrite your code to use Ref::Util

use strict;
use warnings;

use PPI;
use Safe::Isa;
use Exporter   qw< import >;
use List::Util qw< first  >;

my @EXPORT_OK = qw< rewrite_string rewrite_file >;

my %reftype_to_reffunc = (
    SCALAR => 'is_scalarref',
    ARRAY  => 'is_arrayref',
    HASH   => 'is_hashref',
    CODE   => 'is_coderef',
    Regexp => 'is_regexpref',
    GLOB   => 'is_globref',
    IO     => 'is_ioref',
    REF    => 'is_refref',
);

sub rewrite_string {
    my $string = shift;
    my $res    = rewrite_doc( PPI::Document->new(\$string) );
    return $res;
}

sub rewrite_file {
    my $file = shift;
    return rewrite_doc( PPI::Document->new($file) );
}

sub rewrite_doc {
    my $doc            = shift;
    my $all_statements = $doc->find('PPI::Statement');
    my @cond_ops       = qw<or || and &&>;
    my @new_statements;

    foreach my $statement ( @{$all_statements} ) {
        # if there's an "if()" statement, it appears as a Compound statement
        # and then each internal statement appears again,
        # causing duplication in results
        $statement->$_isa('PPI::Statement::Compound')
            and next;

        # find the 'ref' functions
        my $ref_subs = $statement->find( sub {
            $_[1]->isa('PPI::Token::Word') and $_[1]->content eq 'ref'
        }) or next;

        my $statement_def;

        REF_STATEMENT:
        foreach my $ref_sub ( @{$ref_subs} ) {
            # we want to pick up everything until we find a delimiter
            # effectively telling us we ended the parameters to "ref"
            my $sib = $ref_sub;
            my ( @func_args, $reffunc_doc, @rest_of_tokens );

            while ( $sib = $sib->next_sibling ) {
                # end of statement/expression
                my $content = $sib->content;
                $content eq ';' and last;

                # we might already have a statement
                # in this case collect all the rest of the tokens
                # (this could be in two separate loops)
                if ($statement_def) {
                    push @rest_of_tokens, $sib;
                    next;
                }

                # reasons to stop
                if ( ! $statement_def && $sib->$_isa('PPI::Token::Operator') ) {
                    # comparison operators
                    if ( $content eq 'eq' || $content eq 'ne' ) {
                        # "ARRAY" vs. $foo (which has "ARRAY" as value)
                        # we also move $sib to next significant sibling
                        my $val_token = $sib = $sib->snext_sibling;
                        my $val_str   = $val_token->$_isa('PPI::Token::Quote')
                                      ? $val_token->string
                                      : $val_token->content;

                        my $func = $reftype_to_reffunc{$val_str};
                        if ( !$func ) {
                            warn "Error: no match for $val_str\n";
                            next REF_STATEMENT;
                        }

                        $statement_def = [ $func, \@func_args, '' ];
                    } elsif ( first { $content eq $_ } @cond_ops ) {
                        # is_ref

                        # @func_args will now contain spaces too,
                        # which we will need to take out,
                        # in order to add them after the is_ref()
                        # reason those spaces don't appear in is_ref()
                        # we created is because we clean the function up
                        my $spaces_count = 0;
                        foreach my $idx ( reverse 0 .. $#func_args ) {
                            $func_args[$idx]->$_isa('PPI::Token::Whitespace')
                                ? $spaces_count++
                                : last;
                        }

                        # we should add these *and* the cond op
                        # to the statement
                        # technically we can just add them at the end
                        # but it seems easier to stick them as strings
                        # and have them parsed
                        # (wish i understood PPI better)

                        $statement_def = [
                            'is_ref',
                            \@func_args,
                            ' ' x $spaces_count . $content,
                        ];
                    } else {
                        warn "Warning: unknown operator: $sib\n";
                        next REF_STATEMENT;
                    }
                } else {
                    # otherwise, collect it as a parameter
                    push @func_args, $sib;
                }
            }

            # skip when failed (error or warnings should appear from above)
            $statement_def or next;

            my ( $func_name, $func_args, $rest ) = @{$statement_def};
            $rest .= $_ for @rest_of_tokens;
            $sib && $sib->content eq ';'
                and $rest .= ';';

            $reffunc_doc = _create_statement(
                $func_name, $func_args, $rest
            );

            # prevent garbage collection
            # FIXME: turn this into an interation that finds weaken
            # objects and unweakens them (Scalar::Util::unweaken)
            push @new_statements, $reffunc_doc;

            my $new_statement = ( $reffunc_doc->children )[0];

            $ref_sub->parent->insert_before($new_statement);
            $ref_sub->parent->remove;
        }
    }

    return "$doc";
}

sub _create_statement {
    my ( $func, $args, $rest ) = @_;
    my $args_str = join '', @{$args};
    $args_str =~ s/^\s+//;
    $args_str =~ s/\s+$//;
    $args_str =~ s/^\(+//;
    $args_str =~ s/\)+$//;
    defined $rest or $rest = '';
    return PPI::Document::Fragment->new(\"$func($args_str)$rest");
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Ref::Util::Rewriter - Rewrite your code to use Ref::Util

=head1 VERSION

version 0.003

=head1 SYNOPSIS

    use Ref::Util::Rewriter qw< rewrite_string >;
    my $new_string = rewrite_string(
        q! if ( ref($foo) eq 'HASH' ) { ... } !
    );

    # $new_string = q! if ( is_hashref($foo) ) { ... } !;

    use Ref::Util::Rewriter qw< rewrite_file >;
    rewrite_file("script.pl"); # file was now rewritten

=head1 DESCRIPTION

B<Warning:> You should take into account that the meaning of
L<Ref::Util>'s functions are subject to change with regards to
blessed objects. This might change the rewriter code in the future
to be smarter. This might also mean this won't necessarily achieve
what you're expecting.

Run it, check the diff, check your code, run your code, then
(maybe) - knowing the risk you take and absolutely no liability on
me, my family, nor my pets - merge it.

This module rewrites Perl code to use L<Ref::Util> instead of your
regular calls to C<ref>. It is much substantially faster and avoids
several mistakes that haunt beginning and advanced Perl developers.

Please review L<Ref::Util> to fully understand the possible implications
of using it in your case instead of the built-in C<ref> function.

The following constructs of code are supported:

=over 4

=item * Simple statement conditions

    ref($foo) eq 'CODE'; # -> is_coderef($foo)
    ref $foo  eq 'CODE'; # -> is_coderef($foo)
    ref $foo;            # -> is_ref($foo)

=item * Compound statement conditions

    if ( ref($foo) eq 'HASH' ) {...} # -> if( is_hashref($foo) ) {...}
    if ( ref $foo  eq 'HASH' ) {...} # -> if( is_hashref($foo) ) {...}
    if ( ref $foo )            {...} # -> if( is_ref($foo) )     {...}

=item * Postfix logical conditions

    ref($foo) eq 'ARRAY' and ... # -> is_arrayref($foo) and ...
    ref($foo) eq 'ARRAY' or  ... # -> is_arrayref($foo) or  ...
    ref($foo)            or  ... # -> is_ref($foo)      or  ...

=back

The following types of references comparisons are recognized:

=over 4

=item * C<SCALAR> = C<is_scalarref>

=item * C<ARRAY> = C<is_arrayref>

=item * C<HASH> = C<is_hashref>

=item * C<CODE> = C<is_coderef>

=item * C<Regexp> = C<is_coderef>

=item * C<GLOB> = C<is_globref>

=item * C<IO> = C<is_ioref>

=item * C<REF> = C<is_refref>

=back

=head1 SUBROUTINES

=head2 rewrite_string($perl_code_string)

Receive a string representing Perl code and return a new string in which
all C<ref> calls are replaced with the appropriate calls to L<Ref::Util>.

=head2 rewrite_file($filename)

Receive a filename as a string and rewrite the file in place (thus the
file is altered) in which all C<ref> calls are replaced with the
appropriate calls to L<Ref::Util>.

Careful, this function changes your file in place. It is advised to put
your file in some revision control so you could see what changes it has
done and commit them if you accept them.

This does B<not> add a new statement to use L<Ref::Util>, you will still
need to do that yourself.

=head2 rewrite_doc

The guts of the module which uses a direct L<PPI::Document> object and
works on that. It is used internally, but you may call it yourself if
you so wish.

=head1 AUTHOR

Sawyer X

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016 by Sawyer X.

This is free software, licensed under:

  The MIT (X11) License

=cut
