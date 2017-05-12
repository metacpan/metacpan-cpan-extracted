use strict;
use warnings;

use 5.006;

use lib qw{ inc };

use Module::Build;
use My::Module::Build;
use My::Module::Meta;
use My::Module::Recommend;

(my $mbv = Module::Build->VERSION()) =~ s/_//g;

my $meta = My::Module::Meta->new();

my %args = (
    dist_author => 'Thomas R. Wyant, III F<wyant at cpan dot org>',
    dist_abstract => 'Parse Perl string literals and string-literal-like things.',
    module_name => 'PPIx::QuoteLike',
    build_requires => $meta->build_requires(),
    requires => $meta->requires(
	perl => $meta->requires_perl(),
    ),
    license => 'perl',
    add_to_cleanup => [ qw{ cover_db xt/author/optionals } ],
);


$mbv >= 0.28
    and $args{meta_merge} = $meta->meta_merge();

$mbv >= 0.34
    and $args{auto_configure_requires} = 0;	# Don't require Module::Build

My::Module::Recommend->recommend();

my $bldr = My::Module::Build->new (%args);

$bldr->create_build_script ();
