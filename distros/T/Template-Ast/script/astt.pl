#: astt.pl
#: Combining Perl AST with template file using
#:   Perl Template Toolkit
#: Template-Ast v0.01
#: Copyright (C) 2005 Agent Zhang.
#: 2005-07-03 2005-07-18

use strict;
use warnings;

use Getopt::Std;
use Template;
use Template::Ast;

my %opts;
getopts('ho:t:', \%opts);

Usage(0) if $opts{h};

my $ttfile = $opts{t};
my $outfile = $opts{o};
$outfile = '-' unless defined $outfile;

Usage(1) unless $ttfile and @ARGV;

my $ast;
foreach my $astfile (@ARGV) {
    my $temp = Template::Ast->read($astfile);
    die Template::Ast->error() unless $temp;
    $ast = Template::Ast->merge($ast, $temp);
}

my $tt = Template->new;
$tt->process($ttfile, $ast, $outfile)
    || die $tt->error;

sub Usage {
    my $retval = shift;
    my $info = <<'_EOC_';
Usage: astt [-h] [-o <output-file>] -t <template-file> <ast-file1> <ast-file2> ...
Options:
    -h                 Print this help to stdout.
    -o output-file     Specify the output file name. I will print to
                       stdout if this option is omitted.
    -t template-file   Specify the Perl Template Toolkit template file.

Report bugs to Agent Zhang <agent2002@126.com>.
_EOC_
    if ($retval == 0) {
        print $info;
        exit(0);
    }
    warn $info;
    exit($retval);
}

0;
__END__

=head1 NAME

astt - tpage-like tool that combines Perl AST with template file

=head1 SYNOPSIS

    astt -h
    astt -t foo.tt foo.ast > foo.htm
    astt -o test.htm -t test.tt test.ast

    # Apply multiple ASTs to one template file:
    astt -o foo -t foo.tt ast1 ast2 ast3

=head1 USAGE

  astt [-h] [-o <output-file>] -t <template-file> <ast-file1> <ast-file2> ...

=head1 OPTIONS

=over

=item -h

Print this help to stdout.

=item -o I<output-file>

Specify the output file name. I will print to stdout if this option is omitted.

=item -t I<template-file>

Specify the Perl Template Toolkit template file.

=back

=head1 DESCRIPTION

This tool is similar to Perl Template Toolkit's B<tpage.pl> script in some way, but
is much more powerful. With tpage, one can only assign values to template variables
using the I<--define> option. Whereas, one has the ability to apply an extremely
complicated Perl data structures (we will call it AST here) to the template
file. Such data structure is defined in a separated file in the form of Perl codes.
An example is as follows:

    $vars = [ { name => 'John', age => 17 }, { name => 'Marry', age => 12 } ];

The data structure must be assigned to a variable named $vars. Please don't use
"my" or "our" to qualify the variable.

It is strongly recommended to utilize the Perl core module Data::Dumper to
generate the AST automatically if the AST is huge. I'd like to give an instance
here:

    # astgen.pl
    use Data::Dumper;

    my $vars = ... # build the AST in a tricky way
    my $code = Data::Dumper->Dump([$vars], [qw(vars)]);
    open my $fh, '>foo.ast' or die $!;
    print $fh $code;
    close $fh;

After you run your F<astgen.pl>, you will get a perfect AST file named F<foo.ast>
which can be used with my astt tool.

If multiple AST files are passed to C<astt>, it will use the Template::Ast->merge
method to merge the input files from left to right. The AST applied to the template
file will the data structure after merging.

=head1 SEE ALSO

L<Template::Manual>,
L<Template::Ast>,
L<Data::Dumper>

=head1 AUTHOR

Agent Zhang (ียาเดบ), E<lt>agent2002@126.comE<gt>

=head1 COPYRIGHT

Copyright (C) 2005 by Agent Zhang.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
