#!perl
use strict;
use warnings;
use utf8;
use Getopt::Long qw/GetOptions :config auto_help pass_through/;
use Pod::Usage;
use Plack::Runner;

use Plack::App::Directory::Markdown;

=head1 DESCRIPTION

Plack::App::Diectory::Markdown kick start script.

=head1 SYNOPSIS

    % pad-markdown.pl

    Options:
        root=s
        encoding=s
        title=s
        tx_path=s
        markdown_class=s
        markdown_ext=s
        ...and plackup options

=cut

GetOptions(\my %options, qw/
    root=s
    encoding=s
    title=s
    tx_path=s
    markdown_class=s
    markdown_ext=s
/) or pod2usage(2);

my $app = Plack::App::Directory::Markdown->new(%options)->to_app;

push @ARGV, '--port=9119' unless grep {/^(?:--?p(?:o|or|ort)?)\b/} @ARGV;
my $runner = Plack::Runner->new;
$runner->parse_options(@ARGV);
$runner->run($app);
