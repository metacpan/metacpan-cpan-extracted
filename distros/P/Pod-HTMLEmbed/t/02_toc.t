use Test::More;
use FindBin;
use Pod::HTMLEmbed;

eval "use Text::Markdown; 1;";
plan skip_all => "Text::Markdown is required to run this test"
    if $@;

my $finder = Pod::HTMLEmbed->new(
    search_dir => ["$FindBin::Bin/pod"],
);

{
    my $pod = $finder->find('MyTestDoc');
    my $toc_expected = <<__TOC__;
* [NAME](#NAME)
* [SYNOPSIS](#SYNOPSIS)
* [AUTHOR](#AUTHOR)
* [SEE ALSO](#SEE%20ALSO)
__TOC__

    is $pod->toc,
        join('', split "\n", Text::Markdown::markdown($toc_expected)), 'toc ok';
}

{
    my $pod = $finder->find('MyTestDoc2');
    my $toc_expected = <<__TOC__;
* [NAME](#NAME)
* [SYNOPSIS](#SYNOPSIS)
* [DESCRIPTION](#DESCRIPTION)
   * [SECOND](#SECOND)
      * [THIRD](#THIRD)
* [METHODS](#METHODS)
   * [new](#new)
   * [hello](#hello)
* [AUTHOR](#AUTHOR)
* [SEE ALSO](#SEE%20ALSO)
__TOC__

    is $pod->toc,
        join('', split "\n", Text::Markdown::markdown($toc_expected)), 'toc2 ok';
}

done_testing;
