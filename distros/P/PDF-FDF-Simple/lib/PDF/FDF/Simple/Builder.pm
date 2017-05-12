package PDF::FDF::Simple::Builder;

use strict;
use warnings;

use Module::Build;
use File::Copy "mv";

use vars qw(@ISA);
@ISA = ("Module::Build");

sub ACTION_grammar
{
        require Parse::RecDescent;

        my $grammar_file ='lib/auto/PDF/FDF/Simple/grammar';
        open GRAMMAR_FILE, $grammar_file or die "Cannot open grammar file ".$grammar_file;
        local $/;
        my $grammar = <GRAMMAR_FILE>;

        Parse::RecDescent->Precompile($grammar, "PDF::FDF::Simple::Grammar");
        my $target = "lib/PDF/FDF/Simple/Grammar.pm";
        mv "Grammar.pm", $target;
        print "Updated $target\n";
}


1;

=pod

=head1 NAME

PDF::FDF::Simple::Builder - Module::Build extensions for PDF::FDF::Simple

=head1 SYNOPSIS

 perl Build.PL
 ./Build grammar
 ./Build
 ./Build test
 ./Build install

=head1 DESCRIPTION

Provides Module::Build extensions, mainly for precompiling the grammar
file.

=head1 FUNCTIONS

=head2 ACTION_grammar

This defines an Build action C<grammar> which precompiles the grammar
using Parse::RecDescent and moves the file to
lib/PDF/FDF/Simple/Grammar.pm. It is usually done by the maintainer,
before he builds a dist file for CPAN.

=head1 AUTHOR

=over 4

=item *

Steffen Schwigon <ss5@renormalist.net>,

=back

=cut
