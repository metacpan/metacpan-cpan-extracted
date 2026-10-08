#!perl
use strict;
use warnings;
use 5.010;

our $VERSION = '0.001';

use Test2::V0;

use Carp;
use FileHandle ();
use File::Path qw( make_path );
use File::Spec ();
use File::Temp ();
use Cwd        qw( getcwd abs_path );

use Software::Policies;

my $BASIC_V1_MARKDOWN = <<'EOF';
# ADOPTION

If you're interested in adopting this module, and the author/maintainer
appears to be no longer active, please consult the PAUSE module
adoption process documented at
https://metacpan.org/about/faq#how-to-adopt-a-distribution.

The PAUSE admins (modules@perl.org) may grant co-maintainer or
primary-maintainer permissions to a suitable adopter if:

- There has been no release for a year or more, AND
- There are outstanding issues, pull requests, or bug reports that would
  benefit from attention, AND
- Reasonable attempts to contact me have failed, for example:
  email Test Runner <test.runner@example.com>,
  GitHub issues on the project repository, and any other channels listed
  in this distribution, over a period of at least one month, AND
- The prospective adopter intends to make changes that benefit users of
  the module.

In the event of my death or permanent incapacity, my heirs are not
obligated to maintain these modules, and I explicitly authorize the
PAUSE admins to transfer maintainership without further consultation
once the conditions above are met.
EOF

subtest 'Create MaintainerSuccession' => sub {
    my %wanted = (
        policy   => 'MaintainerSuccession',
        class    => 'Basic',
        version  => 1,
        text     => $BASIC_V1_MARKDOWN,
        filename => 'MAINTAINER_SUCCESSION.md',
        format   => 'markdown',
    );
    my @p = Software::Policies->new->create(
        policy     => 'MaintainerSuccession',
        class      => 'Basic',
        version    => 1,
        format     => 'markdown',
        attributes => {
            authors => [ 'Test Runner <test.runner@example.com>', 'Test Runner 2 <test.runner.2@example.com>', ],

            # issues_name => 'GitHub Issues',
            # issues_url => 'https://github.com/author/project/issues',
            # adoption_process_name => 'PAUSE module adoption process',
        },
    );
    is( $p[0], \%wanted, 'MaintainerSuccession (format markdown) is equal' );

    done_testing;
};

subtest 'Faulty attributes' => sub {
    like(
        dies {
            Software::Policies->new->create(
                policy     => 'MaintainerSuccession',
                class      => 'Basic',
                version    => 1,
                format     => 'markdown',
                attributes => {},
            )
        },
        qr{^ Missing \s attributes: \s authors .* $}msx,
        'missing attributes, dies as planned',
    );
    done_testing;
};

done_testing;
