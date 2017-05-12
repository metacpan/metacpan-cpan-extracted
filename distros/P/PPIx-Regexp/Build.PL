use 5.006;

use strict;
use warnings;

use lib qw{ inc };

use Module::Build;
use My::Module::Build;
use My::Module::Meta;

(my $mbv = Module::Build->VERSION()) =~ s/_//g;

my $meta = My::Module::Meta->new();

my %args = (
    dist_author => 'Thomas R. Wyant, III F<wyant at cpan dot org>',
    dist_abstract => 'Parse regular expressions',
    module_name => 'PPIx::Regexp',
    build_requires => $meta->build_requires(),
    requires => $meta->requires(
	perl => $meta->requires_perl(),
    ),
    license => 'perl',
    add_to_cleanup	=> [ qw{ cover_db } ],
);

$mbv >= 0.28
    and $args{meta_merge} = $meta->meta_merge();

# Don't require Module::Build when building distribution, because user
# can use ExtUtils::MakeMaker.
$mbv >= 0.34
    and $args{auto_configure_requires} = !$meta->distribution();

my $bldr = My::Module::Build->new (%args);

$bldr->create_build_script ();

# ex: set textwidth=72 :
