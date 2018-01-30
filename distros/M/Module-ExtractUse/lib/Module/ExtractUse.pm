package Module::ExtractUse;

use strict;
use warnings;
use 5.008;

use Pod::Strip;
use Parse::RecDescent 1.967009;
use Module::ExtractUse::Grammar;
use Carp;
our $VERSION = '0.342';

# ABSTRACT: Find out what modules are used

#$::RD_TRACE=1;
#$::RD_HINT=1;



sub new {
    my $class=shift;
    return bless {
        found=>{},
        files=>0,
    },$class;
}


# Regular expression to detect eval
#  On newer perl, you can use named capture groups and (?&name) for recursive regex
#  However, it requires perl newer than 5.008 declared as requirement in this module
my $re_block;
$re_block = qr {
    ( # eval BLOCK, corresponding to the group 10 in the entire regex
        \{
            ((?:
                (?> [^{}]+ )  # Non-braces without backtracking
            |
                (??{$re_block}) # Recurse to group 10
            )*)
        \}
    )
}xs;
my $re = qr{
    \G(.*?) # group 1
    eval
    (?:
        (?:\s+
            (?:
                qq?\((.*?)\) # eval q(), group 2
                |
                qq?\[(.*?)\] # eval q[], group 3
                |
                qq?{(.*?)}   # eval q{}, group 4
                |
                qq?<(.*?)>   # eval q<>, group 5
                |
                qq?(\S)(.*?)\6 # eval q'' or so, group 6, group 7
            )
        )
        |
        (?:\s*(?:
            (?:(['"])(.*?)\8) # eval '' or eval "", group 8, group 9
            |
            ( # eval BLOCK, group 10
                \{
                    ((?: # group 11
                        (?> [^{}]+ )  # Non-braces without backtracking
                    |
                        (??{$re_block}) # Recurse to group 10
                    )*)
                \}
            )
        ))
    )
}xs;

sub extract_use {
    my $self=shift;
    my $code_to_parse=shift;

    my $podless;
    my $pod_parser=Pod::Strip->new;
    $pod_parser->output_string(\$podless);
    $pod_parser->parse_characters(1) if $pod_parser->can('parse_characters');
    if (ref($code_to_parse) eq 'SCALAR') {
        $pod_parser->parse_string_document($$code_to_parse);
    }
    else {
        $pod_parser->parse_file($code_to_parse);
    }

    # Strip obvious comments.
    $podless =~ s/(^|[\};])\s*#.*$/$1/mg;

    # Strip __(DATA|END)__ sections.
    $podless =~ s/\n__(?:DATA|END)__\b.*$//s;

    my @statements;
    while($podless =~ /$re/gc) {
    # to keep parsing time short, split code in statements
    # (I know that this is not very exact, patches welcome!)
        my $pre = $1;
        my $eval = join('', grep { defined $_ } ($2, $3, $4, $5, $7, $9, $11));
        push @statements, map { [ 0, $_ ] } split(/;/, $pre); # non-eval context
        push @statements, map { [ 1, $_ ] } split(/;/, $eval); # eval context
    }
    push @statements, map { [ 0, $_ ] } split(/;/, substr($podless, pos($podless) || 0)); # non-eval context

    foreach my $statement_ (@statements) {
        my ($eval, $statement) = @$statement_;
        $statement=~s/\n+/ /gs;
        my $result;

        # now that we've got some code containing 'use' or 'require',
        # parse it! (using different entry point to save some more
        # time)
        my $type;
        if ($statement=~m/require_module|use_module|use_package_optimistically/) {
            $statement=~s/^(.*?)\b(\S+(?:require_module|use_module|use_package_optimistically)\([^)]*\))/$2/;
            next if $1 && $1 =~ /->\s*$/;
            eval {
                my $parser=Module::ExtractUse::Grammar->new();
                $result=$parser->token_module_runtime($statement);
            };
            $type = $statement =~ m/require/ ? 'require' : 'use';
        }
        elsif ($statement=~/\buse/) {
            $statement=~s/^(.*?)use\b/use/;
            next if $1 && $1 =~ /->\s*$/;
            eval {
                my $parser=Module::ExtractUse::Grammar->new();
                $result=$parser->token_use($statement.';');
            };
            $type = 'use';
        }
        elsif ($statement=~/\brequire/) {
            $statement=~s/^(.*?)require\b/require/s;
            next if $1 && $1 =~ /->\s*$/;
            eval {
                my $parser=Module::ExtractUse::Grammar->new();
                $result=$parser->token_require($statement.';');
            };
            $type = 'require';
        }
        elsif ($statement=~/\bno/) {
            $statement=~s/^(.*?)no\b/no/s;
            next if $1 && $1 =~ /->\s*$/;
            eval {
                my $parser=Module::ExtractUse::Grammar->new();
                $result=$parser->token_no($statement.';');
            };
            $type = 'no';
        }
        elsif ($statement=~m/load_class|try_load_class|load_first_existing_class|load_optional_class/) {
            $statement=~s/^(.*?)\b(\S+(?:load_class|try_load_class|load_first_existing_class|load_optional_class)\([^)]*\))/$2/;
            next if $1 && $1 =~ /->\s*$/;
            eval {
                my $parser=Module::ExtractUse::Grammar->new();
                $result = $parser->token_class_load($statement.';');
            };
            $type = 'require';
        }

        next unless $result;

        foreach (split(/\s+/,$result)) {
            $self->_add($_, $eval, $type) if($_);
        }
    }

    # increment file counter
    $self->_inc_files;

    return $self;
}



sub used {
    my $self=shift;
    my $key=shift;
    return $self->{found}{$key} if ($key);
    return $self->{found};
}


sub used_in_eval {
    my $self=shift;
    my $key=shift;
    return $self->{found_in_eval}{$key} if ($key);
    return $self->{found_in_eval};
}


sub used_out_of_eval {
    my $self=shift;
    my $key=shift;
    return $self->{found_not_in_eval}{$key} if ($key);
    return $self->{found_not_in_eval};
}


sub required {
    my $self=shift;
    my $key=shift;
    return $self->{require}{$key} if ($key);
    return $self->{require};
}


sub required_in_eval {
    my $self=shift;
    my $key=shift;
    return $self->{require_in_eval}{$key} if ($key);
    return $self->{require_in_eval};
}


sub required_out_of_eval {
    my $self=shift;
    my $key=shift;
    return $self->{require_not_in_eval}{$key} if ($key);
    return $self->{require_not_in_eval};
}


sub noed {
    my $self=shift;
    my $key=shift;
    return $self->{no}{$key} if ($key);
    return $self->{no};
}


sub noed_in_eval {
    my $self=shift;
    my $key=shift;
    return $self->{no_in_eval}{$key} if ($key);
    return $self->{no_in_eval};
}


sub noed_out_of_eval {
    my $self=shift;
    my $key=shift;
    return $self->{no_not_in_eval}{$key} if ($key);
    return $self->{no_not_in_eval};
}


sub string {
    my $self=shift;
    my $sep=shift || ' ';
    return join($sep,sort keys(%{$self->{found}}));
}


sub string_in_eval {
    my $self=shift;
    my $sep=shift || ' ';
    return join($sep,sort keys(%{$self->{found_in_eval}}));
}


sub string_out_of_eval {
    my $self=shift;
    my $sep=shift || ' ';
    return join($sep,sort keys(%{$self->{found_not_in_eval}}));
}


sub array {
    return keys(%{shift->{found}})
}


sub array_in_eval {
    return keys(%{shift->{found_in_eval}})
}


sub array_out_of_eval {
    return keys(%{shift->{found_not_in_eval}})
}


sub arrayref { 
    my @a=shift->array;
    return \@a if @a;
    return;
}


sub arrayref_in_eval {
    my @a=shift->array_in_eval;
    return \@a if @a;
    return;
}


sub arrayref_out_of_eval {
    my @a=shift->array_out_of_eval;
    return \@a if @a;
    return;
}


sub files {
    return shift->{files};
}

# Internal Accessor Methods
sub _add {
    my $self=shift;
    my $found=shift;
    my $eval=shift;
    my $type=shift;
    $self->{found}{$found}++;
    $self->{$type}{$found}++;
    if ($eval) {
        $self->{found_in_eval}{$found}++;
        $self->{"${type}_in_eval"}{$found}++;
    } else {
        $self->{found_not_in_eval}{$found}++;
        $self->{"${type}_not_in_eval"}{$found}++;
    }
}

sub _found {
    return shift->{found}
}

sub _inc_files {
    shift->{files}++
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Module::ExtractUse - Find out what modules are used

=head1 VERSION

version 0.342

=head1 SYNOPSIS

  use Module::ExtractUse;
  
  # get a parser
  my $p=Module::ExtractUse->new;
  
  # parse from a file
  $p->extract_use('/path/to/module.pm');
  
  # or parse from a ref to a string in memory
  $p->extract_use(\$string_containg_code);
  
  # use some reporting methods
  my $used=$p->used;           # $used is a HASHREF
  print $p->used('strict')     # true if code includes 'use strict'
  
  my @used=$p->array;
  my $used=$p->string;
  
  # you can get optional modules, that is use in eval context, in the same style
  my $used=$p->used_in_eval;           # $used is a HASHREF
  print $p->used_in_eval('strict')     # true if code includes 'use strict'
  
  my @used=$p->array_in_eval;
  my $used=$p->string_in_eval;
  
  # and mandatory modules, that is use out of eval context, in the same style, also.
  my $used=$p->used_out_of_eval;           # $used is a HASHREF
  print $p->used_out_of_eval('strict')     # true if code includes 'use strict'
  
  my @used=$p->array_out_of_eval;
  my $used=$p->string_out_of_eval;

=head1 DESCRIPTION

Module::ExtractUse is basically a L<Parse::RecDescent> grammar to parse
Perl code. It tries very hard to find all modules (whether pragmas,
Core, or from CPAN) used by the parsed code.

"Usage" is defined by either calling C<use> or C<require>.

=head2 Methods

=head3 new

 my $p=Module::ExtractUse->new;

Returns a parser object

=head3 extract_use

  $p->extract_use('/path/to/module.pm');
  $p->extract_use(\$string_containg_code);

Runs the parser.

C<$code_to_parse> can be either a SCALAR, in which case
Module::ExtractUse tries to open the file specified in
$code_to_parse. Or a reference to a SCALAR, in which case
Module::ExtractUse assumes the referenced scalar contains the source
code.

The code will be stripped from POD (using L<Pod::Strip>) and split on ";"
(semicolon). Each statement (i.e. the stuff between two semicolons) is
checked by a simple regular expression.

If the statement contains either 'use' or 'require', the statement is
handed over to the parser, who then tries to figure out, B<what> is
used or required. The results will be saved in a data structure that
you can examine afterwards.

You can call C<extract_use> several times on different files. It will
count how many files where examined and how often each module was used.

=head2 Accessor Methods

Those are various ways to get at the result of the parse.

Note that C<extract_use> returns the parser object, so you can say

  print $p->extract_use($code_to_parse)->string;

=head3 used

    my $used=$p->used;           # $used is a HASHREF
    print $p->used('strict')     # true if code includes 'use strict'

If called without an argument, returns a reference to an hash of all
used modules. Keys are the names of the modules, values are the number
of times they were used.

If called with an argument, looks up the value of the argument in the
hash and returns the number of times it was found during parsing.

This is the preferred accessor.

=head3 used_in_eval

Same as C<used>, except for considering in-eval-context only.

=head3 used_out_of_eval

Same as C<used>, except for considering NOT-in-eval-context only.

=head3 required

Same as C<used>, except for considering 'require'd modules only.

=head3 required_in_eval

Same as C<required>, except for considering in-eval-context only.

=head3 required_out_of_eval

Same as C<required>, except for considering NOT-in-eval-context only.

=head3 noed

Same as C<used>, except for considering 'no'ed modules only.

=head3 noed_in_eval

Same as C<noed>, except for considering in-eval-context only.

=head3 noed_out_of_eval

Same as C<noed>, except for considering NOT-in-eval-context only.

=head3 string

    print $p->string($seperator)

Returns a sorted string of all used modules, joined using the value of
C<$seperator> or using a blank space as a default;

Module names are sorted by ascii value (i.e by C<sort>)

=head3 string_in_eval

Same as C<string>, except for considering in-eval-context only.

=head3 string_out_of_eval

Same as C<string>, except for considering NOT-in-eval-context only.

=head3 array

    my @array = $p->array;

Returns an array of all used modules.

=head3 array_in_eval

Same as C<array>, except for considering in-eval-context only.

=head3 array_out_of_eval

Same as C<array>, except for considering NOT-in-eval-context only.

=head3 arrayref

    my $arrayref = $p->arrayref;

Returns a reference to an array of all used modules. Surprise!

=head3 arrayref_in_eval

Same as C<array_ref>, except for considering in-eval-context only.

=head3 arrayref_out_of_eval

Same as C<array_ref>, except for considering NOT-in-eval-context only.

=head3 files

Returns the number of files parsed by the parser object.

=head1 RE-COMPILING THE GRAMMAR

If - for some reasons - you need to alter the grammar, edit the file
F<grammar> and afterwards run:

  perl -MParse::RecDescent - grammar Module::ExtractUse::Grammar

Make sure you're in the right directory, i.e. in F<.../Module/ExtractUse/>

=head1 EXPORTS

Nothing.

=head1 SEE ALSO

L<Parse::RecDescent>, L<Module::Extract::Use>, L<Module::ScanDeps>, L<Module::Info>, L<Module::CPANTS::Analyse>

=head1 CONTRIBUTORS

=over

=item * L<Anthony Brummett|https://github.com/brummett> implemented support for Module::Runtime and Class::Load while participating in the L<CPAN Pull Request Challenge|http://cpan-prc.org/>

=item * L<Jeremy Mates|https://github.com/thrig> fixed some documentation errors

=item * Jonathan Yu provided a nice script, C<example/extractuse.pl>

=back

If I forgot to mention your contribution, please send an email or open an issue / ticket.

=head1 AUTHORS

=over 4

=item *

Thomas Klausner <domm@cpan.org>

=item *

Kenichi Ishigaki <kishigaki@gmail.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Thomas Klausner.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
