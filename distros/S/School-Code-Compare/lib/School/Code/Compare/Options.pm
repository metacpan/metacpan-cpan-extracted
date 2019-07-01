package School::Code::Compare::Options;
# ABSTRACT: don't clutter app with parsing of arguments
$School::Code::Compare::Options::VERSION = '0.101';
use strict;
use warnings;

use OptArgs;

my $opt = undef;

sub new {
    my $class = shift;

    my $self;

    if (not defined $opt) {

        my $s = '                    ';
        my $opt_desc_dir =
            "$s" . 'Input can otherwise also be specified over:'
        . "\n$s" . '  - the option --file / -f'
        . "\n$s" . '  - STDIN, receiving filepaths (e.g. from a find command)';

        my $opt_desc_in =
            "$s" . 'Supportet arguments:'
        . "\n$s" . '  - hashy:  python, perl, bash'
        . "\n$s" . '  - slashy: php, js, java, cpp, cs, c'
        . "\n$s" . '  - html, xml'
        . "\n$s" . '  - txt (default)';

        my $opt_desc_out =
            "$s" . 'You can define an output format:'
        . "\n$s" . '  - html'
        . "\n$s" . '  - tab (default)'
        . "\n$s" . '  - csv';

        my $opt_desc_persist =
            "$s" . 'Saved in local directory with name pattern:'
        . "\n$s" . '  - comparison_[year-month-day-hour-minute]_[method].[format]';

        my $opt_desc_charset =
            "$s" . 'Define one or more subsets of chars, used to compare the files:'
        . "\n$s" . '  - visibles'
        . "\n$s" . '      all chars without witespace'
        . "\n$s" . '  - numsignes (default)'
        . "\n$s" . '      like visibles, but words ignored in meaning (but not in position)'
        . "\n$s" . '  - signes'
        . "\n$s" . '      only special chars, no words or numbers';

        my $opt_desc_yes =
            "$s" . 'Program will start working without further confirmation.'
        . "\n$s" . '(Answer all user prompts with [yes])';

        my $opt_desc_all =
            "$s" . "Don't hide skipped comparisons."
        . "\n$s" . 'Will somethimes cause a lot of output.';

        my $opt_desc_mime =
            "$s" . 'This options needs the Perl Library File::LibMagic installed.'
        . "\n$s" . 'You will also need libmagic development files on your system.';

        my $opt_desc_sort =
            "$s" . 'Useful to ignore order of method declaration.'
        . "\n$s" . 'Will most likely also find more false positives.';

        my $opt_desc_basedir =
            "$s" . 'Folders one below will be seen as project directories.'
        . "\n$s" . 'Files inside projects will not be compared with each other.'
        . "\n$s" . '(This will currently not work on Windows)';

        arg dir => (
            isa      => 'ArrayRef',
            greedy   => 1,
            comment  => "analyse files in given directory\n" . $opt_desc_dir,
        );

        opt in => (
            isa      => 'Str',
            alias   => 'i',
            default  => 'txt',
            comment  => "input format, optimize for language\n" . $opt_desc_in,
        );

        opt file => (
            isa     => 'Str',
            alias   => 'f',
            comment => 'file to read from (containing filepaths)',
        );

        opt out => (
            isa     => 'Str',
            alias   => 'o',
            default => 'tab',
            comment => "output format\n" . $opt_desc_out,
        );

        opt persist => (
            isa     => 'Bool',
            alias   => 'p',
            default =>  0,
            comment => "print result to file (instead STDOUT)\n" . $opt_desc_persist,
        );

        opt charset => (
            isa     => 'Str',
            alias   => 'c',
            default => 'numsignes',
            comment => "chars used for comparison\n" . $opt_desc_charset,
        );

        opt yes => (
            isa     => 'Bool',
            alias   => 'y',
            default =>  0,
            comment => "Don't prompt for questions\n" . $opt_desc_yes,
        );

        opt all => (
            isa     => 'Bool',
            alias   => 'a',
            default =>  0,
            comment => "show all results in output\n" . $opt_desc_all,
        );

        opt help => (
            isa     => 'Bool',
            alias   => 'h',
            comment => 'show this manual',
            ishelp  => 1,
        );

        opt verbose => (
            isa     => 'Bool',
            alias   => 'v',
            default =>  0,
            comment => 'show actually compared data on STDERR',
        );

        opt mime => (
            isa     => 'Bool',
            alias   => 'm',
            default =>  0,
            comment => "only compare if same MIME-type\n" . $opt_desc_mime,
        );

        opt sort => (
            isa     => 'Bool',
            alias   => 's',
            default =>  0,
            comment => "sort data by line before comparison\n" . $opt_desc_sort,
        );

        opt basedir => (
            isa     => 'Str',
            alias   => 'b',
            comment => "skip comparisons within projects under base directory\n"
                       . $opt_desc_basedir,
        );

        $OptArgs::SORT = 1;

        $self = optargs;

        bless $self, $class;

        $opt = $self;

    }
    else {
        $self = $opt;
    }
    return $self;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

School::Code::Compare::Options - don't clutter app with parsing of arguments

=head1 VERSION

version 0.101

=head1 AUTHOR

Boris Däppen <bdaeppen.perl@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Boris Däppen.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
